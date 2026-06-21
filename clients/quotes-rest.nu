# Auto-generated client for They Said So Quotes API v3.1
# Source: https://api.apis.guru/v2/specs/quotes.rest/3.1/openapi.json
# Auth: --token flag or $env.THEY_SAID_SO_QUOTES_API_TOKEN

const BASE_URL = "https://quotes.rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THEY_SAID_SO_QUOTES_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-theysaidso-api-secret" => { {scheme: $scheme, headers: {X-TheySaidSo-Api-Secret: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://quotes.rest" "http://quotes.rest" "http://api01.quotes.rest"] }
def auth-scheme-completer [] { ["x-theysaidso-api-secret"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "qod get" } } | get name | first)
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

# Gets `Quote of the Day`. Optional `category` param determines the category of returned quote of the day
#
# GET /qod
export def "qod get" [
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
  --category: string # QOD Category (format: string)
  --language: string # Language of the QOD. The language must be supported in our QOD system. (format: string, default: en)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qod" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "language": $language} | compact), body: null}
}

# Gets a list of `Quote of the Day` Categories.
#
# GET /qod/categories
export def "qod-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language of the QOD category. The language must be supported in our QOD system. (format: string, default: en)
  --detailed: oneof<nothing, bool> # Return detailed information of the categories. Note the data format changes between the two values of this switch. (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qod/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"language": $language, "detailed": $detailed} | compact), body: null}
}

# Gets a list of supported languages for `Quote of the Day`.
#
# GET /qod/languages
export def "qod-languages get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/qod/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a qshow.
#
# DELETE /qshow
export def "qshow delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Gets a details about a qshow.
#
# GET /qshow
export def "qshow get" [
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
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Update an existing qshow.
#
# PATCH /qshow
export def "qshow update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --title: string # Qshow title (format: string)
  --description: string # Qshow description (format: string)
  --tags: list<string> # Tags for the qshow
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "title": $title, "description": $description, "tags": $tags} | compact), body: null}
}

# Create and add a new qshow to your private collection.
#
# PUT /qshow
export def "qshow update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # Qshow title (format: string)
  --description: string # Qshow description (format: string)
  --tags: list<string> # Tags for the qshow
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"title": $title, "description": $description, "tags": $tags} | compact), body: null}
}

# Get the list of Qshows in They Said So platform.
#
# GET /qshow/list
export def "qshow-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --public: oneof<nothing, bool> # Should include public qshows or not in the list (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "public" $public "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "public": $public} | compact), body: null}
}

# Get the quotes in a given Qshow.
#
# GET /qshow/quotes
export def "qshow-quotes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Add a quote to a given Qshow.
#
# POST /qshow/quotes/add
export def "qshow-quotes-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --quoteid: string # Quote ID to add the qshow collection (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quoteid" $quoteid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "quoteid": $quoteid} | compact), body: null}
}

# Remove a quote to a given Qshow.
#
# POST /qshow/quotes/remove
export def "qshow-quotes-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Qshow ID (format: string)
  --quoteid: string # Quote ID to remove from the qshow collection (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quoteid" $quoteid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/qshow/quotes/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "quoteid": $quoteid} | compact), body: null}
}

# Delete a quote. The user needs to be the owner of the quote to be able to delete it.
#
# DELETE /quote
export def "quote delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Gets a `Quote` with a given `id`.
#
# GET /quote
export def "quote get" [
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
  --id: string # Quote ID (format: string)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Update a quote
#
# PATCH /quote
export def "quote update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
  --tags: string # Comma Separated tags
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "quote": $quote, "author": $author, "language": $language, "tags": $tags} | compact), body: null}
}

# Add a new quote to your private collection. Same as 'PUT' but added since some clients don't handle PUT well.
#
# POST /quote
export def "quote create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --tags: string # Comma Separated tags (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote": $quote, "author": $author, "tags": $tags, "language": $language} | compact), body: null}
}

# Add a new quote to your private collection.
#
# PUT /quote
export def "quote update-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote: string # Quote (format: string)
  --author: string # Quote Author (format: string)
  --tags: string # Comma Separated tags (format: string)
  --language: string # Language. If not supplied an auto detection mechanism will be used to detect a language. (format: string, default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote" $quote "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote": $quote, "author": $author, "tags": $tags, "language": $language} | compact), body: null}
}

# Gets a list of popular author names in the system.
#
# GET /quote/authors/popular
export def "quote-authors-popular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language. A same author may have quotes in two or more different languages. So for example 'Mahatma Gandhi' may be returned for language "en"(English), and "மஹாத்மா காந்தி" may be returned when the language is "ta" (Tamil). (format: string, default: en)
  --detailed: oneof<nothing, bool> # Should return detailed author information such as `birthday`, `death date`, `occupation`, `description` etc. Only available at certain subscription levels. (format: boolean, default: false)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/authors/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"language": $language, "detailed": $detailed, "start": $start, "limit": $limit} | compact), body: null}
}

