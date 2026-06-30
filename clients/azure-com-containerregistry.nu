# Auto-generated client for Azure Container Registry v2019-08-15-preview
# Source: https://api.apis.guru/v2/specs/azure.com/containerregistry/2019-08-15-preview/swagger.json
# Auth: --token flag or $env.AZURE_CONTAINER_REGISTRY_TOKEN

const BASE_URL = "{url}"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AZURE_CONTAINER_REGISTRY_TOKEN | default "" }
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

# HEAD — bodyless; default surfaces just the headers on success
def send-head [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = (http head --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url)
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

def base-url-completer [] { ["{url}"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

# Completers for enum parameters
def grant-type-completer [] { ["access_token" "access_token_refresh_token" "refresh_token"] }
def grant-type-completer-1 [] { ["refresh_token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "acr-catalog get-repository-list" } } | get name | first)
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

# List repositories
#
# GET /acr/v1/_catalog
# operationId: Repository_GetList
export def "acr-catalog get-repository-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
]: nothing -> record<repositories: list<string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last" $last "scalar") (serialize-qp "n" $n "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/acr/v1/_catalog" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"last": $last, "n": $n} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the repository identified by `name`
#
# DELETE /acr/v1/{name}
# operationId: Repository_Delete
export def "acr delete-repository" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<manifestsDeleted: list<string>, tagsDeleted: list<string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/acr/v1/{name}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Get repository attributes
#
# GET /acr/v1/{name}
# operationId: Repository_GetAttributes
export def "acr get-repository-attributes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, imageName: string, lastUpdateTime: string, manifestCount: int, registry: string, tagCount: int> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/acr/v1/{name}") $auth.query)
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

# Update the attribute identified by `name` where `reference` is the name of the repository.
#
# PATCH /acr/v1/{name}
# operationId: Repository_UpdateAttributes
export def "acr update-repository-attributes" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/acr/v1/{name}") $auth.query)
  let req_body = {"deleteEnabled": $delete_enabled, "listEnabled": $list_enabled, "readEnabled": $read_enabled, "writeEnabled": $write_enabled} | compact
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

# List manifests of a repository
#
# GET /acr/v1/{name}/_manifests
# operationId: Manifests_GetList
export def "acr-manifests get-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
  --orderby: string # orderby query parameter
]: nothing -> record<imageName: string, manifests: table<architecture: string, changeableAttributes: record, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list>, registry: string> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "last" $last "scalar") (serialize-qp "n" $n "scalar") (serialize-qp "orderby" $orderby "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/acr/v1/{name}/_manifests") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"last": $last, "n": $n, "orderby": $orderby} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get manifest attributes
#
# GET /acr/v1/{name}/_manifests/{reference}
# operationId: Manifests_GetAttributes
export def "acr-manifests get-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imageName: string, manifest: record<architecture: string, changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, configMediaType: string, createdTime: string, digest: string, imageSize: int, lastUpdateTime: string, mediaType: string, os: string, tags: list<string>>, registry: string> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/acr/v1/{name}/_manifests/{reference}") $auth.query)
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

# Update attributes of a manifest
#
# PATCH /acr/v1/{name}/_manifests/{reference}
# operationId: Manifests_UpdateAttributes
export def "acr-manifests update-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/acr/v1/{name}/_manifests/{reference}") $auth.query)
  let req_body = {"deleteEnabled": $delete_enabled, "listEnabled": $list_enabled, "readEnabled": $read_enabled, "writeEnabled": $write_enabled} | compact
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

# List tags of a repository
#
# GET /acr/v1/{name}/_tags
# operationId: Tag_GetList
export def "acr-tags get-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last: string # Query parameter for the last item in previous query. Result set will include values lexically after last.
  --n: int # query parameter for max number of items
  --orderby: string # orderby query parameter
  --digest: string # filter by digest
]: nothing -> record<imageName: string, registry: string, tags: table<changeableAttributes: record, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "last" $last "scalar") (serialize-qp "n" $n "scalar") (serialize-qp "orderby" $orderby "scalar") (serialize-qp "digest" $digest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/acr/v1/{name}/_tags") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"last": $last, "n": $n, "orderby": $orderby, "digest": $digest} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete tag
#
# DELETE /acr/v1/{name}/_tags/{reference}
# operationId: Tag_Delete
export def "acr-tags delete" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/acr/v1/{name}/_tags/{reference}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Get tag attributes by tag
#
# GET /acr/v1/{name}/_tags/{reference}
# operationId: Tag_GetAttributes
export def "acr-tags get-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imageName: string, registry: string, tag: record<changeableAttributes: record<deleteEnabled: bool, listEnabled: bool, readEnabled: bool, writeEnabled: bool>, createdTime: string, digest: string, lastUpdateTime: string, name: string, signed: bool>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/acr/v1/{name}/_tags/{reference}") $auth.query)
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

