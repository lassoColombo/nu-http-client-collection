# Auto-generated client for Remote Settings PROD v1.22
# Source: https://api.apis.guru/v2/specs/mozilla.com/kinto/1.22/openapi.json
# Auth: --token flag or $env.REMOTE_SETTINGS_PROD_TOKEN

const BASE_URL = "https://firefox.settings.services.mozilla.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REMOTE_SETTINGS_PROD_TOKEN | default "" }
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

def base-url-completer [] { ["https://firefox.settings.services.mozilla.com/v1"] }
def auth-scheme-completer [] { ["none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "utilities get-server" } } | get name | first)
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

# GET /
#
# operationId: server_info
export def "utilities get-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /__api__
#
# operationId: get_openapi_spec
export def "api get-openapi-spec" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__api__")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /__heartbeat__
#
# operationId: __heartbeat__
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__heartbeat__")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /__lbheartbeat__
#
# operationId: __lbheartbeat__
export def "lbheartbeat get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__lbheartbeat__")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /__version__
#
# operationId: __version__
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/__version__")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /batch
#
# operationId: batch
# --defaults shape: {body?: record, headers?: record, method?: "GET"|"HEAD"|"DELETE"|"TRACE"|"POST"|"PUT"|"PATCH", path?: string}
# --requests item shape: {body?: record, headers?: record, method?: "GET"|"HEAD"|"DELETE"|"TRACE"|"POST"|"PUT"|"PATCH", path: string}
export def "batch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaults: record # shape: {body?: record, headers?: record, method?: "GET"|"HEAD"|"DELETE"|"TRACE"|"POST"|"PUT"|"PATCH", path?: string}
  requests: list # item shape: {body?: record, headers?: record, method?: "GET"|"HEAD"|"DELETE"|"TRACE"|"POST"|"PUT"|"PATCH", path: string}
]: any -> record<responses: table<body: record, headers: record, path: string, status: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/batch")
  let req_body = {"defaults": $defaults, "requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /buckets
#
# operationId: get_buckets
export def "buckets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --qp-sort: list<string>
  --qp-token: string
  --since: int
  --qp-to: int
  --before: int
  --id: string
  --last-modified: int
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: table<collection_schema: record, group_schema: record, record_schema: record>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_sort" $qp_sort "csv") (serialize-qp "_token" $qp_token "scalar") (serialize-qp "_since" $since "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "_before" $before "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "last_modified" $last_modified "scalar") (serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/buckets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_limit": $limit, "_sort": $qp_sort, "_token": $qp_token, "_since": $since, "_to": $qp_to, "_before": $before, "id": $id, "last_modified": $last_modified, "_fields": $fields} | compact), body: null}
}

# GET /buckets/monitor/collections/changes/records
#
# operationId: get_changess
export def "buckets-monitor-collections-changes-records get-changess" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --qp-sort: list<string>
  --qp-token: string
  --since: int
  --qp-to: int
  --before: int
  --id: string
  --last-modified: int
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: table<bucket: string, collection: string, host: string>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_sort" $qp_sort "csv") (serialize-qp "_token" $qp_token "scalar") (serialize-qp "_since" $since "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "_before" $before "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "last_modified" $last_modified "scalar") (serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/buckets/monitor/collections/changes/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_limit": $limit, "_sort": $qp_sort, "_token": $qp_token, "_since": $since, "_to": $qp_to, "_before": $before, "id": $id, "last_modified": $last_modified, "_fields": $fields} | compact), body: null}
}

# GET /buckets/{bid}/collections/{cid}/changeset
#
# operationId: get_collection-changeset
export def "buckets-collections-changeset get" [
  bid: string
  cid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string
  --expected: string
  --limit: int
  --bucket: string
  --collection: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bid | is-empty) { error make --unspanned { msg: "path parameter 'bid' must be non-empty" } }
  if ($cid | is-empty) { error make --unspanned { msg: "path parameter 'cid' must be non-empty" } }
  let qp = [(serialize-qp "_since" $since "scalar") (serialize-qp "_expected" $expected "scalar") (serialize-qp "_limit" $limit "scalar") (serialize-qp "bucket" $bucket "scalar") (serialize-qp "collection" $collection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bid: (encode-path-segment $bid), cid: (encode-path-segment $cid)} | format pattern "/buckets/{bid}/collections/{cid}/changeset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_since": $since, "_expected": $expected, "_limit": $limit, "bucket": $bucket, "collection": $collection} | compact), body: null}
}

