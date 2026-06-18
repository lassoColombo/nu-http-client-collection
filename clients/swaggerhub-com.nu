# Auto-generated client for SwaggerHub Registry API v1.0.66
# Source: https://api.apis.guru/v2/specs/swaggerhub.com/1.0.66/swagger.json
# Auth: --token flag or $env.SWAGGERHUB_REGISTRY_API_TOKEN

const BASE_URL = "https://api.swaggerhub.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SWAGGERHUB_REGISTRY_API_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.swaggerhub.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["ALL" "PUBLISHED" "UNPUBLISHED"] }
def sort-completer [] { ["BEST_MATCH" "CREATED" "NAME" "OWNER" "TITLE" "UPDATED"] }
def order-completer [] { ["ASC" "DESC"] }
def accept-completer [] { ["application/json" "application/yaml"] }
def sort-completer-1 [] { ["NAME" "OWNER"] }
def spec-type-completer [] { ["ANY" "API" "DOMAIN" "TEMPLATE"] }
def visibility-completer [] { ["ANY" "PRIVATE" "PUBLIC"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apis list" } } | get name | first)
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

# Search APIs
#
# GET /apis
# operationId: searchApis
export def "apis list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Free text query to match
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of APIs of the specified owner
#
# GET /apis/{owner}
# operationId: getOwnerApis
export def "apis get" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner)} | format pattern "/apis/{owner}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an API
#
# DELETE /apis/{owner}/{api}
# operationId: deleteApi
export def "apis delete-by-owner-api" [
  owner: string
  api: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of API versions
#
# GET /apis/{owner}/{api}
# operationId: getApiVersions
export def "apis get-versions" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update an API
#
# POST /apis/{owner}/{api}
# operationId: saveDefinition
export def "apis create-save-definition" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # Whether to make the API private (`true`) or public (`false`) (default: false)
  --version: string # API version to create or update. If omitted, the version is extracted from the `info.version` field of the provided OpenAPI definition. Either the `version` parameter or the `info.version` value must be specified, otherwise the request will be rejected. If both are specified, the `version` parameter overrides the `info.version` value. If this API version already exists, it will be updated with the new definition (unless that version has been published - in this case the update will be rejected).
  --force: oneof<nothing, bool> # Force update
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPrivate" $is_private "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rename an API
#
# POST /apis/{owner}/{api}/rename
# operationId: renameApi
export def "apis-rename rename" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # New name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newName" $new_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}/rename") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the default version of an API
#
# GET /apis/{owner}/{api}/settings/default
# operationId: getApiDefaultVersion
export def "apis-settings-default get-version" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}/settings/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the default API version
#
# PUT /apis/{owner}/{api}/settings/default
# operationId: setApiDefaultVersion
export def "apis-settings-default update-version" [
  owner: string
  api: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  version: string # Version identifier (case-insensitive) (e.g. 1.0.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api)} | format pattern "/apis/{owner}/{api}/settings/default"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete an API version
#
# DELETE /apis/{owner}/{api}/{version}
# operationId: deleteApiVersion
export def "apis delete-by-owner-api-version" [
  owner: string
  api: string
  version: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition of the specified API version
#
# GET /apis/{owner}/{api}/{version}
# operationId: getDefinition
export def "apis get-definition" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new API version
#
# POST /apis/{owner}/{api}/{version}/clone
# operationId: cloneApi
export def "apis-clone clone" [
  owner: string
  api: string
  version: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/clone"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comments for the specified API version
#
# GET /apis/{owner}/{api}/{version}/comments
# operationId: getApiCommentsV2
export def "apis-comments get" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new comment
#
# POST /apis/{owner}/{api}/{version}/comments
# operationId: addApiCommentV2
# --replies item shape: {body: string}
export def "apis-comments create" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
  position: int # format: int32
  --replies: list # item shape: {body: string}
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/comments"))
  let req_body = {"body": $body, "position": $position, "replies": $replies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk update comments
#
# POST /apis/{owner}/{api}/{version}/comments/batch
# operationId: updateApiCommentsV2
# --addComment item shape: {body: string, position: int, replies?: list}
export def "apis-comments-batch update" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/comments/batch"))
  let req_body = {"addComment": $add_comment, "addReply": $add_reply, "deleteComment": $delete_comment, "deleteReply": $delete_reply, "updateComment": $update_comment, "updateReply": $update_reply, "updateStatus": $update_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a comment
#
# DELETE /apis/{owner}/{api}/{version}/comments/{comment}
# operationId: deleteApiCommentV2
export def "apis-comments delete" [
  owner: string
  api: string
  version: string
  comment: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment
#
# PATCH /apis/{owner}/{api}/{version}/comments/{comment}
# operationId: updateApiCommentV2
export def "apis-comments update" [
  owner: string
  api: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
  --position: int # format: int32
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}"))
  let req_body = {"body": $body, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reply to a comment
#
# POST /apis/{owner}/{api}/{version}/comments/{comment}/replies
# operationId: addApiCommentReplyV2
export def "apis-comments-replies create-reply" [
  owner: string
  api: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}/replies"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a comment reply
#
# DELETE /apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}
# operationId: deleteApiCommentReplyV2
export def "apis-comments-replies delete" [
  owner: string
  api: string
  version: string
  comment: string
  reply: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment), reply: (encode-path-segment $reply)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment reply
#
# PATCH /apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}
# operationId: updateApiCommentReplyV2
export def "apis-comments-replies update" [
  owner: string
  api: string
  version: string
  comment: string
  reply: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment), reply: (encode-path-segment $reply)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}/replies/{reply}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resolve or reopen a comment
#
# PUT /apis/{owner}/{api}/{version}/comments/{comment}/status/{status}
# operationId: setApiCommentStatusV2
export def "apis-comments-status update" [
  owner: string
  api: string
  version: string
  comment: string
  status: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), comment: (encode-path-segment $comment), status: (encode-path-segment $status)} | format pattern "/apis/{owner}/{api}/{version}/comments/{comment}/status/{status}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fork an API
#
# POST /apis/{owner}/{api}/{version}/fork
# operationId: forkApi
export def "apis-fork create" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/fork"))
  let req_body = {"name": $name, "owner": $body_owner, "private": $private, "project": $project, "version": $body_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get all integrations configured for the specified API version
#
# GET /apis/{owner}/{api}/{version}/integrations
# operationId: getIntegrations
export def "apis-integrations list" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<integrations: table<enabled: bool, id: string, name: string, configType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/integrations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an integration for the specified API and version
#
# POST /apis/{owner}/{api}/{version}/integrations
# operationId: createIntegration
export def "apis-integrations create" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/integrations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an integration
#
# DELETE /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: deleteIntegration
export def "apis-integrations delete" [
  owner: string
  api: string
  version: string
  integration_id: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), integration_id: (encode-path-segment $integration_id)} | format pattern "/apis/{owner}/{api}/{version}/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get integration settings
#
# GET /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: getIntegrationById
export def "apis-integrations get" [
  owner: string
  api: string
  version: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), integration_id: (encode-path-segment $integration_id)} | format pattern "/apis/{owner}/{api}/{version}/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update integration settings
#
# PATCH /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: patchIntegration
export def "apis-integrations update-by-owner-api-version-integrationId" [
  owner: string
  api: string
  version: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), integration_id: (encode-path-segment $integration_id)} | format pattern "/apis/{owner}/{api}/{version}/integrations/{integration_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update integration settings
#
# PUT /apis/{owner}/{api}/{version}/integrations/{integrationId}
# operationId: updateIntegration
export def "apis-integrations update-by-owner-api-version-integrationId-1" [
  owner: string
  api: string
  version: string
  integration_id: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), integration_id: (encode-path-segment $integration_id)} | format pattern "/apis/{owner}/{api}/{version}/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run an integration
#
# POST /apis/{owner}/{api}/{version}/integrations/{integrationId}/execute
# operationId: executeIntegration
export def "apis-integrations-execute create" [
  owner: string
  api: string
  version: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commit-message: string # Commit message for source control integrations
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "commitMessage" $commit_message "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version), integration_id: (encode-path-segment $integration_id)} | format pattern "/apis/{owner}/{api}/{version}/integrations/{integration_id}/execute") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the published status for the specified API and version
#
# GET /apis/{owner}/{api}/{version}/settings/lifecycle
# operationId: getLifecycleSettings
export def "apis-settings-lifecycle get" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/settings/lifecycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish or unpublish an API version
#
# PUT /apis/{owner}/{api}/{version}/settings/lifecycle
# operationId: setLifecycleSettings
export def "apis-settings-lifecycle update" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To publish an API that references _unpublished_ domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/settings/lifecycle") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the visibility (public or private) of API version
#
# GET /apis/{owner}/{api}/{version}/settings/private
# operationId: getPrivateSettings
export def "apis-settings-private get" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/settings/private"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the visibility (public or private) of an API version
#
# PUT /apis/{owner}/{api}/{version}/settings/private
# operationId: setPrivateSettings
export def "apis-settings-private update" [
  owner: string
  api: string
  version: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/settings/private"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the standardization errors for a given API definition
#
# GET /apis/{owner}/{api}/{version}/standardization
# operationId: getStandardizationErrors
export def "apis-standardization get-errors" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<validation: table<description: string, line: int, severity: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/standardization"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition for the specified API version in JSON format
#
# GET /apis/{owner}/{api}/{version}/swagger.json
# operationId: getJsonDefinition
export def "apis-swagger-json get-definition" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/swagger.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition for the specified API version in YAML format
#
# GET /apis/{owner}/{api}/{version}/swagger.yaml
# operationId: getYamlDefinition
export def "apis-swagger-yaml get-definition" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --resolved: oneof<nothing, bool> # Set to true to get the resolved version of the API definition. The content of all external $refs will be included in the resulting file. (default: false)
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolved" $resolved "scalar") (serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/swagger.yaml") $qp)
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecated Get API Standardization errors and warnings
#
# GET /apis/{owner}/{api}/{version}/validation
# DEPRECATED
# operationId: getValidation
@deprecated
export def "apis-validation get" [
  owner: string
  api: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<validation: table<description: string, line: int, severity: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), api: (encode-path-segment $api), version: (encode-path-segment $version)} | format pattern "/apis/{owner}/{api}/{version}/validation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search domains
#
# GET /domains
# operationId: searchDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Free text query to match
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of domains of the specified owner
#
# GET /domains/{owner}
# operationId: getOwnerDomains
export def "domains get" [
  owner: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner)} | format pattern "/domains/{owner}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a domain
