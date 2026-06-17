# Auto-generated client for Lucidtech API v2023-03-01T16:45:37Z
# Source: https://api.apis.guru/v2/specs/webflow.com/2023-03-01T164537Z/openapi.json
# Auth: --token flag or $env.LUCIDTECH_API_TOKEN

const BASE_URL = "https://api.lucidtech.ai/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LUCIDTECH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.lucidtech.ai/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["application/pdf" "image/jpeg" "image/png" "image/tiff"] }
def instance-type-completer [] { ["large-gpu" "medium-gpu" "small-gpu"] }
def status-completer [] { ["cancelled"] }
def image-quality-completer [] { ["HIGH" "LOW"] }
def rotation-completer [] { ["0" "180" "270" "90"] }
def transition-type-completer [] { ["docker" "manual"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app-clients get" } } | get name | first)
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

# GET /appClients
export def "app-clients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<appClients: table<appClientId: string, callbackUrls: list, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list, logoutUrls: list, name: string, updatedBy: string, updatedTime: string>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/appClients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /appClients
export def "app-clients options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/appClients")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /appClients
export def "app-clients post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --callback-urls: list
  --default-login-url: string
  --description: string # nullable
  --generate-secret: oneof<nothing, bool> # default: true
  --login-urls: list
  --logout-urls: list
  --name: string # nullable
]: any -> record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/appClients")
  let body = {"callbackUrls": $callback_urls, "defaultLoginUrl": $default_login_url, "description": $description, "generateSecret": $generate_secret, "loginUrls": $login_urls, "logoutUrls": $logout_urls, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /appClients/{appClientId}
export def "app-clients delete" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_client_id: $app_client_id} | format pattern "/appClients/{app_client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /appClients/{appClientId}
export def "app-clients options-by-appClientId" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_client_id: $app_client_id} | format pattern "/appClients/{app_client_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /appClients/{appClientId}
export def "app-clients patch" [
  app_client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --default-login-url: string
  --description: string # nullable
  --login-urls: list
  --name: string # nullable
]: any -> record<appClientId: string, callbackUrls: list<string>, clientId: string, clientSecret: string, createdBy: string, createdTime: string, defaultLoginUrl: string, description: string, hasSecret: bool, loginUrls: list<string>, logoutUrls: list<string>, name: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({app_client_id: $app_client_id} | format pattern "/appClients/{app_client_id}"))
  let body = {"defaultLoginUrl": $default_login_url, "description": $description, "loginUrls": $login_urls, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /assets
export def "assets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<assets: table<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /assets
export def "assets options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /assets
export def "assets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  content: string
  --description: string # nullable
  --name: string # nullable
]: any -> record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/assets")
  let body = {"content": $content, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /assets/{assetId}
export def "assets delete" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: $asset_id} | format pattern "/assets/{asset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /assets/{assetId}
export def "assets get" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: $asset_id} | format pattern "/assets/{asset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /assets/{assetId}
export def "assets options-by-assetId" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: $asset_id} | format pattern "/assets/{asset_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /assets/{assetId}
export def "assets patch" [
  asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --content: string
  --description: string # nullable
  --name: string # nullable
]: any -> record<assetId: string, content: string, contentMD5: string, createdBy: string, createdTime: string, description: string, name: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_id: $asset_id} | format pattern "/assets/{asset_id}"))
  let body = {"content": $content, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /datasets
export def "datasets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /datasets
export def "datasets options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /datasets
export def "datasets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --contains-personally-identifiable-information: oneof<nothing, bool>
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datasets")
  let body = {"containsPersonallyIdentifiableInformation": $contains_personally_identifiable_information, "description": $description, "metadata": $metadata, "name": $name, "retentionInDays": $retention_in_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /datasets/{datasetId}
export def "datasets delete" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: $dataset_id} | format pattern "/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /datasets/{datasetId}
export def "datasets get" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: $dataset_id} | format pattern "/datasets/{dataset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /datasets/{datasetId}
export def "datasets options-by-datasetId" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: $dataset_id} | format pattern "/datasets/{dataset_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /datasets/{datasetId}
export def "datasets patch" [
  dataset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --contains-personally-identifiable-information: oneof<nothing, bool>
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> record<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dataset_id: $dataset_id} | format pattern "/datasets/{dataset_id}"))
  let body = {"containsPersonallyIdentifiableInformation": $contains_personally_identifiable_information, "description": $description, "metadata": $metadata, "name": $name, "retentionInDays": $retention_in_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /deploymentEnvironments
export def "deployment-environments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> record<deploymentEnvironments: table<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/deploymentEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /deploymentEnvironments
export def "deployment-environments options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deploymentEnvironments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /deploymentEnvironments/{deploymentEnvironmentId}
export def "deployment-environments get" [
  deployment_environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deploymentEnvironmentId: string, description: string, modelDeploymentUnits: int, name: string, organizationId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({deployment_environment_id: $deployment_environment_id} | format pattern "/deploymentEnvironments/{deployment_environment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /deploymentEnvironments/{deploymentEnvironmentId}
export def "deployment-environments options-by-deploymentEnvironmentId" [
  deployment_environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({deployment_environment_id: $deployment_environment_id} | format pattern "/deploymentEnvironments/{deployment_environment_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /documents
export def "documents delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --consent-id: string
  --dataset-id: string
  --next-token: string
  --max-results: string
]: nothing -> record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "consentId" $consent_id "scalar") (serialize-qp "datasetId" $dataset_id "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /documents
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dataset-id: string
  --next-token: string
  --order: string
  --document-id: string
  --consent-id: string
  --max-results: string
  --sort-by: string
]: nothing -> record<consentId: list<string>, datasetId: list<string>, documents: table<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: list, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string>, nextToken: string, order: string, sortBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasetId" $dataset_id "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "documentId" $document_id "scalar") (serialize-qp "consentId" $consent_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "sortBy" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /documents
export def "documents options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /documents
#
# --groundTruth item shape: {label: string, value: any}
export def "documents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --consent-id: string
  content: string
  --content-type: string@content-type-completer # nullable
  --dataset-id: string
  --description: string # nullable
  --ground-truth: list # item shape: {label: string, value: any}
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let body = {"consentId": $consent_id, "content": $content, "contentType": $content_type, "datasetId": $dataset_id, "description": $description, "groundTruth": $ground_truth, "metadata": $metadata, "name": $name, "retentionInDays": $retention_in_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /documents/{documentId}
export def "documents delete-by-documentId" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /documents/{documentId}
export def "documents get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /documents/{documentId}
export def "documents options-by-documentId" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /documents/{documentId}
#
# --groundTruth item shape: {label: string, value: any}
export def "documents patch" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --dataset-id: string
  --description: string # nullable
  --ground-truth: list # nullable — item shape: {label: string, value: any}
  --metadata: record
  --name: string # nullable
  --retention-in-days: int
]: any -> record<consentId: string, content: string, contentMD5: string, contentType: string, createdBy: string, createdTime: string, datasetId: string, description: string, documentId: string, groundTruth: table<label: string, value: any>, metadata: record, name: string, retentionInDays: int, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let body = {"datasetId": $dataset_id, "description": $description, "groundTruth": $ground_truth, "metadata": $metadata, "name": $name, "retentionInDays": $retention_in_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /logs
export def "logs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --workflow-id: string
  --next-token: string
  --order: string
  --transition-execution-id: string
  --transition-id: string
  --max-results: string
  --workflow-execution-id: string
]: nothing -> record<logs: table<events: list, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string>, nextToken: string, order: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflowId" $workflow_id "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "transitionExecutionId" $transition_execution_id "scalar") (serialize-qp "transitionId" $transition_id "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "workflowExecutionId" $workflow_execution_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /logs
export def "logs options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /logs/{logId}
export def "logs get" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<events: list<record>, logId: string, startTime: string, transitionExecutionId: string, transitionId: any, workflowExecutionId: string, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({log_id: $log_id} | format pattern "/logs/{log_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /logs/{logId}
export def "logs options-by-logId" [
  log_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({log_id: $log_id} | format pattern "/logs/{log_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /models
export def "models list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> record<models: table<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int>, nextToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /models
export def "models options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /models
#
# --preprocessConfig shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
export def "models post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  field_config: record
  --height: int
  --metadata: record
  --name: string # nullable
  --postprocess-config: any
  --preprocess-config: record # shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
  --width: int
]: any -> record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/models")
  let body = {"description": $description, "fieldConfig": $field_config, "height": $height, "metadata": $metadata, "name": $name, "postprocessConfig": $postprocess_config, "preprocessConfig": $preprocess_config, "width": $width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /models/{modelId}
export def "models delete" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /models/{modelId}
export def "models get" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /models/{modelId}
export def "models options-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /models/{modelId}
#
# --preprocessConfig shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
export def "models patch" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --field-config: record
  --height: int
  --metadata: record
  --name: string # nullable
  --postprocess-config: any
  --preprocess-config: record # shape: {autoRotate: bool, imageQuality: "LOW"|"HIGH", maxPages: int}
  --training-id: string # nullable
  --width: int
]: any -> record<createdBy: string, createdTime: string, description: string, fieldConfig: record, height: int, metadata: record, modelId: string, name: string, numberOfDataBundles: int, numberOfRunningTrainings: int, organizationId: string, postprocessConfig: any, preprocessConfig: record<autoRotate: bool, imageQuality: string, maxPages: int>, status: string, trainingId: string, updatedBy: string, updatedTime: string, width: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}"))
  let body = {"description": $description, "fieldConfig": $field_config, "height": $height, "metadata": $metadata, "name": $name, "postprocessConfig": $postprocess_config, "preprocessConfig": $preprocess_config, "trainingId": $training_id, "width": $width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /models/{modelId}/dataBundles
export def "models-data-bundles get" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --next-token: string
  --max-results: string
]: nothing -> record<dataBundles: table<createdBy: string, createdTime: string, dataBundleId: string, datasets: list, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string>, nextToken: string, status: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/dataBundles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /models/{modelId}/dataBundles
export def "models-data-bundles options-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/dataBundles"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /models/{modelId}/dataBundles
export def "models-data-bundles post" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --dataset-ids: list
  --description: string # nullable
  --name: string # nullable
]: any -> record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/dataBundles"))
  let body = {"datasetIds": $dataset_ids, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /models/{modelId}/dataBundles/{dataBundleId}
export def "models-data-bundles delete" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id, data_bundle_id: $data_bundle_id} | format pattern "/models/{model_id}/dataBundles/{data_bundle_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /models/{modelId}/dataBundles/{dataBundleId}
export def "models-data-bundles options-by-modelId-dataBundleId" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id, data_bundle_id: $data_bundle_id} | format pattern "/models/{model_id}/dataBundles/{data_bundle_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /models/{modelId}/dataBundles/{dataBundleId}
export def "models-data-bundles patch" [
  model_id: string
  data_bundle_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --name: string # nullable
]: any -> record<createdBy: string, createdTime: string, dataBundleId: string, datasets: table<containsPersonallyIdentifiableInformation: bool, createdBy: string, createdTime: string, datasetId: string, description: string, groundTruthSummary: record, metadata: record, name: string, numberOfDocuments: int, retentionInDays: int, storageLocation: string, updatedBy: string, updatedTime: string, version: int>, description: string, modelId: string, name: string, retentionInDays: int, status: string, summary: record, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id, data_bundle_id: $data_bundle_id} | format pattern "/models/{model_id}/dataBundles/{data_bundle_id}"))
  let body = {"description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /models/{modelId}/trainings
export def "models-trainings get" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, status: list<string>, trainings: table<createdBy: string, createdTime: string, dataBundleIds: list, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/trainings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /models/{modelId}/trainings
export def "models-trainings options-by-modelId" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/trainings"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /models/{modelId}/trainings
#
# --warmStartConfig shape: {trainingId: string}
export def "models-trainings post" [
  model_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --data-bundle-ids: list
  --data-scientist-assistance: oneof<nothing, bool>
  --description: string # nullable
  --instance-type: string@instance-type-completer # nullable
  --metadata: record
  --name: string # nullable
  --warm-start-config: record # shape: {trainingId: string}
]: any -> record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id} | format pattern "/models/{model_id}/trainings"))
  let body = {"dataBundleIds": $data_bundle_ids, "dataScientistAssistance": $data_scientist_assistance, "description": $description, "instanceType": $instance_type, "metadata": $metadata, "name": $name, "warmStartConfig": $warm_start_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OPTIONS /models/{modelId}/trainings/{trainingId}
export def "models-trainings options-by-modelId-trainingId" [
  model_id: string
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id, training_id: $training_id} | format pattern "/models/{model_id}/trainings/{training_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /models/{modelId}/trainings/{trainingId}
export def "models-trainings patch" [
  model_id: string
  training_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --deployment-environment-id: string # nullable
  --description: string # nullable
  --metadata: record
  --name: string # nullable
  --status: string@status-completer
]: any -> record<createdBy: string, createdTime: string, dataBundleIds: list<string>, dataScientistAssistance: bool, deploymentEnvironmentId: string, description: string, evaluation: record, gpuHours: float, instanceType: string, metadata: record, modelId: string, name: string, status: string, trainingId: string, updatedBy: string, updatedTime: string, warmStartConfig: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({model_id: $model_id, training_id: $training_id} | format pattern "/models/{model_id}/trainings/{training_id}"))
  let body = {"deploymentEnvironmentId": $deployment_environment_id, "description": $description, "metadata": $metadata, "name": $name, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /organizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, organizations: table<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /organizations
export def "organizations options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /organizations
export def "organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --name: string # nullable
]: any -> record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organizations")
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /organizations/{organizationId}
export def "organizations get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: $organization_id} | format pattern "/organizations/{organization_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /organizations/{organizationId}
export def "organizations options-by-organizationId" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: $organization_id} | format pattern "/organizations/{organization_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /organizations/{organizationId}
export def "organizations patch" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --name: string # nullable
  --payment-method-id: string
  --plan-id: string
]: any -> record<clientId: string, deploymentsAllowed: record, deploymentsCreated: record, description: string, documentRetentionInDays: int, monthlyNumberOfActiveModelsUsed: int, monthlyNumberOfDataBundlesAllowed: int, monthlyNumberOfDataBundlesCreated: int, monthlyNumberOfDocumentsAllowed: int, monthlyNumberOfDocumentsCreated: int, monthlyNumberOfFieldPredictionsUsed: int, monthlyNumberOfGpuHoursUsed: float, monthlyNumberOfModelDeploymentUnitsUsed: int, monthlyNumberOfPredictionsAllowed: int, monthlyNumberOfPredictionsCreated: int, monthlyNumberOfTrainingsAllowed: int, monthlyNumberOfTrainingsCreated: int, monthlyNumberOfTransitionExecutionsAllowed: int, monthlyNumberOfTransitionExecutionsCreated: int, monthlyNumberOfWorkflowExecutionsAllowed: int, monthlyNumberOfWorkflowExecutionsCreated: int, monthlyUsageSummary: record, name: string, numberOfAppClientsAllowed: int, numberOfAppClientsCreated: int, numberOfAssetsAllowed: int, numberOfAssetsCreated: int, numberOfDatasetsAllowed: int, numberOfDatasetsCreated: int, numberOfModelsAllowed: int, numberOfModelsCreated: int, numberOfSecretsAllowed: int, numberOfSecretsCreated: int, numberOfTransitionsAllowed: int, numberOfTransitionsCreated: int, numberOfUsersAllowed: int, numberOfUsersCreated: int, numberOfWorkflowsAllowed: int, numberOfWorkflowsCreated: int, organizationId: string, paymentMethodId: string, planId: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organization_id: $organization_id} | format pattern "/organizations/{organization_id}"))
  let body = {"description": $description, "name": $name, "paymentMethodId": $payment_method_id, "planId": $plan_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /paymentMethods
export def "payment-methods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, paymentMethods: table<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paymentMethods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /paymentMethods
export def "payment-methods options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentMethods")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /paymentMethods
export def "payment-methods post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --name: string # nullable
]: any -> record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentMethods")
  let body = {"description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /paymentMethods/{paymentMethodId}
export def "payment-methods delete" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/paymentMethods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /paymentMethods/{paymentMethodId}
export def "payment-methods get" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/paymentMethods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /paymentMethods/{paymentMethodId}
export def "payment-methods options-by-paymentMethodId" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/paymentMethods/{payment_method_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /paymentMethods/{paymentMethodId}
export def "payment-methods patch" [
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --name: string # nullable
  --stripe-setup-intent-secret: string
]: any -> record<createdBy: string, createdTime: string, description: string, details: record, name: string, paymentMethodId: string, stripePublishableKey: string, stripeSetupIntentSecret: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_method_id: $payment_method_id} | format pattern "/paymentMethods/{payment_method_id}"))
  let body = {"description": $description, "name": $name, "stripeSetupIntentSecret": $stripe_setup_intent_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /plans
export def "plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, plans: table<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /plans
export def "plans options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plans")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /plans/{planId}
export def "plans get" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activeModels: record, available: bool, currency: string, description: string, fieldPredictions: record, gpuHours: record, latest: int, license: record, modelDeploymentUnits: record, name: string, organizationId: string, planId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({plan_id: $plan_id} | format pattern "/plans/{plan_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /plans/{planId}
export def "plans options-by-planId" [
  plan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({plan_id: $plan_id} | format pattern "/plans/{plan_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /predictions
export def "predictions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
  --sort-by: string
  --order: string
]: nothing -> record<nextToken: string, order: string, predictions: table<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list, trainingId: string>, sortBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/predictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /predictions
export def "predictions options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /predictions
export def "predictions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --auto-rotate: oneof<nothing, bool>
  document_id: string
  --image-quality: string@image-quality-completer
  --max-pages: int
  model_id: string
  --postprocess-config: any
  --rotation: int@rotation-completer
  --training-id: string
]: any -> record<createdBy: string, createdTime: string, documentId: string, inferenceTime: float, modelId: string, predictionId: string, predictions: list<any>, trainingId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/predictions")
  let body = {"autoRotate": $auto_rotate, "documentId": $document_id, "imageQuality": $image_quality, "maxPages": $max_pages, "modelId": $model_id, "postprocessConfig": $postprocess_config, "rotation": $rotation, "trainingId": $training_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /profiles/{profileId}
export def "profiles get" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /profiles/{profileId}
export def "profiles options" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /profiles/{profileId}
export def "profiles patch" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdTime: string, email: string, familyName: string, givenName: string, locale: string, metadata: record, name: string, picture: string, profileId: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /secrets
export def "secrets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, secrets: table<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /secrets
export def "secrets options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /secrets
export def "secrets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  data: record
  --description: string # nullable
  --name: string # nullable
]: any -> record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secrets")
  let body = {"data": $data, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /secrets/{secretId}
export def "secrets delete" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/secrets/{secret_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /secrets/{secretId}
export def "secrets options-by-secretId" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/secrets/{secret_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /secrets/{secretId}
export def "secrets patch" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --data: record
  --description: string # nullable
  --name: string # nullable
]: any -> record<createdBy: string, createdTime: string, description: string, name: string, secretId: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/secrets/{secret_id}"))
  let body = {"data": $data, "description": $description, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OPTIONS /signup
export def "signup options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signup")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /signup
export def "signup post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  email: string
  --name: string # nullable
  password: string
  re_captcha_response: string
]: any -> record<clientId: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signup")
  let body = {"email": $email, "name": $name, "password": $password, "reCaptchaResponse": $re_captcha_response} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /transitions
export def "transitions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --transition-type: string
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, transitionType: list<string>, transitions: table<assets: record, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transitionType" $transition_type "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /transitions
export def "transitions options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transitions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /transitions
export def "transitions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --description: string # nullable
  --input-json-schema: record
  --name: string # nullable
  --output-json-schema: record
  --parameters: any
  --timeout-in-seconds: int
  transition_type: string@transition-type-completer
]: any -> record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transitions")
  let body = {"description": $description, "inputJsonSchema": $input_json_schema, "name": $name, "outputJsonSchema": $output_json_schema, "parameters": $parameters, "timeoutInSeconds": $timeout_in_seconds, "transitionType": $transition_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /transitions/{transitionId}
export def "transitions delete" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /transitions/{transitionId}
export def "transitions get" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /transitions/{transitionId}
export def "transitions options-by-transitionId" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /transitions/{transitionId}
#
# --assets shape: {jsRemoteComponent?: string}
export def "transitions patch" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --assets: record # shape: {jsRemoteComponent?: string}
  --description: string # nullable
  --environment: record
  --environment-secrets: list
  --input-json-schema: record
  --name: string # nullable
  --output-json-schema: record
  --parameters: any
]: any -> record<assets: record<jsRemoteComponent: string>, createdBy: string, createdTime: string, description: string, inputJsonSchema: record, name: string, outputJsonSchema: record, parameters: record, timeoutInSeconds: int, transitionId: any, transitionType: string, updatedBy: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}"))
  let body = {"assets": $assets, "description": $description, "environment": $environment, "environmentSecrets": $environment_secrets, "inputJsonSchema": $input_json_schema, "name": $name, "outputJsonSchema": $output_json_schema, "parameters": $parameters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /transitions/{transitionId}/executions
export def "transitions-executions list" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --order: string
  --execution-id: string
  --status: string
  --max-results: string
  --sort-by: string
]: nothing -> record<executions: table<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any>, nextToken: string, status: list<string>, transitionId: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "executionId" $execution_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "sortBy" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /transitions/{transitionId}/executions
export def "transitions-executions options-by-transitionId" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}/executions"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /transitions/{transitionId}/executions
export def "transitions-executions post" [
  transition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --body: record
]: any -> record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id} | format pattern "/transitions/{transition_id}/executions"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /transitions/{transitionId}/executions/{executionId}
export def "transitions-executions get" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id, execution_id: $execution_id} | format pattern "/transitions/{transition_id}/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /transitions/{transitionId}/executions/{executionId}
export def "transitions-executions options-by-transitionId-executionId" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id, execution_id: $execution_id} | format pattern "/transitions/{transition_id}/executions/{execution_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /transitions/{transitionId}/executions/{executionId}
#
# --error shape: {message: string}
export def "transitions-executions patch" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --body-error: record # shape: {message: string}
  --output: record
  --start-time: string # nullable
  --status: string
]: any -> record<completedBy: string, endTime: string, executionId: string, input: record, logId: string, startTime: string, status: string, transitionId: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id, execution_id: $execution_id} | format pattern "/transitions/{transition_id}/executions/{execution_id}"))
  let body = {"error": $body_error, "output": $output, "startTime": $start_time, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OPTIONS /transitions/{transitionId}/executions/{executionId}/heartbeats
export def "transitions-executions-heartbeats options" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id, execution_id: $execution_id} | format pattern "/transitions/{transition_id}/executions/{execution_id}/heartbeats"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /transitions/{transitionId}/executions/{executionId}/heartbeats
export def "transitions-executions-heartbeats post" [
  transition_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transition_id: $transition_id, execution_id: $execution_id} | format pattern "/transitions/{transition_id}/executions/{execution_id}/heartbeats"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, users: table<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /users