# GET /buckets/{bucket_id}/collections
#
# operationId: get_collections
export def "buckets-collections list" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --qp-sort: list<string>
  --qp-token: string
  --since: int
  --qp-to: int
  --before: int
  --id: string
  --last-modified: int
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: table<cache_expires: int, schema: record>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_sort" $qp_sort "csv") (serialize-qp "_token" $qp_token "scalar") (serialize-qp "_since" $since "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "_before" $before "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "last_modified" $last_modified "scalar") (serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id)} | format pattern "/buckets/{bucket_id}/collections") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_limit": $limit, "_sort": $qp_sort, "_token": $qp_token, "_since": $since, "_to": $qp_to, "_before": $before, "id": $id, "last_modified": $last_modified, "_fields": $fields} | compact), body: null}
}

# GET /buckets/{bucket_id}/collections/{collection_id}/records
#
# operationId: get_records
export def "buckets-collections-records list" [
  bucket_id: string
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
  --limit: int
  --qp-sort: list<string>
  --qp-token: string
  --since: int
  --qp-to: int
  --before: int
  --id: string
  --last-modified: int
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_sort" $qp_sort "csv") (serialize-qp "_token" $qp_token "scalar") (serialize-qp "_since" $since "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "_before" $before "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "last_modified" $last_modified "scalar") (serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), collection_id: (encode-path-segment $collection_id)} | format pattern "/buckets/{bucket_id}/collections/{collection_id}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_limit": $limit, "_sort": $qp_sort, "_token": $qp_token, "_since": $since, "_to": $qp_to, "_before": $before, "id": $id, "last_modified": $last_modified, "_fields": $fields} | compact), body: null}
}

# GET /buckets/{bucket_id}/collections/{collection_id}/records/{id}
#
# operationId: get_record
export def "buckets-collections-records get" [
  bucket_id: string
  collection_id: string
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
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: record, permissions: record<read: list<string>, write: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), collection_id: (encode-path-segment $collection_id), id: (encode-path-segment $id)} | format pattern "/buckets/{bucket_id}/collections/{collection_id}/records/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_fields": $fields} | compact), body: null}
}

# DELETE /buckets/{bucket_id}/collections/{collection_id}/records/{id}/attachment
#
# operationId: delete_attachment
export def "buckets-collections-records-attachment delete" [
  bucket_id: string
  collection_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), collection_id: (encode-path-segment $collection_id), id: (encode-path-segment $id)} | format pattern "/buckets/{bucket_id}/collections/{collection_id}/records/{id}/attachment"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /buckets/{bucket_id}/collections/{collection_id}/records/{id}/attachment
#
# operationId: create_attachment
export def "buckets-collections-records-attachment create" [
  bucket_id: string
  collection_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), collection_id: (encode-path-segment $collection_id), id: (encode-path-segment $id)} | format pattern "/buckets/{bucket_id}/collections/{collection_id}/records/{id}/attachment"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /buckets/{bucket_id}/collections/{id}
#
# operationId: get_collection
export def "buckets-collections get" [
  bucket_id: string
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
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: record<cache_expires: int, schema: record>, permissions: record<read: list<string>, record_create: list<string>, write: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), id: (encode-path-segment $id)} | format pattern "/buckets/{bucket_id}/collections/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_fields": $fields} | compact), body: null}
}

# GET /buckets/{bucket_id}/groups
#
# operationId: get_groups
export def "buckets-groups list" [
  bucket_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int
  --qp-sort: list<string>
  --qp-token: string
  --since: int
  --qp-to: int
  --before: int
  --id: string
  --last-modified: int
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: table<members: list>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  let qp = [(serialize-qp "_limit" $limit "scalar") (serialize-qp "_sort" $qp_sort "csv") (serialize-qp "_token" $qp_token "scalar") (serialize-qp "_since" $since "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "_before" $before "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "last_modified" $last_modified "scalar") (serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id)} | format pattern "/buckets/{bucket_id}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_limit": $limit, "_sort": $qp_sort, "_token": $qp_token, "_since": $since, "_to": $qp_to, "_before": $before, "id": $id, "last_modified": $last_modified, "_fields": $fields} | compact), body: null}
}

# GET /buckets/{bucket_id}/groups/{id}
#
# operationId: get_group
export def "buckets-groups get" [
  bucket_id: string
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
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: record<members: list<string>>, permissions: record<read: list<string>, write: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($bucket_id | is-empty) { error make --unspanned { msg: "path parameter 'bucket_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({bucket_id: (encode-path-segment $bucket_id), id: (encode-path-segment $id)} | format pattern "/buckets/{bucket_id}/groups/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_fields": $fields} | compact), body: null}
}

# GET /buckets/{id}
#
# operationId: get_bucket
export def "buckets get" [
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
  --fields: list<string>
  --if-match: string
  --if-none-match: string
]: nothing -> record<data: record<collection_schema: record, group_schema: record, record_schema: record>, permissions: record<collection_create: list<string>, group_create: list<string>, read: list<string>, write: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "_fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/buckets/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_fields": $fields} | compact), body: null}
}

# GET /contribute.json
#
# operationId: contribute
export def "contribute-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contribute.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