#
# DELETE /domains/{owner}/{domain}
# operationId: deleteDomain
export def "domains delete-by-owner-domain" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If this domain is referenced from other APIs and domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of domain versions
#
# GET /domains/{owner}/{domain}
# operationId: getDomainVersions
export def "domains get-versions" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a domain
#
# POST /domains/{owner}/{domain}
# operationId: saveDomainDefinition
export def "domains create-save-definition" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # Specifies whether the domain has to be private (default: false)
  --version: string # Domain version. If omitted, will be taken from the `info.version` field in the definition.
  --force: oneof<nothing, bool> # Force update
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPrivate" $is_private "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rename a domain
#
# POST /domains/{owner}/{domain}/rename
# operationId: renameDomain
export def "domains-rename rename" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # New name
  --force: oneof<nothing, bool> # If this domain is referenced from other APIs and domains, this parameter must be true. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newName" $new_name "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}/rename") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the default version of a domain
#
# GET /domains/{owner}/{domain}/settings/default
# operationId: getDomainDefaultVersion
export def "domains-settings-default get-version" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}/settings/default"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the default version for a domain
#
# PUT /domains/{owner}/{domain}/settings/default
# operationId: setDomainDefaultVersion
export def "domains-settings-default update-version" [
  owner: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  version: string # Version identifier (case-insensitive) (e.g. 1.0.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain)} | format pattern "/domains/{owner}/{domain}/settings/default"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a domain version
#
# DELETE /domains/{owner}/{domain}/{version}
# operationId: deleteDomainVersion
export def "domains delete-by-owner-domain-version" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # If this domain version is referenced from other APIs and domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition of the specified domain version
#
# GET /domains/{owner}/{domain}/{version}
# operationId: getDomainDefinition
export def "domains get-definition" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new domain version
#
# POST /domains/{owner}/{domain}/{version}/clone
# operationId: cloneDomain
export def "domains-clone clone" [
  owner: string
  domain: string
  version: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/clone"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comments for the specified domain version
#
# GET /domains/{owner}/{domain}/{version}/comments
# operationId: getDomainCommentsV2
export def "domains-comments get" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new comment
#
# POST /domains/{owner}/{domain}/{version}/comments
# operationId: addDomainCommentV2
# --replies item shape: {body: string}
export def "domains-comments create" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
  position: int # format: int32
  --replies: list # item shape: {body: string}
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/comments"))
  let req_body = {"body": $body, "position": $position, "replies": $replies} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk update comments
#
# POST /domains/{owner}/{domain}/{version}/comments/batch
# operationId: updateDomainCommentsV2
# --addComment item shape: {body: string, position: int, replies?: list}
export def "domains-comments-batch update" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/comments/batch"))
  let req_body = {"addComment": $add_comment, "addReply": $add_reply, "deleteComment": $delete_comment, "deleteReply": $delete_reply, "updateComment": $update_comment, "updateReply": $update_reply, "updateStatus": $update_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a comment
#
# DELETE /domains/{owner}/{domain}/{version}/comments/{comment}
# operationId: deleteDomainCommentV2
export def "domains-comments delete" [
  owner: string
  domain: string
  version: string
  comment: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment
#
# PATCH /domains/{owner}/{domain}/{version}/comments/{comment}
# operationId: updateDomainCommentV2
export def "domains-comments update" [
  owner: string
  domain: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
  --position: int # format: int32
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: table<body: string, created: string, id: string, modified: string, user: record>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}"))
  let req_body = {"body": $body, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reply to a comment
#
# POST /domains/{owner}/{domain}/{version}/comments/{comment}/replies
# operationId: addDomainCommentReplyV2
export def "domains-comments-replies create-reply" [
  owner: string
  domain: string
  version: string
  comment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  body: string
]: any -> table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}/replies"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a comment reply
#
# DELETE /domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}
# operationId: deleteDomainCommentReplyV2
export def "domains-comments-replies delete" [
  owner: string
  domain: string
  version: string
  comment: string
  reply: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment), reply: (encode-path-segment $reply)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment reply
#
# PATCH /domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}
# operationId: updateDomainCommentReplyV2
export def "domains-comments-replies update" [
  owner: string
  domain: string
  version: string
  comment: string
  reply: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment), reply: (encode-path-segment $reply)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}/replies/{reply}"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resolve or reopen a comment
#
# PUT /domains/{owner}/{domain}/{version}/comments/{comment}/status/{status}
# operationId: setDomainCommentStatusV2
export def "domains-comments-status update" [
  owner: string
  domain: string
  version: string
  comment: string
  status: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version), comment: (encode-path-segment $comment), status: (encode-path-segment $status)} | format pattern "/domains/{owner}/{domain}/{version}/comments/{comment}/status/{status}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition for the specified domain version in JSON format
#
# GET /domains/{owner}/{domain}/{version}/domain.json
# operationId: getDomainJsonDefinition
export def "domains-domain-json get-definition" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/domain.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the OpenAPI definition for the specified domain version in YAML format
#
# GET /domains/{owner}/{domain}/{version}/domain.yaml
# operationId: getDomainYamlDefinition
export def "domains-domain-yaml get-definition" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/domain.yaml"))
  let accept_val = "application/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fork a domain
#
# POST /domains/{owner}/{domain}/{version}/fork
# operationId: forkDomain
export def "domains-fork create" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/fork"))
  let req_body = {"name": $name, "owner": $body_owner, "private": $private, "project": $project, "version": $body_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the published status for the specified domain and version
#
# GET /domains/{owner}/{domain}/{version}/settings/lifecycle
# operationId: getDomainLifecycleSettings
export def "domains-settings-lifecycle get" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/settings/lifecycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish or unpublish a domain version
#
# PUT /domains/{owner}/{domain}/{version}/settings/lifecycle
# operationId: setDomainLifecycleSettings
export def "domains-settings-lifecycle update" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To publish a domain that references other _unpublished_ domains, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/settings/lifecycle") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the visibility (public or private) of a domain version
#
# GET /domains/{owner}/{domain}/{version}/settings/private
# operationId: getDomainPrivateSettings
export def "domains-settings-private get" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/settings/private"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the visibility (public or private) of a domain version
#
# PUT /domains/{owner}/{domain}/{version}/settings/private
# operationId: setDomainPrivateSettings
export def "domains-settings-private update" [
  owner: string
  domain: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # To change the visibility from _public_ to _private_ in case this domain is referenced from other _public_ definitions, this parameter must be `true`. Otherwise, the request will be rejected with status code 424. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), domain: (encode-path-segment $domain), version: (encode-path-segment $version)} | format pattern "/domains/{owner}/{domain}/{version}/settings/private") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all projects that a user has access to
#
# GET /projects
# operationId: getUserProjects
export def "projects get-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-only: oneof<nothing, bool> # Return the project information excluding APIs and domains (default: false - DELETE)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer-1 # Sort criteria or result set: * NAME * OWNER (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameOnly" $name_only "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all projects of an organization
#
# GET /projects/{owner}
# operationId: getOrgProjectsV2
export def "projects get-org" [
  owner: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-only: oneof<nothing, bool> # Return the project information excluding APIs and domains (default: false - DELETE)
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> record<offset: int, projects: table<apis: list, description: string, domains: list, name: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameOnly" $name_only "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner)} | format pattern "/projects/{owner}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project in an organization
#
# POST /projects/{owner}
# operationId: createProject
export def "projects create" [
  owner: any
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner)} | format pattern "/projects/{owner}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a project
#
# DELETE /projects/{owner}/{projectId}
# operationId: deleteProjectV2
export def "projects delete" [
  owner: string
  project_id: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id)} | format pattern "/projects/{owner}/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project information
#
# GET /projects/{owner}/{projectId}
# operationId: getProjectV2
export def "projects get" [
  owner: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apis: list<string>, description: string, domains: list<string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id)} | format pattern "/projects/{owner}/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project
