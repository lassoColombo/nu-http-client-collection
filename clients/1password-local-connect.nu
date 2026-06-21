# Auto-generated client for 1Password Connect v1.5.7
# Source: https://api.apis.guru/v2/specs/1password.local/connect/1.5.7/openapi.json
# Auth: --token flag or $env.1PASSWORD_CONNECT_TOKEN

const BASE_URL = "http://1password.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o 1PASSWORD_CONNECT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["http://1password.local" "http://localhost:8080/v1" "http://localhost:8080"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def category-completer [] { ["API_CREDENTIAL" "BANK_ACCOUNT" "CREDIT_CARD" "CUSTOM" "DATABASE" "DOCUMENT" "DRIVER_LICENSE" "EMAIL_ACCOUNT" "IDENTITY" "LOGIN" "MEDICAL_RECORD" "MEMBERSHIP" "OUTDOOR_LICENSE" "PASSPORT" "PASSWORD" "REWARD_PROGRAM" "SECURE_NOTE" "SERVER" "SOCIAL_SECURITY_NUMBER" "SOFTWARE_LICENSE" "SSH_KEY" "WIRELESS_ROUTER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activity get" } } | get name | first)
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

# Retrieve a list of API Requests that have been made.
#
# GET /activity
# operationId: GetApiActivity
export def "activity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # How many API Events should be retrieved in a single request. (default: 50, e.g. 10)
  --offset: int # How far into the collection of API Events should the response start (default: 0, e.g. 50)
]: nothing -> table<action: string, actor: record<account: string, id: string, jti: string, requestIp: string, userAgent: string>, requestId: string, resource: record<item: record, itemVersion: int, type: string, vault: record>, result: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Get state of the server and its dependencies.
#
# GET /health
# operationId: GetServerHealth
export def "health get-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dependencies: table<message: string, service: string, status: string>, name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Ping the server for liveness
#
# GET /heartbeat
# operationId: GetHeartbeat
export def "heartbeat get" [
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
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/heartbeat")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Query server for exposed Prometheus metrics
#
# GET /metrics
# operationId: GetPrometheusMetrics
export def "metrics get-prometheus" [
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
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/metrics")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all Vaults
#
# GET /vaults
# operationId: GetVaults
export def "vaults list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter the Vault collection based on Vault name using SCIM eq filter (e.g. name eq "Some Vault Name")
]: nothing -> table<attributeVersion: int, contentVersion: int, createdAt: string, description: string, id: string, items: int, name: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vaults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# Get Vault details and metadata
#
# GET /vaults/{vaultUuid}
# operationId: GetVaultById
export def "vaults get" [
  vault_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributeVersion: int, contentVersion: int, createdAt: string, description: string, id: string, items: int, name: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid)} | format pattern "/vaults/{vault_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all items for inside a Vault
#
# GET /vaults/{vaultUuid}/items
# operationId: GetVaultItems
export def "vaults-items list" [
  vault_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter the Item collection based on Item name using SCIM eq filter (e.g. title eq "Some Item Name")
]: nothing -> table<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: list<record>, vault: record<id: string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid)} | format pattern "/vaults/{vault_uuid}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# Create a new Item
#
# POST /vaults/{vaultUuid}/items
# operationId: CreateVaultItem
# --urls item shape: {href: string, label?: string, primary?: bool}
# --vault shape: {id: string}
# --fields item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
# --files item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
# --sections item shape: {id?: string, label?: string}
export def "vaults-items create" [
  vault_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --favorite: oneof<nothing, bool> # default: false
  --id: string
  --tags: list<string>
  --title: string
  --urls: list # e.g. [{href: https://example.com, primary: true}, {href: https://example.org}] — item shape: {href: string, label?: string, primary?: bool}
  vault: record # shape: {id: string}
  --version: int
  --fields: list # item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
  --files: list # item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
  --sections: list # item shape: {id?: string, label?: string}
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid)} | format pattern "/vaults/{vault_uuid}/items"))
  let req_body = {"category": $category, "favorite": $favorite, "id": $id, "tags": $tags, "title": $title, "urls": $urls, "vault": $vault, "version": $version, "fields": $fields, "files": $files, "sections": $sections} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Item
