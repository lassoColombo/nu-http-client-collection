# Auto-generated client for Browserbase API vv1
# Source: https://storage.googleapis.com/stainless-sdk-openapi-specs/browserbase/browserbase-f39b852755134d01a440f7c37701f6c5397f43d13740d9ba08739cae488382a7.yml
# Auth: --token flag or $env.BROWSERBASE_API_TOKEN

const BASE_URL = "https://api.browserbase.com"
const DEFAULT_AUTH = "x-bb-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BROWSERBASE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-bb-api-key" => { {headers: {X-BB-API-Key: $token_val}, query: ""} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.browserbase.com"] }
def auth-scheme-completer [] { ["x-bb-api-key"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/octet-stream"] }
def status-completer [] { ["COMPLETED" "ERROR" "PENDING" "RUNNING" "TIMED_OUT"] }
def region-completer [] { ["ap-southeast-1" "eu-central-1" "us-east-1" "us-west-2"] }
def status-completer-1 [] { ["REQUEST_RELEASE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "certificates upload" } } | get name | first)
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

# Upload a Certificate
#
# POST /v1/certificates
# operationId: Certificates_upload
export def "certificates upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # format: binary
]: any -> record<id: string, createdAt: string, updatedAt: string, projectId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List Certificates
#
# GET /v1/certificates
# operationId: Certificates_list
export def "certificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, createdAt: string, updatedAt: string, projectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Certificate
#
# GET /v1/certificates/{id}
# operationId: Certificates_get
export def "certificates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, projectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Certificate
#
# DELETE /v1/certificates/{id}
# operationId: Certificates_delete
export def "certificates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/certificates/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Context
#
# POST /v1/contexts
# operationId: Contexts_create
export def "contexts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The Project ID. Can be found in [Settings](https://www.browserbase.com/settings). Optional - if not provided, the project will be inferred from the API key.
]: any -> record<id: string, uploadUrl: string, publicKey: string, cipherAlgorithm: string, initializationVectorSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/contexts")
  let body = {projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Context
#
# GET /v1/contexts/{id}
# operationId: Contexts_get
export def "contexts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, projectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contexts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Context
#
# PUT /v1/contexts/{id}
# operationId: Contexts_update
export def "contexts update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, uploadUrl: string, publicKey: string, cipherAlgorithm: string, initializationVectorSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contexts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Context
#
# DELETE /v1/contexts/{id}
# operationId: Contexts_delete
export def "contexts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/contexts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Downloads
#
# GET /v1/downloads
# operationId: Downloads_list
export def "downloads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sessionId: string # Filter downloads by session ID (required).
  --filename: string # Filter by exact filename match.
  --mimeType: string # Filter by MIME type.
  --minSize: float # Minimum file size in bytes.
  --maxSize: float # Maximum file size in bytes.
  --createdAfter: string # Filter downloads created on or after this timestamp. (format: date-time)
  --createdBefore: string # Filter downloads created on or before this timestamp. (format: date-time)
  --limit: float # Maximum number of results to return. (default: 20)
  --offset: float # Number of results to skip for pagination. (default: 0)
]: nothing -> record<downloads: table<id: string, sessionId: string, filename: string, mimeType: string, size: float, checksum: string, createdAt: string>, total: float, limit: float, offset: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sessionId" $sessionId "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "mimeType" $mimeType "scalar") (serialize-qp "minSize" $minSize "scalar") (serialize-qp "maxSize" $maxSize "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/downloads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Download
#
# GET /v1/downloads/{id}
# operationId: Downloads_get
export def "downloads get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, sessionId: string, filename: string, mimeType: string, size: float, checksum: string, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/downloads/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Download
#
# DELETE /v1/downloads/{id}
# operationId: Downloads_delete
export def "downloads delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/downloads/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload an Extension
#
# POST /v1/extensions
# operationId: Extensions_upload
export def "extensions upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # format: binary
]: any -> record<id: string, createdAt: string, updatedAt: string, fileName: string, projectId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/extensions")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get an Extension
#
# GET /v1/extensions/{id}
# operationId: Extensions_get
export def "extensions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, fileName: string, projectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/extensions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Extension
#
# DELETE /v1/extensions/{id}
# operationId: Extensions_delete
export def "extensions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/extensions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a Page
#
# POST /v1/fetch
# operationId: Fetch_create
export def "fetch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL to fetch (format: uri)
  --allowRedirects: string@bool-completer # Whether to follow HTTP redirects (default: false)
  --allowInsecureSsl: string@bool-completer # Whether to bypass TLS certificate verification (default: false)
  --proxies: string@bool-completer # Whether to enable proxy support for the request (default: false)
  --format: any # Output format for the response content. `raw` (default) returns the response body unchanged; `json` returns structured data (requires `schema`); `markdown` returns the page as markdown. (default: raw)
  --schema: record # JSON Schema describing the desired structure of the response. Only used when `format` is `json`.
]: any -> record<id: string, statusCode: int, headers: record, content: any, contentType: string, encoding: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/fetch")
  let body = {url: $body_url, allowRedirects: $allowRedirects, allowInsecureSsl: $allowInsecureSsl, proxies: $proxies, format: $format, schema: $schema} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Functions
#
# GET /v1/functions
# operationId: Functions_list
export def "functions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # default: 0
  --limit: int # default: 20
]: nothing -> record<data: table<id: string, projectId: string, name: string, createdAt: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Function Builds
#
# GET /v1/functions/builds
# operationId: FunctionBuilds_list
export def "functions-builds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # default: 0
  --limit: int # default: 20
  --status: string
]: nothing -> record<data: table<id: string, projectId: string, request: record, status: string, createdAt: string, updatedAt: string, startedAt: string, endedAt: string, expiresAt: string, builtFunctions: list, cause: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/functions/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Function Build
#
# GET /v1/functions/builds/{id}
# operationId: FunctionBuilds_get
export def "functions-builds get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, projectId: string, request: record<entrypoint: string, functionNames: list<string>>, status: string, createdAt: string, updatedAt: string, startedAt: string, endedAt: string, expiresAt: string, builtFunctions: table<id: string, projectId: string, name: string, createdAt: string, updatedAt: string, createdVersion: record>, cause: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/builds/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Function Build Logs
#
# GET /v1/functions/builds/{id}/logs
# operationId: FunctionBuilds_getLogs
export def "functions-builds-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logs: table<message: string, timestamp: float>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/builds/($id)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Invocation
#
# GET /v1/functions/invocations/{id}
# operationId: Invocations_get
export def "functions-invocations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, projectId: string, functionId: string, versionId: string, sessionId: string, region: string, params: record, status: string, results: record, createdAt: string, updatedAt: string, startedAt: string, endedAt: string, expiresAt: string, cause: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/invocations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Invocation Logs
#
# GET /v1/functions/invocations/{id}/logs
# operationId: Invocations_getLogs
export def "functions-invocations-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<logs: table<message: string, timestamp: float>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/invocations/($id)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Function Version
#
# GET /v1/functions/versions/{id}
# operationId: FunctionVersions_get
export def "functions-versions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, projectId: string, functionId: string, functionBuildId: string, sessionCreateParams: record, userParamsSchema: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/versions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Invocations for a Function Version
#
# GET /v1/functions/versions/{id}/invocations
# operationId: FunctionVersions_listInvocations
export def "functions-versions-invocations listInvocations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # default: 0
  --limit: int # default: 20
  --status: string
]: nothing -> record<results: table<id: string, projectId: string, functionId: string, versionId: string, sessionId: string, region: string, params: record, status: string, results: record, createdAt: string, updatedAt: string, startedAt: string, endedAt: string, expiresAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/functions/versions/($id)/invocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Function
#
# GET /v1/functions/{id}
# operationId: Functions_get
export def "functions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, projectId: string, name: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke a Function
#
# POST /v1/functions/{id}/invoke
# operationId: Functions_invoke
# --sessionCreateParams shape: {extensionId?: string, browserSettings?: record, proxies?: any, proxySettings?: record, userMetadata?: record, timeout?: int}
export def "functions-invoke invoke" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --params: record # JSON object that can be stored in a JSONB column
  --sessionCreateParams: record # shape: {extensionId?: string, browserSettings?: record, proxies?: any, proxySettings?: record, userMetadata?: record, timeout?: int}
]: any -> record<id: string, projectId: string, functionId: string, versionId: string, sessionId: string, region: string, params: record, status: string, results: record, createdAt: string, updatedAt: string, startedAt: string, endedAt: string, expiresAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/functions/($id)/invoke")
  let body = {params: $params, sessionCreateParams: $sessionCreateParams} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Function Versions
