# Auto-generated client for Postman API v1.20.0
# Source: https://api.apis.guru/v2/specs/getpostman.com/1.20.0/openapi.json
# Auth: --token flag or $env.POSTMAN_API_TOKEN

const BASE_URL = "https://api.getpostman.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POSTMAN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.getpostman.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apis get-list-ap-is" } } | get name | first)
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

# Get all APIs
#
# GET /apis
# operationId: getAllApIs
export def "apis get-list-ap-is" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # Only return APIs that are inside the given workspace. (e.g. {{workspaceId}})
  --since: string # Only return APIs that have been updated after this time. Time is represented using the ISO 8601 date and time format. (e.g. {{since}})
  --until: string # Only return APIs that have been updated before this time. Time is represented using the ISO 8601 date and time format. (e.g. {{until}})
  --created-by: string # Only return APIs that have been created by the user ID represented by the given value. (e.g. {{createdBy}})
  --updated-by: string # Only return APIs that have been updated by the user ID represented by the given value. (e.g. {{updatedBy}})
  --is-public: string # Only return APIs with the corresponding privacy state. Public APIs have the isPublic value true; private APIs have the isPublic value false. (e.g. {{isPublic}})
  --name: string # Only return APIs whose name includes the given value. Matching is case insensitive. (e.g. {{name}})
  --summary: string # Only return APIs whose summary includes the given value. Matching is case insensitive. (e.g. {{summary}})
  --description: string # Only return APIs whose description includes the given value. Matching is case insensitive. (e.g. {{description}})
  --qp-sort: string # The value of sort can be one of the names of the fields included in the response. (e.g. {{sort}})
  --direction: string # The sorting direction, which can be ascending or descending. The value can be asc to specify an ascending direction or desc to specify a descending direction. If none is specified, the default sorting direction is descending for timestamp and numeric fields and ascending otherwise. An ID is not considered a numeric field. (e.g. {{direction}})
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "createdBy" $created_by "scalar") (serialize-qp "updatedBy" $updated_by "scalar") (serialize-qp "isPublic" $is_public "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "summary" $summary "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"workspace": $workspace, "since": $since, "until": $until, "createdBy": $created_by, "updatedBy": $updated_by, "isPublic": $is_public, "name": $name, "summary": $summary, "description": $description, "sort": $qp_sort, "direction": $direction} | compact), body: null}
}

# Create API
#
# POST /apis
# operationId: createApi
# --api shape: {description?: string, name?: string, summary?: string}
export def "apis create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # e.g. {{workspaceId}}
  --api: record # shape: {description?: string, name?: string, summary?: string}
]: any -> record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apis" $qp)
  let req_body = {"api": $api} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"workspace": $workspace} | compact), body: $req_body}
}

# Delete an API
#
# DELETE /apis/{apiId}
# operationId: deleteAnApi
export def "apis delete" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single API
#
# GET /apis/{apiId}
# operationId: singleApi
export def "apis get-single" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/apis/{api_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an API
#
# PUT /apis/{apiId}
# operationId: updateAnApi
# --api shape: {description?: string, name?: string}
export def "apis update" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api: record # shape: {description?: string, name?: string}
]: any -> record<api: record<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/apis/{api_id}"))
  let req_body = {"api": $api} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get All API Versions