export def "users options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --app-client-id: string
  --avatar: string # nullable
  email: string
  --metadata: record
  --name: string # nullable
]: any -> record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let body = {"appClientId": $app_client_id, "avatar": $avatar, "email": $email, "metadata": $metadata, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /users/{userId}
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /users/{userId}
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /users/{userId}
export def "users options-by-userId" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /users/{userId}
export def "users patch" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --avatar: string # nullable
  --metadata: record
  --name: string # nullable
]: any -> record<avatar: string, createdBy: string, createdTime: string, email: string, metadata: record, name: string, profileId: string, updatedBy: string, updatedTime: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/users/{user_id}"))
  let body = {"avatar": $avatar, "metadata": $metadata, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /workflows
export def "workflows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-token: string
  --max-results: string
]: nothing -> record<nextToken: string, workflows: table<completedConfig: record, createdBy: string, createdTime: string, description: string, errorConfig: record, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nextToken" $next_token "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /workflows
export def "workflows options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /workflows
#
# --completedConfig shape: {environment?: record, environmentSecrets?: list, imageUrl: string, secretId?: string}
# --errorConfig shape: {email?: string, manualRetry?: bool}
# --specification shape: {definition: record, language?: "ASL", version?: "1.0.0"}
export def "workflows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --completed-config: record # shape: {environment?: record, environmentSecrets?: list, imageUrl: string, secretId?: string}
  --description: string # nullable
  --error-config: record # shape: {email?: string, manualRetry?: bool}
  --name: string # nullable
  specification: record # shape: {definition: record, language?: "ASL", version?: "1.0.0"}
]: any -> record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workflows")
  let body = {"completedConfig": $completed_config, "description": $description, "errorConfig": $error_config, "name": $name, "specification": $specification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /workflows/{workflowId}
export def "workflows delete" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /workflows/{workflowId}
export def "workflows get" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /workflows/{workflowId}
export def "workflows options-by-workflowId" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /workflows/{workflowId}
#
# --completedConfig shape: {environment?: record, environmentSecrets?: list, imageUrl: string, secretId?: string}
# --errorConfig shape: {email?: string, manualRetry?: bool}
export def "workflows patch" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --completed-config: record # shape: {environment?: record, environmentSecrets?: list, imageUrl: string, secretId?: string}
  --description: string # nullable
  --error-config: record # shape: {email?: string, manualRetry?: bool}
  --name: string # nullable
]: any -> record<completedConfig: record<environment: record, environmentSecrets: list<string>, imageUrl: string, secretId: string>, createdBy: string, createdTime: string, description: string, errorConfig: record<email: string, manualRetry: bool>, name: string, numberOfRunningExecutions: int, updatedBy: string, updatedTime: string, workflowId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}"))
  let body = {"completedConfig": $completed_config, "description": $description, "errorConfig": $error_config, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /workflows/{workflowId}/executions
export def "workflows-executions list" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-start-time: string
  --to-start-time: string
  --next-token: string
  --order: string
  --status: string
  --max-results: string
  --sort-by: string
]: nothing -> record<executions: table<completedBy: list, completedTaskLogId: string, endTime: string, events: list, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string>, nextToken: string, order: string, sortBy: string, status: list<string>, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromStartTime" $from_start_time "scalar") (serialize-qp "toStartTime" $to_start_time "scalar") (serialize-qp "nextToken" $next_token "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "sortBy" $sort_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /workflows/{workflowId}/executions
export def "workflows-executions options-by-workflowId" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}/executions"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /workflows/{workflowId}/executions
export def "workflows-executions post" [
  workflow_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  input: record
]: any -> record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id} | format pattern "/workflows/{workflow_id}/executions"))
  let body = {"input": $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /workflows/{workflowId}/executions/{executionId}
export def "workflows-executions delete" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id, execution_id: $execution_id} | format pattern "/workflows/{workflow_id}/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /workflows/{workflowId}/executions/{executionId}
export def "workflows-executions get" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id, execution_id: $execution_id} | format pattern "/workflows/{workflow_id}/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# OPTIONS /workflows/{workflowId}/executions/{executionId}
export def "workflows-executions options-by-workflowId-executionId" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id, execution_id: $execution_id} | format pattern "/workflows/{workflow_id}/executions/{execution_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "options" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /workflows/{workflowId}/executions/{executionId}
export def "workflows-executions patch" [
  workflow_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  next_transition_id: any
]: any -> record<completedBy: list<any>, completedTaskLogId: string, endTime: string, events: list<record>, executionId: string, input: record, logId: string, output: record, startTime: string, status: string, transitionExecutions: record, workflowId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({workflow_id: $workflow_id, execution_id: $execution_id} | format pattern "/workflows/{workflow_id}/executions/{execution_id}"))
  let body = {"nextTransitionId": $next_transition_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