# Update tag attributes
#
# PATCH /acr/v1/{name}/_tags/{reference}
# operationId: Tag_UpdateAttributes
export def "acr-tags update-attributes" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --delete-enabled: oneof<nothing, bool> # Delete enabled
  --list-enabled: oneof<nothing, bool> # List enabled
  --read-enabled: oneof<nothing, bool> # Read enabled
  --write-enabled: oneof<nothing, bool> # Write enabled
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/acr/v1/{name}/_tags/{reference}") $auth.query)
  let req_body = {"deleteEnabled": $delete_enabled, "listEnabled": $list_enabled, "readEnabled": $read_enabled, "writeEnabled": $write_enabled} | compact
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

# Exchange AAD tokens for an ACR refresh Token
#
# POST /oauth2/exchange
# operationId: RefreshTokens_GetFromExchange
export def "oauth2-exchange refresh-tokens-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer # Can take a value of access_token_refresh_token, or access_token, or refresh_token
  service: string # Indicates the name of your Azure container registry.
  --tenant: string # AAD tenant associated to the AAD credentials.
  --refresh-token: string # AAD refresh token, mandatory when grant_type is access_token_refresh_token or refresh_token
  --access-token: string # AAD access token, mandatory when grant_type is access_token_refresh_token or access_token.
]: any -> record<refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/exchange" $auth.query)
  let req_body = {"grant_type": $grant_type, "service": $service, "tenant": $tenant, "refresh_token": $refresh_token, "access_token": $access_token} | compact
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

# Exchange Username, Password and Scope an ACR Access Token
#
# GET /oauth2/token
# operationId: AccessTokens_GetFromLogin
export def "oauth2-token get-access-from-login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --service: string # Indicates the name of your Azure container registry.
  --scope: string # Expected to be a valid scope, and can be specified more than once for multiple scope requests. You can obtain this from the Www-Authenticate response header from the challenge.
]: nothing -> record<access_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "service" $service "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth2/token" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"service": $service, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Exchange ACR Refresh token for an ACR Access Token
#
# POST /oauth2/token
# operationId: AccessTokens_Get
export def "oauth2-token get-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string@grant-type-completer-1 # Grant type is expected to be refresh_token
  service: string # Indicates the name of your Azure container registry.
  scope: string # Which is expected to be a valid scope, and can be specified more than once for multiple scope requests. You obtained this from the Www-Authenticate response header from the challenge.
  refresh_token: string # Must be a valid ACR refresh token
]: any -> record<access_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token" $auth.query)
  let req_body = {"grant_type": $grant_type, "service": $service, "scope": $scope, "refresh_token": $refresh_token} | compact
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

# Tells whether this Docker Registry instance supports Docker Registry HTTP API v2
#
# GET /v2/
# operationId: V2Support_Check
export def "v2 check-support" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/" $auth.query)
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

# Mount a blob identified by the `mount` parameter from another repository.
#
# POST /v2/{name}/blobs/uploads/
# operationId: Blob_Mount
export def "blobs-uploads create-mount" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Name of the source repository.
  --mount: string # Digest of blob to mount from the source repository.
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "mount" $mount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2/{name}/blobs/uploads/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"from": $qp_from, "mount": $mount} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# Removes an already uploaded blob.
#
# DELETE /v2/{name}/blobs/{digest}
# operationId: Blob_Delete
export def "blobs delete" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), digest: (encode-path-segment $digest)} | format pattern "/v2/{name}/blobs/{digest}") $auth.query)
  let accept_val = "application/octet-stream"
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Retrieve the blob from the registry identified by digest.
#
# GET /v2/{name}/blobs/{digest}
# operationId: Blob_Get
export def "blobs get" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), digest: (encode-path-segment $digest)} | format pattern "/v2/{name}/blobs/{digest}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [200 307]
}

# Same as GET, except only the headers are returned.
#
# HEAD /v2/{name}/blobs/{digest}
# operationId: Blob_Check
export def "blobs check" [
  name: string
  digest: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), digest: (encode-path-segment $digest)} | format pattern "/v2/{name}/blobs/{digest}") $auth.query)
  let accept_val = "application/json"
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
  send-head $req $insecure $allow_errors $full [200 307]
}

