# Auto-generated client for Semantria v4.0
# Source: https://api.apis.guru/v2/specs/semantria.com/4.0/swagger.json
# Auth: --token flag or $env.SEMANTRIA_TOKEN

const BASE_URL = "https://api.semantria.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SEMANTRIA_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.semantria.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "blacklist-content-type delete-items" } } | get name | first)
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

# Remove items from blacklist
#
# DELETE /blacklist.{content_type}
# operationId: deleteBlacklistItems
export def "blacklist-content-type delete-items" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration blacklist items linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve blacklisted items
#
# GET /blacklist.{content_type}
# operationId: getBlacklist
export def "blacklist-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration blacklist linked to.
]: nothing -> table<id: string, modified: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add items to blacklist
#
# POST /blacklist.{content_type}
# operationId: addBlacklist
export def "blacklist-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Update items in blacklist
#
# PUT /blacklist.{content_type}
# operationId: updateBlacklist
export def "blacklist-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration blacklist linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/blacklist.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Remove user categories
#
# DELETE /categories.{content_type}
# operationId: deleteCategories
export def "categories-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user categories linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve user categories
#
# GET /categories.{content_type}
# operationId: getCategories
export def "categories-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user categories linked to.
]: nothing -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add user categories
#
# POST /categories.{content_type}
# operationId: addCategories
export def "categories-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Updates user categories
#
# PUT /categories.{content_type}
# operationId: updateCategories
export def "categories-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user categories linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, samples: list<string>, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/categories.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Queue collection for analysis
#
# POST /collection.{content_type}
# operationId: queueCollection
export def "collection-content-type create-queue" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<documents: list<string>, id: string, job_id: string, tag: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/collection.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve collections analysis
#
# GET /collection/processed.{content_type}
# operationId: retrieveProcessedCollections
export def "collection-processed-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/collection/processed.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Cancel collection analysis
#
# DELETE /collection/{collection_id}.{content_type}
# operationId: cancelCollection
export def "collection cancel" [
  collection_id: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), content_type: (encode-path-segment $content_type)} | format pattern "/collection/{collection_id}.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve collection analysis or its status in queue
#
# GET /collection/{collection_id}.{content_type}
# operationId: receiveCollectionAnalyticData
export def "collection receive-analytic-data" [
  collection_id: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<config_id: string, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, facets: table<attributes: list, count: int, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int>, id: string, job_id: string, status: string, tag: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), content_type: (encode-path-segment $content_type)} | format pattern "/collection/{collection_id}.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove user configurations
#
# DELETE /configurations.{content_type}
# operationId: deleteConfigurations
export def "configurations-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve user configurations
#
# GET /configurations.{content_type}
# operationId: getConfigurations
export def "configurations-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}") $auth.query)
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

# Create user configurations
#
# POST /configurations.{content_type}
# operationId: addConfigurations
export def "configurations-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}") $auth.query)
  let req_body = $body
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Update user configurations
#
# PUT /configurations.{content_type}
# operationId: updateConfigurations
export def "configurations-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: record
]: any -> table<auto_response: bool, callback: string, categories_threshold: float, chars_threshold: int, collection: record<attribute_mentions_limit: int, concept_topics_limit: int, facet_atts_limit: int, facet_mentions_limit: int, facets_limit: int, named_entities_limit: int, named_mentions_limit: int, query_topics_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int>, config_id: string, document: record<auto_categories_limit: int, concept_topics_limit: int, detect_language: bool, entity_themes_limit: int, intentions: bool, model_sentiment: bool, named_entities_limit: int, named_mentions_limit: int, named_opinions_limit: int, named_relations_limit: int, phrases_limit: int, pos_types: string, possible_phrases_limit: int, query_topics_limit: int, summary_limit: int, theme_mentions_limit: int, themes_limit: int, user_entities_limit: int, user_mentions_limit: int, user_opinions_limit: int, user_relations_limit: int>, entities_threshold: int, from_template_config_id: string, is_primary: bool, language: string, modified: string, name: string, one_sentence: bool, process_html: bool, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/configurations.{content_type}") $auth.query)
  let req_body = $body
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
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Queue document for analysis
#
# POST /document.{content_type}
# operationId: queueDocument
export def "document-content-type create-queue" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<id: string, job_id: string, tag: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Queue batch of documents for analysis
#
# POST /document/batch.{content_type}
# operationId: queueBatchOfDocuments
export def "document-batch-content-type create-queue" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
  --body: record
]: any -> record<id: string, job_id: string, tag: string, text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document/batch.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve documents analysis
#
# GET /document/processed.{content_type}
# operationId: retrieveProcessedDocuments
export def "document-processed-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/document/processed.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Cancel document analysis
#
# DELETE /document/{document_id}.{content_type}
# operationId: cancelDocument
export def "document cancel" [
  document_id: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), content_type: (encode-path-segment $content_type)} | format pattern "/document/{document_id}.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve document analysis or its status in queue