#
# DELETE /vaults/{vaultUuid}/items/{itemUuid}
# operationId: DeleteVaultItem
export def "vaults-items delete" [
  vault_uuid: string
  item_uuid: string
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
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the details of an Item
#
# GET /vaults/{vaultUuid}/items/{itemUuid}
# operationId: GetVaultItemById
export def "vaults-items get" [
  vault_uuid: string
  item_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a subset of Item attributes
#
# PATCH /vaults/{vaultUuid}/items/{itemUuid}
# operationId: PatchVaultItem
export def "vaults-items update-by-vault-uuid-item-uuid" [
  vault_uuid: string
  item_uuid: string
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
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update an Item
#
# PUT /vaults/{vaultUuid}/items/{itemUuid}
# operationId: UpdateVaultItem
# --urls item shape: {href: string, label?: string, primary?: bool}
# --vault shape: {id: string}
# --fields item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
# --files item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
# --sections item shape: {id?: string, label?: string}
export def "vaults-items update-by-vault-uuid-item-uuid-1" [
  vault_uuid: string
  item_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --favorite: oneof<nothing, bool> # default: false
  --id: string
  --tags: list<string>
  --title: string
  --urls: list # e.g. [{href: https://example.com, primary: true}, {href: https://example.org}] — item shape: {href: string, label?: string, primary?: bool}
  vault: record # shape: {id: string}
  --version: int
  --fields: list # item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
  --files: list # item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
  --sections: list # item shape: {id?: string, label?: string}
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}"))
  let req_body = {"category": $category, "favorite": $favorite, "id": $id, "tags": $tags, "title": $title, "urls": $urls, "vault": $vault, "version": $version, "fields": $fields, "files": $files, "sections": $sections} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the files inside an Item
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files
# operationId: GetItemFiles
export def "vaults-items-files get" [
  vault_uuid: string
  item_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inline-files: oneof<nothing, bool> # Tells server to return the base64-encoded file contents in the response. (e.g. true)
]: nothing -> table<content: string, content_path: string, id: string, name: string, section: record<id: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let qp = [(serialize-qp "inline_files" $inline_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}/files") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"inline_files": $inline_files} | compact), body: null}
}

# Get the details of a File
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files/{fileUuid}
# operationId: GetDetailsOfFileById
export def "vaults-items-files get-details-of" [
  vault_uuid: string
  item_uuid: string
  file_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inline-files: oneof<nothing, bool> # Tells server to return the base64-encoded file contents in the response. (e.g. true)
]: nothing -> record<content: string, content_path: string, id: string, name: string, section: record<id: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  if ($file_uuid | is-empty) { error make --unspanned { msg: "path parameter 'fileUuid' must be non-empty" } }
  let qp = [(serialize-qp "inline_files" $inline_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid), file_uuid: (encode-path-segment $file_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}/files/{file_uuid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"inline_files": $inline_files} | compact), body: null}
}

# Get the content of a File
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files/{fileUuid}/content
# operationId: DownloadFileByID
export def "vaults-items-files-content download" [
  vault_uuid: string
  item_uuid: string
  file_uuid: string
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
  if ($vault_uuid | is-empty) { error make --unspanned { msg: "path parameter 'vaultUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  if ($file_uuid | is-empty) { error make --unspanned { msg: "path parameter 'fileUuid' must be non-empty" } }
  let full_url = (build-url $base ({vault_uuid: (encode-path-segment $vault_uuid), item_uuid: (encode-path-segment $item_uuid), file_uuid: (encode-path-segment $file_uuid)} | format pattern "/vaults/{vault_uuid}/items/{item_uuid}/files/{file_uuid}/content"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