# Delete the manifest identified by `name` and `reference`. Note that a manifest can _only_ be deleted by `digest`.
#
# DELETE /v2/{name}/manifests/{reference}
# operationId: Manifests_Delete
export def "manifests delete" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/v2/{name}/manifests/{reference}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Get the manifest identified by `name` and `reference` where `reference` can be a tag or digest.
#
# GET /v2/{name}/manifests/{reference}
# operationId: Manifests_Get
export def "manifests get" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Accept header string delimited by comma. For example, application/vnd.docker.distribution.manifest.v2+json
]: nothing -> record<annotations: record<org_opencontainers_image_authors: string, org_opencontainers_image_created: string, org_opencontainers_image_description: string, org_opencontainers_image_documentation: string, org_opencontainers_image_licenses: string, org_opencontainers_image_ref_name: string, org_opencontainers_image_revision: string, org_opencontainers_image_source: string, org_opencontainers_image_title: string, org_opencontainers_image_url: string, org_opencontainers_image_vendor: string, org_opencontainers_image_version: string>, architecture: string, config: record<annotations: record<org_opencontainers_image_authors: string, org_opencontainers_image_created: string, org_opencontainers_image_description: string, org_opencontainers_image_documentation: string, org_opencontainers_image_licenses: string, org_opencontainers_image_ref_name: string, org_opencontainers_image_revision: string, org_opencontainers_image_source: string, org_opencontainers_image_title: string, org_opencontainers_image_url: string, org_opencontainers_image_vendor: string, org_opencontainers_image_version: string>, digest: string, mediaType: string, size: int, urls: list<string>>, fsLayers: table<blobSum: string>, history: table<v1Compatibility: string>, layers: table<annotations: record, digest: string, mediaType: string, size: int, urls: list>, manifests: table<digest: string, mediaType: string, platform: record, size: int>, mediaType: string, name: string, signatures: table<header: record, protected: string, signature: string>, tag: string, schemaVersion: int> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/v2/{name}/manifests/{reference}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"accept": $hdr_accept} | compact
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

# Put the manifest identified by `name` and `reference` where `reference` can be a tag or digest.
#
# PUT /v2/{name}/manifests/{reference}
# operationId: Manifests_Create
export def "manifests create" [
  name: string
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  if ($reference | is-empty) { error make --unspanned { msg: "path parameter 'reference' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name), reference: (encode-path-segment $reference)} | format pattern "/v2/{name}/manifests/{reference}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/vnd.docker.distribution.manifest.v2+json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Cancel outstanding upload processes, releasing associated resources. If this is not called, the unfinished uploads will eventually timeout.
#
# DELETE /{nextBlobUuidLink}
# operationId: Blob_CancelUpload
export def "layer cancel-blob-upload" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($next_blob_uuid_link | is-empty) { error make --unspanned { msg: "path parameter 'nextBlobUuidLink' must be non-empty" } }
  let full_url = (build-url $base ({next_blob_uuid_link: (encode-path-segment $next_blob_uuid_link)} | format pattern "/{next_blob_uuid_link}") $auth.query)
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

# Retrieve status of upload identified by uuid. The primary purpose of this endpoint is to resolve the current status of a resumable upload.
#
# GET /{nextBlobUuidLink}
# operationId: Blob_GetStatus
export def "layer get-blob-status" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errors: table<code: string, detail: record, message: string>> {
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($next_blob_uuid_link | is-empty) { error make --unspanned { msg: "path parameter 'nextBlobUuidLink' must be non-empty" } }
  let full_url = (build-url $base ({next_blob_uuid_link: (encode-path-segment $next_blob_uuid_link)} | format pattern "/{next_blob_uuid_link}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [204]
}

# Upload a stream of data without completing the upload.
#
# PATCH /{nextBlobUuidLink}
# operationId: Blob_Upload
export def "layer upload-blob" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($next_blob_uuid_link | is-empty) { error make --unspanned { msg: "path parameter 'nextBlobUuidLink' must be non-empty" } }
  let full_url = (build-url $base ({next_blob_uuid_link: (encode-path-segment $next_blob_uuid_link)} | format pattern "/{next_blob_uuid_link}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/octet-stream"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [202]
}

# Complete the upload, providing all the data in the body, if necessary. A request without a body will just complete the upload with previously uploaded content.
#
# PUT /{nextBlobUuidLink}
# operationId: Blob_EndUpload
export def "layer upload-blob-end" [
  next_blob_uuid_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-registryauth: string # Auth token for registry_auth (Authorization)
  --token-registryoauth2: string # Auth token for registry_oauth2 (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --digest: string # Digest of a BLOB
  --body: any
]: any -> record<errors: table<code: string, detail: record, message: string>> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_registryauth | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYAUTH_TOKEN | default "")) "basic") (build-auth ($token_registryoauth2 | default ($env | get -o AZURE_CONTAINER_REGISTRY_REGISTRYOAUTH2_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($next_blob_uuid_link | is-empty) { error make --unspanned { msg: "path parameter 'nextBlobUuidLink' must be non-empty" } }
  let qp = [(serialize-qp "digest" $digest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({next_blob_uuid_link: (encode-path-segment $next_blob_uuid_link)} | format pattern "/{next_blob_uuid_link}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"digest": $digest} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/octet-stream"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}
