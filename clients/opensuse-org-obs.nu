# Auto-generated client for Open Build Service API v2.10.50
# Source: https://api.apis.guru/v2/specs/opensuse.org/obs/2.10.50/openapi.json
# Auth: --token flag or $env.OPEN_BUILD_SERVICE_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_BUILD_SERVICE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def cmd-completer [] { ["abortbuild" "killbuild" "rebuild" "restartbuild" "sendsysrq" "unpublish" "wipe"] }
def view-completer [] { ["binarylist" "status" "summary"] }
def view-completer-1 [] { ["order" "pkgnames" "revpkgnames"] }
def cmd-completer-1 [] { ["add_user" "remove_user" "set_email"] }
def cmd-completer-2 [] { ["register"] }
def cmd-completer-3 [] { ["change_password" "delete" "lock"] }
def operation-completer [] { ["rebuild" "release" "runservice"] }
def accept-completer [] { ["application/*" "text/xml"] }
def view-completer-2 [] { ["status"] }
def cmd-completer-4 [] { ["create"] }
def addrevision-completer [] { ["1"] }
def ignore-delegate-completer [] { ["1"] }
def ignore-build-state-completer [] { ["1"] }
def view-completer-3 [] { ["xml"] }
def withissues-completer [] { ["1" "true"] }
def accept-completer-1 [] { ["application/xml; charset=utf-8" "text/plain; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "about get" } } | get name | first)
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

# Get information about API.
#
# GET /about
export def "about get" [
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
  let full_url = (build-url $base "/about")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all known architectures.
#
# GET /architectures
export def "architectures list" [
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
  let full_url = (build-url $base "/architectures")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show one architecture.
#
# GET /architectures/{architecture_name}
export def "architectures get" [
  architecture_name: string
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
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  let full_url = (build-url $base ({architecture_name: (encode-path-segment $architecture_name)} | format pattern "/architectures/{architecture_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all attribute namespaces.
#
# GET /attribute
export def "attribute list" [
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
  let full_url = (build-url $base "/attribute")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an attribute namespace and all attributes below.
#
# DELETE /attribute/{namespace}
export def "attribute delete-by-namespace" [
  namespace: any
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all attributes below a namespace.
#
# GET /attribute/{namespace}
export def "attribute get" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an attribute namespace and all attributes below.
#
# DELETE /attribute/{namespace}/_meta
export def "attribute-meta delete-by-namespace" [
  namespace: any
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}/_meta"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show attribute namespace.
#
# GET /attribute/{namespace}/_meta
export def "attribute-meta list" [
  namespace: any
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}/_meta"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change attribute namespace. Create an attribute namespace if it doesn't exist.
#
# POST /attribute/{namespace}/_meta
export def "attribute-meta create-by-namespace" [
  namespace: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}/_meta"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Change attribute namespace. Create an attribute namespace if it doesn't exist.
#
# PUT /attribute/{namespace}/_meta
export def "attribute-meta update-by-namespace" [
  namespace: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace)} | format pattern "/attribute/{namespace}/_meta"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Delete an attribute and all its values in projects or packages.
#
# DELETE /attribute/{namespace}/{attribute_name}
export def "attribute delete-by-namespace-attribute-name" [
  namespace: any
  attribute_name: string
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attribute_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/attribute/{namespace}/{attribute_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete an attribute and all its values in projects or packages.
#
# DELETE /attribute/{namespace}/{attribute_name}/_meta
export def "attribute-meta delete-by-namespace-attribute-name" [
  namespace: any
  attribute_name: any
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attribute_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/attribute/{namespace}/{attribute_name}/_meta"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Shows attribute.
#
# GET /attribute/{namespace}/{attribute_name}/_meta
export def "attribute-meta get" [
  namespace: any
  attribute_name: any
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
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attribute_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/attribute/{namespace}/{attribute_name}/_meta"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Change attribute data. Create an attribute if it doesn't exist.
#
# POST /attribute/{namespace}/{attribute_name}/_meta
export def "attribute-meta create-by-namespace-attribute-name" [
  namespace: any
  attribute_name: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attribute_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/attribute/{namespace}/{attribute_name}/_meta"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Change attribute data. Create an attribute if it doesn't exist.
#
# PUT /attribute/{namespace}/{attribute_name}/_meta
export def "attribute-meta update-by-namespace-attribute-name" [
  namespace: any
  attribute_name: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($namespace | is-empty) { error make --unspanned { msg: "path parameter 'namespace' must be non-empty" } }
  if ($attribute_name | is-empty) { error make --unspanned { msg: "path parameter 'attribute_name' must be non-empty" } }
  let full_url = (build-url $base ({namespace: (encode-path-segment $namespace), attribute_name: (encode-path-segment $attribute_name)} | format pattern "/attribute/{namespace}/{attribute_name}/_meta"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Get a simple directory listing of all projects
#
# GET /build
export def "build get" [
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
  let full_url = (build-url $base "/build")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a simple directory listing of all repositories for the specified project
#
# GET /build/{project_name}
export def "build get-by-project-name" [
  project_name: string
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/build/{project_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Apply different actions on builds/build processes of the specified project
#
# POST /build/{project_name}
export def "build create" [
  project_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string # Name of the package. Scope the commands to the specified package. (e.g. firefox)
  --arch: string # Name of the build architecture. Scope the commands to the specified architectures. (e.g. x86_64)
  --repository: string # Name of the repository. Scope the commands to the specified repository. (e.g. openSUSE_Leap_15.2)
  --cmd: string@cmd-completer # **NOTE**: All commands described below, can be scoped to a package within the project by setting the `package` parameter. * `wipe`: Delete all binaries build by the project. * `restartbuild`: Restart all running build processes inside the project. * `rebuild`: Trigger a rebuild of all packages inside the project. * `abortbuild`: Abort all running build processes for the specified project, marking them as failed. * `killbuild`: Alias for `abortbuild`. * `unpublish`: Delete all published package binaries, for the specified project, from the download repository. * `sendsysrq`: Send a single sysrq character to the kernel of a running build. Character need to be specified through the `sysrq` parameter. Only a subset of debugging requests are supported (eg. 9, t or w).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  let qp = [(serialize-qp "package" $package "scalar") (serialize-qp "arch" $arch "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "cmd" $cmd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/build/{project_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"package": $package, "arch": $arch, "repository": $repository, "cmd": $cmd} | compact), body: null}
}

# Get the build results for packages, architectures and repositories of the specified project.
#
# GET /build/{project_name}/_result
export def "build-result get" [
  project_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer # Specify which sections should be included in the result list. * `status`: Include detailed infos about the build status. **Default** * `summary`: Include the summary of the status values. * `binarylist`: Include a list of generated binary files.
  --package: string # Name of the package. Limit results to the specified package. (e.g. obs-server)
  --arch: string # Name of the build architecture. Limit results to the specified build architecture. (e.g. x86_64)
  --repository: string # Name of the repository. Limit results to the specified repository. (e.g. openSUSE_Leap_15.2)
  --lastbuild: oneof<nothing, bool> # Show the last build result (excludes current building job states). (e.g. 1)
  --locallink: oneof<nothing, bool> # Include build results from packages with project local links. (e.g. 1)
  --multibuild: oneof<nothing, bool> # Include build results from _multibuild definitions. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "arch" $arch "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "lastbuild" $lastbuild "scalar") (serialize-qp "locallink" $locallink "scalar") (serialize-qp "multibuild" $multibuild "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/build/{project_name}/_result") $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"view": $view, "package": $package, "arch": $arch, "repository": $repository, "lastbuild": $lastbuild, "locallink": $locallink, "multibuild": $multibuild} | compact), body: null}
}

# List of all architectures the specified project builds against a given repository.
#
# GET /build/{project_name}/{repository_name}
export def "build get-by-project-name-repository-name" [
  project_name: any
  repository_name: string
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/build/{project_name}/{repository_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show the build configuration for the specified repository.
#
# GET /build/{project_name}/{repository_name}/_buildconfig
export def "build-buildconfig get" [
  project_name: any
  repository_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/build/{project_name}/{repository_name}/_buildconfig"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show the build dependencies of packages that are part of the project.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/_builddepinfo
export def "build-builddepinfo get" [
  project_name: any
  repository_name: any
  architecture_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --package: string # Name of the package. Limit results to the specified package. (e.g. obs-server)
  --view: string@view-completer-1 # * `pkgnames`: Show whole package dependencies, instead of individual binaries. * `revpkgnames`: Show which packages depend on the provided project/package for the given repository/architecture, and therefore a rebuild gets triggered on change. * `order`: Show packages ordered by dependencies.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  let qp = [(serialize-qp "package" $package "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/_builddepinfo") $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"package": $package, "view": $view} | compact), body: null}
}

# List all binaries (produced by all packages of the given project).
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/_repository
export def "build-repository get" [
  project_name: any
  repository_name: any
  architecture_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/_repository"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List binaries built by the sources of the specified package.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}
export def "build get-by-project-name-repository-name-architecture-name-package-name" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: string
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This endpoint returns information about some specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_buildinfo
# operationId: getBuildProjectRepositoryArchPackageBuildinfo
export def "build-buildinfo get-arch" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_buildinfo"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This endpoint returns the build history for a specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_history
# operationId: getBuildProjectRepositoryArchPackageHistory
export def "build-history get-arch" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_history"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show the build status of a currently running build job.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_jobstatus
export def "build-jobstatus get" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_jobstatus"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This endpoint returns the last log file for a specific build artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_log
# operationId: getBuildProjectRepositoryArchPackageLog
export def "build-log get-arch" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_log"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show the reason for the lastly triggered build.
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_reason
export def "build-reason get" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_reason"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This endpoint returns the building status for a specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_status
# operationId: getBuildProjectRepositoryArchPackageStatus
export def "build-status get-arch" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/_status"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return a specific artifact file contents
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}
# operationId: getBuildProjectRepositoryArchitecturePackageFile
export def "build get-by-project-name-repository-name-architecture-name-package-name-file-name" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'file_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name), file_name: (encode-path-segment $file_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}"))
  let accept_val = "application/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a specific artifact file contents
#
# PUT /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}
# operationId: putBuildProjectRepositoryArchitecturePackageFile
export def "build update" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: list
  file_name: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'file_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-array $package_name), file_name: (encode-path-segment $file_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "plain/text" $req_body {query: {}, body: $req_body}
}

# This endpoint returns details about an specific artifact
#
# GET /build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}?view=fileinfo
# operationId: getBuildProjectRepositoryArchitecturePackageFileViewFileinfo
export def "build get-view-fileinfo" [
  project_name: any
  repository_name: any
  architecture_name: any
  package_name: any
  file_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: list<string>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($package_name | is-empty) { error make --unspanned { msg: "path parameter 'package_name' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'file_name' must be non-empty" } }
  let qp = [(serialize-qp "view" $view "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), package_name: (encode-path-segment $package_name), file_name: (encode-path-segment $file_name)} | format pattern "/build/{project_name}/{repository_name}/{architecture_name}/{package_name}/{file_name}?view=fileinfo") $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"view": $view} | compact), body: null}
}

# Display the configuration of this Open Build Service instance
#
# GET /configuration
export def "configuration get" [
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
  let full_url = (build-url $base "/configuration")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the configuration of this Open Build Service instance
#
# PUT /configuration
export def "configuration update" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# List all distributions.
#
# GET /distributions
export def "distributions list" [
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
  let full_url = (build-url $base "/distributions")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a distribution.
#
# POST /distributions
export def "distributions create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/distributions")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Bulk replace all distributions.
#
# PUT /distributions/bulk_replace
export def "distributions-bulk-replace update" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/distributions/bulk_replace")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# List all distributions including remote.
#
# GET /distributions/include_remotes
export def "distributions-include-remotes get" [
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
  let full_url = (build-url $base "/distributions/include_remotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a distribution.
#
# DELETE /distributions/{distribution_id}
export def "distributions delete" [
  distribution_id: any
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
  if ($distribution_id | is-empty) { error make --unspanned { msg: "path parameter 'distribution_id' must be non-empty" } }
  let full_url = (build-url $base ({distribution_id: (encode-path-segment $distribution_id)} | format pattern "/distributions/{distribution_id}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show a distribution.
#
# GET /distributions/{distribution_id}
export def "distributions get" [
  distribution_id: int
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
  if ($distribution_id | is-empty) { error make --unspanned { msg: "path parameter 'distribution_id' must be non-empty" } }
  let full_url = (build-url $base ({distribution_id: (encode-path-segment $distribution_id)} | format pattern "/distributions/{distribution_id}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a distribution.
#
# PUT /distributions/{distribution_id}
export def "distributions update" [
  distribution_id: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($distribution_id | is-empty) { error make --unspanned { msg: "path parameter 'distribution_id' must be non-empty" } }
  let full_url = (build-url $base ({distribution_id: (encode-path-segment $distribution_id)} | format pattern "/distributions/{distribution_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# List available groups.
#
# GET /group
export def "group list" [
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
  let full_url = (build-url $base "/group")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a group.
#
# DELETE /group/{group_title}
export def "group delete" [
  group_title: any
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
  if ($group_title | is-empty) { error make --unspanned { msg: "path parameter 'group_title' must be non-empty" } }
  let full_url = (build-url $base ({group_title: (encode-path-segment $group_title)} | format pattern "/group/{group_title}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Read group data.
#
# GET /group/{group_title}
export def "group get" [
  group_title: string
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
  if ($group_title | is-empty) { error make --unspanned { msg: "path parameter 'group_title' must be non-empty" } }
  let full_url = (build-url $base ({group_title: (encode-path-segment $group_title)} | format pattern "/group/{group_title}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Modify group data.
#
# POST /group/{group_title}
export def "group create" [
  group_title: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-1 # Command to be executed. It takes one of these available values: * `add_user`: add a user to a group. `userid` query parameter must be also used. * `remove_user`: remove a user from a group. `userid` query parameter must be also used. * `set_email`: set email adress of group. `email` query parameter must be also used.
  --userid: string # User login. Used with `cmd=add_user` or `cmd=remove_user`.
  --email: string # Group email. Used with `cmd=set_email`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($group_title | is-empty) { error make --unspanned { msg: "path parameter 'group_title' must be non-empty" } }
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "userid" $userid "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_title: (encode-path-segment $group_title)} | format pattern "/group/{group_title}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cmd": $cmd, "userid": $userid, "email": $email} | compact), body: null}
}

# Write group data.
#
# PUT /group/{group_title}
export def "group update" [
  group_title: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($group_title | is-empty) { error make --unspanned { msg: "path parameter 'group_title' must be non-empty" } }
  let full_url = (build-url $base ({group_title: (encode-path-segment $group_title)} | format pattern "/group/{group_title}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Get the list of issue trackers.
#
# GET /issue_trackers
export def "issue-trackers list" [
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
  let full_url = (build-url $base "/issue_trackers")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an issue tracker.
#
# POST /issue_trackers
export def "issue-trackers create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issue_trackers")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Delete an issue tracker.
#
# DELETE /issue_trackers/{issue_tracker_name}
export def "issue-trackers delete" [
  issue_tracker_name: any
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
  if ($issue_tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'issue_tracker_name' must be non-empty" } }
  let full_url = (build-url $base ({issue_tracker_name: (encode-path-segment $issue_tracker_name)} | format pattern "/issue_trackers/{issue_tracker_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show an issue tracker.
#
# GET /issue_trackers/{issue_tracker_name}
export def "issue-trackers get" [
  issue_tracker_name: string
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
  if ($issue_tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'issue_tracker_name' must be non-empty" } }
  let full_url = (build-url $base ({issue_tracker_name: (encode-path-segment $issue_tracker_name)} | format pattern "/issue_trackers/{issue_tracker_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update or create an issue tracker.
#
# PUT /issue_trackers/{issue_tracker_name}
export def "issue-trackers update" [
  issue_tracker_name: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($issue_tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'issue_tracker_name' must be non-empty" } }
  let full_url = (build-url $base ({issue_tracker_name: (encode-path-segment $issue_tracker_name)} | format pattern "/issue_trackers/{issue_tracker_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Show an issue of an issue tracker.
#
# GET /issue_trackers/{issue_tracker_name}/issues/{issue_name}
export def "issue-trackers-issues get" [
  issue_tracker_name: any
  issue_name: string
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
  if ($issue_tracker_name | is-empty) { error make --unspanned { msg: "path parameter 'issue_tracker_name' must be non-empty" } }
  if ($issue_name | is-empty) { error make --unspanned { msg: "path parameter 'issue_name' must be non-empty" } }
  let full_url = (build-url $base ({issue_tracker_name: (encode-path-segment $issue_tracker_name), issue_name: (encode-path-segment $issue_name)} | format pattern "/issue_trackers/{issue_tracker_name}/issues/{issue_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all people.
#
# GET /person
export def "person list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prefix: string # A prefix to filter the people to look for (e.g. Adm)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "prefix" $prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/person" $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"prefix": $prefix} | compact), body: null}
}

# Executes a command on the person endpoint.
#
# POST /person
export def "person create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-2 # The command to execute (e.g. register)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/person" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: ({"cmd": $cmd} | compact), body: $req_body}
}

# Registers a new person
#
# POST /person/register
export def "person-register create" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/person/register")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Get details about a person
#
# GET /person/{login}
export def "person get" [
  login: string
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
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Perform changes on a registered person
#
# POST /person/{login}
export def "person create-by-login" [
  login: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-3 # The command to execute against the provided person. (e.g. change_password)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let qp = [(serialize-qp "cmd" $cmd "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/plain" $req_body {query: ({"cmd": $cmd} | compact), body: $req_body}
}

# Update person
#
# PUT /person/{login}
export def "person update" [
  login: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# List the groups of a person
#
# GET /person/{login}/group
export def "person-group get" [
  login: any
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
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}/group"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the authentication tokens of a person.
#
# GET /person/{login}/token
export def "person-token get" [
  login: any
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
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}/token"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new authentication token for a person.
#
# POST /person/{login}/token
export def "person-token create" [
  login: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string # Project name. Should be provided, together with the package query parameter, to limit the token to a specific package. (e.g. home:hans)
  --package: string # Package name. Should be provided, together with the project query parameter, to limit the token to a specific package. (e.g. gchz)
  --operation: string@operation-completer # Operation indicates the kind of token that is going to be created. When operation is not specified, 'runservice' is the default value. (e.g. runservice)
  --scm-token: string # **(Beta/Unstable)** SCM token used in OBS workflows to report back the workflow status, when the operation is workflow. It's normally possible to generate SCM tokens directly on the SCM's website like GitHub or GitLab. (e.g. ghp_fake_token_123)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "scm_token" $scm_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({login: (encode-path-segment $login)} | format pattern "/person/{login}/token") $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"project": $project, "package": $package, "operation": $operation, "scm_token": $scm_token} | compact), body: null}
}

# Delete a token of a person.
#
# DELETE /person/{login}/token/{id}
export def "person-token delete" [
  login: any
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
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({login: (encode-path-segment $login), id: (encode-path-segment $id)} | format pattern "/person/{login}/token/{id}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all the published projects.
#
# GET /published
export def "published get" [
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
  let full_url = (build-url $base "/published")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the repositories of a project with published binaries
#
# GET /published/{project_name}
export def "published get-by-project-name" [
  project_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name)} | format pattern "/published/{project_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the content of the directory tree where the binaries are published at the level project/repository.
#
# GET /published/{project_name}/{repository_name}
export def "published get-by-project-name-repository-name" [
  project_name: any
  repository_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/published/{project_name}/{repository_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the content of the directory tree where the binaries are published at the level project/repository/architecture.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}
export def "published get-by-project-name-repository-name-architecture-name" [
  project_name: any
  repository_name: any
  architecture_name: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name)} | format pattern "/published/{project_name}/{repository_name}/{architecture_name}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return the binary file itself.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}
export def "published get-by-project-name-repository-name-architecture-name-binary-filename" [
  project_name: any
  repository_name: any
  architecture_name: any
  binary_filename: string
  --base-url(-b): string@base-url-completer # API base URL
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($binary_filename | is-empty) { error make --unspanned { msg: "path parameter 'binary_filename' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), binary_filename: (encode-path-segment $binary_filename)} | format pattern "/published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}"))
  let accept_val = ($accept | default "application/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate a ymp pattern that includes the needed repositories to install the given binary.
#
# GET /published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}?view=ymp
export def "published get-by-project-name-repository-name-architecture-name-binary-filename-1" [
  project_name: any
  repository_name: any
  architecture_name: any
  binary_filename: any
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
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($binary_filename | is-empty) { error make --unspanned { msg: "path parameter 'binary_filename' must be non-empty" } }
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name), architecture_name: (encode-path-segment $architecture_name), binary_filename: (encode-path-segment $binary_filename)} | format pattern "/published/{project_name}/{repository_name}/{architecture_name}/{binary_filename}?view=ymp"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Present information about the last publication of the pair project and repository.
#
# GET /published/{project_name}/{repository_name}?view=status
export def "published get-by-project-name-repository-name-1" [
  project_name: any
  repository_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view: string@view-completer-2 # Set this parameter to status in order to get details about the last publication. (e.g. status)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($project_name | is-empty) { error make --unspanned { msg: "path parameter 'project_name' must be non-empty" } }
  if ($repository_name | is-empty) { error make --unspanned { msg: "path parameter 'repository_name' must be non-empty" } }
  let qp = [(serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_name: (encode-path-segment $project_name), repository_name: (encode-path-segment $repository_name)} | format pattern "/published/{project_name}/{repository_name}?view=status") $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"view": $view} | compact), body: null}
}

# Get a simple directory listing of all requests
#
# GET /request
export def "request list" [
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
  let full_url = (build-url $base "/request")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a request
#
# POST /request
export def "request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string@cmd-completer-4 # This endpoint will refuse the creation of a new request if this parameter is not set.
  --addrevision: string@addrevision-completer # Ask the server to add revisions of the current sources to the request.
  --ignore-delegate: string@ignore-delegate-completer # Enforce a new package instance in a project which has OBS:DelegateRequestTarget set
  --ignore-build-state: string@ignore-build-state-completer # Skip the build state check
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "addrevision" $addrevision "scalar") (serialize-qp "ignore_delegate" $ignore_delegate "scalar") (serialize-qp "ignore_build_state" $ignore_build_state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/request" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: ({"cmd": $cmd, "addrevision": $addrevision, "ignore_delegate": $ignore_delegate, "ignore_build_state": $ignore_build_state} | compact), body: $req_body}
}

# Delete a given request.
#
# DELETE /request/{id}
export def "request delete" [
  id: any
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/request/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show details about a specified request.
#
# GET /request/{id}
export def "request get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --withhistory: string # Include the request history in the results. (e.g. 1)
  --withfullhistory: string # Includes both, request and review history in the results. (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "withhistory" $withhistory "scalar") (serialize-qp "withfullhistory" $withfullhistory "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/request/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"withhistory": $withhistory, "withfullhistory": $withfullhistory} | compact), body: null}
}

# Apply certain actions on a specified request.
#
# POST /request/{id}
export def "request create-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cmd: string # - `addreview`: Add a review to a request. **NOTE:** You need to specify who has to address the review by providing an additional paramter. Possible options are: * by_user * by_group * by_project - `assignreview`: Accept a review for a given group and assign a new review to a specific user. **NOTE:** You need to pass the group name in the `by_group` parameter and the new reviewer in the `reviewer` parameter. - `changestate`: Modify the state of a given request. **NOTE:** You need to pass the new state throug the `newstate` parameter. Changing from one state to another is in certain cases not allowed. You can still force the operation by using the `force=1` parameter. - `changereviewstate`: Change the state of a review inside a given request. - `setpriority`: Change the priority of a given request. You have to pass the choosen priority through the `priority` parameter. Possible values are: * low * moderate * important * critical - `setincident`: Change the target incident for maintenance_incident actions **NOTE:** You need to provide the incident number through the `incident` parameter. - `setacceptat`: Set or modify the accept_at time. Either specified by the `time` parameter or by default set to now. - `approve`: Pre-approve a request in the review state. It will turn into state `accepted` after the last review. - `cancelapproval`: Reset the approval of a request
  --newstate: string # Define the new state
  --priority: string # Define the new priority
  --by-user: string # Specify the user of a new review
  --by-group: string # Specify the group of the new review
  --by-project: string # Specify the project of the new review
  --by-package: string # Specify the package of the new review
  --incident: string # Specify the incident number for `setincident`
  --time: string # Specify the time for `setacceptat`
  --comment: string # Add a comment to one of the actions
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "cmd" $cmd "scalar") (serialize-qp "newstate" $newstate "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "by_user" $by_user "scalar") (serialize-qp "by_group" $by_group "scalar") (serialize-qp "by_project" $by_project "scalar") (serialize-qp "by_package" $by_package "scalar") (serialize-qp "incident" $incident "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/request/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"cmd": $cmd, "newstate": $newstate, "priority": $priority, "by_user": $by_user, "by_group": $by_group, "by_project": $by_project, "by_package": $by_package, "incident": $incident, "time": $time, "comment": $comment} | compact), body: null}
}

# Modify a given request.
#
# PUT /request/{id}
export def "request update" [
  id: any
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/request/{id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: {}, body: $req_body}
}

# Get the diff for all packages affected by the request.
#
# POST /request/{id}?cmd=diff
export def "request create-by-id-1" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --diff-to-superseded: string # Diff relative to a given superseded request. State the id of the corresponding superseded request. (e.g. 10401)
  --view: string@view-completer-3 # Set this parameter to xml in order to receive a structured diff instead of plain text.
  --withissues: string@withissues-completer # Include parsed issues
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "diff_to_superseded" $diff_to_superseded "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "withissues" $withissues "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/request/{id}?cmd=diff") $qp)
  let accept_val = ($accept | default "application/xml; charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"diff_to_superseded": $diff_to_superseded, "view": $view, "withissues": $withissues} | compact), body: null}
}

# Get a collection of requests for a specified target
#
# GET /request?view=collection
export def "request-viewcollection get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Filter the results of requests and open reviews for a certain user. If no other parameters are applied, it will include requests where the user is maintainer of the target or the creator of the request. (e.g. hans)
  --project: string # Limit the results of requests and open review requests to the specified target project. (e.g. home:hans)
  --package: string # Limit the results of requests and open review requests to the specified target package. (e.g. ruby)
  --states: string # Limit results to a given request state. Multiple states can be provided as a comma separated list. (e.g. new,review)
  --types: string # Limit the results to certain action types. Multiple types can be provided as a comma separated list. (e.g. add_role,submit)
  --roles: string # Limit the results to a given role. Multiple roles can be provided as a comma separated list. (e.g. creator,maintainer,reviewer,source,target)
  --withhistory: string # Include the request history in the results. (e.g. 1)
  --withfullhistory: string # Includes both, request and review history in the results. (e.g. 1)
  --limit: int # Limit the results to the specified amount of requests. (e.g. 7)
  --ids: string # Limit the result to specified request id's. Multiple id's can be provided as a comma separated list. (e.g. 15,19,23)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "package" $package "scalar") (serialize-qp "states" $states "scalar") (serialize-qp "types" $types "scalar") (serialize-qp "roles" $roles "scalar") (serialize-qp "withhistory" $withhistory "scalar") (serialize-qp "withfullhistory" $withfullhistory "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/request?view=collection" $qp)
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user": $user, "project": $project, "package": $package, "states": $states, "types": $types, "roles": $roles, "withhistory": $withhistory, "withfullhistory": $withfullhistory, "limit": $limit, "ids": $ids} | compact), body: null}
}

# Lists status of workers, jobs, backend services and general statistics.
#
# GET /worker/status
export def "worker-status get" [
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
  let full_url = (build-url $base "/worker/status")
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists capabilites of a worker.
#
# GET /worker/{architecture_name}:{worker_id}
export def "worker get" [
  architecture_name: any
  worker_id: string
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
  if ($architecture_name | is-empty) { error make --unspanned { msg: "path parameter 'architecture_name' must be non-empty" } }
  if ($worker_id | is-empty) { error make --unspanned { msg: "path parameter 'worker_id' must be non-empty" } }
  let full_url = (build-url $base ({architecture_name: (encode-path-segment $architecture_name), worker_id: (encode-path-segment $worker_id)} | format pattern "/worker/{architecture_name}:{worker_id}"))
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists workers which match a constraints filter.
#
# POST /worker?cmd=checkconstraints
export def "worker-cmdcheckconstraints create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project: string # Project name. (e.g. home:user1)
  --repository: string # Repository name. (e.g. openSUSE_Tumbleweed)
  --arch: string # Architecture name. (e.g. x86_64)
  --package: string # Package name. (e.g. test_package)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "repository" $repository "scalar") (serialize-qp "arch" $arch "scalar") (serialize-qp "package" $package "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/worker?cmd=checkconstraints" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml; charset=utf-8" $req_body {query: ({"project": $project, "repository": $repository, "arch": $arch, "package": $package} | compact), body: $req_body}
}