#
# GET /apis/{apiId}/versions
# operationId: getAllApiVersions
export def "apis-versions get-list" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<versions: table<createdAt: string, createdBy: string, description: string, id: string, name: string, summary: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/apis/{api_id}/versions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create API Version
#
# POST /apis/{apiId}/versions
# operationId: createApiVersion
# --version shape: {name?: string, source?: record}
export def "apis-versions create" [
  api_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: record # shape: {name?: string, source?: record}
]: any -> record<version: record<api: string, id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id)} | format pattern "/apis/{api_id}/versions"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an API Version
#
# DELETE /apis/{apiId}/versions/{apiVersionId}
# operationId: deleteAnApiVersion
export def "apis-versions delete" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an API Version
#
# GET /apis/{apiId}/versions/{apiVersionId}
# operationId: getAnApiVersion
export def "apis-versions get" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, schema: list<string>, updatedAt: string, updatedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an API Version
#
# PUT /apis/{apiId}/versions/{apiVersionId}
# operationId: updateAnApiVersion
# --version shape: {name?: string}
export def "apis-versions update" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: record # shape: {name?: string}
]: any -> record<version: record<api: string, createdAt: string, createdBy: string, id: string, name: string, updatedAt: string, updatedBy: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}"))
  let req_body = {"version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get contract test relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/contracttest
# operationId: getContractTestRelations
export def "apis-versions-contracttest get-contract-test-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contracttest: table<collectionId: string, id: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/contracttest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get documentation relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/documentation
# operationId: getDocumentationRelations
export def "apis-versions-documentation get-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<documentation: table<collectionId: string, id: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/documentation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get environment relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/environment
# operationId: getEnvironmentRelations
export def "apis-versions-environment get-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environment: table<id: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/environment"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get integration test relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/integrationtest
# operationId: getIntegrationTestRelations
export def "apis-versions-integrationtest get-integration-test-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<integrationtest: table<collectionId: string, id: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/integrationtest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get monitor relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/monitor
# operationId: getMonitorRelations
export def "apis-versions-monitor get-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<monitor: table<id: string, monitorId: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/monitor"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get linked relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/relations
# operationId: getLinkedRelations
export def "apis-versions-relations get-linked" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<relations: record<contracttest: record<2a9b8fa8_88b7_4b86_8372_8e3f6f6e07f2: record>, integrationtest: record<521b0486_ab91_4d3a_9189_43c9380a0533: record, a236b715_e682_460b_97b6_c1db24f7612e: record>, mock: record<4ccd755f_2c80_481b_a262_49b55e12f5e1: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/relations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create relations
#
# POST /apis/{apiId}/versions/{apiVersionId}/relations
# operationId: createRelations
export def "apis-versions-relations create" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contracttest: list<string>
  --documentation: list<string>
  --mock: list<string>
  --testsuite: list<string>
]: any -> record<contracttest: list<string>, documentation: list<string>, testsuite: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/relations"))
  let req_body = {"contracttest": $contracttest, "documentation": $documentation, "mock": $mock, "testsuite": $testsuite} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Schema
#
# POST /apis/{apiId}/versions/{apiVersionId}/schemas
# operationId: createSchema
# --schema shape: {language?: string, schema?: string, type?: string}
export def "apis-versions-schemas create" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: record # shape: {language?: string, schema?: string, type?: string}
]: any -> record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/schemas"))
  let req_body = {"schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Schema
#
# GET /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}
# operationId: getSchema
export def "apis-versions-schemas get" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  if ($schema_id | is-empty) { error make --unspanned { msg: "path parameter 'schemaId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id), schema_id: (encode-path-segment $schema_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/schemas/{schema_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Schema
#
# PUT /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}
# operationId: updateSchema
# --schema shape: {language?: string, schema?: string, type?: string}
export def "apis-versions-schemas update" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema: record # shape: {language?: string, schema?: string, type?: string}
]: any -> record<schema: record<apiVersion: string, createdAt: string, createdBy: string, id: string, language: string, type: string, updateBy: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  if ($schema_id | is-empty) { error make --unspanned { msg: "path parameter 'schemaId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id), schema_id: (encode-path-segment $schema_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/schemas/{schema_id}"))
  let req_body = {"schema": $schema} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create collection from schema
#
# POST /apis/{apiId}/versions/{apiVersionId}/schemas/{schemaId}/collections
# operationId: createCollectionFromSchema
# --relations item shape: {type?: string}
export def "apis-versions-schemas-collections create" [
  api_id: string
  api_version_id: string
  schema_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # e.g. {{workspaceId}}
  --name: string # e.g. My generated collection
  --relations: list # item shape: {type?: string}
]: any -> record<collection: record<id: string, uid: string>, relations: table<id: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  if ($schema_id | is-empty) { error make --unspanned { msg: "path parameter 'schemaId' must be non-empty" } }
  let qp = [(serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id), schema_id: (encode-path-segment $schema_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/schemas/{schema_id}/collections") $qp)
  let req_body = {"name": $name, "relations": $relations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"workspace": $workspace} | compact), body: $req_body}
}

# Get test suite relations
#
# GET /apis/{apiId}/versions/{apiVersionId}/testsuite
# operationId: getTestSuiteRelations
export def "apis-versions-testsuite get-test-suite-relations" [
  api_id: string
  api_version_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<testsuite: table<collectionId: string, id: string, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/testsuite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sync relations with schema
#
# PUT /apis/{apiId}/versions/{apiVersionId}/{entityType}/{entityId}/syncWithSchema
# operationId: syncRelationsWithSchema
export def "apis-versions-sync-with-schema sync-relations" [
  api_id: string
  api_version_id: string
  entity_type: string
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($api_id | is-empty) { error make --unspanned { msg: "path parameter 'apiId' must be non-empty" } }
  if ($api_version_id | is-empty) { error make --unspanned { msg: "path parameter 'apiVersionId' must be non-empty" } }
  if ($entity_type | is-empty) { error make --unspanned { msg: "path parameter 'entityType' must be non-empty" } }
  if ($entity_id | is-empty) { error make --unspanned { msg: "path parameter 'entityId' must be non-empty" } }
  let full_url = (build-url $base ({api_id: (encode-path-segment $api_id), api_version_id: (encode-path-segment $api_version_id), entity_type: (encode-path-segment $entity_type), entity_id: (encode-path-segment $entity_id)} | format pattern "/apis/{api_id}/versions/{api_version_id}/{entity_type}/{entity_id}/syncWithSchema"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# All Collections
#
# GET /collections
# operationId: allCollections
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
]: nothing -> record<collections: table<id: string, name: string, owner: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Collection
#
# POST /collections
# operationId: createCollection
# --collection shape: {info?: record, item?: list}
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
  --collection: record # shape: {info?: record, item?: list}
]: any -> record<collection: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let req_body = {"collection": $collection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a Fork
#
# POST /collections/fork/{collection_uid}
# operationId: createAFork
export def "collections-fork create" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # Workspace ID is required to create a fork (e.g. {{workspace_id}})
  --name: string # e.g. Fork name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_uid | is-empty) { error make --unspanned { msg: "path parameter 'collection_uid' must be non-empty" } }
  let qp = [(serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_uid: (encode-path-segment $collection_uid)} | format pattern "/collections/fork/{collection_uid}") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"workspace": $workspace} | compact), body: $req_body}
}