# Gets a list of author names in the system.
#
# GET /quote/authors/search
export def "quote-authors-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text string to search for in author names (format: string)
  --language: string # Language. A same author may have quotes in two or more different languages. So for example 'Mahatma Gandhi' may be returned for language "en"(English), and "மஹாத்மா காந்தி" may be returned when the language is "ta" (Tamil). (format: string, default: en)
  --detailed: oneof<nothing, bool> # Should return detailed author information such as `birthday`, `death date`, `occupation`, `description` etc. Only available at certain subscription levels. (format: boolean, default: false)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "detailed" $detailed "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/authors/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "language": $language, "detailed": $detailed, "start": $start, "limit": $limit} | compact), body: null}
}

# Gets a list of popular `Quote` Categories.
#
# GET /quote/categories/popular
export def "quote-categories-popular get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/categories/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "limit": $limit} | compact), body: null}
}

# Gets a list of `Quote` Categories matching the query string.
#
# GET /quote/categories/search
export def "quote-categories-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Text string to search for in the categories (format: string, default: 0)
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. The maximum depends on the subscription level. (format: int32, default: 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/categories/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "start": $start, "limit": $limit} | compact), body: null}
}

# Remove the disLike for the given Quote as a user of the API Key.
#
# DELETE /quote/dislike
export def "quote-dislike delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Dislike the given Quote as a user of the API Key. Same as `put` but a convenient alias for those clients that don't support `put` cleanly.
#
# POST /quote/dislike
export def "quote-dislike create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Dislike the given Quote as a user of the API Key. Some clients don't cleanly support `PUT`, in such scenarios use the `POST` version of this.
#
# PUT /quote/dislike
export def "quote-dislike update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/dislike" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Delete a quote image. The user needs to be the owner of the quote image to be able to delete it.
#
# DELETE /quote/image
export def "quote-image delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote Image ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Gets a Quote image for a given id. Response can be an image file as a binary or a base64 encoded contents wrapped in json. `TODO`
#
# GET /quote/image
export def "quote-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote Image id (format: string)
  --binary: oneof<nothing, bool> # Should the response be a direct file download of the image or a base64 encoded image file wrapped in json? (format: boolean, default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "binary" $binary "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "binary": $binary} | compact), body: null}
}

# Create a new quote image for a given quote. Choose background colors/images , choose different font styles and generate a beautiful quote image. Did you just had a feeling of being a god or what?!
#
# PUT /quote/image
export def "quote-image update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote id (format: string)
  --bgimage-id: string # Background Image id ( Will override bgcolor if supplied) (format: string, default: theysaidso_default_background_image)
  --bg-color: string # Background Color(if background image id is not supplied) (format: string)
  --font-id: string # Font id (format: string, default: theysaidso_default_font)
  --text-color: string # Text Color (format: string)
  --text-size: string # Text/font size (format: string)
  --halign: string # Horizontal text Alignment Value (format: string, default: center)
  --valign: string # Vertical text Alignment Value (format: string, default: center)
  --width: int # Image Width(By default this takes the width of the background image) (format: integer)
  --height: int # Image Height(By default this takes the height of the background image) (format: integer)
  --branding: oneof<nothing, bool> # Disable They Said So branding (Only available in certain subscription levels. Ignored in other levels) (format: boolean, default: false)
  --include-transparent-layer: oneof<nothing, bool> # Should include a transparent layer between the text and the background image? This helps when the background image is bright and obscures the text. (format: boolean, default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar") (serialize-qp "bgimage_id" $bgimage_id "scalar") (serialize-qp "bg_color" $bg_color "scalar") (serialize-qp "font_id" $font_id "scalar") (serialize-qp "text_color" $text_color "scalar") (serialize-qp "text_size" $text_size "scalar") (serialize-qp "halign" $halign "scalar") (serialize-qp "valign" $valign "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "branding" $branding "scalar") (serialize-qp "include_transparent_layer" $include_transparent_layer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id, "bgimage_id": $bgimage_id, "bg_color": $bg_color, "font_id": $font_id, "text_color": $text_color, "text_size": $text_size, "halign": $halign, "valign": $valign, "width": $width, "height": $height, "branding": $branding, "include_transparent_layer": $include_transparent_layer} | compact), body: null}
}

# Delete a background image file. The user needs to be the owner of the background image to be able to delete it.
#
# DELETE /quote/image/background
export def "quote-image-background delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Add an image for use later as a quote background image.
#
# POST /quote/image/background
export def "quote-image-background create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  image: string # Image file to add to your collection (png/jpg/gif are supported) (format: binary)
  --tags: string # Optional comma separated tags (format: string)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quote/image/background")
  let req_body = {"image": $image, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Lists background images in your private collection.
#
# GET /quote/image/background/list
export def "quote-image-background-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter determines where the response should start. (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start} | compact), body: null}
}