#
# PUT /projects/{owner}/{projectId}
# operationId: saveProjectV2
export def "projects update-save" [
  owner: any
  project_id: any
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id)} | format pattern "/projects/{owner}/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project members
#
# GET /projects/{owner}/{projectId}/members
# operationId: getProjectMembersV2
export def "projects-members get" [
  owner: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<members: table<name: string, roles: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id)} | format pattern "/projects/{owner}/{project_id}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a project's members list
#
# PUT /projects/{owner}/{projectId}/members
# operationId: updateProjectMembersV2
export def "projects-members update" [
  owner: any
  project_id: any
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id)} | format pattern "/projects/{owner}/{project_id}/members"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an API or domain to a project
#
# PUT /projects/{owner}/{projectId}/{specType}/{name}
# operationId: addSpecToProjectV2
export def "projects create-spec" [
  owner: string
  project_id: string
  spec_type: string
  name: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), project_id: (encode-path-segment $project_id), spec_type: (encode-path-segment $spec_type), name: (encode-path-segment $name)} | format pattern "/projects/{owner}/{project_id}/{spec_type}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of currently defined APIs, domains, and templates in APIs.json format
#
# GET /specs
# operationId: searchApisAndDomains
export def "specs list-and-domains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spec-type: string@spec-type-completer # Type of definitions to search: * API - APIs only * DOMAIN - domains only * TEMPLATE - templates only * ANY - APIs, domains, and templates (default: ANY)
  --visibility: string@visibility-completer # The visibility of a definition in SwaggerHub: * PUBLIC - can be viewed by anyone * PRIVATE - can only be viewed by you or your organization and those that you are collaborating with or have shared it with * ANY - either PUBLIC or PRIVATE (default: ANY)
  --state: string@state-completer # Matches against published state of the spec: * UNPUBLISHED - spec is a draft, a work in progress * PUBLISHED - spec is a stable version ready for consuming from client applications * ANY - either PUBLISHED or UNPUBLISHED (default: ALL)
  --owner: string # API or domain owner. Can be username or organization name. Case-sensitive.
  --query: string # Free text query to match
  --page: int # Page to return (format: int32, default: 0)
  --limit: int # Number of results per page (1 .. 100) (format: int32, default: 10)
  --qp-sort: string@sort-completer # Sort criteria of result set: * NAME * UPDATED * CREATED * OWNER * BEST_MATCH - by relevance * TITLE - by `info.title` (default: NAME)
  --order: string@order-completer # Sort order (default: ASC)
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "specType" $spec_type "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/specs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of templates for an owner
#
# GET /templates
# operationId: getTemplates
export def "templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --owner: string # Owner name
]: nothing -> record<builtIn: bool, defaultVersion: string, id: string, specification: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a template
#
# DELETE /templates/{owner}/{templateId}
# operationId: deleteTemplate
export def "templates delete-by-owner-templateId" [
  owner: string
  template_id: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id)} | format pattern "/templates/{owner}/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an APIs.json listing for all template versions for an owner and template
