# Auto-generated client for OSF APIv2 Documentation v2.0
# Source: https://api.apis.guru/v2/specs/osf.io/2.0/openapi.json
# Auth: --token flag or $env.OSF_APIV2_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.test.osf.io/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o OSF_APIV2_DOCUMENTATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.test.osf.io/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["*/*" "application/json"] }
def accept-completer-1 [] { ["data" "meta"] }
def accept-completer-2 [] { ["application/json" "links" "meta"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "base get" } } | get name | first)
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

# Root
#
# GET /
# operationId: base_read
export def "base get" [
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

# Actions
#
# GET /actions/
# operationId: logs_actions
export def "actions logs" [
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
  let full_url = (build-url $base "/actions/" $auth.query)
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

# List all addons
#
# GET /addons/
# operationId: addons_list
export def "addons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addons/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all citation styles
#
# GET /citations/styles/
# operationId: citations_styles_list
export def "citations-styles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/citations/styles/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a citation style
#
# GET /citations/styles/{style_id}/
# operationId: citations_styles_read
export def "citations-styles get" [
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($style_id | is-empty) { error make --unspanned { msg: "path parameter 'style_id' must be non-empty" } }
  let full_url = (build-url $base ({style_id: (encode-path-segment $style_id)} | format pattern "/citations/styles/{style_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all Collections
#
# GET /collections/
# operationId: collections_list
export def "collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a Collection
#
# POST /collections/
# operationId: collections_create
export def "collections create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections/" $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a Collection
#
# DELETE /collections/{collection_id}/
# operationId: collections_delete
export def "collections delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/") $auth.query)
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

# Retrieve a Collection
#
# GET /collections/{collection_id}/
# operationId: collections_detail
export def "collections get-detail" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bookmarks: bool, collected_type_choices: list, date_created: string, date_modified: string, is_promoted: bool, is_public: bool, issue_choices: list, program_area_choices: list, status_choices: list, title: string, volume_choices: list>, id: string, links: record<self: string>, relationships: record<collected_metadata: string, linked_nodes: string, linked_preprints: string, linked_registrations: string, node_links: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a list of collected metadata for a collection
#
# GET /collections/{collection_id}/collected_metadata/
# operationId: collections_metadata_registrations_list
export def "collections-collected-metadata list-registrations" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/collected_metadata/") $auth.query)
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

# Add Metadata or Subjects to a Entity in a Collection
#
# POST /collections/{collection_id}/collected_metadata/
# operationId: collections_add_metadata
export def "collections-collected-metadata create" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/collected_metadata/") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete Collection Metadata from entitiy
#
# DELETE /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_delete
export def "collections-collected-metadata delete" [
  collection_id: string
  cgm_id: string
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
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}") $auth.query)
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

# Retrieve Specific Metadata for a Collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_registrations_detail
export def "collections-collected-metadata get-registrations-detail" [
  collection_id: string
  cgm_id: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}") $auth.query)
  let accept_val = ($accept | default "data")
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

# Add Metadata or Subjects to an Entity in a Collection
#
# POST /collections/{collection_id}/collected_metadata/{cgm_id}
# operationId: collections_metadata_detail
export def "collections-collected-metadata create-detail" [
  collection_id: string
  cgm_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve subject metadata for a specific piece of metadata in a collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/
# operationId: collections_metadata_subjects_relationships
export def "collections-collected-metadata-relationships-subjects get" [
  collection_id: string
  cgm_id: string
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
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/") $auth.query)
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

# Update subjects for a specific piece of metadata in a collection
#
# POST /collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/
# operationId: collections_metadata_subjects_relationships_update
export def "collections-collected-metadata-relationships-subjects update" [
  collection_id: string
  cgm_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}/relationships/subjects/") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve subject data for a specific piece of metadata info for a collection
#
# GET /collections/{collection_id}/collected_metadata/{cgm_id}/subjects/
# operationId: collections_collected_metadata
export def "collections-collected-metadata-subjects get" [
  collection_id: string
  cgm_id: string
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
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($cgm_id | is-empty) { error make --unspanned { msg: "path parameter 'cgm_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), cgm_id: (encode-path-segment $cgm_id)} | format pattern "/collections/{collection_id}/collected_metadata/{cgm_id}/subjects/") $auth.query)
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

# List All Linked Nodes for a Collection
#
# GET /collections/{collection_id}/linked_nodes
# operationId: collections_linked_nodes_list
export def "collections-linked-nodes list" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_nodes") $auth.query)
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

# Remove Nodes From Collection
#
# DELETE /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships_delete
export def "collections-linked-nodes-relationships delete" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_nodes/relationships/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Give a Sparse List of Node Ids
#
# GET /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships_create
export def "collections-linked-nodes-relationships create-by-collection-id" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_nodes/relationships/") $auth.query)
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

# Link Nodes to Collection
#
# POST /collections/{collection_id}/linked_nodes/relationships/
# operationId: collections_linked_nodes_relationships
export def "collections-linked-nodes-relationships create-by-collection-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_nodes/relationships/") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List All Linked Preprints for a Collection
#
# GET /collections/{collection_id}/linked_preprints/
# operationId: collections_linked_preprints_list
export def "collections-linked-preprints list" [
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
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_preprints/") $auth.query)
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

# List All Linked Registrations for a Collection
#
# GET /collections/{collection_id}/linked_registrations/
# operationId: collections_linked_registrations_list
export def "collections-linked-registrations list" [
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
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_registrations/") $auth.query)
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

# Remove Registrations From Collection
#
# DELETE /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships_delete
export def "collections-linked-registrations-relationships delete" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_registrations/relationships/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Give a Sparse List of Registrations Ids
#
# GET /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships_create
export def "collections-linked-registrations-relationships create-by-collection-id" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_registrations/relationships/") $auth.query)
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

# Link Registrations to Collection
#
# POST /collections/{collection_id}/linked_registrations/relationships/
# operationId: collections_linked_registrations_relationships
export def "collections-linked-registrations-relationships create-by-collection-id-1" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/collections/{collection_id}/linked_registrations/relationships/") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a comment
#
# DELETE /comments/{comment_id}/
# operationId: comments_delete
export def "comments delete" [
  comment_id: string
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
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/comments/{comment_id}/") $auth.query)
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

# Retrieve a comment
#
# GET /comments/{comment_id}/
# operationId: comments_read
export def "comments get" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/comments/{comment_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a comment
#
# PUT /comments/{comment_id}/
# operationId: comments_put
export def "comments update" [
  comment_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/comments/{comment_id}/") $auth.query)
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

# Retrieve a list of Draft Registrations
#
# GET /draft_registrations/
# operationId: draft_registrations_read
export def "draft-registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft_registrations/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a Draft Registration
#
# POST /draft_registrations/
# operationId: draft_registrations_create
# --attributes shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
export def "draft-registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft_registrations/" $auth.query)
  let req_body = {"attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "*/*")
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

# Delete a draft registration
#
# DELETE /draft_registrations/{draft_id}/
export def "draft-registrations delete" [
  draft_id: string
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
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/") $auth.query)
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

# Retrieve a Draft Registration
#
# GET /draft_registrations/{draft_id}/
export def "draft-registrations get" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a Draft Registration
#
# PATCH /draft_registrations/{draft_id}/
export def "draft-registrations update" [
  draft_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Retreive a list Contributors from a Draft Registration
#
# GET /draft_registrations/{draft_id}/contributors/
# operationId: draft_registration_contributors_list
export def "draft-registrations-contributors list" [
  draft_id: string
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
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/contributors/") $auth.query)
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

# Add a contributor to a Draft Registration
#
# POST /draft_registrations/{draft_id}/contributors/
# operationId: draft_registration_contributors_create
# --attributes shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
# --relationships shape: {user: string}
export def "draft-registrations-contributors create" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/contributors/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retreive a Contributor from a Draft Registration
#
# GET /draft_registrations/{draft_id}/contributors/{user_id}/
export def "draft-registrations-contributors get" [
  draft_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id), user_id: (encode-path-segment $user_id)} | format pattern "/draft_registrations/{draft_id}/contributors/{user_id}/") $auth.query)
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

# Retrieve Institutions afilliated with a Draft Registration
#
# GET /draft_registrations/{draft_id}/institutions/
export def "draft-registrations-institutions get" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/institutions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve Subjects associated with a Draft Registration
#
# GET /draft_registrations/{draft_id}/subjects/
# operationId: nodes_draft_registrations_subjects
export def "draft-registrations-subjects get-nodes" [
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<taxonomy_name: string, text: string>, embeds: record<parent: record<data: record>>, id: string, links: record<self: string>, relationships: record<children: string, parent: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({draft_id: (encode-path-segment $draft_id)} | format pattern "/draft_registrations/{draft_id}/subjects/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a file
#
# GET /files/{file_id}/
# operationId: files_detail
export def "files get-detail" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a file
#
# PATCH /files/{file_id}/
# operationId: files_patch
export def "files update" [
  file_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all file versions
#
# GET /files/{file_id}/versions/
# operationId: files_versions
export def "files-versions get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/files/{file_id}/versions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a file version
#
# GET /files/{file_id}/versions/{version_id}/
# operationId: files_version_detail
export def "files-versions version-detail" [
  file_id: string
  version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<content_type: record, date_created: string, size: int>, id: string, links: record<html: string, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  if ($version_id | is-empty) { error make --unspanned { msg: "path parameter 'version_id' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), version_id: (encode-path-segment $version_id)} | format pattern "/files/{file_id}/versions/{version_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all institutions
#
# GET /institutions/
# operationId: institutions_list
export def "institutions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve an institution
#
# GET /institutions/{institution_id}/
# operationId: institutions_detail
export def "institutions get-detail" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($institution_id | is-empty) { error make --unspanned { msg: "path parameter 'institution_id' must be non-empty" } }
  let full_url = (build-url $base ({institution_id: (encode-path-segment $institution_id)} | format pattern "/institutions/{institution_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all affiliated nodes
#
# GET /institutions/{institution_id}/nodes/
# operationId: institutions_node_list
export def "institutions-nodes list" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($institution_id | is-empty) { error make --unspanned { msg: "path parameter 'institution_id' must be non-empty" } }
  let full_url = (build-url $base ({institution_id: (encode-path-segment $institution_id)} | format pattern "/institutions/{institution_id}/nodes/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all affiliated registrations
#
# GET /institutions/{institution_id}/registrations/
# operationId: institutions_registration_list
export def "institutions-registrations list" [
  institution_id: string
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
  if ($institution_id | is-empty) { error make --unspanned { msg: "path parameter 'institution_id' must be non-empty" } }
  let full_url = (build-url $base ({institution_id: (encode-path-segment $institution_id)} | format pattern "/institutions/{institution_id}/registrations/") $auth.query)
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

# List all affiliated users
#
# GET /institutions/{institution_id}/users/
# operationId: institutions_users_list
export def "institutions-users list" [
  institution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($institution_id | is-empty) { error make --unspanned { msg: "path parameter 'institution_id' must be non-empty" } }
  let full_url = (build-url $base ({institution_id: (encode-path-segment $institution_id)} | format pattern "/institutions/{institution_id}/users/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a license
#
# GET /license/{license_id}/
# operationId: licenses_read
export def "license get" [
  license_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($license_id | is-empty) { error make --unspanned { msg: "path parameter 'license_id' must be non-empty" } }
  let full_url = (build-url $base ({license_id: (encode-path-segment $license_id)} | format pattern "/license/{license_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all licenses
#
# GET /licenses/
# operationId: license_list
export def "licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<name: string, required_fields: list, text: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/licenses/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a log
#
# GET /logs/{log_id}/
# operationId: logs_read
export def "logs get" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record<action: string, date: string, params: record<addon: string, anonymous_link: bool, bucket: string, citation_name: string, contributors: string, data_set: string, destination: string, figshare_title: string, file: string, filename: string, folder: string, folder_name: string, forward_url: string, github_repo: string, github_user: string, identifiers: string, institution: string, kind: string, license: string, old_page: string, page: string, page_id: string, params_node: string, params_project: string, path: string, pointer: string, preprint: string, preprint_provider: string, previous_institution: string, source: string, study: string, tag: string, tags: string, target: string, template_node: string, title_new: string, title_original: string, updated_fields: string, urls: string, version: string, wiki: string>>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'log_id' must be non-empty" } }
  let full_url = (build-url $base ({log_id: (encode-path-segment $log_id)} | format pattern "/logs/{log_id}/") $auth.query)
  let accept_val = "*/*"
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

# List all nodes
#
# GET /nodes/
# operationId: nodes_list
export def "nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodes/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a node
#
# POST /nodes/
# operationId: nodes_create
# --attributes shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
export def "nodes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nodes/" $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a node
#
# DELETE /nodes/{node_id}/
# operationId: nodes_delete
export def "nodes delete" [
  node_id: string
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
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/") $auth.query)
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

# Retrieve a node
#
# GET /nodes/{node_id}/
# operationId: nodes_read
export def "nodes get" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list<string>, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a node
#
# PATCH /nodes/{node_id}/
# operationId: nodes_partial_update
export def "nodes update" [
  node_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all addons
#
# GET /nodes/{node_id}/addons/
# operationId: nodes_addons_list
export def "nodes-addons list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/addons/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve an addon
#
# GET /nodes/{node_id}/addons/{provider}/
# operationId: nodes_addon_read
export def "nodes-addons get" [
  node_id: string
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
]: nothing -> record<attributes: record<configured: bool, enabled: bool, external_account_id: string, folder_id: string, folder_path: string, label: string, node_has_auth: bool, url: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider)} | format pattern "/nodes/{node_id}/addons/{provider}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update an addon
#
# PATCH /nodes/{node_id}/addons/{provider}/
# operationId: nodes_node_addon_update
export def "nodes-addons update" [
  node_id: string
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider)} | format pattern "/nodes/{node_id}/addons/{provider}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all addon folders
#
# GET /nodes/{node_id}/addons/{provider}/folders/
# operationId: nodes_addons_folders_list
export def "nodes-addons-folders list" [
  node_id: string
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
]: nothing -> table<attributes: record<categories: list, description: string, name: string, url: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider)} | format pattern "/nodes/{node_id}/addons/{provider}/folders/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all child nodes
#
# GET /nodes/{node_id}/children/
# operationId: nodes_children_list
export def "nodes-children list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/children/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a child node
#
# POST /nodes/{node_id}/children/
# operationId: nodes_children_create
# --attributes shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
export def "nodes-children create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/children/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve citation details
#
# GET /nodes/{node_id}/citation/
# operationId: nodes_citation_list
export def "nodes-citation list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/citation/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a styled citation
#
# GET /nodes/{node_id}/citation/{style_id}/
# operationId: nodes_citation_read
export def "nodes-citation get" [
  node_id: string
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<citation: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($style_id | is-empty) { error make --unspanned { msg: "path parameter 'style_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), style_id: (encode-path-segment $style_id)} | format pattern "/nodes/{node_id}/citation/{style_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all comments
#
# GET /nodes/{node_id}/comments/
# operationId: nodes_comments_list
export def "nodes-comments list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/comments/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a comment
#
# POST /nodes/{node_id}/comments/
# operationId: nodes_comment_create
# --attributes shape: {content?: string}
export def "nodes-comments create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the comment entity. — shape: {content?: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the comment entity.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/comments/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all contributors
#
# GET /nodes/{node_id}/contributors/
# operationId: nodes_contributors_list
export def "nodes-contributors list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/contributors/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a contributor
#
# POST /nodes/{node_id}/contributors/
# operationId: nodes_contributors_create
# --attributes shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
# --relationships shape: {user: string}
export def "nodes-contributors create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/contributors/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a contributor
#
# DELETE /nodes/{node_id}/contributors/{user_id}/
# operationId: nodes_contributors_delete
export def "nodes-contributors delete" [
  node_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), user_id: (encode-path-segment $user_id)} | format pattern "/nodes/{node_id}/contributors/{user_id}/") $auth.query)
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

# Retrieve a contributor
#
# GET /nodes/{node_id}/contributors/{user_id}/
# operationId: nodes_contributors_read
export def "nodes-contributors get" [
  node_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), user_id: (encode-path-segment $user_id)} | format pattern "/nodes/{node_id}/contributors/{user_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a contributor
#
# PATCH /nodes/{node_id}/contributors/{user_id}/
# operationId: nodes_contributors_partial_update
# --attributes shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
# --relationships shape: {user: string}
export def "nodes-contributors update" [
  node_id: string
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
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
  relationships: record # URLs to other entities or entity collections that have a relationship to the contributor entity. — shape: {user: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), user_id: (encode-path-segment $user_id)} | format pattern "/nodes/{node_id}/contributors/{user_id}/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all draft registrations
#
# GET /nodes/{node_id}/draft_registrations/
# operationId: nodes_draft_registrations_list
export def "nodes-draft-registrations list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, current_user_permissions: list, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record, registration_metadata: record, registration_responses: record, tags: list, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/draft_registrations/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a draft registration based on your current project Node.
#
# POST /nodes/{node_id}/draft_registrations/
# operationId: nodes_draft_registrations_create
# --attributes shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
export def "nodes-draft-registrations create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/draft_registrations/") $auth.query)
  let req_body = {"attributes": $attributes} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a draft registration
#
# DELETE /nodes/{node_id}/draft_registrations/{draft_id}/
# operationId: nodes_draft_registrations_delete
export def "nodes-draft-registrations delete" [
  node_id: string
  draft_id: string
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
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), draft_id: (encode-path-segment $draft_id)} | format pattern "/nodes/{node_id}/draft_registrations/{draft_id}/") $auth.query)
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

# Retrieve a Draft Registration
#
# GET /nodes/{node_id}/draft_registrations/{draft_id}/
# operationId: nodes_draft_registrations_read
export def "nodes-draft-registrations get" [
  node_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<category: string, current_user_permissions: list<string>, datetime_initiated: string, datetime_updated: string, description: string, has_project: bool, node_license: record<copyright_holders: list, year: int>, registration_metadata: record, registration_responses: record, tags: list<string>, title: string>, id: string, links: record<html: string>, relationships: record<branched_from: string, initiator: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), draft_id: (encode-path-segment $draft_id)} | format pattern "/nodes/{node_id}/draft_registrations/{draft_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a draft registration
#
# PATCH /nodes/{node_id}/draft_registrations/{draft_id}/
# operationId: nodes_draft_registrations_partial_update
# --attributes shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
export def "nodes-draft-registrations update" [
  node_id: string
  draft_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the Draft Registration entity. — shape: {category?: string, description?: string, node_license?: record, registration_metadata?: record, registration_responses?: record, tags?: list<string>, title?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($draft_id | is-empty) { error make --unspanned { msg: "path parameter 'draft_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), draft_id: (encode-path-segment $draft_id)} | format pattern "/nodes/{node_id}/draft_registrations/{draft_id}/") $auth.query)
  let req_body = {"attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all storage providers
#
# GET /nodes/{node_id}/files/
# operationId: nodes_providers_list
export def "nodes-files list-providers" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/files/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a storage provider
#
# GET /nodes/{node_id}/files/providers/{provider}/
# operationId: nodes_providers_read
export def "nodes-files-providers get" [
  node_id: string
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
]: nothing -> record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider)} | format pattern "/nodes/{node_id}/files/providers/{provider}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all node files
#
# GET /nodes/{node_id}/files/{provider}/
# operationId: nodes_files_list
export def "nodes-files list" [
  node_id: string
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
]: nothing -> table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider)} | format pattern "/nodes/{node_id}/files/{provider}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a file
#
# GET /nodes/{node_id}/files/{provider}/{path}/
# operationId: nodes_files_read
export def "nodes-files get" [
  node_id: string
  provider: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), provider: (encode-path-segment $provider), path: (encode-path-segment $path)} | format pattern "/nodes/{node_id}/files/{provider}/{path}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all forks of this node
#
# GET /nodes/{node_id}/forks/
# operationId: nodes_forks_list
export def "nodes-forks list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/forks/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a fork of this node
#
# POST /nodes/{node_id}/forks/
# operationId: nodes_forks_create
# --attributes shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
export def "nodes-forks create" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  attributes: record # The properties of the node entity. — shape: {category: "analysis"|"communication"|"data"|"hypothesis"|"instrumentation"|"methods and measures"|"procedure"|"project"|"software"|"other", description?: string, node_license?: string, public?: bool, tags?: list<string>, template_from?: string, title: string}
  --relationships: record # URLs to other entities or entity collections that have a relationship to the node entity.
  type: string # The type identifier of the node entity (`nodes`).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/forks/") $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all identifiers
#
# GET /nodes/{node_id}/identifiers/
# operationId: nodes_identifiers_list
export def "nodes-identifiers list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/identifiers/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all institutions
#
# GET /nodes/{node_id}/institutions/
# operationId: nodes_institutions_list
export def "nodes-institutions list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/institutions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all linked nodes
#
# GET /nodes/{node_id}/linked_nodes/
# operationId: nodes_linked_nodes_list
export def "nodes-linked-nodes list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/linked_nodes/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all logs
#
# GET /nodes/{node_id}/logs/
# operationId: nodes_logs_list
export def "nodes-logs list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/logs/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all preprints
#
# GET /nodes/{node_id}/preprints/
# operationId: nodes_preprints_list
export def "nodes-preprints list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/preprints/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all registrations
#
# GET /nodes/{node_id}/registrations/
# operationId: nodes_registrations_list
export def "nodes-registrations list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/registrations/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all view only links
#
# GET /nodes/{node_id}/view_only_links/
# operationId: nodes_view_only_links_list
export def "nodes-view-only-links list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/view_only_links/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a view only link
#
# GET /nodes/{node_id}/view_only_links/{link_id}/
# operationId: nodes_view_only_links_read
export def "nodes-view-only-links get" [
  node_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'link_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id), link_id: (encode-path-segment $link_id)} | format pattern "/nodes/{node_id}/view_only_links/{link_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all wikis
#
# GET /nodes/{node_id}/wikis/
# operationId: nodes_wikis_list
export def "nodes-wikis list" [
  node_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($node_id | is-empty) { error make --unspanned { msg: "path parameter 'node_id' must be non-empty" } }
  let full_url = (build-url $base ({node_id: (encode-path-segment $node_id)} | format pattern "/nodes/{node_id}/wikis/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all preprint providers
#
# GET /preprint_providers/
# operationId: preprint_provider_list
export def "preprint-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/preprint_providers/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a preprint provider
#
# GET /preprint_providers/{preprint_provider_id}/
# operationId: preprint_provider_detail
export def "preprint-providers get-detail" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<advisory_board: string, banner_path: string, description: string, domain: string, domain_redirect_enabled: bool, email_contact: string, email_support: string, example: string, logo_path: string, name: string, social_facebook: string, social_instagram: string, subjects_acceptable: string>, id: string, links: record<external_url: string, preprints: string, self: string>, relationships: record<licenses_acceptable: string, preprints: string, taxonomies: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_provider_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_provider_id: (encode-path-segment $preprint_provider_id)} | format pattern "/preprint_providers/{preprint_provider_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all licenses
#
# GET /preprint_providers/{preprint_provider_id}/licenses/
# operationId: preprint_provider_licenses_list
export def "preprint-providers-licenses list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<name: string, required_fields: list<string>, text: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_provider_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_provider_id: (encode-path-segment $preprint_provider_id)} | format pattern "/preprint_providers/{preprint_provider_id}/licenses/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all preprints
#
# GET /preprint_providers/{preprint_provider_id}/preprints/
# operationId: preprint_providers_preprints_list
export def "preprint-providers-preprints list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_provider_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_provider_id: (encode-path-segment $preprint_provider_id)} | format pattern "/preprint_providers/{preprint_provider_id}/preprints/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all taxonomies
#
# GET /preprint_providers/{preprint_provider_id}/taxonomies/
# operationId: preprint_provider_taxonomies_list
export def "preprint-providers-taxonomies list" [
  preprint_provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_provider_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_provider_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_provider_id: (encode-path-segment $preprint_provider_id)} | format pattern "/preprint_providers/{preprint_provider_id}/taxonomies/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all preprints
#
# GET /preprints/
# operationId: preprints_list
export def "preprints list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/preprints/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a preprint
#
# POST /preprints/
# operationId: preprints_create
# --attributes shape: {doi?: string, license_record?: string, subjects?: list<string>}
# --relationships shape: {bibliographic_contributors?: string, license?: string, node: string, primary_file: string, provider: string}
export def "preprints create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the preprint entity. — shape: {doi?: string, license_record?: string, subjects?: list<string>}
  relationships: record # URLs to other entities or entity collections that have a relationship to the preprint entity. — shape: {bibliographic_contributors?: string, license?: string, node: string, primary_file: string, provider: string}
  type: string # The type identifier of the preprint entity (`preprints`).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/preprints/" $auth.query)
  let req_body = {"attributes": $attributes, "relationships": $relationships, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a preprint
#
# GET /preprints/{preprint_id}/
# operationId: preprints_read
export def "preprints get" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list<string>>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a preprint
#
# PATCH /preprints/{preprint_id}/
# operationId: preprints_partial_update
export def "preprints update" [
  preprint_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all Bibliographic Contributors
#
# GET /preprints/{preprint_id}/bibliographic_contributors/
# operationId: preprints_bibliographic_contributors_list
export def "preprints-bibliographic-contributors list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/bibliographic_contributors/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve citation details
#
# GET /preprints/{preprint_id}/citation/
# operationId: preprints_citation_list
export def "preprints-citation list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/citation/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a styled citation
#
# GET /preprints/{preprint_id}/citation/{style_id}/
# operationId: preprints_citation_read
export def "preprints-citation get" [
  preprint_id: string
  style_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<citation: string>, id: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  if ($style_id | is-empty) { error make --unspanned { msg: "path parameter 'style_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id), style_id: (encode-path-segment $style_id)} | format pattern "/preprints/{preprint_id}/citation/{style_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all Contributors for a Preprint
#
# GET /preprints/{preprint_id}/contributors/
# operationId: preprints_contributors_list
export def "preprints-contributors list" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/contributors/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a Contributor
#
# POST /preprints/{preprint_id}/contributors/
# operationId: preprints_contributors_create
# --attributes shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
# --relationships shape: {user: string}
export def "preprints-contributors create" [
  preprint_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record # The properties of the contributor entity. — shape: {bibliographic?: bool, index?: int, permission?: "read"|"write"|"admin"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id)} | format pattern "/preprints/{preprint_id}/contributors/") $auth.query)
  let req_body = {"attributes": $attributes} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a contributor
#
# GET /preprints/{preprint_id}/contributors/{user_id}/
# operationId: preprints_contributor_read
export def "preprints-contributors get" [
  preprint_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preprint_id | is-empty) { error make --unspanned { msg: "path parameter 'preprint_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({preprint_id: (encode-path-segment $preprint_id), user_id: (encode-path-segment $user_id)} | format pattern "/preprints/{preprint_id}/contributors/{user_id}/") $auth.query)
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

# List all registrations
#
# GET /registrations/
# operationId: registrations_list
export def "registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/registrations/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a registration
#
# GET /registrations/{registration_id}/
# operationId: registrations_read
export def "registrations get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list<string>, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list<string>, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/") $auth.query)
  let accept_val = "*/*"
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

# Update a registration
#
# PATCH /registrations/{registration_id}/
# operationId: registrations_partial_update
# --attributes shape: {public?: bool}
export def "registrations update" [
  registration_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all child registrations
#
# GET /registrations/{registration_id}/children/
# operationId: registrations_children_list
export def "registrations-children list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/children/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all citation styles
#
# GET /registrations/{registration_id}/citations/
# operationId: registrations_citations_list
export def "registrations-citations list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_parsed: string, short_title: string, summary: string, title: string>, id: string, links: record, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/citations/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a citation
#
# GET /registrations/{registration_id}/citations/{citation_id}/
# operationId: registrations_citation_read
export def "registrations-citations get" [
  registration_id: string
  citation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<author: string, doi: string, publisher: string, title: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  if ($citation_id | is-empty) { error make --unspanned { msg: "path parameter 'citation_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id), citation_id: (encode-path-segment $citation_id)} | format pattern "/registrations/{registration_id}/citations/{citation_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all comments
#
# GET /registrations/{registration_id}/comments/
# operationId: registrations_comments_list
export def "registrations-comments list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<can_edit: bool, content: string, date_created: string, date_modified: string, deleted: bool, has_children: bool, has_report: bool, is_abuse: bool, is_ham: bool, modified: bool, page: string>, id: string, links: record<self: string>, relationships: record<node: string, replies: string, reports: string, target: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/comments/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all contributors
#
# GET /registrations/{registration_id}/contributors/
# operationId: registrations_contributors_list
export def "registrations-contributors list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/contributors/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a contributor
#
# GET /registrations/{registration_id}/contributors/{user_id}/
# operationId: registrations_contributors_read
export def "registrations-contributors get" [
  registration_id: string
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<bibliographic: bool, index: int, permission: string, unregistered_contributor: string>, id: string, links: record<self: string>, relationships: record<node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id), user_id: (encode-path-segment $user_id)} | format pattern "/registrations/{registration_id}/contributors/{user_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all storage providers
#
# GET /registrations/{registration_id}/files/
# operationId: registrations_providers_list
export def "registrations-files list-providers" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/files/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all files
#
# GET /registrations/{registration_id}/files/{provider}/
# operationId: registrations_files_list
export def "registrations-files list" [
  registration_id: string
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
]: nothing -> table<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id), provider: (encode-path-segment $provider)} | format pattern "/registrations/{registration_id}/files/{provider}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a file
#
# GET /registrations/{registration_id}/files/{provider}/{path}/
# operationId: registrations_files_read
export def "registrations-files get" [
  registration_id: string
  provider: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<checkout: string, current_user_can_comment: bool, current_version: int, date_created: string, date_modified: string, delete_allowed: bool, extra: record, guid: string, kind: string, last_touched: string, materialized_path: string, name: string, path: string, provider: string, size: int, tags: list<string>>, id: string, links: record<delete: string, download: string, info: string, move: string, new_folder: string, self: string, upload: string>, relationships: record<checkout: string, comments: string, node: string, versions: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id), provider: (encode-path-segment $provider), path: (encode-path-segment $path)} | format pattern "/registrations/{registration_id}/files/{provider}/{path}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all forks
#
# GET /registrations/{registration_id}/forks/
# operationId: registrations_forks_list
export def "registrations-forks list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, date_registered: string, date_withdrawn: string, description: string, embargo_end_date: string, fork: bool, node_license: string, pending_embargo_approval: bool, pending_registration_approval: bool, pending_withdrawal: bool, preprint: bool, public: bool, registered_meta: string, registration: bool, registration_supplement: string, tags: list, template_from: string, title: string, withdrawal_justification: string, withdrawn: bool>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, files: string, forks: string, identifiers: string, linked_nodes: string, logs: string, node_links: string, parent: string, registered_by: string, registered_from: string, registration_schema: string, root: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/forks/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a fork
#
# POST /registrations/{registration_id}/forks/
# operationId: registrations_forks_create
# --attributes shape: {public?: bool}
export def "registrations-forks create" [
  registration_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/forks/") $auth.query)
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List all identifiers
#
# GET /registrations/{registration_id}/identifiers/
# operationId: registrations_identifiers_list
export def "registrations-identifiers list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, value: string>, id: string, links: record<self: string>, relationships: record<referent: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/identifiers/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all institutions
#
# GET /registrations/{registration_id}/institutions/
# operationId: registrations_institutions_list
export def "registrations-institutions list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/institutions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all linked nodes
#
# GET /registrations/{registration_id}/linked_nodes/
# operationId: registrations_linked_nodes_list
export def "registrations-linked-nodes list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/linked_nodes/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all logs
#
# GET /registrations/{registration_id}/logs/
# operationId: registrations_logs_list
export def "registrations-logs list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<action: string, date: string, params: record>, id: string, links: record<self: string>, relationships: record<linked_node: string, node: string, original_node: string, template_node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/logs/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all view only links
#
# GET /registrations/{registration_id}/view_only_links/
# operationId: registrations_view_only_links_list
export def "registrations-view-only-links list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/view_only_links/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a view only link
#
# GET /registrations/{registration_id}/view_only_links/{link_id}/
# operationId: registrations_view_only_links_read
export def "registrations-view-only-links get" [
  registration_id: string
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'link_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id), link_id: (encode-path-segment $link_id)} | format pattern "/registrations/{registration_id}/view_only_links/{link_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all wikis
#
# GET /registrations/{registration_id}/wikis/
# operationId: registrations_wikis_list
export def "registrations-wikis list" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/registrations/{registration_id}/wikis/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all Schema Responses
#
# GET /schema_responses/
# operationId: schema_responses_list
export def "schema-responses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema_responses/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a new Schema Response
#
# POST /schema_responses/
# operationId: schema_response_ppost
# --attributes shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
# --links shape: {self?: string}
# --relationships shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
export def "schema-responses create-ppost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Schema Response. — shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
  --links: record # URLs to alternative representations of the Schema Response entity. — shape: {self?: string}
  --relationships: record # Links to other entities or entity collections that have a relationship to the file entity. — shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
  type: string # The type identifier of the Schema Response (`schema-response`).
]: any -> record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema_responses/" $auth.query)
  let req_body = {"attributes": $attributes, "links": $links, "relationships": $relationships, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "*/*")
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

# Delete a Incomplete Schema Response
#
# DELETE /schema_responses/{schema_response_id}
# operationId: schema_response_delete
export def "schema-responses delete" [
  schema_response_id: string
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
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}") $auth.query)
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

# Retrieve a Schema Response
#
# GET /schema_responses/{schema_response_id}
# operationId: schema_responses_read
export def "schema-responses get" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Update a Registration's Schema Response
#
# PATCH /schema_responses/{schema_response_id}
# operationId: schema_response_patch
# --attributes shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
# --links shape: {self?: string}
# --relationships shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
export def "schema-responses update" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  attributes: record # The properties of the Schema Response. — shape: {date_created?: int, date_modified?: int, date_submitted?: int, is_original_response?: bool, is_pending_current_user_approval?: bool, reviews_state?: "initial"|"in_progress"|"approved"|"pending_moderation", revision_justification?: string, revision_responses?: record}
  --links: record # URLs to alternative representations of the Schema Response entity. — shape: {self?: string}
  --relationships: record # Links to other entities or entity collections that have a relationship to the file entity. — shape: {actions?: string, initiated_by?: string, registration?: string, registration_schema?: string}
  type: string # The type identifier of the Schema Response (`schema-response`).
]: any -> record<attributes: record<date_created: int, date_modified: int, date_submitted: int, is_original_response: bool, is_pending_current_user_approval: bool, reviews_state: string, revision_justification: string, revision_responses: record, updated_response_keys: list<any>>, id: string, links: record<self: string>, relationships: record<actions: string, initiated_by: string, registration: string, registration_schema: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}") $auth.query)
  let req_body = {"attributes": $attributes, "links": $links, "relationships": $relationships, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "*/*")
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
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Retrieve a list of Schema Response Actions for a Schema Response
#
# GET /schema_responses/{schema_response_id}/actions/
# operationId: schema_response_action_read
export def "schema-responses-actions list" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}/actions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Create a new Schema Response Action
#
# POST /schema_responses/{schema_response_id}/actions/
export def "schema-responses-actions create" [
  schema_response_id: string
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
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}/actions/") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# A Schema Response Action from a Schema Response
#
# GET /schema_responses/{schema_response_id}/actions/{schema_response_action_id}
export def "schema-responses-actions get" [
  schema_response_id: string
  schema_response_action_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<auto: bool, comment: string, date_created: string, from_state: string, to_state: string, trigger: string, visible: bool>, id: string, links: record<self: string>, relationships: record<creator: string, target: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  if ($schema_response_action_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_action_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id), schema_response_action_id: (encode-path-segment $schema_response_action_id)} | format pattern "/schema_responses/{schema_response_id}/actions/{schema_response_action_id}") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a list of Registration Schema Blocks for a Schema Response
#
# GET /schema_responses/{schema_response_id}/schema_blocks/
# operationId: schema_response_blocks_read
export def "schema-responses-schema-blocks list" [
  schema_response_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id)} | format pattern "/schema_responses/{schema_response_id}/schema_blocks/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a Registration Schema Block
#
# GET /schema_responses/{schema_response_id}/schema_blocks/{schema_response_block_id}
export def "schema-responses-schema-blocks get" [
  schema_response_id: string
  schema_response_block_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<block_type: string, display_text: string, example_text: string, index: int, registration_response_key: string, required: bool, schema_block_group_key: string>, id: string, links: record<self: string>, relationships: record<schema: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($schema_response_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_id' must be non-empty" } }
  if ($schema_response_block_id | is-empty) { error make --unspanned { msg: "path parameter 'schema_response_block_id' must be non-empty" } }
  let full_url = (build-url $base ({schema_response_id: (encode-path-segment $schema_response_id), schema_response_block_id: (encode-path-segment $schema_response_block_id)} | format pattern "/schema_responses/{schema_response_id}/schema_blocks/{schema_response_block_id}") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a list of Registration Schemas
#
# GET /schemas/registrations/
# operationId: registration_schemas_list
export def "schemas-registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schemas/registrations/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a Registration Schema
#
# GET /schemas/registrations/{registration_schema_id}
# operationId: registration_schema_read
export def "schemas-registrations get" [
  registration_schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<active: bool, name: string, schema: record, schema_version: int>, id: string, links: record<self: string>, relationships: record<schema_blocks: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_schema_id | is-empty) { error make --unspanned { msg: "path parameter 'registration_schema_id' must be non-empty" } }
  let full_url = (build-url $base ({registration_schema_id: (encode-path-segment $registration_schema_id)} | format pattern "/schemas/registrations/{registration_schema_id}") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all taxonomies
#
# GET /taxonomies/
# operationId: taxonomies_list
export def "taxonomies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<child_count: int, parents: list, text: string>, id: string, links: record<parents: list, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taxonomies/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a taxonomy
#
# GET /taxonomies/{taxonomy_id}/
# operationId: taxonomies_read
export def "taxonomies get" [
  taxonomy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<child_count: int, parents: list<string>, text: string>, id: string, links: record<parents: list<string>, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($taxonomy_id | is-empty) { error make --unspanned { msg: "path parameter 'taxonomy_id' must be non-empty" } }
  let full_url = (build-url $base ({taxonomy_id: (encode-path-segment $taxonomy_id)} | format pattern "/taxonomies/{taxonomy_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all users
#
# GET /users/
# operationId: users_list
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/" $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a user
#
# GET /users/{user_id}/
# operationId: users_read
export def "users get" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<active: bool, date_registered: string, family_name: string, full_name: string, given_name: string, locale: string, middle_names: string, suffix: string, timezone: string>, id: string, links: record<html: string, profile_image: string>, relationships: record<institutions: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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
# PATCH /users/{user_id}/
# operationId: users_partial_update
# --attributes shape: {family_name?: string, full_name: string, given_name?: string, locale?: string, middle_names?: string, suffix?: string, timezone?: string}
export def "users update" [
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
  attributes: record # The properties of the user entity. — shape: {family_name?: string, full_name: string, given_name?: string, locale?: string, middle_names?: string, suffix?: string, timezone?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/") $auth.query)
  let req_body = {"attributes": $attributes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List all user addons
#
# GET /users/{user_id}/addons/
# operationId: users_addons_list
export def "users-addons list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/addons/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a user addon
#
# GET /users/{user_id}/addons/{provider}/
# operationId: users_addons_read
export def "users-addons get" [
  user_id: string
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
]: nothing -> record<attributes: record<user_has_auth: bool>, id: string, links: record<accounts: record, self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), provider: (encode-path-segment $provider)} | format pattern "/users/{user_id}/addons/{provider}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all addon accounts
#
# GET /users/{user_id}/addons/{provider}/accounts/
# operationId: Users_addon_accounts_list
export def "users-addons-accounts list" [
  user_id: string
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
]: nothing -> table<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), provider: (encode-path-segment $provider)} | format pattern "/users/{user_id}/addons/{provider}/accounts/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve an addon account
#
# GET /users/{user_id}/addons/{provider}/accounts/{account_id}/
# operationId: Users_addon_accounts_read
export def "users-addons-accounts get" [
  user_id: string
  provider: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<display_name: string, profile_url: string, provider: string>, id: string, links: record<self: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'account_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), provider: (encode-path-segment $provider), account_id: (encode-path-segment $account_id)} | format pattern "/users/{user_id}/addons/{provider}/accounts/{account_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all institutions
#
# GET /users/{user_id}/institutions/
# operationId: users_institutions_list
export def "users-institutions list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<auth_url: string, description: string, logo_path: string, name: string>, id: string, links: record<self: string>, relationships: record<nodes: string, registrations: string, users: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/institutions/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all nodes
#
# GET /users/{user_id}/nodes/
# operationId: users_nodes_list
export def "users-nodes list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/nodes/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all preprints
#
# GET /users/{user_id}/preprints/
# operationId: users_preprints_list
export def "users-preprints list" [
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
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<date_created: string, date_modified: string, date_published: string, doi: string, is_preprint_orphan: bool, license_record: string, subjects: list>, id: string, links: record<doi: string, html: string, preprint_doi: string, self: string>, relationships: record<bibliographic_contributors: string, citation: string, identifiers: string, license: string, node: string, primary_file: string, provider: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/preprints/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all registrations
#
# GET /users/{user_id}/registrations/
# operationId: users_registrations_list
export def "users-registrations list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/registrations/") $auth.query)
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

# Retrieve a view only link
#
# GET /view_only_links/{link_id}/
# operationId: view_only_links_read
export def "view-only-links get" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<anonymous: bool, date_created: string, key: string, name: string>, id: string, relationships: record<creator: string, nodes: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'link_id' must be non-empty" } }
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/view_only_links/{link_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# List all nodes
#
# GET /view_only_links/{link_id}/nodes/
# operationId: view_only_links_node_list
export def "view-only-links-nodes list" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<attributes: record<category: string, collection: bool, current_user_can_comment: bool, current_user_permissions: list, date_created: string, date_modified: string, description: string, fork: bool, forked_date: string, node_license: string, preprint: bool, public: bool, registration: bool, tags: list, template_from: string, title: string>, id: string, links: record<html: string, self: string>, relationships: record<affiliated_institutions: string, children: string, citation: string, comments: string, contributors: string, draft_registrations: string, files: string, forked_from: string, forks: string, identifiers: string, license: string, linked_nodes: string, logs: string, node_links: string, parent: string, preprints: string, registrations: string, root: string, template_node: string, view_only_links: string, wikis: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'link_id' must be non-empty" } }
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/view_only_links/{link_id}/nodes/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve a Wiki
#
# GET /wikis/{wiki_id}/
# operationId: wiki_read
export def "wikis get" [
  wiki_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<attributes: record<content_type: string, current_user_can_comment: string, date_modified: string, extra: string, kind: string, materialized_path: string, name: string, path: string, size: string>, id: string, links: record<download: string, info: string, self: string>, relationships: record<comments: string, node: string, user: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($wiki_id | is-empty) { error make --unspanned { msg: "path parameter 'wiki_id' must be non-empty" } }
  let full_url = (build-url $base ({wiki_id: (encode-path-segment $wiki_id)} | format pattern "/wikis/{wiki_id}/") $auth.query)
  let accept_val = ($accept | default "*/*")
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

# Retrieve the Content of a Wiki
#
# GET /wikis/{wiki_id}/content/
# operationId: wiki_content
export def "wikis-content get" [
  wiki_id: string
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
  if ($wiki_id | is-empty) { error make --unspanned { msg: "path parameter 'wiki_id' must be non-empty" } }
  let full_url = (build-url $base ({wiki_id: (encode-path-segment $wiki_id)} | format pattern "/wikis/{wiki_id}/content/") $auth.query)
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
