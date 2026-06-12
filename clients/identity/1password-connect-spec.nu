# Auto-generated client for 1Password Connect v1.5.7
# Source: https://api.apis.guru/v2/specs/1password.local/connect/1.5.7/openapi.json
# Auth: --token flag or $env.1PASSWORD_CONNECT_TOKEN

const BASE_URL = "http://1password.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o 1PASSWORD_CONNECT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def base-url-completer [] { ["http://1password.local" "http://localhost:8080/v1" "http://localhost:8080"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def category-completer [] { ["API_CREDENTIAL" "BANK_ACCOUNT" "CREDIT_CARD" "CUSTOM" "DATABASE" "DOCUMENT" "DRIVER_LICENSE" "EMAIL_ACCOUNT" "IDENTITY" "LOGIN" "MEDICAL_RECORD" "MEMBERSHIP" "OUTDOOR_LICENSE" "PASSPORT" "PASSWORD" "REWARD_PROGRAM" "SECURE_NOTE" "SERVER" "SOCIAL_SECURITY_NUMBER" "SOFTWARE_LICENSE" "SSH_KEY" "WIRELESS_ROUTER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activity GetApiActivity" } } | get name | first)
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
export def "activity GetApiActivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get state of the server and its dependencies.
#
# GET /health
# operationId: GetServerHealth
export def "health GetServerHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dependencies: table<message: string, service: string, status: string>, name: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping the server for liveness
#
# GET /heartbeat
# operationId: GetHeartbeat
export def "heartbeat GetHeartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/heartbeat")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query server for exposed Prometheus metrics
#
# GET /metrics
# operationId: GetPrometheusMetrics
export def "metrics GetPrometheusMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://localhost:8080")
  let full_url = (build-url $base "/metrics")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Vaults
#
# GET /vaults
# operationId: GetVaults
export def "vaults GetVaults" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter the Vault collection based on Vault name using SCIM eq filter (e.g. name eq "Some Vault Name")
]: nothing -> table<attributeVersion: int, contentVersion: int, createdAt: string, description: string, id: string, items: int, name: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vaults" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Vault details and metadata
#
# GET /vaults/{vaultUuid}
# operationId: GetVaultById
export def "vaults GetVaultById" [
  vaultUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributeVersion: int, contentVersion: int, createdAt: string, description: string, id: string, items: int, name: string, type: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all items for inside a Vault
#
# GET /vaults/{vaultUuid}/items
# operationId: GetVaultItems
export def "vaults-items GetVaultItems" [
  vaultUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter the Item collection based on Item name using SCIM eq filter (e.g. title eq "Some Item Name")
]: nothing -> table<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: list<record>, vault: record<id: string>, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
export def "vaults-items CreateVaultItem" [
  vaultUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --favorite: oneof<nothing, bool> # default: false
  --id: string
  --tags: list
  --title: string
  --urls: list # e.g. [{href: https://example.com, primary: true}, {href: https://example.org}] — item shape: {href: string, label?: string, primary?: bool}
  vault: record # shape: {id: string}
  --version: int
  --body-fields: list # item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
  --files: list # item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
  --sections: list # item shape: {id?: string, label?: string}
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items")
  let body = {category: $category, favorite: $favorite, id: $id, tags: $tags, title: $title, urls: $urls, vault: $vault, version: $version, fields: $body_fields, files: $files, sections: $sections} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Item
#
# DELETE /vaults/{vaultUuid}/items/{itemUuid}
# operationId: DeleteVaultItem
export def "vaults-items DeleteVaultItem" [
  vaultUuid: string
  itemUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of an Item
#
# GET /vaults/{vaultUuid}/items/{itemUuid}
# operationId: GetVaultItemById
export def "vaults-items GetVaultItemById" [
  vaultUuid: string
  itemUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a subset of Item attributes
#
# PATCH /vaults/{vaultUuid}/items/{itemUuid}
# operationId: PatchVaultItem
export def "vaults-items PatchVaultItem" [
  vaultUuid: string
  itemUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "vaults-items UpdateVaultItem" [
  vaultUuid: string
  itemUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer
  --favorite: oneof<nothing, bool> # default: false
  --id: string
  --tags: list
  --title: string
  --urls: list # e.g. [{href: https://example.com, primary: true}, {href: https://example.org}] — item shape: {href: string, label?: string, primary?: bool}
  vault: record # shape: {id: string}
  --version: int
  --body-fields: list # item shape: {generate?: bool, id: string, label?: string, purpose?: ""|"USERNAME"|"PASSWORD"|"NOTES", recipe?: record, section?: record, type: "STRING"|"EMAIL"|"CONCEALED"|"URL"|"TOTP"|"DATE"|"MONTH_YEAR"|"MENU", value?: string}
  --files: list # item shape: {content?: string, id?: string, name?: string, section?: record, size?: int}
  --sections: list # item shape: {id?: string, label?: string}
]: any -> record<category: string, createdAt: string, favorite: bool, id: string, lastEditedBy: string, state: string, tags: list<string>, title: string, updatedAt: string, urls: table<href: string, label: string, primary: bool>, vault: record<id: string>, version: int, fields: table<entropy: float, generate: bool, id: string, label: string, purpose: string, recipe: record, section: record, type: string, value: string>, files: table<content: string, content_path: string, id: string, name: string, section: record, size: int>, sections: table<id: string, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)")
  let body = {category: $category, favorite: $favorite, id: $id, tags: $tags, title: $title, urls: $urls, vault: $vault, version: $version, fields: $body_fields, files: $files, sections: $sections} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the files inside an Item
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files
# operationId: GetItemFiles
export def "vaults-items-files GetItemFiles" [
  vaultUuid: string
  itemUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inline-files: oneof<nothing, bool> # Tells server to return the base64-encoded file contents in the response. (e.g. true)
]: nothing -> table<content: string, content_path: string, id: string, name: string, section: record<id: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inline_files" $inline_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of a File
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files/{fileUuid}
# operationId: GetDetailsOfFileById
export def "vaults-items-files GetDetailsOfFileById" [
  vaultUuid: string
  itemUuid: string
  fileUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inline-files: oneof<nothing, bool> # Tells server to return the base64-encoded file contents in the response. (e.g. true)
]: nothing -> record<content: string, content_path: string, id: string, name: string, section: record<id: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inline_files" $inline_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)/files/($fileUuid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the content of a File
#
# GET /vaults/{vaultUuid}/items/{itemUuid}/files/{fileUuid}/content
# operationId: DownloadFileByID
export def "vaults-items-files-content DownloadFileByID" [
  vaultUuid: string
  itemUuid: string
  fileUuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vaults/($vaultUuid)/items/($itemUuid)/files/($fileUuid)/content")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