#
# GET /templates/{owner}/{templateId}
# operationId: getTemplateVersions
export def "templates get-versions" [
  owner: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apis: table<description: string, name: string, properties: list, tags: list>, description: string, name: string, offset: int, totalCount: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id)} | format pattern "/templates/{owner}/{template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a template
#
# POST /templates/{owner}/{templateId}
# operationId: saveTemplateDefinition
export def "templates create-save-definition" [
  owner: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # Defines whether the API or template has to be private (default: false)
  --version: string # Template version to create or update. If omitted, the version will be taken from the `info.version` field in the definition.
  --force: oneof<nothing, bool> # Force update
  --project-name: string # The project to add the API, domain, or template to
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPrivate" $is_private "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "force" $force "scalar") (serialize-qp "projectName" $project_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id)} | format pattern "/templates/{owner}/{template_id}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Rename a template
#
# POST /templates/{owner}/{templateId}/rename
# operationId: renameTemplate
export def "templates-rename rename" [
  owner: string
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-name: string # New name
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "newName" $new_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id)} | format pattern "/templates/{owner}/{template_id}/rename") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a particular version of a template
#
# DELETE /templates/{owner}/{templateId}/{version}
# operationId: deleteTemplateVersion
export def "templates delete-by-owner-templateId-version" [
  owner: string
  template_id: string
  version: string
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
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a template definition
#
# GET /templates/{owner}/{templateId}/{version}
# operationId: getTemplateDefinition
export def "templates get-definition" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # If set to `true`, it creates models from inline schemas in OpenAPI definition. AsyncAPI definitions cannot be flattened. (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the list of comments for a template
#
# GET /templates/{owner}/{templateId}/{version}/comments
# operationId: getTemplateComments
export def "templates-comments get" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: string, created: string, id: string, modified: string, user: record<active: bool, id: string>, position: int, replies: list<record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the list of comments for a template
#
# POST /templates/{owner}/{templateId}/{version}/comments/batch
# operationId: updateTemplateComments
# --addComment item shape: {body: string, position: int, replies?: list}
export def "templates-comments-batch update" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-comment: list # item shape: {body: string, position: int, replies?: list}
  --add-reply: record
  --delete-comment: list<string>
  --delete-reply: record
  --update-comment: record
  --update-reply: record
  --update-status: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/comments/batch"))
  let req_body = {"addComment": $add_comment, "addReply": $add_reply, "deleteComment": $delete_comment, "deleteReply": $delete_reply, "updateComment": $update_comment, "updateReply": $update_reply, "updateStatus": $update_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create a fork for a template
#
# POST /templates/{owner}/{templateId}/{version}/fork
# operationId: forkTemplate
export def "templates-fork create" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/creating-api.html). Can be the name of an existing definition, in which case the fork will become a new version in that definition, unless that version already exists. (e.g. api-fork)
  --body-owner: string # The account to fork into. Can be an organization or user name. Case-sensitive. The authenticated user must have permissions to create definitions in this account. (e.g. acme)
  --private: oneof<nothing, bool> # Whether the forked version should be public (`false`) or private (`true`). If the value is not set, the original version's setting will be used.
  --project: string # If forking into an organization, you can optionally specify an existing project to add the forked definition to.
  --body-version: string # Version identifier for the forked definition. Must follow the [naming rules](https://support.smartbear.com/swaggerhub/docs/apis/versioning.html#format). If forking into an existing definition, this version must not already exist. (e.g. 1.0.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/fork"))
  let req_body = {"name": $name, "owner": $body_owner, "private": $private, "project": $project, "version": $body_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve lifecycle settings for a template
#
# GET /templates/{owner}/{templateId}/{version}/settings/lifecycle
# operationId: getTemplateLifecycleSettings
export def "templates-settings-lifecycle get" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/settings/lifecycle"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update lifecycle settings for a template
#
# PUT /templates/{owner}/{templateId}/{version}/settings/lifecycle
# operationId: setTemplateLifecycleSettings
export def "templates-settings-lifecycle update" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force update
  --published: oneof<nothing, bool> # Whether the definition is published (`true`) or unpublished (`false`)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/settings/lifecycle") $qp)
  let req_body = {"published": $published} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve visibility settings for a template
#
# GET /templates/{owner}/{templateId}/{version}/settings/private
# operationId: getTemplatePrivateSettings
export def "templates-settings-private get" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/settings/private"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update visibility settings for a template
#
# PUT /templates/{owner}/{templateId}/{version}/settings/private
# operationId: setTemplatePrivateSettings
export def "templates-settings-private update" [
  owner: string
  template_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --private: oneof<nothing, bool> # Whether the definition version is private (`true`) or public (`false`)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({owner: (encode-path-segment $owner), template_id: (encode-path-segment $template_id), version: (encode-path-segment $version)} | format pattern "/templates/{owner}/{template_id}/{version}/settings/private"))
  let req_body = {"private": $private} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