# Searches for a background image with a given tag.
#
# GET /quote/image/background/search
export def "quote-image-background-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tag string (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query} | compact), body: null}
}

# Add a tag to a given Image.
#
# POST /quote/image/background/tags/add
export def "quote-image-background-tags-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Image ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}

# Remove a tag from a given Image.
#
# POST /quote/image/background/tags/remove
export def "quote-image-background-tags-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Image ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/background/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}

# Delete a font file. The user needs to be the owner of the font to be able to delete it.
#
# DELETE /quote/image/font
export def "quote-image-font delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Add a font file for use later in creating a quote image. This is essentially a `PUT` but not many clients handle PUT with binary stream i.e. a file, gracefully.
#
# POST /quote/image/font
export def "quote-image-font create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  font: string # Font file to add to your collection (ttf/otf are supported) (format: binary)
  --tags: string # Optional comma separated tags (format: string)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/quote/image/font")
  let req_body = {"font": $font, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["font"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Lists background images in your private collection.
#
# GET /quote/image/font/list
export def "quote-image-font-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter determines where the response should start. (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start} | compact), body: null}
}

# Searches for a font with a given tag.
#
# GET /quote/image/font/search
export def "quote-image-font-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tag string (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query} | compact), body: null}
}

# Add a tag to a given font.
#
# POST /quote/image/font/tags/add
export def "quote-image-font-tags-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}

# Remove a tag from a given Font.
#
# POST /quote/image/font/tags/remove
export def "quote-image-font-tags-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Font ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/font/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}

# Gets a Random Quote image. Optional `category` param determines the category of quote used in the image. Optional `author` param gets the quote image of a given author.
#
# GET /quote/image/search
export def "quote-image-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string # Quote Category (format: string)
  --author: string # Quote Author (format: string)
  --private: oneof<nothing, bool> # Should search private collection. Default searches public image collection. (format: boolean, default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "private" $private "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/image/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "author": $author, "private": $private} | compact), body: null}
}

# Remove the Like for the given Quote as a user of the API Key.
#
# DELETE /quote/like
export def "quote-like delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Like the given Quote as a user of the API Key. Same as `PUT` but a convenient alias for those clients that don't support `PUT` cleanly.
#
# POST /quote/like
export def "quote-like create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Like the given Quote as a user of the API Key. Some clients don't cleanly support `PUT`, in such scenarios use the `POST` version of this.
#
# PUT /quote/like
export def "quote-like update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: string # Quote ID (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quote_id" $quote_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/like" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"quote_id": $quote_id} | compact), body: null}
}

# Get the list of quotes in your private collection.
#
# GET /quote/list
export def "quote-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Response is paged. This parameter controls where response starts the listing at (format: int32, default: 0)
  --limit: int # Response is paged. This parameter controls how many is returned in the result. (format: int32, default: 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "limit": $limit} | compact), body: null}
}

# Gets a `Random Quote`. When you are in a hurry this is what you call to get a random famous quote.
#
# GET /quote/random
export def "quote-random get" [
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
  --language: string # Language of the Quote. The language must be supported in our system. (format: string, default: en)
  --limit: int # No of quotes to return. The max limit depends on the subscription level. (format: integer, default: 1)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/random" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"language": $language, "limit": $limit} | compact), body: null}
}

# Search for a `Quote` in They Said So platform. Optional `category` , `author`, `minlength`, `maxlength` params determines the filters applied while searching for the quote.
#
# GET /quote/search
export def "quote-search get" [
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
  --category: string # Quote Category (format: string)
  --author: string # Quote Author (format: string)
  --minlength: int # Quote minimum Length (format: int32, default: 100)
  --maxlength: int # Quote maximum Length (format: int32, default: 300)
  --query: string # keyword to search for in the quote (format: string)
  --private: oneof<nothing, bool> # Should search private collection? Default searches public collection. (format: boolean, default: false)
  --language: string # Language of the Quote. The language must be supported in our system. (format: string, default: en)
  --limit: int # No of quotes to return. The max limit depends on the subscription level. (format: integer, default: 1)
  --sfw: oneof<nothing, bool> # Should search only SFW (Safe For Work) quotes? (format: boolean, default: false)
]: nothing -> record<contents: record<quotes: list<record>>, success: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category" $category "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "minlength" $minlength "scalar") (serialize-qp "maxlength" $maxlength "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "private" $private "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sfw" $sfw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"category": $category, "author": $author, "minlength": $minlength, "maxlength": $maxlength, "query": $query, "private": $private, "language": $language, "limit": $limit, "sfw": $sfw} | compact), body: null}
}

# Add a tag to a given Quote.
#
# POST /quote/tags/add
export def "quote-tags-add create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/tags/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}

# Remove a tag from a given quote.
#
# POST /quote/tags/remove
export def "quote-tags-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # Quote ID (format: string)
  --tags: string # Comma Separated tags (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-theysaidso-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tags" $tags "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quote/tags/remove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "tags": $tags} | compact), body: null}
}