#
# GET /document/{document_id}.{content_type}
# operationId: receiveDocumentAnalyticData
export def "document receive-analytic-data" [
  document_id: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration used for analysis.
]: nothing -> record<auto_categories: table<categories: list, sentiment_polarity: string, sentiment_score: float, strength_score: float, title: string, type: string>, config_id: string, details: table<is_imperative: bool, is_polar: bool, words: list>, entities: table<count: int, entity_type: string, label: string, mentions: list, negative_count: int, neutral_count: int, positive_count: int, title: string, type: string>, id: string, intentions: table<evidence_phrase: string, type: string, what: string, who: string>, job_id: string, language: string, language_score: float, model_sentiment: record<mixed_score: float, model_name: string, negative_score: float, neutral_score: float, positive_score: float, sentiment_polarity: string>, opinions: table<quotation: string, sentiment_polarity: string, sentiment_score: float, speaker: float, topic: string, type: string>, phrases: table<intensifying_phrase: string, is_intensified: bool, is_negated: bool, negating_phrase: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, relations: table<confidence_score: float, entities: list, extra: string, relation_type: string, type: string>, sentiment_polarity: string, sentiment_score: float, source_text: string, status: string, summary: string, taxonomy: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>, themes: table<mentions: list, normalized: string, phrases_count: int, sentiment_polarity: string, sentiment_score: float, stemmed: string, themes_count: int, title: string>, topics: table<hitcount: int, id: string, sentiment_polarity: string, sentiment_score: float, title: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'document_id' must be non-empty" } }
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id), content_type: (encode-path-segment $content_type)} | format pattern "/document/{document_id}.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove user entities
#
# DELETE /entities.{content_type}
# operationId: deleteEntities
export def "entities-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [200 202]
}

# Retrieve user entities
#
# GET /entities.{content_type}
# operationId: getEntities
export def "entities-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user entities linked to.
]: nothing -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add user entities
#
# POST /entities.{content_type}
# operationId: addEntities
export def "entities-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Update user entities
#
# PUT /entities.{content_type}
# operationId: updateEntities
export def "entities-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration user entities linked to.
  --body: record
]: any -> table<id: string, label: string, modified: string, name: string, normalized: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/entities.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve supported features
#
# GET /features.{content_type}
# operationId: getFeatures
export def "features-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language: string # Filter features by specified language
]: nothing -> table<detailed_mode: record<auto_categories: bool, entity_mentions: bool, entity_opinions: bool, entity_relations: bool, entity_themes: bool, intentions: bool, language_detection: bool, model_sentiment: bool, named_entities: bool, pos_tagging: bool, queries: bool, sentiment: bool, sentiment_phrases: bool, summarization: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, discovery_mode: record<entity_mentions: bool, facet_attributes: bool, facet_mentioins: bool, facets: bool, named_entities: bool, queries: bool, taxonomy: bool, theme_mentions: bool, themes: bool, user_categories: bool, user_entities: bool>, html_processing: bool, id: string, language: string, one_sentence_mode: bool, settings: record<blacklist: bool, queries: bool, sentiment_phrases: bool, taxonomy: bool, user_categories: bool, user_entities: bool>, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/features.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Remove sentiment-bearing phrases
#
# DELETE /phrases.{content_type}
# operationId: deletePhrases
export def "phrases-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration phrases linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve sentiment-bearing phrases
#
# GET /phrases.{content_type}
# operationId: getPhrases
export def "phrases-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration phrases linked to.
]: nothing -> table<id: string, modified: string, name: string, weight: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add sentiment-bearing phrases
#
# POST /phrases.{content_type}
# operationId: addPhrases
export def "phrases-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Updates sentiment-bearing phrases
#
# PUT /phrases.{content_type}
# operationId: updatePhrases
export def "phrases-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration phrases linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, weight: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/phrases.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Remove queries
#
# DELETE /queries.{content_type}
# operationId: deleteQueries
export def "queries-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve queries
#
# GET /queries.{content_type}
# operationId: getQueries
export def "queries-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
]: nothing -> table<id: string, modified: string, name: string, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add or update queries
#
# POST /queries.{content_type}
# operationId: addQueries
export def "queries-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, query: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Update queries
#
# PUT /queries.{content_type}
# operationId: updateQueries
export def "queries-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<id: string, modified: string, name: string, query: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/queries.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve usage statistics
#
# GET /statistics.{content_type}
# operationId: getStatistic
export def "statistics-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Configuration identifier for usage statistics retrieving.
  --interval: string # Hour, Day, Week, Month, Year values are supported.
]: nothing -> record<calls_data: int, calls_polling: int, calls_settings: int, colls_documents: int, colls_failed: int, colls_processed: int, colls_responded: int, configurations: table<calls_data: int, calls_polling: int, calls_settings: int, colls_failed: int, colls_processed: int, colls_responded: int, config_id: string, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, used_apps: string>, docs_failed: int, docs_processed: int, docs_responded: int, latest_used_app: string, name: string, overall_batches: int, overall_calls: int, overall_docs: int, overall_exceeded: int, overall_texts: int, overcall_colls: int, status: string, used_apps: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/statistics.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id, "interval": $interval} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve API status
#
# GET /status.{content_type}
# operationId: getStatus
export def "status-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<api_version: string, service_status: string, service_version: string, supported_compression: string, supported_encoding: string, supported_languages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/status.{content_type}") $auth.query)
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

