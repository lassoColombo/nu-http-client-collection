# Auto-generated client for Superset vv1
# Source: https://api.apis.guru/v2/specs/superset.apache.local/superset/v1/openapi.json
# Auth: --token flag or $env.SUPERSET_TOKEN

const BASE_URL = "http://superset.apache.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUPERSET_TOKEN | default "" }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["http://superset.apache.local" "http://localhost/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def datasource-type-completer [] { ["druid" "table" "view"] }
def accept-completer [] { ["application/json" "image/*"] }
def report-format-completer [] { ["CSV" "PNG" "TEXT"] }
def type-completer [] { ["Alert" "Report"] }
def validator-type-completer [] { ["not null" "operator"] }
def provider-completer [] { ["db" "ldap"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "annotation-layer delete" } } | get name | first)
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

# Deletes multiple annotation layers in a bulk operation.
#
# DELETE /annotation_layer/
export def "annotation-layer delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/annotation_layer/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of Annotation layers, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /annotation_layer/
export def "annotation-layer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, descr: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/annotation_layer/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create an Annotation layer
#
# POST /annotation_layer/
export def "annotation-layer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descr: string # Give a description for this annotation layer (nullable)
  --name: string # The annotation layer name
]: any -> record<id: float, result: record<descr: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/annotation_layer/")
  let req_body = {"descr": $descr, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /annotation_layer/_info
export def "annotation-layer-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/annotation_layer/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /annotation_layer/related/{column_name}
export def "annotation-layer-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/annotation_layer/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Delete Annotation layer
#
# DELETE /annotation_layer/{pk}
export def "annotation-layer delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an Annotation layer
#
# GET /annotation_layer/{pk}
export def "annotation-layer get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<descr: string, id: int, name: string>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Update an Annotation layer
#
# PUT /annotation_layer/{pk}
export def "annotation-layer update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descr: string # Give a description for this annotation layer
  --name: string # The annotation layer name
]: any -> record<id: float, result: record<descr: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}"))
  let req_body = {"descr": $descr, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes multiple annotation in a bulk operation.
#
# DELETE /annotation_layer/{pk}/annotation/
export def "annotation-layer-annotation delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}/annotation/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of Annotation layers, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /annotation_layer/{pk}/annotation/
export def "annotation-layer-annotation list" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, ids: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, end_dttm: string, id: int, long_descr: string, short_descr: string, start_dttm: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}/annotation/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create an Annotation layer
#
# POST /annotation_layer/{pk}/annotation/
export def "annotation-layer-annotation create" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-dttm: string # The annotation end date time (format: date-time)
  --json-metadata: string # JSON metadata (nullable)
  --long-descr: string # A long description (nullable)
  --short-descr: string # A short description
  --start-dttm: string # The annotation start date time (format: date-time)
]: any -> record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/annotation_layer/{pk}/annotation/"))
  let req_body = {"end_dttm": $end_dttm, "json_metadata": $json_metadata, "long_descr": $long_descr, "short_descr": $short_descr, "start_dttm": $start_dttm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete Annotation layer
#
# DELETE /annotation_layer/{pk}/annotation/{annotation_id}
export def "annotation-layer-annotation delete-by-pk-annotation-id" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotation_id' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/annotation_layer/{pk}/annotation/{annotation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an Annotation layer
#
# GET /annotation_layer/{pk}/annotation/{annotation_id}
export def "annotation-layer-annotation get" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<id: string, result: record<end_dttm: string, id: int, json_metadata: string, layer: record<id: int, name: string>, long_descr: string, short_descr: string, start_dttm: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotation_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/annotation_layer/{pk}/annotation/{annotation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Update an Annotation layer
#
# PUT /annotation_layer/{pk}/annotation/{annotation_id}
export def "annotation-layer-annotation update" [
  pk: int
  annotation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-dttm: string # The annotation end date time (format: date-time)
  --json-metadata: string # JSON metadata
  --long-descr: string # A long description
  --short-descr: string # A short description
  --start-dttm: string # The annotation start date time (format: date-time)
]: any -> record<id: float, result: record<end_dttm: string, json_metadata: string, long_descr: string, short_descr: string, start_dttm: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($annotation_id | is-empty) { error make --unspanned { msg: "path parameter 'annotation_id' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), annotation_id: (encode-path-segment $annotation_id)} | format pattern "/annotation_layer/{pk}/annotation/{annotation_id}"))
  let req_body = {"end_dttm": $end_dttm, "json_metadata": $json_metadata, "long_descr": $long_descr, "short_descr": $short_descr, "start_dttm": $start_dttm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reads off of the Redis events stream, using the user's JWT token and optional query params for last event received.
#
# GET /async_event/
export def "async-event get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-id: string # Last ID received by the client
]: nothing -> record<result: table<channel_id: string, errors: list, id: string, job_id: string, result_url: string, status: string, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "last_id" $last_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/async_event/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"last_id": $last_id} | compact), body: null}
}

# Takes a list of datasources, finds the associated cache records and invalidates them and removes the database records
#
# POST /cachekey/invalidate
# --datasources item shape: {database_name?: string, datasource_name?: string, datasource_type: "druid"|"table"|"view", schema?: string}
export def "cachekey-invalidate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource-uids: list<string> # The uid of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_uid`
  --datasources: list # A list of the data source and database names — item shape: {database_name?: string, datasource_name?: string, datasource_type: "druid"|"table"|"view", schema?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cachekey/invalidate")
  let req_body = {"datasource_uids": $datasource_uids, "datasources": $datasources} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes multiple Charts in a bulk operation.