#
# GET /v1/functions/{id}/versions
# operationId: Functions_listVersions
export def "functions-versions listVersions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # default: 0
  --limit: int # default: 20
]: nothing -> record<results: table<id: string, projectId: string, functionId: string, functionBuildId: string, sessionCreateParams: record, userParamsSchema: record, createdAt: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/functions/($id)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Projects
#
# GET /v1/projects
# operationId: Projects_list
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, createdAt: string, updatedAt: string, name: string, ownerId: string, defaultTimeout: int, concurrency: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Project
#
# GET /v1/projects/{id}
# operationId: Projects_get
export def "projects get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, name: string, ownerId: string, defaultTimeout: int, concurrency: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Project Usage
#
# GET /v1/projects/{id}/usage
# operationId: Projects_usage
export def "projects-usage usage" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<browserMinutes: int, proxyBytes: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/projects/($id)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Web Search
#
# POST /v1/search
# operationId: Search_web
export def "search web" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # The search query string
  --numResults: int # Number of results to return (1-25) (default: 10)
]: any -> record<requestId: string, query: string, results: table<id: string, url: string, title: string, author: string, publishedDate: string, image: string, favicon: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/search")
  let body = {query: $body_query, numResults: $numResults} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Sessions
#
# GET /v1/sessions
# operationId: Sessions_list
export def "sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --q: string # Query sessions by user metadata. See [Querying Sessions by User Metadata](/features/sessions#querying-sessions-by-user-metadata) for the schema of this query.
]: nothing -> table<id: string, createdAt: string, updatedAt: string, projectId: string, startedAt: string, endedAt: string, expiresAt: string, status: string, proxyBytes: int, keepAlive: bool, contextId: string, region: string, userMetadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Session
#
# POST /v1/sessions
# operationId: Sessions_create
# --browserSettings shape: {context?: record, extensionId?: string, viewport?: record, blockAds?: bool, solveCaptchas?: bool, recordSession?: bool, logSession?: bool, advancedStealth?: bool, verified?: bool, captchaImageSelector?: string, captchaInputSelector?: string, os?: "windows"|"mac"|"linux"|"mobile"|"tablet", ignoreCertificateErrors?: bool}
# --proxySettings shape: {caCertificates?: list}
export def "sessions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The Project ID. Can be found in [Settings](https://www.browserbase.com/settings). Optional - if not provided, the project will be inferred from the API key.
  --extensionId: string # The uploaded Extension ID. See [Upload Extension](/reference/api/upload-an-extension).
  --browserSettings: record # shape: {context?: record, extensionId?: string, viewport?: record, blockAds?: bool, solveCaptchas?: bool, recordSession?: bool, logSession?: bool, advancedStealth?: bool, verified?: bool, captchaImageSelector?: string, captchaInputSelector?: string, os?: "windows"|"mac"|"linux"|"mobile"|"tablet", ignoreCertificateErrors?: bool}
  --timeout: int # Duration in seconds after which the session will automatically end. Defaults to the Project's `defaultTimeout`.
  --keepAlive: string@bool-completer # Set to true to keep the session alive even after disconnections. Available on the Hobby Plan and above.
  --proxies: any # Proxy configuration. Can be true for default proxy, or an array of proxy configurations.
  --proxySettings: record # Supplementary proxy settings. Optional. — shape: {caCertificates?: list}
  --region: string@region-completer # The region where the Session should run. (default: us-west-2)
  --userMetadata: record # Arbitrary user metadata to attach to the session. To learn more about user metadata, see [User Metadata](/features/sessions#user-metadata).
]: any -> record<id: string, createdAt: string, updatedAt: string, projectId: string, startedAt: string, endedAt: string, expiresAt: string, status: string, proxyBytes: int, keepAlive: bool, contextId: string, region: string, userMetadata: record, connectUrl: string, seleniumRemoteUrl: string, signingKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions")
  let body = {projectId: $projectId, extensionId: $extensionId, browserSettings: $browserSettings, timeout: $timeout, keepAlive: $keepAlive, proxies: $proxies, proxySettings: $proxySettings, region: $region, userMetadata: $userMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Session
#
# GET /v1/sessions/{id}
# operationId: Sessions_get
export def "sessions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, createdAt: string, updatedAt: string, projectId: string, startedAt: string, endedAt: string, expiresAt: string, status: string, proxyBytes: int, keepAlive: bool, contextId: string, region: string, userMetadata: record, connectUrl: string, seleniumRemoteUrl: string, signingKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a Session
#
# POST /v1/sessions/{id}
# operationId: Sessions_update
export def "sessions update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string # The Project ID. Can be found in [Settings](https://www.browserbase.com/settings). Optional - if not provided, the project will be inferred from the API key.
  status: string@status-completer-1 # Set to `REQUEST_RELEASE` to request that the session complete. Use before session's timeout to avoid additional charges.
]: any -> record<id: string, createdAt: string, updatedAt: string, projectId: string, startedAt: string, endedAt: string, expiresAt: string, status: string, proxyBytes: int, keepAlive: bool, contextId: string, region: string, userMetadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)")
  let body = {projectId: $projectId, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Session Live URLs
#
# GET /v1/sessions/{id}/debug
# operationId: Sessions_getDebug
export def "sessions-debug get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<debuggerFullscreenUrl: string, debuggerUrl: string, pages: table<id: string, url: string, faviconUrl: string, title: string, debuggerUrl: string, debuggerFullscreenUrl: string>, wsUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/debug")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Session Downloads
#
# GET /v1/sessions/{id}/downloads
# operationId: Sessions_getDownloads
export def "sessions-downloads get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/downloads")
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Session Downloads
#
# DELETE /v1/sessions/{id}/downloads
# operationId: Sessions_deleteDownloads
export def "sessions-downloads delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/downloads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Session Logs
#
# GET /v1/sessions/{id}/logs
# operationId: Sessions_getLogs
export def "sessions-logs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<method: string, pageId: int, sessionId: string, request: record<timestamp: int, params: record, rawBody: string>, response: record<timestamp: int, result: record, rawBody: string>, timestamp: int, frameId: string, loaderId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Session Recording
#
# GET /v1/sessions/{id}/recording
# operationId: Sessions_getRecording
export def "sessions-recording get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<data: record, sessionId: string, timestamp: int, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/recording")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session Replay
#
# GET /v1/sessions/{id}/replays
# operationId: Sessions_getReplay
export def "sessions-replays list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pages: table<pageId: string, url: string, startTimeMs: int, endTimeMs: int>, pageCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/replays")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Replay Page
#
# GET /v1/sessions/{id}/replays/{pageId}
# operationId: Sessions_getReplayPage
export def "sessions-replays get" [
  id: string
  pageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/replays/($pageId)")
  let accept_val = "application/vnd.apple.mpegurl"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Session Uploads
#
# POST /v1/sessions/{id}/uploads
# operationId: Sessions_uploadFile
export def "sessions-uploads uploadFile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # format: binary
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-bb-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/($id)/uploads")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}