# Retrieve subscription details
#
# GET /subscription.{content_type}
# operationId: getSubscription
export def "subscription-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<basic_settings: record<auto_response_limit: int, batch_limit: int, blacklist_limit: int, callback_batch_limit: int, categories_limit: int, category_samples_limit: int, characters_limit: int, collection_limit: int, configurations_limit: int, entities_limit: int, output_data_limit: int, processed_batch_limit: int, queries_limit: int, return_source_text: bool, sentiment_limit: int>, billing_settings: record<app_seats_allocated: int, app_seats_permitted: int, data_calls_balance: int, data_calls_limit: int, data_calls_limit_interval: int, docs_balance: int, docs_limit: int, docs_limit_interval: int, docs_suggested: int, docs_suggested_interval: int, expiration_date: string, limit_type: string, polling_calls_balance: int, polling_calls_limit: int, polling_calls_limit_interval: int, priority: string, settings_calls_balance: int, settings_calls_limit: int, settings_calls_limit_interval: int>, feature_settings: record<collection: record<concept_topics: bool, facets: bool, mentions: bool, named_entities: bool, query_topics: bool, themes: bool, user_entities: bool>, document: record<auto_categories: bool, concept_topics: bool, entity_themes: bool, intentions: bool, language_detection: bool, mentions: bool, model_sentiment: bool, named_entities: bool, named_relations: bool, opinions: bool, phrases_detection: bool, pos_tagging: bool, query_topics: bool, sentiment_phrases: bool, summary: bool, themes: bool, user_entities: bool, user_relations: bool>, html_processing: bool, supported_languages: string, templates: record<config_id: string, description: string, id: string, is_free: bool, language: string, name: string, type: string, version: string>>, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/subscription.{content_type}") $auth.query)
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

# Remove taxonomy nodes
#
# DELETE /taxonomy.{content_type}
# operationId: deleteTaxonomy
export def "taxonomy-content-type delete" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Retrieve taxonomy
#
# GET /taxonomy.{content_type}
# operationId: getTaxonomy
export def "taxonomy-content-type get" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration taxonomy linked to.
]: nothing -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 202]
}

# Add taxonomy nodes
#
# POST /taxonomy.{content_type}
# operationId: addTaxonomy
export def "taxonomy-content-type create" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 202]
}

# Update taxonomy nodes
#
# PUT /taxonomy.{content_type}
# operationId: updateTaxonomy
export def "taxonomy-content-type update" [
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --config-id: string # Identifier of configuration queries linked to.
  --body: record
]: any -> table<enforce_parent_matching: bool, id: string, modified: string, name: string, nodes: list<any>, topics: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($content_type | is-empty) { error make --unspanned { msg: "path parameter 'content_type' must be non-empty" } }
  let qp = [(serialize-qp "config_id" $config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({content_type: (encode-path-segment $content_type)} | format pattern "/taxonomy.{content_type}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"config_id": $config_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 202]
}