# Merge a Fork
#
# POST /collections/merge
# operationId: mergeAFork
export def "collections-merge create-fork" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --destination: string # e.g. {{destination_collection_uid}}
  --body-source: string # e.g. {{source_collection_uid}}
  --strategy: string # e.g. deleteSource
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections/merge")
  let req_body = {"destination": $destination, "source": $body_source, "strategy": $strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Collection
#
# DELETE /collections/{collection_uid}
# operationId: deleteCollection
export def "collections delete" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<collection: record<id: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_uid | is-empty) { error make --unspanned { msg: "path parameter 'collection_uid' must be non-empty" } }
  let full_url = (build-url $base ({collection_uid: (encode-path-segment $collection_uid)} | format pattern "/collections/{collection_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single Collection
#
# GET /collections/{collection_uid}
# operationId: singleCollection
export def "collections get-single" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<collection: record<info: record<_postman_id: string, description: string, name: string, schema: string>, item: list<record>, variables: list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_uid | is-empty) { error make --unspanned { msg: "path parameter 'collection_uid' must be non-empty" } }
  let full_url = (build-url $base ({collection_uid: (encode-path-segment $collection_uid)} | format pattern "/collections/{collection_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Collection
#
# PUT /collections/{collection_uid}
# operationId: updateCollection
# --collection shape: {info?: record, item?: list}
export def "collections update" [
  collection_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --collection: record # shape: {info?: record, item?: list}
]: any -> record<collection: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_uid | is-empty) { error make --unspanned { msg: "path parameter 'collection_uid' must be non-empty" } }
  let full_url = (build-url $base ({collection_uid: (encode-path-segment $collection_uid)} | format pattern "/collections/{collection_uid}"))
  let req_body = {"collection": $collection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# All Environments
#
# GET /environments
# operationId: allEnvironments
export def "environments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environments: table<id: string, name: string, owner: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Environment
#
# POST /environments
# operationId: createEnvironment
# --environment shape: {name?: string, values?: list}
export def "environments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: record # shape: {name?: string, values?: list}
]: any -> record<environment: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let req_body = {"environment": $environment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Environment
#
# DELETE /environments/{environment_uid}
# operationId: deleteEnvironment
export def "environments delete" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environment: record<id: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_uid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uid' must be non-empty" } }
  let full_url = (build-url $base ({environment_uid: (encode-path-segment $environment_uid)} | format pattern "/environments/{environment_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single Environment
#
# GET /environments/{environment_uid}
# operationId: singleEnvironment
export def "environments get-single" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<environment: record<id: string, name: string, values: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_uid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uid' must be non-empty" } }
  let full_url = (build-url $base ({environment_uid: (encode-path-segment $environment_uid)} | format pattern "/environments/{environment_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Environment
#
# PUT /environments/{environment_uid}
# operationId: updateEnvironment
# --environment shape: {name?: string, values?: list}
export def "environments update" [
  environment_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment: record # shape: {name?: string, values?: list}
]: any -> record<environment: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($environment_uid | is-empty) { error make --unspanned { msg: "path parameter 'environment_uid' must be non-empty" } }
  let full_url = (build-url $base ({environment_uid: (encode-path-segment $environment_uid)} | format pattern "/environments/{environment_uid}"))
  let req_body = {"environment": $environment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Import exported data
#
# POST /import/exported
# operationId: importExportedData
export def "import-exported import-data" [
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
]: any -> record<collections: table<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/import/exported")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: {}, body: $req_body}
}

# Import external API specification
#
# POST /import/openapi
# operationId: importExternalApiSpecification
# --input shape: {info?: record, openapi?: string, paths?: record, servers?: list}
export def "import-openapi import-external-specification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --input: record # shape: {info?: record, openapi?: string, paths?: record, servers?: list}
  --type: string # e.g. json
]: any -> record<collections: table<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/import/openapi")
  let req_body = {"input": $input, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# API Key Owner
#
# GET /me
# operationId: apiKeyOwner
export def "me get-key-owner" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<operations: table<limit: float, name: string, overage: float, usage: float>, user: record<avatar: string, email: string, fullName: string, id: string, isPublic: bool, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# All Mocks
#
# GET /mocks
# operationId: allMocks
export def "mocks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mocks: table<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mocks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Mock
#
# POST /mocks
# operationId: createMock
# --mock shape: {collection?: string, environment?: string}
export def "mocks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mock: record # shape: {collection?: string, environment?: string}
]: any -> record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/mocks")
  let req_body = {"mock": $mock} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Mock
#
# DELETE /mocks/{mock_uid}
# operationId: deleteMock
export def "mocks delete" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mock: record<id: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mock_uid | is-empty) { error make --unspanned { msg: "path parameter 'mock_uid' must be non-empty" } }
  let full_url = (build-url $base ({mock_uid: (encode-path-segment $mock_uid)} | format pattern "/mocks/{mock_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single Mock
#
# GET /mocks/{mock_uid}
# operationId: singleMock
export def "mocks get-single" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mock: record<collection: string, environment: string, id: string, mockUrl: string, owner: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mock_uid | is-empty) { error make --unspanned { msg: "path parameter 'mock_uid' must be non-empty" } }
  let full_url = (build-url $base ({mock_uid: (encode-path-segment $mock_uid)} | format pattern "/mocks/{mock_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Mock
#
# PUT /mocks/{mock_uid}
# operationId: updateMock
# --mock shape: {description?: string, environment?: string, name?: string, private?: bool, versionTag?: string}
export def "mocks update" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mock: record # shape: {description?: string, environment?: string, name?: string, private?: bool, versionTag?: string}
]: any -> record<mock: record<collection: string, config: record<headers: list, matchBody: bool, matchQueryParams: bool, matchWildcards: bool>, environment: string, id: string, mockUrl: string, name: string, owner: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mock_uid | is-empty) { error make --unspanned { msg: "path parameter 'mock_uid' must be non-empty" } }
  let full_url = (build-url $base ({mock_uid: (encode-path-segment $mock_uid)} | format pattern "/mocks/{mock_uid}"))
  let req_body = {"mock": $mock} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Publish Mock
#
# POST /mocks/{mock_uid}/publish
# operationId: publishMock
export def "mocks-publish publish" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mock: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mock_uid | is-empty) { error make --unspanned { msg: "path parameter 'mock_uid' must be non-empty" } }
  let full_url = (build-url $base ({mock_uid: (encode-path-segment $mock_uid)} | format pattern "/mocks/{mock_uid}/publish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unpublish Mock
#
# DELETE /mocks/{mock_uid}/unpublish
# operationId: unpublishMock
export def "mocks-unpublish delete" [
  mock_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mock: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mock_uid | is-empty) { error make --unspanned { msg: "path parameter 'mock_uid' must be non-empty" } }
  let full_url = (build-url $base ({mock_uid: (encode-path-segment $mock_uid)} | format pattern "/mocks/{mock_uid}/unpublish"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# All Monitors
#
# GET /monitors
# operationId: allMonitors
export def "monitors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<monitors: table<id: string, name: string, owner: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Monitor
#
# POST /monitors
# operationId: createMonitor
# --monitor shape: {collection?: string, environment?: string, name?: string, schedule?: record}
export def "monitors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor: record # shape: {collection?: string, environment?: string, name?: string, schedule?: record}
]: any -> record<monitor: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/monitors")
  let req_body = {"monitor": $monitor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Monitor
#
# DELETE /monitors/{monitor_uid}
# operationId: deleteMonitor
export def "monitors delete" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<monitor: record<id: string, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($monitor_uid | is-empty) { error make --unspanned { msg: "path parameter 'monitor_uid' must be non-empty" } }
  let full_url = (build-url $base ({monitor_uid: (encode-path-segment $monitor_uid)} | format pattern "/monitors/{monitor_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single Monitor
#
# GET /monitors/{monitor_uid}
# operationId: singleMonitor
export def "monitors get-single" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<monitor: record<collectionUid: string, distribution: list<any>, environmentUid: string, id: string, lastRun: record<finishedAt: string, startedAt: string, stats: record, status: string>, name: string, notifications: record<onError: list, onFailure: list>, options: record<followRedirects: bool, requestDelay: float, requestTimeout: float, strictSSL: bool>, owner: string, schedule: record<cron: string, nextRun: string, timezone: string>, uid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($monitor_uid | is-empty) { error make --unspanned { msg: "path parameter 'monitor_uid' must be non-empty" } }
  let full_url = (build-url $base ({monitor_uid: (encode-path-segment $monitor_uid)} | format pattern "/monitors/{monitor_uid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Monitor
#
# PUT /monitors/{monitor_uid}
# operationId: updateMonitor
# --monitor shape: {name?: string, schedule?: record}
export def "monitors update" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --monitor: record # shape: {name?: string, schedule?: record}
]: any -> record<monitor: record<id: string, name: string, uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($monitor_uid | is-empty) { error make --unspanned { msg: "path parameter 'monitor_uid' must be non-empty" } }
  let full_url = (build-url $base ({monitor_uid: (encode-path-segment $monitor_uid)} | format pattern "/monitors/{monitor_uid}"))
  let req_body = {"monitor": $monitor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run a Monitor
#
# POST /monitors/{monitor_uid}/run
# operationId: runAMonitor
export def "monitors-run create" [
  monitor_uid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<run: record<executions: list<record>, failures: list<record>, info: record<collectionUid: string, finishedAt: string, jobId: string, monitorId: string, name: string, startedAt: string, status: string>, stats: record<assertions: record, requests: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($monitor_uid | is-empty) { error make --unspanned { msg: "path parameter 'monitor_uid' must be non-empty" } }
  let full_url = (build-url $base ({monitor_uid: (encode-path-segment $monitor_uid)} | format pattern "/monitors/{monitor_uid}/run"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Webhook
#
# POST /webhooks
# operationId: createWebhook
# --webhook shape: {collection?: string, name?: string}
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: string # e.g. {{workspace_id}}
  --webhook: record # shape: {collection?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workspace" $workspace "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let req_body = {"webhook": $webhook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"workspace": $workspace} | compact), body: $req_body}
}

# All workspaces
#
# GET /workspaces
# operationId: allWorkspaces
export def "workspaces list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workspaces: table<id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workspaces")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Workspace
#
# POST /workspaces
# operationId: createWorkspace
# --workspace shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string, type?: string}
export def "workspaces create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: record # shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string, type?: string}
]: any -> record<workspace: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/workspaces")
  let req_body = {"workspace": $workspace} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Workspace
#
# DELETE /workspaces/{workspace_id}
# operationId: deleteWorkspace
export def "workspaces delete" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workspace: record<id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_id | is-empty) { error make --unspanned { msg: "path parameter 'workspace_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_id: (encode-path-segment $workspace_id)} | format pattern "/workspaces/{workspace_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Single workspace
#
# GET /workspaces/{workspace_id}
# operationId: singleWorkspace
export def "workspaces get-single" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<workspace: record<collections: list<record>, description: string, environments: list<record>, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_id | is-empty) { error make --unspanned { msg: "path parameter 'workspace_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_id: (encode-path-segment $workspace_id)} | format pattern "/workspaces/{workspace_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Workspace
#
# PUT /workspaces/{workspace_id}
# operationId: updateWorkspace
# --workspace shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string}
export def "workspaces update" [
  workspace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --workspace: record # shape: {collections?: list, description?: string, environments?: list, mocks?: list, monitors?: list, name?: string}
]: any -> record<workspace: record<id: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($workspace_id | is-empty) { error make --unspanned { msg: "path parameter 'workspace_id' must be non-empty" } }
  let full_url = (build-url $base ({workspace_id: (encode-path-segment $workspace_id)} | format pattern "/workspaces/{workspace_id}"))
  let req_body = {"workspace": $workspace} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