#
# DELETE /chart/
export def "chart delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of charts, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /chart/
export def "chart list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<cache_timeout: int, changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, datasource_id: int, datasource_name_text: any, datasource_type: string, datasource_url: any, description: string, description_markeddown: any, edit_url: any, id: int, owners: record, params: string, slice_name: string, table: record, thumbnail_url: any, url: any, viz_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a new Chart.
#
# POST /chart/
export def "chart create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-timeout: int # Duration (in seconds) of the caching timeout for this chart. Note this defaults to the datasource/table timeout if undefined. (nullable, format: int32)
  --dashboards: list<int>
  datasource_id: int # The id of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_id` and `datasource_type`. (format: int32)
  --datasource-name: string # The datasource name. (nullable)
  datasource_type: string@datasource-type-completer # The type of dataset/datasource identified on `datasource_id`.
  --description: string # A description of the chart propose. (nullable)
  --owners: list<int>
  --params: string # Parameters are generated dynamically when clicking the save or overwrite button in the explore view. This JSON object for power users who may want to alter specific parameters. (nullable)
  --query-context: string # The query context represents the queries that need to run in order to generate the data the visualization, and in what format the data should be returned. (nullable)
  slice_name: string # The name of the chart.
  --viz-type: string # The type of chart visualization used. (e.g. [bar, line_multi, area, table])
]: any -> record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_name: string, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chart/")
  let req_body = {"cache_timeout": $cache_timeout, "dashboards": $dashboards, "datasource_id": $datasource_id, "datasource_name": $datasource_name, "datasource_type": $datasource_type, "description": $description, "owners": $owners, "params": $params, "query_context": $query_context, "slice_name": $slice_name, "viz_type": $viz_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Several metadata information about chart API endpoints.
#
# GET /chart/_info
export def "chart-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Takes a query context constructed in the client and returns payload data response for the given query.
#
# POST /chart/data
# --datasource shape: {id: int, type?: "druid"|"table"}
# --queries item shape: {annotation_layers?: list, applied_time_extras?: record, apply_fetch_values_predicate?: bool, columns?: list<string>, datasource?: any, druid_time_origin?: string, extras?: any, filters?: list, granularity?: string, granularity_sqla?: string, groupby?: list<string>, having?: string, having_filters?: list, is_rowcount?: bool, is_timeseries?: bool, metrics?: list, order_desc?: bool, orderby?: list, post_processing?: list, result_type?: any, row_limit?: int, row_offset?: int, ... (7 more fields)}
export def "chart-data create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: record # shape: {id: int, type?: "druid"|"table"}
  --force: oneof<nothing, bool> # Should the queries be forced to load from the source. Default: `false`
  --queries: list # item shape: {annotation_layers?: list, applied_time_extras?: record, apply_fetch_values_predicate?: bool, columns?: list<string>, datasource?: any, druid_time_origin?: string, extras?: any, filters?: list, granularity?: string, granularity_sqla?: string, groupby?: list<string>, having?: string, having_filters?: list, is_rowcount?: bool, is_timeseries?: bool, metrics?: list, order_desc?: bool, orderby?: list, post_processing?: list, result_type?: any, row_limit?: int, row_offset?: int, ... (7 more fields)}
  --result-format: any
  --result-type: any
]: any -> record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chart/data")
  let req_body = {"datasource": $datasource, "force": $force, "queries": $queries, "result_format": $result_format, "result_type": $result_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Takes a query context cache key and returns payload data response for the given query.
#
# GET /chart/data/{cache_key}
export def "chart-data get-by-cache-key" [
  cache_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($cache_key | is-empty) { error make --unspanned { msg: "path parameter 'cache_key' must be non-empty" } }
  let full_url = (build-url $base ({cache_key: (encode-path-segment $cache_key)} | format pattern "/chart/data/{cache_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Exports multiple charts and downloads them as YAML files
#
# GET /chart/export/
export def "chart-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart/export/" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Check favorited dashboards for current user
#
# GET /chart/favorite_status/
export def "chart-favorite-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<result: table<id: int, value: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart/favorite_status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /chart/import/
export def "chart-import create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/chart/import/")
  let req_body = {"formData": $form_data, "overwrite": $overwrite, "passwords": $passwords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["formData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get a list of all possible owners for a chart. Use `owners` has the `column_name` parameter
#
# GET /chart/related/{column_name}
export def "chart-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/chart/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Deletes a Chart.
#
# DELETE /chart/{pk}
export def "chart delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/chart/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a chart detail information.
#
# GET /chart/{pk}
export def "chart get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, dashboards: record<dashboard_title: string, id: int>, description: string, owners: record<first_name: string, id: int, last_name: string, username: string>, params: string, query_context: string, slice_name: string, viz_type: string>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/chart/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Changes a Chart.
#
# PUT /chart/{pk}
export def "chart update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-timeout: int # Duration (in seconds) of the caching timeout for this chart. Note this defaults to the datasource/table timeout if undefined. (nullable, format: int32)
  --dashboards: list<int>
  --datasource-id: int # The id of the dataset/datasource this new chart will use. A complete datasource identification needs `datasouce_id` and `datasource_type`. (nullable, format: int32)
  --datasource-type: string@datasource-type-completer # The type of dataset/datasource identified on `datasource_id`. (nullable)
  --description: string # A description of the chart propose. (nullable)
  --owners: list<int>
  --params: string # Parameters are generated dynamically when clicking the save or overwrite button in the explore view. This JSON object for power users who may want to alter specific parameters. (nullable)
  --query-context: string # The query context represents the queries that need to run in order to generate the data the visualization, and in what format the data should be returned. (nullable)
  --slice-name: string # The name of the chart. (nullable)
  --viz-type: string # The type of chart visualization used. (nullable, e.g. [bar, line_multi, area, table])
]: any -> record<id: float, result: record<cache_timeout: int, dashboards: list<int>, datasource_id: int, datasource_type: string, description: string, owners: list<int>, params: string, query_context: string, slice_name: string, viz_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/chart/{pk}"))
  let req_body = {"cache_timeout": $cache_timeout, "dashboards": $dashboards, "datasource_id": $datasource_id, "datasource_type": $datasource_type, "description": $description, "owners": $owners, "params": $params, "query_context": $query_context, "slice_name": $slice_name, "viz_type": $viz_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Compute and cache a screenshot.
#
# GET /chart/{pk}/cache_screenshot/
export def "chart-cache-screenshot get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<cache_key: string, chart_url: string, image_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/chart/{pk}/cache_screenshot/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Takes a chart ID and uses the query context stored when the chart was saved to return payload data response.
#
# GET /chart/{pk}/data/
export def "chart-data get-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The format in which the data should be returned
  --type: string # The type in which the data should be returned
]: nothing -> record<result: table<annotation_data: list, applied_filters: list, cache_key: string, cache_timeout: int, cached_dttm: string, data: list, error: string, is_cached: bool, query: string, rejected_filters: list, rowcount: int, stacktrace: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/chart/{pk}/data/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "type": $type} | compact), body: null}
}

# Get a computed screenshot from cache.
#
# GET /chart/{pk}/screenshot/{digest}/
export def "chart-screenshot get" [
  pk: int
  digest: string
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
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), digest: (encode-path-segment $digest)} | format pattern "/chart/{pk}/screenshot/{digest}/"))
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Compute or get already computed chart thumbnail from cache.
#
# GET /chart/{pk}/thumbnail/{digest}/
export def "chart-thumbnail get" [
  pk: int
  digest: string
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
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), digest: (encode-path-segment $digest)} | format pattern "/chart/{pk}/thumbnail/{digest}/"))
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes multiple css templates in a bulk operation.
#
# DELETE /css_template/
export def "css-template delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/css_template/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of CSS templates, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /css_template/
export def "css-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_on_delta_humanized: any, created_by: record, created_on: string, css: string, id: int, template_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/css_template/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a CSS template
#
# POST /css_template/
export def "css-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # nullable
  --template-name: string # nullable
]: any -> record<id: string, result: record<css: string, template_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/css_template/")
  let req_body = {"css": $css, "template_name": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /css_template/_info
export def "css-template-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/css_template/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /css_template/related/{column_name}
export def "css-template-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/css_template/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Delete CSS template
#
# DELETE /css_template/{pk}
export def "css-template delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/css_template/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a CSS template
#
# GET /css_template/{pk}
export def "css-template get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, css: string, id: int, template_name: string>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/css_template/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Update a CSS template
#
# PUT /css_template/{pk}
export def "css-template update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # nullable
  --template-name: string # nullable
]: any -> record<result: record<css: string, template_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/css_template/{pk}"))
  let req_body = {"css": $css, "template_name": $template_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes multiple Dashboards in a bulk operation.
#
# DELETE /dashboard/
export def "dashboard delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of dashboards, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /dashboard/
export def "dashboard list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, created_by: record, css: string, dashboard_title: string, id: int, json_metadata: string, owners: record, position_json: string, published: bool, roles: record, slug: string, status: any, thumbnail_url: any, url: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a new Dashboard.
#
# POST /dashboard/
export def "dashboard create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string
  --dashboard-title: string # A title for the dashboard. (nullable)
  --json-metadata: string # This JSON object is generated dynamically when clicking the save or overwrite button in the dashboard view. It is exposed here for reference and for power users who may want to alter specific parameters.
  --owners: list<int>
  --position-json: string # This json object describes the positioning of the widgets in the dashboard. It is dynamically generated when adjusting the widgets size and positions by using drag & drop in the dashboard view
  --published: oneof<nothing, bool> # Determines whether or not this dashboard is visible in the list of all dashboards.
  --roles: list<int>
  --slug: string # Unique identifying part for the web address of the dashboard. (nullable)
]: any -> record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard/")
  let req_body = {"css": $css, "dashboard_title": $dashboard_title, "json_metadata": $json_metadata, "owners": $owners, "position_json": $position_json, "published": $published, "roles": $roles, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Several metadata information about dashboard API endpoints.
#
# GET /dashboard/_info
export def "dashboard-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Exports multiple Dashboards and downloads them as YAML files.
#
# GET /dashboard/export/
export def "dashboard-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/export/" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Check favorited dashboards for current user
#
# GET /dashboard/favorite_status/
export def "dashboard-favorite-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<result: table<id: int, value: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dashboard/favorite_status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /dashboard/import/
export def "dashboard-import create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP or JSON) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard/import/")
  let req_body = {"formData": $form_data, "overwrite": $overwrite, "passwords": $passwords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["formData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get a list of all possible owners for a dashboard.
#
# GET /dashboard/related/{column_name}
export def "dashboard-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/dashboard/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a dashboard detail information.
#
# GET /dashboard/{id_or_slug}
export def "dashboard get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: record<changed_by: record<first_name: string, id: int, last_name: string, username: string>, changed_by_name: string, changed_by_url: string, changed_on: string, changed_on_delta_humanized: string, charts: list<string>, css: string, dashboard_title: string, id: int, json_metadata: string, owners: list<record>, position_json: string, published: bool, roles: list<record>, slug: string, table_names: string, thumbnail_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({id_or_slug: (encode-path-segment $id_or_slug)} | format pattern "/dashboard/{id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the chart definitions for a given dashboard
#
# GET /dashboard/{id_or_slug}/charts
export def "dashboard-charts get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<cache_timeout: int, changed_on: string, datasource: string, description: string, description_markeddown: string, form_data: record, modified: string, slice_id: int, slice_name: string, slice_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({id_or_slug: (encode-path-segment $id_or_slug)} | format pattern "/dashboard/{id_or_slug}/charts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of a dashboard's datasets. Each dataset includes only the information necessary to render the dashboard's charts.
#
# GET /dashboard/{id_or_slug}/datasets
export def "dashboard-datasets get" [
  id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<cache_timeout: int, column_formats: record, column_types: list, columns: list, database: record, datasource_name: string, default_endpoint: string, edit_url: string, fetch_values_predicate: string, filter_select: bool, filter_select_enabled: bool, granularity_sqla: list, health_check_message: string, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: list, name: string, offset: int, order_by_choices: list, owners: list, params: string, perm: string, schema: string, select_star: string, sql: string, table_name: string, template_params: string, time_grain_sqla: list, type: string, uid: string, verbose_map: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({id_or_slug: (encode-path-segment $id_or_slug)} | format pattern "/dashboard/{id_or_slug}/datasets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes a Dashboard.
#
# DELETE /dashboard/{pk}
export def "dashboard delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dashboard/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Changes a Dashboard.
#
# PUT /dashboard/{pk}
export def "dashboard update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --css: string # Override CSS for the dashboard. (nullable)
  --dashboard-title: string # A title for the dashboard. (nullable)
  --json-metadata: string # This JSON object is generated dynamically when clicking the save or overwrite button in the dashboard view. It is exposed here for reference and for power users who may want to alter specific parameters. (nullable)
  --owners: list<int>
  --position-json: string # This json object describes the positioning of the widgets in the dashboard. It is dynamically generated when adjusting the widgets size and positions by using drag & drop in the dashboard view (nullable)
  --published: oneof<nothing, bool> # Determines whether or not this dashboard is visible in the list of all dashboards. (nullable)
  --roles: list<int>
  --slug: string # Unique identifying part for the web address of the dashboard. (nullable)
]: any -> record<id: float, result: record<css: string, dashboard_title: string, json_metadata: string, owners: list<int>, position_json: string, published: bool, roles: list<int>, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dashboard/{pk}"))
  let req_body = {"css": $css, "dashboard_title": $dashboard_title, "json_metadata": $json_metadata, "owners": $owners, "position_json": $position_json, "published": $published, "roles": $roles, "slug": $slug} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Compute async or get already computed dashboard thumbnail from cache.
#
# GET /dashboard/{pk}/thumbnail/{digest}/
export def "dashboard-thumbnail get" [
  pk: int
  digest: string
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
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($digest | is-empty) { error make --unspanned { msg: "path parameter 'digest' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), digest: (encode-path-segment $digest)} | format pattern "/dashboard/{pk}/thumbnail/{digest}/") $qp)
  let accept_val = ($accept | default "image/*")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of models
#
# GET /database/
export def "database list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, allows_cost_estimate: any, allows_subquery: any, allows_virtual_table_explore: any, backend: any, changed_on: string, changed_on_delta_humanized: any, created_by: record, database_name: string, explore_database_id: any, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/database/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a new Database.
#
# POST /database/
export def "database create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-csv-upload: oneof<nothing, bool> # Allow to upload CSV file data into this databaseIf selected, please set the schemas allowed for csv upload in Extra.
  --allow-ctas: oneof<nothing, bool> # Allow CREATE TABLE AS option in SQL Lab
  --allow-cvas: oneof<nothing, bool> # Allow CREATE VIEW AS option in SQL Lab
  --allow-dml: oneof<nothing, bool> # Allow users to run non-SELECT statements (UPDATE, DELETE, CREATE, ...) in SQL Lab
  --allow-multi-schema-metadata-fetch: oneof<nothing, bool> # Allow SQL Lab to fetch a list of all tables and all views across all database schemas. For large data warehouse with thousands of tables, this can be expensive and put strain on the system.
  --allow-run-async: oneof<nothing, bool> # Operate the database in asynchronous mode, meaning that the queries are executed on remote workers as opposed to on the web server itself. This assumes that you have a Celery worker setup as well as a results backend. Refer to the installation docs for more information.
  --cache-timeout: int # Duration (in seconds) of the caching timeout for charts of this database. A timeout of 0 indicates that the cache never expires. Note this defaults to the global timeout if undefined. (nullable, format: int32)
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  database_name: string # A database name to identify this connection.
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --expose-in-sqllab: oneof<nothing, bool> # Expose this database to SQLLab
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --force-ctas-schema: string # When allowing CREATE TABLE AS option in SQL Lab, this option forces the table to be created in this schema (nullable)
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/")
  let req_body = {"allow_csv_upload": $allow_csv_upload, "allow_ctas": $allow_ctas, "allow_cvas": $allow_cvas, "allow_dml": $allow_dml, "allow_multi_schema_metadata_fetch": $allow_multi_schema_metadata_fetch, "allow_run_async": $allow_run_async, "cache_timeout": $cache_timeout, "configuration_method": $configuration_method, "database_name": $database_name, "encrypted_extra": $encrypted_extra, "engine": $engine, "expose_in_sqllab": $expose_in_sqllab, "extra": $extra, "force_ctas_schema": $force_ctas_schema, "impersonate_user": $impersonate_user, "parameters": $parameters, "server_cert": $server_cert, "sqlalchemy_uri": $sqlalchemy_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /database/_info
export def "database-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/database/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get names of databases currently available
#
# GET /database/available/
export def "database-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<available_drivers: list<string>, default_driver: string, engine: string, name: string, parameters: record, preferred: bool, sqlalchemy_uri_placeholder: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/available/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download database(s) and associated dataset(s) as a zip file
#
# GET /database/export/
export def "database-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/database/export/" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /database/import/
export def "database-import create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing databases?
  --passwords: string # JSON map of passwords for each file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/import/")
  let req_body = {"formData": $form_data, "overwrite": $overwrite, "passwords": $passwords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["formData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Tests a database connection
#
# POST /database/test_connection
export def "database-test-connection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/test_connection")
  let req_body = {"configuration_method": $configuration_method, "database_name": $database_name, "encrypted_extra": $encrypted_extra, "engine": $engine, "extra": $extra, "impersonate_user": $impersonate_user, "parameters": $parameters, "server_cert": $server_cert, "sqlalchemy_uri": $sqlalchemy_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Validates parameters used to connect to a database
#
# POST /database/validate_parameters
export def "database-validate-parameters create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  configuration_method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri.
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  engine: string # SQLAlchemy engine to use
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/validate_parameters")
  let req_body = {"configuration_method": $configuration_method, "database_name": $database_name, "encrypted_extra": $encrypted_extra, "engine": $engine, "extra": $extra, "impersonate_user": $impersonate_user, "parameters": $parameters, "server_cert": $server_cert} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Database.
#
# DELETE /database/{pk}
export def "database delete" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an item model
#
# GET /database/{pk}
export def "database get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, backend: any, cache_timeout: int, configuration_method: string, database_name: string, encrypted_extra: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, id: int, impersonate_user: bool, parameters: any, server_cert: string, sqlalchemy_uri: string>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Changes a Database.
#
# PUT /database/{pk}
export def "database update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-csv-upload: oneof<nothing, bool> # Allow to upload CSV file data into this databaseIf selected, please set the schemas allowed for csv upload in Extra.
  --allow-ctas: oneof<nothing, bool> # Allow CREATE TABLE AS option in SQL Lab
  --allow-cvas: oneof<nothing, bool> # Allow CREATE VIEW AS option in SQL Lab
  --allow-dml: oneof<nothing, bool> # Allow users to run non-SELECT statements (UPDATE, DELETE, CREATE, ...) in SQL Lab
  --allow-multi-schema-metadata-fetch: oneof<nothing, bool> # Allow SQL Lab to fetch a list of all tables and all views across all database schemas. For large data warehouse with thousands of tables, this can be expensive and put strain on the system.
  --allow-run-async: oneof<nothing, bool> # Operate the database in asynchronous mode, meaning that the queries are executed on remote workers as opposed to on the web server itself. This assumes that you have a Celery worker setup as well as a results backend. Refer to the installation docs for more information.
  --cache-timeout: int # Duration (in seconds) of the caching timeout for charts of this database. A timeout of 0 indicates that the cache never expires. Note this defaults to the global timeout if undefined. (nullable, format: int32)
  --configuration-method: any # Configuration_method is used on the frontend to inform the backend whether to explode parameters or to provide only a sqlalchemy_uri. (default: sqlalchemy_form)
  --database-name: string # A database name to identify this connection. (nullable)
  --encrypted-extra: string # JSON string containing additional connection configuration.This is used to provide connection information for systems like Hive, Presto, and BigQuery, which do not conform to the username:password syntax normally used by SQLAlchemy. (nullable)
  --engine: string # SQLAlchemy engine to use (nullable)
  --expose-in-sqllab: oneof<nothing, bool> # Expose this database to SQLLab
  --extra: string # JSON string containing extra configuration elements.1. The engine_params object gets unpacked into the sqlalchemy.create_engine (https://docs.sqlalchemy.org/en/latest/core/engines.html#sqlalchemy.create_engine) call, while the metadata_params gets unpacked into the sqlalchemy.MetaData (https://docs.sqlalchemy.org/en/rel_1_0/core/metadata.html#sqlalchemy.schema.MetaData) call.2. The metadata_cache_timeout is a cache timeout setting in seconds for metadata fetch of this database. Specify it as "metadata_cache_timeout": {"schema_cache_timeout": 600, "table_cache_timeout": 600}. If unset, cache will not be enabled for the functionality. A timeout of 0 indicates that the cache never expires.3. The schemas_allowed_for_csv_upload is a comma separated list of schemas that CSVs are allowed to upload to. Specify it as "schemas_allowed_for_csv_upload": ["public", "csv_upload"]. If database flavor does not support schema or any schema is allowed to be accessed, just leave the list empty4. the version field is a string specifying the this db's version. This should be used with Presto DBs so that the syntax is correct5. The allows_virtual_table_explore field is a boolean specifying whether or not the Explore button in SQL Lab results is shown.
  --force-ctas-schema: string # When allowing CREATE TABLE AS option in SQL Lab, this option forces the table to be created in this schema (nullable)
  --impersonate-user: oneof<nothing, bool> # If Presto, all the queries in SQL Lab are going to be executed as the currently logged on user who must have permission to run them.If Hive and hive.server2.enable.doAs is enabled, will run the queries as service account, but impersonate the currently logged on user via hive.server2.proxy.user property.
  --parameters: record # DB-specific parameters for configuration
  --server-cert: string # Optional CA_BUNDLE contents to validate HTTPS requests. Only available on certain database engines. (nullable)
  --sqlalchemy-uri: string # Refer to the SqlAlchemy docs (https://docs.sqlalchemy.org/en/rel_1_2/core/engines.html#database-urls) for more information on how to structure your URI.
]: any -> record<id: float, result: record<allow_csv_upload: bool, allow_ctas: bool, allow_cvas: bool, allow_dml: bool, allow_multi_schema_metadata_fetch: bool, allow_run_async: bool, cache_timeout: int, configuration_method: any, database_name: string, encrypted_extra: string, engine: string, expose_in_sqllab: bool, extra: string, force_ctas_schema: string, impersonate_user: bool, parameters: record, server_cert: string, sqlalchemy_uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}"))
  let req_body = {"allow_csv_upload": $allow_csv_upload, "allow_ctas": $allow_ctas, "allow_cvas": $allow_cvas, "allow_dml": $allow_dml, "allow_multi_schema_metadata_fetch": $allow_multi_schema_metadata_fetch, "allow_run_async": $allow_run_async, "cache_timeout": $cache_timeout, "configuration_method": $configuration_method, "database_name": $database_name, "encrypted_extra": $encrypted_extra, "engine": $engine, "expose_in_sqllab": $expose_in_sqllab, "extra": $extra, "force_ctas_schema": $force_ctas_schema, "impersonate_user": $impersonate_user, "parameters": $parameters, "server_cert": $server_cert, "sqlalchemy_uri": $sqlalchemy_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get function names supported by a database
#
# GET /database/{pk}/function_names/
export def "database-function-names get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<function_names: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}/function_names/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get charts and dashboards count associated to a database
#
# GET /database/{pk}/related_objects/
export def "database-related-objects get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}/related_objects/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all schemas from a database
#
# GET /database/{pk}/schemas/
export def "database-schemas get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<result: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/database/{pk}/schemas/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get database select star for table
#
# GET /database/{pk}/select_star/{table_name}/
export def "database-select-star list" [
  pk: int
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --schema-name: string # Table schema
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'table_name' must be non-empty" } }
  let qp = [(serialize-qp "schema_name" $schema_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), table_name: (encode-path-segment $table_name)} | format pattern "/database/{pk}/select_star/{table_name}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"schema_name": $schema_name} | compact), body: null}
}

# Get database select star for table
#
# GET /database/{pk}/select_star/{table_name}/{schema_name}/
export def "database-select-star get" [
  pk: int
  table_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'table_name' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schema_name' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), table_name: (encode-path-segment $table_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/database/{pk}/select_star/{table_name}/{schema_name}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get database table metadata
#
# GET /database/{pk}/table/{table_name}/{schema_name}/
export def "database-table get" [
  pk: int
  table_name: string
  schema_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<columns: table<duplicates_constraint: string, keys: list, longType: string, name: string, type: string>, foreignKeys: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, indexes: table<column_names: list, name: string, options: record, referred_columns: list, referred_schema: string, referred_table: string, type: string>, name: string, primaryKey: record<column_names: list<string>, name: string, type: string>, selectStar: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'table_name' must be non-empty" } }
  if ($schema_name | is-empty) { error make --unspanned { msg: "path parameter 'schema_name' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), table_name: (encode-path-segment $table_name), schema_name: (encode-path-segment $schema_name)} | format pattern "/database/{pk}/table/{table_name}/{schema_name}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes multiple Datasets in a bulk operation.
#
# DELETE /dataset/
export def "dataset delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of models
#
# GET /dataset/
export def "dataset list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_by: record, changed_by_name: any, changed_by_url: any, changed_on_delta_humanized: any, changed_on_utc: any, database: record, default_endpoint: string, explore_url: any, extra: string, id: int, kind: any, owners: record, schema: string, sql: string, table_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a new Dataset
#
# POST /dataset/
export def "dataset create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  database: int # format: int32
  --owners: list<int>
  --schema: string
  table_name: string
]: any -> record<id: float, result: record<database: int, owners: list<int>, schema: string, table_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataset/")
  let req_body = {"database": $database, "owners": $owners, "schema": $schema, "table_name": $table_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /dataset/_info
export def "dataset-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /dataset/distinct/{column_name}
export def "dataset-distinct get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/dataset/distinct/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Exports multiple datasets and downloads them as YAML files
#
# GET /dataset/export/
export def "dataset-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/export/" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /dataset/import/
export def "dataset-import create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP or YAML) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing datasets?
  --passwords: string # JSON map of passwords for each file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataset/import/")
  let req_body = {"formData": $form_data, "overwrite": $overwrite, "passwords": $passwords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["formData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# GET /dataset/related/{column_name}
export def "dataset-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/dataset/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Deletes a Dataset
#
# DELETE /dataset/{pk}
export def "dataset delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dataset/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an item model
#
# GET /dataset/{pk}
export def "dataset get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<cache_timeout: int, columns: record<changed_on: string, column_name: string, created_on: string, description: string, expression: string, filterable: bool, groupby: bool, id: int, is_active: bool, is_dttm: bool, python_date_format: string, type: string, type_generic: any, uuid: string, verbose_name: string>, database: record<database_name: string, id: int>, datasource_type: any, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, id: int, is_sqllab_view: bool, main_dttm_col: string, metrics: record<changed_on: string, created_on: string, d3format: string, description: string, expression: string, extra: string, id: int, metric_name: string, metric_type: string, uuid: string, verbose_name: string, warning_text: string>, offset: int, owners: record<first_name: string, id: int, last_name: string, username: string>, schema: string, sql: string, table_name: string, template_params: string, url: any>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dataset/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Changes a Dataset
#
# PUT /dataset/{pk}
# --columns item shape: {column_name: string, description?: string, expression?: string, filterable?: bool, groupby?: bool, id?: int, is_active?: bool, is_dttm?: bool, python_date_format?: string, type?: string, uuid?: string, verbose_name?: string}
# --metrics item shape: {d3format?: string, description?: string, expression: string, id?: int, metric_name: string, metric_type?: string, warning_text?: string}
export def "dataset update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --override-columns: oneof<nothing, bool>
  --cache-timeout: int # nullable, format: int32
  --columns: list # item shape: {column_name: string, description?: string, expression?: string, filterable?: bool, groupby?: bool, id?: int, is_active?: bool, is_dttm?: bool, python_date_format?: string, type?: string, uuid?: string, verbose_name?: string}
  --database-id: int # format: int32
  --default-endpoint: string # nullable
  --description: string # nullable
  --extra: string # nullable
  --fetch-values-predicate: string # nullable
  --filter-select-enabled: oneof<nothing, bool> # nullable
  --is-sqllab-view: oneof<nothing, bool> # nullable
  --main-dttm-col: string # nullable
  --metrics: list # item shape: {d3format?: string, description?: string, expression: string, id?: int, metric_name: string, metric_type?: string, warning_text?: string}
  --offset: int # nullable, format: int32
  --owners: list<int>
  --schema: string # nullable
  --sql: string # nullable
  --table-name: string # nullable
  --template-params: string # nullable
]: any -> record<id: float, result: record<cache_timeout: int, columns: list<record>, database_id: int, default_endpoint: string, description: string, extra: string, fetch_values_predicate: string, filter_select_enabled: bool, is_sqllab_view: bool, main_dttm_col: string, metrics: list<record>, offset: int, owners: list<int>, schema: string, sql: string, table_name: string, template_params: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "override_columns" $override_columns "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dataset/{pk}") $qp)
  let req_body = {"cache_timeout": $cache_timeout, "columns": $columns, "database_id": $database_id, "default_endpoint": $default_endpoint, "description": $description, "extra": $extra, "fetch_values_predicate": $fetch_values_predicate, "filter_select_enabled": $filter_select_enabled, "is_sqllab_view": $is_sqllab_view, "main_dttm_col": $main_dttm_col, "metrics": $metrics, "offset": $offset, "owners": $owners, "schema": $schema, "sql": $sql, "table_name": $table_name, "template_params": $template_params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"override_columns": $override_columns} | compact), body: $req_body}
}

# Delete a Dataset column
#
# DELETE /dataset/{pk}/column/{column_id}
export def "dataset-column delete" [
  pk: int
  column_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($column_id | is-empty) { error make --unspanned { msg: "path parameter 'column_id' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), column_id: (encode-path-segment $column_id)} | format pattern "/dataset/{pk}/column/{column_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a Dataset metric
#
# DELETE /dataset/{pk}/metric/{metric_id}
export def "dataset-metric delete" [
  pk: int
  metric_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($metric_id | is-empty) { error make --unspanned { msg: "path parameter 'metric_id' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), metric_id: (encode-path-segment $metric_id)} | format pattern "/dataset/{pk}/metric/{metric_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refreshes and updates columns of a dataset
#
# PUT /dataset/{pk}/refresh
export def "dataset-refresh update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dataset/{pk}/refresh"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get charts and dashboards count associated to a dataset
#
# GET /dataset/{pk}/related_objects
export def "dataset-related-objects get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<charts: record<count: int, result: list<record>>, dashboards: record<count: int, result: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/dataset/{pk}/related_objects"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of models
#
# GET /log/
export def "log list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record, user_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/log/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /log/
export def "log create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # format: int32
]: any -> record<id: string, result: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log/")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get an item model
#
# GET /log/{pk}
export def "log get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<action: string, dashboard_id: int, dttm: string, duration_ms: int, json: string, referrer: string, slice_id: int, user: record<username: string>, user_id: int>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/log/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get the menu data structure. Returns a forest like structure with the menu the user has access to
#
# GET /menu/
export def "menu get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: table<childs: list, icon: string, label: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/menu/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the OpenAPI spec for a specific API version
#
# GET /openapi/{version}/_openapi
export def "openapi-openapi get" [
  version: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/openapi/{version}/_openapi"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of queries, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /query/
export def "query list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on: string, database: record, end_time: float, executed_sql: string, id: int, rows: int, schema: string, sql: string, sql_tables: any, start_time: float, status: string, tab_name: string, tmp_table_name: string, tracking_url: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /query/distinct/{column_name}
export def "query-distinct get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/query/distinct/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /query/related/{column_name}
export def "query-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/query/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get query detail information.
#
# GET /query/{pk}
export def "query get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<changed_on: string, client_id: string, database: record<id: int>, end_result_backend_time: float, end_time: float, error_message: string, executed_sql: string, id: int, limit: int, progress: int, results_key: string, rows: int, schema: string, select_as_cta: bool, select_as_cta_used: bool, select_sql: string, sql: string, sql_editor_id: string, start_running_time: float, start_time: float, status: string, tab_name: string, tmp_schema_name: string, tmp_table_name: string, tracking_url: string>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/query/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Deletes multiple report schedules in a bulk operation.
#
# DELETE /report/
export def "report delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of report schedules, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /report/
export def "report list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<active: bool, changed_by: record, changed_on: string, changed_on_delta_humanized: any, created_by: record, created_on: string, creation_method: string, crontab: string, crontab_humanized: any, description: string, id: int, last_eval_dttm: string, last_state: string, name: string, owners: record, recipients: record, timezone: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a report schedule
#
# POST /report/
# --recipients item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
# --validator_config_json shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
export def "report create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --chart: int # nullable, format: int32
  --context-markdown: string # Markdown description (nullable)
  --creation-method: any # Creation method is used to inform the frontend whether the report/alert was created in the dashboard, chart, or alerts and reports UI.
  crontab: string # A CRON expression.[Crontab Guru](https://crontab.guru/) is a helpful resource that can help you craft a CRON expression. (e.g. */5 * * * *)
  --dashboard: int # nullable, format: int32
  --database: int # format: int32
  --description: string # Use a nice description to give context to this Alert/Report (nullable, e.g. Daily sales dashboard to marketing)
  --grace-period: int # Once an alert is triggered, how long, in seconds, before Superset nags you again. (in seconds) (format: int32, e.g. 14400)
  --log-retention: int # How long to keep the logs around for this report (in days) (format: int32, e.g. 90)
  name: string # The report schedule name. (e.g. Daily dashboard email)
  --owners: list<int>
  --recipients: list # item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
  --report-format: string@report-format-completer
  --sql: string # A SQL statement that defines whether the alert should get triggered or not. The query is expected to return either NULL or a number value. (e.g. SELECT value FROM time_series_table)
  --timezone: string # A timezone string that represents the location of the timezone.
  type: string@type-completer # The report schedule type
  --validator-config-json: record # shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
  --validator-type: string@validator-type-completer # Determines when to trigger alert based off value from alert query. Alerts will be triggered with these validator types: - Not Null - When the return value is Not NULL, Empty, or 0 - Operator - When `sql_return_value comparison_operator threshold` is True e.g. `50 <= 75`Supports the comparison operators <, <=, >, >=, ==, and !=
  --working-timeout: int # If an alert is staled at a working state, how long until it's state is reseted to error (format: int32, e.g. 3600)
]: any -> record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/report/")
  let req_body = {"active": $active, "chart": $chart, "context_markdown": $context_markdown, "creation_method": $creation_method, "crontab": $crontab, "dashboard": $dashboard, "database": $database, "description": $description, "grace_period": $grace_period, "log_retention": $log_retention, "name": $name, "owners": $owners, "recipients": $recipients, "report_format": $report_format, "sql": $sql, "timezone": $timezone, "type": $type, "validator_config_json": $validator_config_json, "validator_type": $validator_type, "working_timeout": $working_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /report/_info
export def "report-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/report/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /report/related/{column_name}
export def "report-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/report/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Delete a report schedule
#
# DELETE /report/{pk}
export def "report delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/report/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a report schedule
#
# GET /report/{pk}
export def "report get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<active: bool, chart: record<id: int, slice_name: string, viz_type: string>, context_markdown: string, creation_method: string, crontab: string, dashboard: record<dashboard_title: string, id: int>, database: record<database_name: string, id: int>, description: string, grace_period: int, id: int, last_eval_dttm: string, last_state: string, last_value: float, last_value_row_json: string, log_retention: int, name: string, owners: record<first_name: string, id: int, last_name: string>, recipients: record<id: int, recipient_config_json: string, type: string>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: string, validator_type: string, working_timeout: int>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/report/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Update a report schedule
#
# PUT /report/{pk}
# --recipients item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
# --validator_config_json shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
export def "report update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --chart: int # nullable, format: int32
  --context-markdown: string # Markdown description (nullable)
  --creation-method: any # Creation method is used to inform the frontend whether the report/alert was created in the dashboard, chart, or alerts and reports UI. (nullable)
  --crontab: string # A CRON expression.[Crontab Guru](https://crontab.guru/) is a helpful resource that can help you craft a CRON expression.
  --dashboard: int # nullable, format: int32
  --database: int # format: int32
  --description: string # Use a nice description to give context to this Alert/Report (nullable, e.g. Daily sales dashboard to marketing)
  --grace-period: int # Once an alert is triggered, how long, in seconds, before Superset nags you again. (in seconds) (format: int32, e.g. 14400)
  --log-retention: int # How long to keep the logs around for this report (in days) (format: int32, e.g. 90)
  --name: string # The report schedule name.
  --owners: list<int>
  --recipients: list # item shape: {recipient_config_json?: record, type: "Email"|"Slack"}
  --report-format: string@report-format-completer
  --sql: string # A SQL statement that defines whether the alert should get triggered or not. The query is expected to return either NULL or a number value. (nullable, e.g. SELECT value FROM time_series_table)
  --timezone: string # A timezone string that represents the location of the timezone.
  --type: string@type-completer # The report schedule type
  --validator-config-json: record # shape: {op?: "<"|"<="|">"|">="|"=="|"!=", threshold?: int}
  --validator-type: string@validator-type-completer # Determines when to trigger alert based off value from alert query. Alerts will be triggered with these validator types: - Not Null - When the return value is Not NULL, Empty, or 0 - Operator - When `sql_return_value comparison_operator threshold` is True e.g. `50 <= 75`Supports the comparison operators <, <=, >, >=, ==, and != (nullable)
  --working-timeout: int # If an alert is staled at a working state, how long until it's state is reseted to error (nullable, format: int32, e.g. 3600)
]: any -> record<id: float, result: record<active: bool, chart: int, context_markdown: string, creation_method: any, crontab: string, dashboard: int, database: int, description: string, grace_period: int, log_retention: int, name: string, owners: list<int>, recipients: list<record>, report_format: string, sql: string, timezone: string, type: string, validator_config_json: record<op: string, threshold: int>, validator_type: string, working_timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/report/{pk}"))
  let req_body = {"active": $active, "chart": $chart, "context_markdown": $context_markdown, "creation_method": $creation_method, "crontab": $crontab, "dashboard": $dashboard, "database": $database, "description": $description, "grace_period": $grace_period, "log_retention": $log_retention, "name": $name, "owners": $owners, "recipients": $recipients, "report_format": $report_format, "sql": $sql, "timezone": $timezone, "type": $type, "validator_config_json": $validator_config_json, "validator_type": $validator_type, "working_timeout": $working_timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of report schedule logs, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /report/{pk}/log/
export def "report-log list" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, ids: list<string>, result: table<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/report/{pk}/log/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a report schedule log
#
# GET /report/{pk}/log/{log_id}
export def "report-log get" [
  pk: int
  log_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<id: string, result: record<end_dttm: string, error_message: string, id: int, scheduled_dttm: string, start_dttm: string, state: string, uuid: string, value: float, value_row_json: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  if ($log_id | is-empty) { error make --unspanned { msg: "path parameter 'log_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk), log_id: (encode-path-segment $log_id)} | format pattern "/report/{pk}/log/{log_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Deletes multiple saved queries in a bulk operation.
#
# DELETE /saved_query/
export def "saved-query delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_query/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Get a list of saved queries, use Rison or JSON query parameters for filtering, sorting, pagination and for selecting specific columns and metadata.
#
# GET /saved_query/
export def "saved-query list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: float, description_columns: record<column_name: string>, ids: list<string>, label_columns: record<column_name: string>, list_columns: list<string>, list_title: string, order_columns: list<string>, result: table<changed_on_delta_humanized: any, created_by: record, created_on: string, database: record, db_id: int, description: string, extra: any, id: int, label: string, last_run_delta_humanized: any, rows: int, schema: string, sql: string, sql_tables: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_query/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Create a saved query
#
# POST /saved_query/
export def "saved-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-id: int # nullable, format: int32
  --description: string # nullable
  --label: string # nullable
  --schema: string # nullable
  --sql: string # nullable
]: any -> record<id: string, result: record<db_id: int, description: string, label: string, schema: string, sql: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_query/")
  let req_body = {"db_id": $db_id, "description": $description, "label": $label, "schema": $schema, "sql": $sql} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get metadata information about this API resource
#
# GET /saved_query/_info
export def "saved-query-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<add_columns: record, edit_columns: record, filters: record<column_name: list<record>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_query/_info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# GET /saved_query/distinct/{column_name}
export def "saved-query-distinct get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/saved_query/distinct/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Exports multiple saved queries and downloads them as YAML files
#
# GET /saved_query/export/
export def "saved-query-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/saved_query/export/" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# POST /saved_query/import/
export def "saved-query-import create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-data: string # upload file (ZIP) (format: binary)
  --overwrite: oneof<nothing, bool> # overwrite existing saved queries?
  --passwords: string # JSON map of passwords for each file
]: any -> record<message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/saved_query/import/")
  let req_body = {"formData": $form_data, "overwrite": $overwrite, "passwords": $passwords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["formData"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# GET /saved_query/related/{column_name}
export def "saved-query-related get" [
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<count: int, result: table<text: string, value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'column_name' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({column_name: (encode-path-segment $column_name)} | format pattern "/saved_query/related/{column_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Delete saved query
#
# DELETE /saved_query/{pk}
export def "saved-query delete-by-pk" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/saved_query/{pk}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a saved query
#
# GET /saved_query/{pk}
export def "saved-query get" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
]: nothing -> record<description_columns: record<column_name: string>, id: string, label_columns: record<column_name: string>, result: record<created_by: record<first_name: string, id: int, last_name: string>, database: record<database_name: string, id: int>, description: string, id: int, label: string, schema: string, sql: string, sql_tables: any>, show_columns: list<string>, show_title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/saved_query/{pk}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Update a saved query
#
# PUT /saved_query/{pk}
export def "saved-query update" [
  pk: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-id: int # nullable, format: int32
  --description: string # nullable
  --label: string # nullable
  --schema: string # nullable
  --sql: string # nullable
]: any -> record<result: record<db_id: int, description: string, label: string, schema: string, sql: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($pk | is-empty) { error make --unspanned { msg: "path parameter 'pk' must be non-empty" } }
  let full_url = (build-url $base ({pk: (encode-path-segment $pk)} | format pattern "/saved_query/{pk}"))
  let req_body = {"db_id": $db_id, "description": $description, "label": $label, "schema": $schema, "sql": $sql} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch the CSRF token
#
# GET /security/csrf_token/
export def "security-csrf-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<result: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/csrf_token/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Authenticate and get a JWT access and refresh token
#
# POST /security/login
export def "security-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password for authentication (e.g. complex-password)
  --provider: string@provider-completer # Choose an authentication provider (e.g. db)
  --refresh: oneof<nothing, bool> # If true a refresh token is provided also (e.g. true)
  --username: string # The username for authentication (e.g. admin)
]: any -> record<access_token: string, refresh_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/login")
  let req_body = {"password": $password, "provider": $provider, "refresh": $refresh, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Use the refresh token to get a new JWT access token
#
# POST /security/refresh
export def "security-refresh create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/security/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
