# Auto-generated client for Apacta v0.0.42
# Source: https://api.apis.guru/v2/specs/apacta.com/0.0.42/openapi.json
# Auth: --token flag or $env.APACTA_TOKEN

const BASE_URL = "https://app.apacta.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APACTA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-auth-token" => { {scheme: $scheme, headers: {X-Auth-Token: $token_val}, query: "", location: "header"} }
    "query-api_token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_token")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://app.apacta.com/api/v1"] }
def auth-scheme-completer [] { ["x-auth-token" "query-api_token"] }

# Completers for enum parameters
def due-date-completer [] { ["" "exceeded" "valid"] }
def status-completer [] { ["" "approved" "expired_subscription"] }
def projects-completer [] { ["[project1, project2, project3]" "all" "none"] }
def extended-completer [] { ["false" "true"] }
def is-draft-completer [] { ["0" "1"] }
def is-offer-completer [] { ["0" "1"] }
def is-locked-completer [] { ["0" "1"] }
def is-fixed-price-completer [] { ["0" "1"] }
def billing-cysle-completer [] { ["daily" "hourly" "weekly"] }
def status-completer-1 [] { ["accepted" "draft" "rejected"] }
def variant-type-completer [] { ["expense_line" "vendor_product"] }
def status-completer-2 [] { ["awaiting" "expired" "failed" "fresh"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activities get" } } | get name | first)
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

# Get a list of activities
#
# GET /activities
export def "activities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, hex_code: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activities")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an activity
#
# POST /activities
export def "activities create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hex-code: string
  --name: string
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activities")
  let req_body = {"hex_code": $hex_code, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete activities
#
# DELETE /activities/bulkDelete
export def "activities-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/activities/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an activity
#
# DELETE /activities/{activity_id}
export def "activities delete" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activity_id' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/activities/{activity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an activity
#
# PUT /activities/{activity_id}
export def "activities update" [
  activity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hex-code: string
  --name: string
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activity_id' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/activities/{activity_id}"))
  let req_body = {"hex_code": $hex_code, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of cities supported in Apacta
#
# GET /cities
export def "cities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --zip-code: string # Used to search for a city with specific zip code
  --name: string # Used to search for a city by name
  --include-all: oneof<nothing, bool> # Used to search for a city without filtering by country
]: nothing -> record<data: table<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "zip_code" $zip_code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "include_all" $include_all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"zip_code": $zip_code, "name": $name, "include_all": $include_all} | compact), body: null}
}

# Get details about one city
#
# GET /cities/{city_id}
export def "cities get" [
  city_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, deleted: string, id: string, modified: string, name: string, zip_code: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($city_id | is-empty) { error make --unspanned { msg: "path parameter 'city_id' must be non-empty" } }
  let full_url = (build-url $base ({city_id: (encode-path-segment $city_id)} | format pattern "/cities/{city_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of clocking records
#
# GET /clocking_records
export def "clocking-records list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Used to search for active clocking records
]: nothing -> record<data: table<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clocking_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"active": $active} | compact), body: null}
}

# Create clocking record for authenticated user
#
# POST /clocking_records
export def "clocking-records create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkin-latitude: string
  --checkin-longitude: string
  --checkout-latitude: string
  --checkout-longitude: string
  --project-id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clocking_records")
  let req_body = {"checkin_latitude": $checkin_latitude, "checkin_longitude": $checkin_longitude, "checkout_latitude": $checkout_latitude, "checkout_longitude": $checkout_longitude, "project_id": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Checkout active clocking record for authenticated user
#
# POST /clocking_records/checkout
export def "clocking-records-checkout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/clocking_records/checkout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a clocking record
#
# DELETE /clocking_records/{clocking_record_id}
export def "clocking-records delete" [
  clocking_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($clocking_record_id | is-empty) { error make --unspanned { msg: "path parameter 'clocking_record_id' must be non-empty" } }
  let full_url = (build-url $base ({clocking_record_id: (encode-path-segment $clocking_record_id)} | format pattern "/clocking_records/{clocking_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 clocking_record
#
# GET /clocking_records/{clocking_record_id}
export def "clocking-records get" [
  clocking_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<checked_in: string, checked_out: string, checkin_latitude: string, checkin_longitude: string, checkout_latitude: string, checkout_longitude: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, project_id: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($clocking_record_id | is-empty) { error make --unspanned { msg: "path parameter 'clocking_record_id' must be non-empty" } }
  let full_url = (build-url $base ({clocking_record_id: (encode-path-segment $clocking_record_id)} | format pattern "/clocking_records/{clocking_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a clocking record
#
# PUT /clocking_records/{clocking_record_id}
export def "clocking-records update" [
  clocking_record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($clocking_record_id | is-empty) { error make --unspanned { msg: "path parameter 'clocking_record_id' must be non-empty" } }
  let full_url = (build-url $base ({clocking_record_id: (encode-path-segment $clocking_record_id)} | format pattern "/clocking_records/{clocking_record_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of companies
#
# GET /companies
export def "companies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# URL for subscription selfservice
#
# GET /companies/subscription_self_service
export def "companies-subscription-self-service get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<subscription_self_service_url: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies/subscription_self_service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 company
#
# GET /companies/{company_id}
export def "companies get" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<city_id: string, contact_person_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, expired: string, file_id: string, id: string, invoice_email: string, language_id: string, modified: string, name: string, next_invoice_number: int, next_offer_number: int, next_project_number: int, phone: string, phone_countrycode: string, receive_form_mails: string, street_name: string, vat_percent: int, website: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List a company integration feature settings
#
# GET /companies/{company_id}/companies_integration_feature_settings
export def "companies-companies-integration-feature-settings list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/companies_integration_feature_settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a company integration feature setting
#
# POST /companies/{company_id}/companies_integration_feature_settings
export def "companies-companies-integration-feature-settings create" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-feature-setting-id: string # format: uuid
  --value: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/companies_integration_feature_settings"))
  let req_body = {"integration_feature_setting_id": $integration_feature_setting_id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View a company integration feature setting
#
# GET /companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}
export def "companies-companies-integration-feature-settings get" [
  company_id: string
  c_integration_feature_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($c_integration_feature_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'c_integration_feature_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), c_integration_feature_setting_id: (encode-path-segment $c_integration_feature_setting_id)} | format pattern "/companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a company integration feature setting
#
# PUT /companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}
export def "companies-companies-integration-feature-settings update" [
  company_id: string
  c_integration_feature_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_feature_setting_id: string, modified: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($c_integration_feature_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'c_integration_feature_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), c_integration_feature_setting_id: (encode-path-segment $c_integration_feature_setting_id)} | format pattern "/companies/{company_id}/companies_integration_feature_settings/{c_integration_feature_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of company form templates
#
# GET /companies/{company_id}/form_templates/
export def "companies-form-templates list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-template-id: string
]: nothing -> record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let qp = [(serialize-qp "form_template_id" $form_template_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/form_templates/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"form_template_id": $form_template_id} | compact), body: null}
}

# Delete a form template company
#
# DELETE /companies/{company_id}/form_templates/{form_template_id}
export def "companies-form-templates delete" [
  company_id: string
  form_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($form_template_id | is-empty) { error make --unspanned { msg: "path parameter 'form_template_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), form_template_id: (encode-path-segment $form_template_id)} | format pattern "/companies/{company_id}/form_templates/{form_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a company form template
#
# GET /companies/{company_id}/form_templates/{form_template_id}
export def "companies-form-templates get" [
  company_id: string
  form_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
]: nothing -> record<data: list<any>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($form_template_id | is-empty) { error make --unspanned { msg: "path parameter 'form_template_id' must be non-empty" } }
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), form_template_id: (encode-path-segment $form_template_id)} | format pattern "/companies/{company_id}/form_templates/{form_template_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id} | compact), body: null}
}

# Get a list of integration feature settings
#
# GET /companies/{company_id}/integration_feature_settings
export def "companies-integration-feature-settings list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/integration_feature_settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show details of 1 integration feature setting
#
# GET /companies/{company_id}/integration_feature_settings/{integration_feature_setting_id}
export def "companies-integration-feature-settings get" [
  company_id: string
  integration_feature_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, default_value: string, deleted: string, description: string, id: string, identifier: string, integration_feature_id: string, is_custom_setting: bool, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($integration_feature_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_feature_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), integration_feature_setting_id: (encode-path-segment $integration_feature_setting_id)} | format pattern "/companies/{company_id}/integration_feature_settings/{integration_feature_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of company integration settings
#
# GET /companies/{company_id}/integration_settings
export def "companies-integration-settings list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string # The identifier of an ERP integration
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let qp = [(serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/integration_settings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"identifier": $identifier} | compact), body: null}
}

# Add a company integration setting
#
# POST /companies/{company_id}/integration_settings
export def "companies-integration-settings create" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-setting-id: string # format: uuid
  --value: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/integration_settings"))
  let req_body = {"integration_setting_id": $integration_setting_id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a company integration setting
#
# DELETE /companies/{company_id}/integration_settings/{companies_integration_setting_id}
export def "companies-integration-settings delete" [
  company_id: string
  companies_integration_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($companies_integration_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_integration_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), companies_integration_setting_id: (encode-path-segment $companies_integration_setting_id)} | format pattern "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a company integration setting
#
# GET /companies/{company_id}/integration_settings/{companies_integration_setting_id}
export def "companies-integration-settings get" [
  company_id: string
  companies_integration_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($companies_integration_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_integration_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), companies_integration_setting_id: (encode-path-segment $companies_integration_setting_id)} | format pattern "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a company integration setting
#
# PUT /companies/{company_id}/integration_settings/{companies_integration_setting_id}
export def "companies-integration-settings update" [
  company_id: string
  companies_integration_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($companies_integration_setting_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_integration_setting_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), companies_integration_setting_id: (encode-path-segment $companies_integration_setting_id)} | format pattern "/companies/{company_id}/integration_settings/{companies_integration_setting_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a company price margin
#
# DELETE /companies/{company_id}/price_margins/{price_margins_id}
export def "companies-price-margins delete" [
  company_id: string
  price_margins_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --price-margin-id: string
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($price_margins_id | is-empty) { error make --unspanned { msg: "path parameter 'price_margins_id' must be non-empty" } }
  let qp = [(serialize-qp "price_margin_id" $price_margin_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), price_margins_id: (encode-path-segment $price_margins_id)} | format pattern "/companies/{company_id}/price_margins/{price_margins_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"price_margin_id": $price_margin_id} | compact), body: null}
}

# Get a list of company price margins
#
# GET /companies/{company_id}/price_margins/{price_margins_id}
export def "companies-price-margins get" [
  company_id: string
  price_margins_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<amount_from: float, amount_to: float, company_id: string, created: string, deleted: string, id: string, modified: string, percentage_ratio: float, ratio: float, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($price_margins_id | is-empty) { error make --unspanned { msg: "path parameter 'price_margins_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), price_margins_id: (encode-path-segment $price_margins_id)} | format pattern "/companies/{company_id}/price_margins/{price_margins_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a company price margin
#
# POST /companies/{company_id}/price_margins/{price_margins_id}
export def "companies-price-margins create" [
  company_id: string
  price_margins_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # format: uuid
  --value: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'company_id' must be non-empty" } }
  if ($price_margins_id | is-empty) { error make --unspanned { msg: "path parameter 'price_margins_id' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), price_margins_id: (encode-path-segment $price_margins_id)} | format pattern "/companies/{company_id}/price_margins/{price_margins_id}"))
  let req_body = {"id": $id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of companies vendors
#
# GET /companies_vendors
# operationId: getCompaiesVendorsList
export def "companies-vendors get-compaies-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies_vendors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new companies vendor
#
# POST /companies_vendors
# operationId: addCompaniesVendor
export def "companies-vendors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --delivery-price: float # format: float
  --free-delivery-price: float # format: float
  --is-active: oneof<nothing, bool>
  --password: string
  --receive-automatic-price-files: oneof<nothing, bool>
  --receive-invoice-mails: oneof<nothing, bool>
  --reviewed: oneof<nothing, bool>
  --use-price-files: oneof<nothing, bool>
  --username: string
  --vendor-account-reference: string
  --vendor-department-id: string # format: uuid
  --vendor-email: string
  --vendor-id: string # format: uuid
  --vendor-name: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies_vendors")
  let req_body = {"company_id": $company_id, "delivery_price": $delivery_price, "free_delivery_price": $free_delivery_price, "is_active": $is_active, "password": $password, "receive_automatic_price_files": $receive_automatic_price_files, "receive_invoice_mails": $receive_invoice_mails, "reviewed": $reviewed, "use_price_files": $use_price_files, "username": $username, "vendor_account_reference": $vendor_account_reference, "vendor_department_id": $vendor_department_id, "vendor_email": $vendor_email, "vendor_id": $vendor_id, "vendor_name": $vendor_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete companies vendors
#
# DELETE /companies_vendors/bulkDelete
# operationId: bulkCompaniesVendors
export def "companies-vendors-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies_vendors/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a companies vendor
#
# DELETE /companies_vendors/{companies_vendor_id}
export def "companies-vendors delete" [
  companies_vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($companies_vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({companies_vendor_id: (encode-path-segment $companies_vendor_id)} | format pattern "/companies_vendors/{companies_vendor_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a companies vendor
#
# GET /companies_vendors/{companies_vendor_id}
# operationId: getCompaniesVendor
export def "companies-vendors get" [
  companies_vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, company_password: string, created: string, created_by_id: string, deleted: string, delivery_price: float, free_delivery_price: float, id: string, is_active: bool, modified: string, modified_by_id: string, receive_automatic_price_files: bool, receive_invoice_mails: bool, reviewed: bool, use_price_files: bool, username: string, vendor: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, vendor_account_reference: string, vendor_department_id: string, vendor_email: string, vendor_id: string, vendor_name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($companies_vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({companies_vendor_id: (encode-path-segment $companies_vendor_id)} | format pattern "/companies_vendors/{companies_vendor_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a companies vendor
#
# PUT /companies_vendors/{companies_vendor_id}
# operationId: editCompaniesVendor
export def "companies-vendors update-edit" [
  companies_vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --delivery-price: float # format: float
  --free-delivery-price: float # format: float
  --is-active: oneof<nothing, bool>
  --password: string
  --receive-automatic-price-files: oneof<nothing, bool>
  --receive-invoice-mails: oneof<nothing, bool>
  --reviewed: oneof<nothing, bool>
  --use-price-files: oneof<nothing, bool>
  --username: string
  --vendor-account-reference: string
  --vendor-department-id: string # format: uuid
  --vendor-email: string
  --vendor-id: string # format: uuid
  --vendor-name: string
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($companies_vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({companies_vendor_id: (encode-path-segment $companies_vendor_id)} | format pattern "/companies_vendors/{companies_vendor_id}"))
  let req_body = {"company_id": $company_id, "delivery_price": $delivery_price, "free_delivery_price": $free_delivery_price, "is_active": $is_active, "password": $password, "receive_automatic_price_files": $receive_automatic_price_files, "receive_invoice_mails": $receive_invoice_mails, "reviewed": $reviewed, "use_price_files": $use_price_files, "username": $username, "vendor_account_reference": $vendor_account_reference, "vendor_department_id": $vendor_department_id, "vendor_email": $vendor_email, "vendor_id": $vendor_id, "vendor_name": $vendor_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get companies vendor expense statistics
#
# GET /companies_vendors/{companies_vendor_id}/expense_statistics
# operationId: getCompaniesVendorsExpenseStatistics
export def "companies-vendors-expense-statistics get" [
  companies_vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<last_month: list, thirty_days: list, vendor_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($companies_vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'companies_vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({companies_vendor_id: (encode-path-segment $companies_vendor_id)} | format pattern "/companies_vendors/{companies_vendor_id}/expense_statistics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of company settings
#
# GET /company_settings
# operationId: getCompaySettingsList
export def "company-settings get-compay-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filter by name
  --description: string # Filter by description
]: nothing -> record<data: record<company_settings_category_id: string, created: string, created_by_id: string, default_value: string, deleted: string, description: string, feature_id: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, options: string, placement: int, type: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/company_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "description": $description} | compact), body: null}
}

# Get a list of contact custom field attributes
#
# GET /contact_custom_field_attributes
export def "contact-custom-field-attributes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contact_custom_field_attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 contact custom field attribute
#
# GET /contact_custom_field_attributes/{contact_custom_field_attribute_id}
export def "contact-custom-field-attributes get" [
  contact_custom_field_attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_custom_field_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_custom_field_attribute_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_custom_field_attribute_id: (encode-path-segment $contact_custom_field_attribute_id)} | format pattern "/contact_custom_field_attributes/{contact_custom_field_attribute_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of contact types supported in Apacta
#
# GET /contact_types
export def "contact-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifier: string # Search for specific identifier value
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contact_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"identifier": $identifier} | compact), body: null}
}

# Get details about one contact type
#
# GET /contact_types/{contact_type_id}
export def "contact-types get" [
  contact_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_type_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_type_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_type_id: (encode-path-segment $contact_type_id)} | format pattern "/contact_types/{contact_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of contacts
#
# GET /contacts
export def "contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to search for a contact with a specific name
  --cvr: string # Search for values in CVR field
  --ean: string # Search for values in EAN field
  --erp-id: string # Search for values in ERP id field
  --contact-type: string # Used to show only contacts with with one specific `ContactType` (format: uuid)
  --city: string # Used to show only contacts with with one specific `City`
  --modified-gte: string # format: datetime
]: nothing -> record<data: table<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "cvr" $cvr "scalar") (serialize-qp "ean" $ean "scalar") (serialize-qp "erp_id" $erp_id "scalar") (serialize-qp "contact_type" $contact_type "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "modified_gte" $modified_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "cvr": $cvr, "ean": $ean, "erp_id": $erp_id, "contact_type": $contact_type, "city": $city, "modified_gte": $modified_gte} | compact), body: null}
}

# Add a new contact
#
# POST /contacts
# --contact_types shape: {_ids?: list<string>}
export def "contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Street address
  --city-id: string # format: uuid
  --contact-types: record # shape: {_ids?: list<string>}
  --cvr: string
  --description: string
  --email: string
  --erp-id: string # If company has integration to an ERP system, and the contacts are synchronized, this will be the ERP-systems ID of this contact
  --name: string
  --phone: string # Format like eg. `28680133` or `046158971404`
  --website: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts")
  let req_body = {"address": $address, "city_id": $city_id, "contact_types": $contact_types, "cvr": $cvr, "description": $description, "email": $email, "erp_id": $erp_id, "name": $name, "phone": $phone, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete contacts
#
# DELETE /contacts/bulkDelete
# operationId: bulkDeleteContacts
export def "contacts-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a contact
#
# DELETE /contacts/{contact_id}
export def "contacts delete" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 contact
#
# GET /contacts/{contact_id}
export def "contacts get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<address: string, centiga_id: string, city_id: string, company_id: string, country_id: string, created: string, created_by_id: string, cvr: string, deleted: string, description: string, email: string, erp_id: string, id: string, modified: string, name: string, phone: string, pogo_id: string, tripletex_id: string, website: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a contact
#
# PUT /contacts/{contact_id}
# --contact_types shape: {_ids?: list<string>}
export def "contacts update" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # Street address
  --city-id: string # format: uuid
  --contact-types: record # shape: {_ids?: list<string>}
  --cvr: string
  --description: string
  --email: string
  --erp-id: string # If company has integration to an ERP system, and the contacts are synchronized, this will be the ERP-systems ID of this contact
  --name: string
  --phone: string # Format like eg. `28680133` or `046158971404`
  --website: string
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}"))
  let req_body = {"address": $address, "city_id": $city_id, "contact_types": $contact_types, "cvr": $cvr, "description": $description, "email": $email, "erp_id": $erp_id, "name": $name, "phone": $phone, "website": $website} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of contact custom field values
#
# GET /contacts/{contact_id}/contact_custom_field_values
export def "contacts-contact-custom-field-values get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<contact_custom_field_attribute_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}/contact_custom_field_values"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of contact people
#
# GET /contacts/{contact_id}/contact_persons
# operationId: getContactPersonsList
export def "contacts-contact-persons get-list" [
  contact_id: string
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
  --created-gte: string # format: date
  --created-lte: string # format: date
]: nothing -> record<data: table<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "created_gte" $created_gte "scalar") (serialize-qp "created_lte" $created_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}/contact_persons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "created_gte": $created_gte, "created_lte": $created_lte} | compact), body: null}
}

# Add a new contact person to a contact
#
# POST /contacts/{contact_id}/contact_persons
# operationId: addContactPerson
export def "contacts-contact-persons create" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string
  --phone: string
  --title: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/contacts/{contact_id}/contact_persons"))
  let req_body = {"email": $email, "name": $name, "phone": $phone, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a contact person
#
# DELETE /contacts/{contact_id}/contact_persons/{contact_person_id}
export def "contacts-contact-persons delete" [
  contact_id: string
  contact_person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  if ($contact_person_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_person_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), contact_person_id: (encode-path-segment $contact_person_id)} | format pattern "/contacts/{contact_id}/contact_persons/{contact_person_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a contact person
#
# GET /contacts/{contact_id}/contact_persons/{contact_person_id}
# operationId: getContactPerson
export def "contacts-contact-persons get" [
  contact_id: string
  contact_person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<contact_id: string, created: string, created_by_id: string, deleted: string, email: string, id: string, modified: string, name: string, phone: string, title: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  if ($contact_person_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_person_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), contact_person_id: (encode-path-segment $contact_person_id)} | format pattern "/contacts/{contact_id}/contact_persons/{contact_person_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a contact person
#
# PUT /contacts/{contact_id}/contact_persons/{contact_person_id}
# operationId: editContactPerson
export def "contacts-contact-persons update-edit" [
  contact_id: string
  contact_person_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --name: string
  --phone: string
  --title: string
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($contact_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_id' must be non-empty" } }
  if ($contact_person_id | is-empty) { error make --unspanned { msg: "path parameter 'contact_person_id' must be non-empty" } }
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), contact_person_id: (encode-path-segment $contact_person_id)} | format pattern "/contacts/{contact_id}/contact_persons/{contact_person_id}"))
  let req_body = {"email": $email, "name": $name, "phone": $phone, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of countries supported in Apacta
#
# GET /countries
export def "countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details about one country
#
# GET /countries/{country_id}
export def "countries get" [
  country_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, currency_id: string, deleted: string, id: string, identifier: string, language_id: string, modified: string, name: string, phone_code: string, time_zone: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($country_id | is-empty) { error make --unspanned { msg: "path parameter 'country_id' must be non-empty" } }
  let full_url = (build-url $base ({country_id: (encode-path-segment $country_id)} | format pattern "/countries/{country_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of currencies supported in Apacta
#
# GET /currencies
export def "currencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details about one currency
#
# GET /currencies/{currency_id}
export def "currencies get" [
  currency_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<centiga_id: string, created: string, currency_sign: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string, pogo_id: string, tripletex_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($currency_id | is-empty) { error make --unspanned { msg: "path parameter 'currency_id' must be non-empty" } }
  let full_url = (build-url $base ({currency_id: (encode-path-segment $currency_id)} | format pattern "/currencies/{currency_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List the driving types of the company
#
# GET /driving_types
# operationId: get-driving_types
export def "driving-types list" [
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
  --qp-sort: string
  --direction: string
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/driving_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort": $qp_sort, "direction": $direction} | compact), body: null}
}

# Create driving type
#
# POST /driving_types
# operationId: post-driving_types
export def "driving-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  company_id: string # format: uuid
  employee_price: float # format: float
  --erp-id: string
  invoice_price: float # format: float
  name: string
  --salary-id: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driving_types")
  let req_body = {"company_id": $company_id, "employee_price": $employee_price, "erp_id": $erp_id, "invoice_price": $invoice_price, "name": $name, "salary_id": $salary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete driving types
#
# DELETE /driving_types/bulkDelete
# operationId: bulkDeleteDrivingTypes
export def "driving-types-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driving_types/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete driving type
#
# DELETE /driving_types/{driving_type_id}
# operationId: delete-driving_types-driving_type_id
export def "driving-types delete" [
  driving_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($driving_type_id | is-empty) { error make --unspanned { msg: "path parameter 'driving_type_id' must be non-empty" } }
  let full_url = (build-url $base ({driving_type_id: (encode-path-segment $driving_type_id)} | format pattern "/driving_types/{driving_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View driving type
#
# GET /driving_types/{driving_type_id}
# operationId: get-driving_types-driving_type_id
export def "driving-types get" [
  driving_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --driving-type-id: string
]: nothing -> record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($driving_type_id | is-empty) { error make --unspanned { msg: "path parameter 'driving_type_id' must be non-empty" } }
  let qp = [(serialize-qp "driving_type_id" $driving_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({driving_type_id: (encode-path-segment $driving_type_id)} | format pattern "/driving_types/{driving_type_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"driving_type_id": $driving_type_id} | compact), body: null}
}

# Edit driving type
#
# PUT /driving_types/{driving_type_id}
# operationId: put-driving_types-driving_type_id
export def "driving-types update" [
  driving_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<company_id: string, created: string, created_by_id: string, deleted: string, employee_price: float, erp_id: string, id: string, invoice_price: float, modified: string, modified_by_id: string, name: string, salary_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($driving_type_id | is-empty) { error make --unspanned { msg: "path parameter 'driving_type_id' must be non-empty" } }
  let full_url = (build-url $base ({driving_type_id: (encode-path-segment $driving_type_id)} | format pattern "/driving_types/{driving_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Used to retrieve details about the logged in user's hours
#
# GET /employee_hours
export def "employee-hours get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date formatted as Y-m-d (2016-06-28)
  --date-to: string # Date formatted as Y-m-d (2016-06-28)
]: nothing -> record<data: table<form_date: string, form_id: string, project_name: string, total_hours: int, working_description: string, working_description_full: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/employee_hours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Show list of events
#
# GET /events
export def "events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # format: uuid
  --project-id: string # format: uuid
  --start-gt: string # format: datetime
  --start-lt: string # format: datetime
  --start-eq: string # format: datetime
  --end-gt: string # format: datetime
  --end-lt: string # format: datetime
  --end-eq: string # format: datetime
  --tags: string # List events with given tag ids separated by comma. Example tags=0377d6ce-db5e-4b1e-ac3a-8ca39ea3142e,8cec327e-a559-4b40-9ed6-316b9de46743 (format: string)
  --without-users: oneof<nothing, bool> # List events without attached user
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "start[][gt]" $start_gt "scalar") (serialize-qp "start[][lt]" $start_lt "scalar") (serialize-qp "start[][eq]" $start_eq "scalar") (serialize-qp "end[][gt]" $end_gt "scalar") (serialize-qp "end[][lt]" $end_lt "scalar") (serialize-qp "end[][eq]" $end_eq "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "without_users" $without_users "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_id": $user_id, "project_id": $project_id, "start[][gt]": $start_gt, "start[][lt]": $start_lt, "start[][eq]": $start_eq, "end[][gt]": $end_gt, "end[][lt]": $end_lt, "end[][eq]": $end_eq, "tags": $tags, "without_users": $without_users} | compact), body: null}
}

# Create event
#
# POST /events
export def "events create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --end: string # format: datetime
  --name: string
  --project-id: string # format: uuid
  --start: string # format: datetime
  --user-id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let req_body = {"description": $description, "end": $end, "name": $name, "project_id": $project_id, "start": $start, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check if user is available at given datetime range
#
# GET /events/is_user_free
export def "events-is-user-free get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # format: uuid
  --start: string # format: dateTime
  --end: string # format: dateTime
]: nothing -> record<result: bool, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/events/is_user_free" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_id": $user_id, "start": $start, "end": $end} | compact), body: null}
}

# Delete event
#
# DELETE /events/{event_id}
export def "events delete" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show event
#
# GET /events/{event_id}
export def "events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit event
#
# PUT /events/{event_id}
export def "events update" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, end: string, id: string, modified: string, modified_by_id: string, name: string, project_id: string, start: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'event_id' must be non-empty" } }
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of expense files
#
# GET /expense_files
export def "expense-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --expense-id: string # format: uuid
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, expense_id: string, file: string, file_extension: string, file_original_name: string, file_size: string, file_type: string, file_url: string, id: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_by_id" $created_by_id "scalar") (serialize-qp "expense_id" $expense_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/expense_files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"created_by_id": $created_by_id, "expense_id": $expense_id} | compact), body: null}
}

# Add file to expense
#
# POST /expense_files
export def "expense-files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  file: string # format: binary
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expense_files")
  let req_body = {"description": $description, "file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete file
#
# DELETE /expense_files/{expense_file_id}
export def "expense-files delete" [
  expense_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_file_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_file_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_file_id: (encode-path-segment $expense_file_id)} | format pattern "/expense_files/{expense_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show file
#
# GET /expense_files/{expense_file_id}
export def "expense-files get" [
  expense_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_file_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_file_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_file_id: (encode-path-segment $expense_file_id)} | format pattern "/expense_files/{expense_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit file
#
# PUT /expense_files/{expense_file_id}
export def "expense-files update" [
  expense_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_file_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_file_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_file_id: (encode-path-segment $expense_file_id)} | format pattern "/expense_files/{expense_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of expense lines
#
# GET /expense_lines
export def "expense-lines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --currency-id: string # format: uuid
  --expense-id: string # format: uuid
]: nothing -> record<data: table<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_by_id" $created_by_id "scalar") (serialize-qp "currency_id" $currency_id "scalar") (serialize-qp "expense_id" $expense_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/expense_lines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"created_by_id": $created_by_id, "currency_id": $currency_id, "expense_id": $expense_id} | compact), body: null}
}

# Add line to expense
#
# POST /expense_lines
export def "expense-lines create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buying-price: float # format: float
  --currency-id: string # format: uuid
  --expense-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --text: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expense_lines")
  let req_body = {"buying_price": $buying_price, "currency_id": $currency_id, "expense_id": $expense_id, "quantity": $quantity, "selling_price": $selling_price, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete expense line
#
# DELETE /expense_lines/{expense_line_id}
export def "expense-lines delete" [
  expense_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_line_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_line_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_line_id: (encode-path-segment $expense_line_id)} | format pattern "/expense_lines/{expense_line_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show expense line
#
# GET /expense_lines/{expense_line_id}
export def "expense-lines get" [
  expense_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_line_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_line_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_line_id: (encode-path-segment $expense_line_id)} | format pattern "/expense_lines/{expense_line_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit expense line
#
# PUT /expense_lines/{expense_line_id}
export def "expense-lines update" [
  expense_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<buying_price: float, created: string, created_by_id: string, currency_id: string, deleted: string, expense_id: string, id: string, is_invoiced: string, modified: string, quantity: int, selling_price: float, text: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_line_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_line_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_line_id: (encode-path-segment $expense_line_id)} | format pattern "/expense_lines/{expense_line_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of expenses
#
# GET /expenses
export def "expenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # format: uuid
  --company-id: string # format: uuid
  --contact-id: string # format: uuid
  --project-id: string # format: uuid
  --due-date: string@due-date-completer # Filter by [valid=records in future including today], [exceeded=records in past] or [null=all records] (format: string)
  --gt-created: string # Created after date (format: date)
  --lt-created: string # Created before date (format: date)
  --status: string@status-completer # Filter by status identifier. [null=all records] (format: string)
  --is-imported: oneof<nothing, bool> # default: true
  --min-amount: float # Expenses `total_selling_price` > `min_amount` (format: float)
  --max-amount: float # Expenses `total_selling_price` < `max_amount` (format: float)
  --projects: string@projects-completer # You can select `all projects`, `no projects` or select `multiple projects`
]: nothing -> record<data: table<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "created_by_id" $created_by_id "scalar") (serialize-qp "company_id" $company_id "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "due_date" $due_date "scalar") (serialize-qp "gt_created" $gt_created "scalar") (serialize-qp "lt_created" $lt_created "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "is_imported" $is_imported "scalar") (serialize-qp "min_amount" $min_amount "scalar") (serialize-qp "max_amount" $max_amount "scalar") (serialize-qp "projects" $projects "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/expenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"created_by_id": $created_by_id, "company_id": $company_id, "contact_id": $contact_id, "project_id": $project_id, "due_date": $due_date, "gt_created": $gt_created, "lt_created": $lt_created, "status": $status, "is_imported": $is_imported, "min_amount": $min_amount, "max_amount": $max_amount, "projects": $projects} | compact), body: null}
}

# Add line to expense
#
# POST /expenses
export def "expenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --currency-id: string # format: uuid
  --delivery-date: string # format: date
  --description: string
  --project-id: string # format: uuid
  --reference: string
  --short-text: string
  --supplier-invoice-number: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expenses")
  let req_body = {"contact_id": $contact_id, "currency_id": $currency_id, "delivery_date": $delivery_date, "description": $description, "project_id": $project_id, "reference": $reference, "short_text": $short_text, "supplier_invoice_number": $supplier_invoice_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete expenses
#
# DELETE /expenses/bulkDelete
# operationId: bulkDeleteExpenses
export def "expenses-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expenses/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Show highest Expense amount(`total_selling_price`)
#
# GET /expenses/highest_amount
export def "expenses-highest-amount get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --gt-created: string # Used to filter time range (format: date)
  --lt-created: string # Used to filter time range (format: date)
]: nothing -> record<data: table<highest_amount: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gt_created" $gt_created "scalar") (serialize-qp "lt_created" $lt_created "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/expenses/highest_amount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"gt_created": $gt_created, "lt_created": $lt_created} | compact), body: null}
}

# Bulk delete expenses
#
# DELETE /expenses/sendEmails
# operationId: sendEmailsExpenses
export def "expenses-send-emails send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/expenses/sendEmails")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete expense
#
# DELETE /expenses/{expense_id}
export def "expenses delete" [
  expense_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_id: (encode-path-segment $expense_id)} | format pattern "/expenses/{expense_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show expense
#
# GET /expenses/{expense_id}
export def "expenses get" [
  expense_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_id: (encode-path-segment $expense_id)} | format pattern "/expenses/{expense_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit expense
#
# PUT /expenses/{expense_id}
export def "expenses update" [
  expense_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<activity_id: string, comment: string, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, delivery_date: string, description: string, due_date: string, file_reference: string, id: string, is_imported: string, modified: string, order_number: string, project_id: string, readsoft_id: string, reference: string, roger_id: string, sent_to_email: string, short_text: string, status: string, supplier_invoice_number: string, total_buying_price: float, total_selling_price: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_id: (encode-path-segment $expense_id)} | format pattern "/expenses/{expense_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of all OIOUBL files for the expense
#
# GET /expenses/{expense_id}/original_files
export def "expenses-original-files list" [
  expense_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_id: (encode-path-segment $expense_id)} | format pattern "/expenses/{expense_id}/original_files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show OIOUBL file
#
# GET /expenses/{expense_id}/original_files/{file_id}
export def "expenses-original-files get" [
  expense_id: string
  file_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($expense_id | is-empty) { error make --unspanned { msg: "path parameter 'expense_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({expense_id: (encode-path-segment $expense_id), file_id: (encode-path-segment $file_id)} | format pattern "/expenses/{expense_id}/original_files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get general statistics
#
# GET /financial_statistics
# operationId: getFinancialStatistics
export def "financial-statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
  --project-status-ids: string # format: uuid
  --only-not-invoiced: oneof<nothing, bool>
  --details: oneof<nothing, bool>
]: nothing -> record<data: record<invoicedAmount: float, invoicedWorkingHours: string, notInvoicedAmount: float, notInvoicedWorkingHours: string, productsCosts: float, productsSales: float, rentalsCosts: float, rentalsSales: float, totalCosts: float, totalSales: float, workTimeCosts: float, workTimeSales: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "project_status_ids[]" $project_status_ids "scalar") (serialize-qp "only_not_invoiced" $only_not_invoiced "scalar") (serialize-qp "details" $details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id, "project_status_ids[]": $project_status_ids, "only_not_invoiced": $only_not_invoiced, "details": $details} | compact), body: null}
}

# Get expenses sales price
#
# GET /financial_statistics/expensesSalesPrice
# operationId: getExpensesSalesPrice
export def "financial-statistics-expenses-sales-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<expensesSalesPrice: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/expensesSalesPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get invoiced amount
#
# GET /financial_statistics/invoicedAmount
# operationId: getInvoicedAmount
export def "financial-statistics-invoiced-amount get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<invoicedAmount: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/invoicedAmount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get margin
#
# GET /financial_statistics/margin
# operationId: getMargin
export def "financial-statistics-margin get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<margin: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/margin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get products material rentals cost price
#
# GET /financial_statistics/materialRentalsCostPrice
# operationId: getMaterialRentalsCostPrice
export def "financial-statistics-material-rentals-cost-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<materialRentalsCostPrice: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/materialRentalsCostPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get statistics overview
#
# GET /financial_statistics/overview
# operationId: getFinancialStatisticsOverview
export def "financial-statistics-overview get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<data: record<expensesSalesPrice: float, invoicedAmount: float, margin: float, materialRentalsCostPrice: float, productsCostPrice: float, totalWorkingHours: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/overview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get products cost price
#
# GET /financial_statistics/productsCostPrice
# operationId: getProductsCostPrice
export def "financial-statistics-products-cost-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<productsCostPrice: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/productsCostPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get Total working hours grouped by time entry type
#
# GET /financial_statistics/workingHours
export def "financial-statistics-working-hours get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --project-id: string # format: uuid
]: nothing -> record<normalWorkingHours: string, timeEntries: table<id: string, name: string, total: string>, totalWorkingHours: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "project_id" $project_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/financial_statistics/workingHours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "project_id": $project_id} | compact), body: null}
}

# Get list of form field types
#
# GET /form_field_types
export def "form-field-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the form_fields
  --identifier: string # Used to filter on the `identifier` of the form_fields
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/form_field_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "identifier": $identifier} | compact), body: null}
}

# Get details about single `FormField`
#
# GET /form_field_types/{form_field_type_id}
export def "form-field-types get" [
  form_field_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_field_type_id | is-empty) { error make --unspanned { msg: "path parameter 'form_field_type_id' must be non-empty" } }
  let full_url = (build-url $base ({form_field_type_id: (encode-path-segment $form_field_type_id)} | format pattern "/form_field_types/{form_field_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new field to a `Form`
#
# POST /form_fields
export def "form-fields create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  --content-value: string
  --file-id: string # format: uuid
  --form-field-type-id: string # format: uuid
  --form-id: string # format: uuid
  --form-template-field-id: string # format: uuid
  --placement: int # format: int32
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/form_fields")
  let req_body = {"comment": $comment, "content_value": $content_value, "file_id": $file_id, "form_field_type_id": $form_field_type_id, "form_id": $form_id, "form_template_field_id": $form_template_field_id, "placement": $placement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get details about single `FormField`
#
# GET /form_fields/{form_field_id}
export def "form-fields get" [
  form_field_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<comment: string, content_value: string, created: string, created_by_id: string, deleted: string, file_id: string, form_field_type_id: string, form_id: string, form_template_field_id: string, id: string, modified: string, placement: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_field_id | is-empty) { error make --unspanned { msg: "path parameter 'form_field_id' must be non-empty" } }
  let full_url = (build-url $base ({form_field_id: (encode-path-segment $form_field_id)} | format pattern "/form_fields/{form_field_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get array of form_templates for your company
#
# GET /form_templates
export def "form-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the form_templates
  --identifier: string # Used to filter on the `identifier` of the form_templates
  --pdf-template-identifier: string # Used to filter on the `pdf_template_identifier` of the form_templates
  --description: string # Used to filter on the `description` of the form_templates
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "pdf_template_identifier" $pdf_template_identifier "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/form_templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "identifier": $identifier, "pdf_template_identifier": $pdf_template_identifier, "description": $description} | compact), body: null}
}

# View one form template
#
# GET /form_templates/{form_template_id}
export def "form-templates get" [
  form_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, form_category_id: string, form_overview_category_id: string, id: string, identifier: string, is_active: bool, modified: string, name: string, pdf_template_identifier: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_template_id | is-empty) { error make --unspanned { msg: "path parameter 'form_template_id' must be non-empty" } }
  let full_url = (build-url $base ({form_template_id: (encode-path-segment $form_template_id)} | format pattern "/form_templates/{form_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve array of forms
#
# GET /forms
export def "forms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --extended: string@extended-completer # Used to have extended details from the forms from the `Form`'s `FormFields`
  --date-from: string # Used in conjunction with `date_to` to only show forms within these dates - format like `2016-28-05` (format: Y-m-d)
  --date-to: string # Used in conjunction with `date_from` to only show forms within these dates - format like `2016-28-30` (format: Y-m-d)
  --show: string # Used to show forms with trashed (format: with_trashed)
  --project-id: string # Used to filter on the `project_id` of the forms (format: uuid)
  --created-by-id: string # Used to filter on the `created_by_id` of the forms
  --form-template-id: list<string> # Used to filter on the `form_template_id` of the forms. Accept single value and array.
  --form-template-type: string # Filter by `form_templates.identifier` containing string passed in `form_template_type`. Accept strings like [`qa`, `dagseddel`]
  --employee-name: string # Used to filter forms by user's first or last name
]: nothing -> record<data: table<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extended" $extended "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "show" $show "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "created_by_id" $created_by_id "scalar") (serialize-qp "form_template_id" $form_template_id "csv") (serialize-qp "form_template_type" $form_template_type "scalar") (serialize-qp "employee_name" $employee_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"extended": $extended, "date_from": $date_from, "date_to": $date_to, "show": $show, "project_id": $project_id, "created_by_id": $created_by_id, "form_template_id": $form_template_id, "form_template_type": $form_template_type, "employee_name": $employee_name} | compact), body: null}
}

# Add new form
#
# POST /forms
export def "forms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  form_template_id: string # format: uuid
  project_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forms")
  let req_body = {"form_template_id": $form_template_id, "project_id": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Undelete form and related entities to it
#
# GET /forms/undelete/{form_id}
export def "forms-undelete get" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/undelete/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate time form pdf
#
# GET /forms/view_time_form_pdf/{form_id}
export def "forms-view-time-form-pdf get" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/view_time_form_pdf/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a form
#
# DELETE /forms/{form_id}
export def "forms delete" [
  form_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View form
#
# GET /forms/{form_id}
export def "forms get" [
  form_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<approved_by_id: string, company_id: string, created: string, created_by_id: string, deleted: string, form_date: string, form_template_id: string, id: string, is_draft: bool, is_invoiced: string, is_shared: bool, mass_form_id: string, modified: string, project_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a form
#
# PUT /forms/{form_id}
export def "forms update" [
  form_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($form_id | is-empty) { error make --unspanned { msg: "path parameter 'form_id' must be non-empty" } }
  let full_url = (build-url $base ({form_id: (encode-path-segment $form_id)} | format pattern "/forms/{form_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get integrations list
#
# GET /integrations
# operationId: get-integrations-list
export def "integrations get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Authenticate to Billys
#
# POST /integrations/billysAuthenticate
export def "integrations-billys-authenticate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/billysAuthenticate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Force Synchronization with ERP systems
#
# GET /integrations/contactsSync
# operationId: get-integrations-contactsSync
export def "integrations-contacts-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/contactsSync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sync products from erp integration
#
# GET /integrations/productsSync
export def "integrations-products-sync get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/productsSync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View integration details
#
# GET /integrations/{integration_id}
# operationId: get-integrations-view
export def "integrations get-view" [
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($integration_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_id' must be non-empty" } }
  let full_url = (build-url $base ({integration_id: (encode-path-segment $integration_id)} | format pattern "/integrations/{integration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of invoice line text templates
#
# GET /invoice_line_text_template
export def "invoice-line-text-template list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_line_text_template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new invoice line text template
#
# POST /invoice_line_text_template
export def "invoice-line-text-template create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_line_text_template")
  let req_body = {"html": $html, "image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete an invoice line text template
#
# DELETE /invoice_line_text_template/{invoice_line_text_template_id}
export def "invoice-line-text-template delete" [
  invoice_line_text_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_text_template_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_text_template_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_text_template_id: (encode-path-segment $invoice_line_text_template_id)} | format pattern "/invoice_line_text_template/{invoice_line_text_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single invoice line text template
#
# GET /invoice_line_text_template/{invoice_line_text_template_id}
export def "invoice-line-text-template get" [
  invoice_line_text_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, html: string, id: string, image: string, modified: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_text_template_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_text_template_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_text_template_id: (encode-path-segment $invoice_line_text_template_id)} | format pattern "/invoice_line_text_template/{invoice_line_text_template_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an invoice line text template
#
# POST /invoice_line_text_template/{invoice_line_text_template_id}
export def "invoice-line-text-template create-by-invoice-line-text-template-id" [
  invoice_line_text_template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_text_template_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_text_template_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_text_template_id: (encode-path-segment $invoice_line_text_template_id)} | format pattern "/invoice_line_text_template/{invoice_line_text_template_id}"))
  let req_body = {"html": $html, "image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Add invoice line text
#
# POST /invoice_line_texts/
export def "invoice-line-texts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
  invoice_id: string # format: uuid
  --placement: int
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_line_texts/")
  let req_body = {"html": $html, "image": $image, "invoice_id": $invoice_id, "placement": $placement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Edit invoice line text
#
# POST /invoice_line_texts/{invoice_line_text_id}
export def "invoice-line-texts create-by-invoice-line-text-id" [
  invoice_line_text_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  html: string
  --image: string # format: binary
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_text_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_text_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_text_id: (encode-path-segment $invoice_line_text_id)} | format pattern "/invoice_line_texts/{invoice_line_text_id}"))
  let req_body = {"html": $html, "image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# View list of invoice lines
#
# GET /invoice_lines
export def "invoice-lines list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --invoice-id: string # format: uuid
  --product-id: string # format: uuid
  --user-id: string # format: uuid
  --name: string
  --discount-text: string
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "invoice_id" $invoice_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "discount_text" $discount_text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoice_lines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"invoice_id": $invoice_id, "product_id": $product_id, "user_id": $user_id, "name": $name, "discount_text": $discount_text} | compact), body: null}
}

# Add invoice line
#
# POST /invoice_lines
export def "invoice-lines create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --child-invoice-lines: list
  --description: string
  --discount-percent: int # format: int32
  --discount-text: string
  --invoice-id: string # format: uuid
  --name: string
  --product-bundle-id: string # format: uuid
  --product-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --user-id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice_lines")
  let req_body = {"child_invoice_lines": $child_invoice_lines, "description": $description, "discount_percent": $discount_percent, "discount_text": $discount_text, "invoice_id": $invoice_id, "name": $name, "product_bundle_id": $product_bundle_id, "product_id": $product_id, "quantity": $quantity, "selling_price": $selling_price, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete invoice line
#
# DELETE /invoice_lines/{invoice_line_id}
export def "invoice-lines delete" [
  invoice_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_id: (encode-path-segment $invoice_line_id)} | format pattern "/invoice_lines/{invoice_line_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View invoice line
#
# GET /invoice_lines/{invoice_line_id}
export def "invoice-lines get" [
  invoice_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, discount_text: string, ean_product_id: string, form_id: string, id: string, invoice_id: string, material_id: string, modified: string, name: string, parent_id: string, product_bundle_id: string, product_id: string, quantity: int, selling_price: float, type: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_id: (encode-path-segment $invoice_line_id)} | format pattern "/invoice_lines/{invoice_line_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit invoice line
#
# PUT /invoice_lines/{invoice_line_id}
export def "invoice-lines update" [
  invoice_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --discount-percent: int # format: int32
  --discount-text: string
  --invoice-id: string # format: uuid
  --name: string
  --product-id: string # format: uuid
  --quantity: int # format: int32
  --selling-price: float # format: float
  --user-id: string # format: uuid
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_line_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_line_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_line_id: (encode-path-segment $invoice_line_id)} | format pattern "/invoice_lines/{invoice_line_id}"))
  let req_body = {"description": $description, "discount_percent": $discount_percent, "discount_text": $discount_text, "invoice_id": $invoice_id, "name": $name, "product_id": $product_id, "quantity": $quantity, "selling_price": $selling_price, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View list of invoices
#
# GET /invoices
export def "invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Used to filter on the `contact_id` of the invoices (format: uuid)
  --project-id: string # Used to filter on the `project_id` of the invoices (format: uuid)
  --invoice-number: string # Used to filter on the `invoice_number` of the invoices
  --offer-number: string
  --is-draft: int@is-draft-completer
  --is-offer: int@is-offer-completer
  --is-locked: int@is-locked-completer
  --is-fixed-price: int@is-fixed-price-completer
  --date-from: string # format: date
  --date-to: string # format: date
  --issued-date: string # format: date
  --sent-as-draft: int # Used to filter invoices which are sent as draft to integration
]: nothing -> record<data: table<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "invoice_number" $invoice_number "scalar") (serialize-qp "offer_number" $offer_number "scalar") (serialize-qp "is_draft" $is_draft "scalar") (serialize-qp "is_offer" $is_offer "scalar") (serialize-qp "is_locked" $is_locked "scalar") (serialize-qp "is_fixed_price" $is_fixed_price "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "issued_date" $issued_date "scalar") (serialize-qp "sent_as_draft" $sent_as_draft "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"contact_id": $contact_id, "project_id": $project_id, "invoice_number": $invoice_number, "offer_number": $offer_number, "is_draft": $is_draft, "is_offer": $is_offer, "is_locked": $is_locked, "is_fixed_price": $is_fixed_price, "date_from": $date_from, "date_to": $date_to, "issued_date": $issued_date, "sent_as_draft": $sent_as_draft} | compact), body: null}
}

# Add invoice
#
# POST /invoices
export def "invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --created-or-modified-gte: string # format: date
  --date-from: string # format: date
  --date-to: string # format: date
  --erp-id: string
  --erp-payment-term-id: string
  --invoice-number: int # format: int32
  --is-draft: oneof<nothing, bool>
  --is-locked: oneof<nothing, bool>
  --is-offer: oneof<nothing, bool>
  --issued-date: string # format: date
  --message: string
  --offer-number: int # format: int32
  --payment-due-date: string # format: date
  --payment-term-id: string # format: uuid
  --project-id: string # format: uuid
  --reference: string
  --vat-percent: int # format: int32
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices")
  let req_body = {"contact_id": $contact_id, "created_or_modified_gte": $created_or_modified_gte, "date_from": $date_from, "date_to": $date_to, "erp_id": $erp_id, "erp_payment_term_id": $erp_payment_term_id, "invoice_number": $invoice_number, "is_draft": $is_draft, "is_locked": $is_locked, "is_offer": $is_offer, "issued_date": $issued_date, "message": $message, "offer_number": $offer_number, "payment_due_date": $payment_due_date, "payment_term_id": $payment_term_id, "project_id": $project_id, "reference": $reference, "vat_percent": $vat_percent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete invoices
#
# DELETE /invoices/bulkDelete
# operationId: bulkDeleteInvoices
export def "invoices-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List VAT options
#
# GET /invoices/vatOptions
export def "invoices-vat-options get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoices/vatOptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete invoice
#
# DELETE /invoices/{invoice_id}
export def "invoices delete" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View invoice
#
# GET /invoices/{invoice_id}
export def "invoices get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<all_products_one_line: bool, all_working_hours_one_line: bool, company_id: string, contact_id: string, created: string, created_by_id: string, currency_id: string, date_from: string, date_to: string, deleted: string, downloaded: string, erp_id: string, erp_payment_term_id: string, eu_customer: bool, gross_payment: float, group_by_forms: bool, id: string, include_invoiced_lines: bool, integration_id: string, invoice_number: int, is_draft: bool, is_final_invoice: bool, is_locked: bool, is_offer: bool, issued_date: string, message: string, modified: string, net_payment: float, offer_number: int, order_line_group_id: string, payment_due_date: string, payment_term_id: string, project_id: string, project_overview_attached: bool, reference: string, show_employee_name: bool, show_price_product_bundle: bool, show_prices_products_and_hours: bool, show_product_images: bool, show_products_product_bundle: bool, title: string, total_cost_price: float, total_discount_percent: float, vat_percent: int, vendor_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit invoice
#
# PUT /invoices/{invoice_id}
export def "invoices update" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --date-from: string # format: date
  --date-to: string # format: date
  --erp-id: string
  --erp-payment-term-id: string
  --invoice-number: int # format: int32
  --is-draft: oneof<nothing, bool>
  --is-locked: oneof<nothing, bool>
  --is-offer: oneof<nothing, bool>
  --issued-date: string # format: date
  --message: string
  --offer-number: int # format: int32
  --payment-due-date: string # format: date
  --payment-term-id: string # format: uuid
  --project-id: string # format: uuid
  --reference: string
  --vat-percent: int # format: int32
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}"))
  let req_body = {"contact_id": $contact_id, "date_from": $date_from, "date_to": $date_to, "erp_id": $erp_id, "erp_payment_term_id": $erp_payment_term_id, "invoice_number": $invoice_number, "is_draft": $is_draft, "is_locked": $is_locked, "is_offer": $is_offer, "issued_date": $issued_date, "message": $message, "offer_number": $offer_number, "payment_due_date": $payment_due_date, "payment_term_id": $payment_term_id, "project_id": $project_id, "reference": $reference, "vat_percent": $vat_percent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a copy of an invoice
#
# POST /invoices/{invoice_id}/copy
export def "invoices-copy create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # format: uuid
  --contact-id: string # format: uuid
]: nothing -> record<data: record<id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let qp = [(serialize-qp "project_id" $project_id "scalar") (serialize-qp "contact_id" $contact_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}/copy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"project_id": $project_id, "contact_id": $contact_id} | compact), body: null}
}

# Get an invoice emails
#
# GET /invoices/{invoice_id}/emails/{email_id}
# operationId: getOneInvoiceEmails
export def "invoices-emails get-one" [
  invoice_id: string
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<api_response: string, body: string, carbon_copy: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_sent: bool, modified: string, recipients: string, reply_to: string, subject: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'email_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), email_id: (encode-path-segment $email_id)} | format pattern "/invoices/{invoice_id}/emails/{email_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of invoice files
#
# GET /invoices/{invoice_id}/files
# operationId: getInvoiceFiles
export def "invoices-files get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new invoice file
#
# POST /invoices/{invoice_id}/files
# operationId: createInvoiceFile
export def "invoices-files create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # format: uuid
  --body-invoice-id: string # format: uuid
  --type: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}/files"))
  let req_body = {"file_id": $file_id, "invoice_id": $body_invoice_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete invoice file
#
# DELETE /invoices/{invoice_id}/files/{file_id}
export def "invoices-files delete" [
  invoice_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), file_id: (encode-path-segment $file_id)} | format pattern "/invoices/{invoice_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an invoice files
#
# GET /invoices/{invoice_id}/files/{file_id}
# operationId: getOneInvoiceFiles
export def "invoices-files get-one" [
  invoice_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, deleted: string, file_id: string, id: string, invoice_id: string, modified: string, type: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), file_id: (encode-path-segment $file_id)} | format pattern "/invoices/{invoice_id}/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates an invoice file containing the project's pdf overview
#
# POST /invoices/{invoice_id}/linkProjectPdf
export def "invoices-link-project-pdf create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}/linkProjectPdf"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deletes the linked project overview pdf
#
# POST /invoices/{invoice_id}/unlinkProjectPdf
export def "invoices-unlink-project-pdf create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoice_id' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/invoices/{invoice_id}/unlinkProjectPdf"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of mass messages for specific user
#
# GET /mass_messages_users
export def "mass-messages-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-read: oneof<nothing, bool> # Used to filter on the `is_read` of the mass messages
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_read" $is_read "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mass_messages_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"is_read": $is_read} | compact), body: null}
}

# View mass message
#
# GET /mass_messages_users/{mass_messages_user_id}
export def "mass-messages-users get" [
  mass_messages_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, id: string, is_read: bool, is_sent_email: bool, mass_message: record<company_id: string, content: string, created: string, created_by_id: string, deleted: string, id: string, modified: string>, mass_message_id: string, modified: string, modified_by_id: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($mass_messages_user_id | is-empty) { error make --unspanned { msg: "path parameter 'mass_messages_user_id' must be non-empty" } }
  let full_url = (build-url $base ({mass_messages_user_id: (encode-path-segment $mass_messages_user_id)} | format pattern "/mass_messages_users/{mass_messages_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit mass message
#
# PUT /mass_messages_users/{mass_messages_user_id}
export def "mass-messages-users update" [
  mass_messages_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($mass_messages_user_id | is-empty) { error make --unspanned { msg: "path parameter 'mass_messages_user_id' must be non-empty" } }
  let full_url = (build-url $base ({mass_messages_user_id: (encode-path-segment $mass_messages_user_id)} | format pattern "/mass_messages_users/{mass_messages_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of all materials
#
# GET /materials
export def "materials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string # Used to filter on the `barcode` of the materials
  --name: string # Used to filter on the `name` of the materials
  --project-id: string # Used to find materials used in specific project by `project_id` (format: uuid)
  --currently-rented: oneof<nothing, bool> # Used to find currently rented materials
]: nothing -> record<data: table<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "barcode" $barcode "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "currently_rented" $currently_rented "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/materials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"barcode": $barcode, "name": $name, "project_id": $project_id, "currently_rented": $currently_rented} | compact), body: null}
}

# Add material
#
# POST /materials
export def "materials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string
  --billing-cysle: string@billing-cysle-completer
  --cost-price: float # format: float
  --description: string
  --is-single-usage: oneof<nothing, bool>
  --name: string
  --selling-price: float # format: float
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/materials")
  let req_body = {"barcode": $barcode, "billing_cysle": $billing_cysle, "cost_price": $cost_price, "description": $description, "is_single_usage": $is_single_usage, "name": $name, "selling_price": $selling_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete material
#
# DELETE /materials/{material_id}
export def "materials delete" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View material
#
# GET /materials/{material_id}
export def "materials get" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<barcode: string, billing_cycle: string, centiga_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, description: string, id: string, is_single_usage: bool, modified: string, modified_by_id: string, name: string, pogo_id: string, selling_price: float, tripletex_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit material
#
# PUT /materials/{material_id}
export def "materials update" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of rentals for specific material
#
# GET /materials/{material_id}/rentals/
export def "materials-rentals list" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}/rentals/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add material rental
#
# POST /materials/{material_id}/rentals/
export def "materials-rentals create" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-date: string # format: dateTime
  --is-invoiced: string # format: dateTime
  --body-material-id: string # format: uuid
  --project-id: string # format: uuid
  --quantity: float # format: float
  --to-date: string # format: dateTime
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}/rentals/"))
  let req_body = {"form_id": $form_id, "from_date": $from_date, "is_invoiced": $is_invoiced, "material_id": $body_material_id, "project_id": $project_id, "quantity": $quantity, "to_date": $to_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Checkout material rental
#
# POST /materials/{material_id}/rentals/checkout/
export def "materials-rentals-checkout create" [
  material_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --material-rental-id: string # format: uuid
  --to-date: string # format: dateTime
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id)} | format pattern "/materials/{material_id}/rentals/checkout/"))
  let req_body = {"form_id": $form_id, "material_rental_id": $material_rental_id, "to_date": $to_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete material rental
#
# DELETE /materials/{material_id}/rentals/{material_rental_id}/
export def "materials-rentals delete" [
  material_id: string
  material_rental_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  if ($material_rental_id | is-empty) { error make --unspanned { msg: "path parameter 'material_rental_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id), material_rental_id: (encode-path-segment $material_rental_id)} | format pattern "/materials/{material_id}/rentals/{material_rental_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show rental foor materi
#
# GET /materials/{material_id}/rentals/{material_rental_id}/
export def "materials-rentals get" [
  material_id: string
  material_rental_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<amount: float, created: string, created_by_id: string, deleted: string, from_date: string, id: string, is_invoiced: string, material_id: string, modified: string, modified_by_id: string, project_id: string, quantity: float, to_date: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  if ($material_rental_id | is-empty) { error make --unspanned { msg: "path parameter 'material_rental_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id), material_rental_id: (encode-path-segment $material_rental_id)} | format pattern "/materials/{material_id}/rentals/{material_rental_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit material rental
#
# PUT /materials/{material_id}/rentals/{material_rental_id}/
export def "materials-rentals update" [
  material_id: string
  material_rental_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($material_id | is-empty) { error make --unspanned { msg: "path parameter 'material_id' must be non-empty" } }
  if ($material_rental_id | is-empty) { error make --unspanned { msg: "path parameter 'material_rental_id' must be non-empty" } }
  let full_url = (build-url $base ({material_id: (encode-path-segment $material_id), material_rental_id: (encode-path-segment $material_rental_id)} | format pattern "/materials/{material_id}/rentals/{material_rental_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of offer statuses
#
# GET /offer_statuses
export def "offer-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offer_statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new offer status
#
# POST /offer_statuses
export def "offer-statuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # format: uuid
  --description: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offer_statuses")
  let req_body = {"company_id": $company_id, "description": $description, "identifier": $identifier, "is_custom": $is_custom, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete offer statuses
#
# DELETE /offer_statuses/bulkDelete
export def "offer-statuses-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offer_statuses/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a offer status
#
# DELETE /offer_statuses/{offer_status_id}
export def "offer-statuses delete" [
  offer_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_status_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_status_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_status_id: (encode-path-segment $offer_status_id)} | format pattern "/offer_statuses/{offer_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single offer status
#
# GET /offer_statuses/{offer_status_id}
export def "offer-statuses get" [
  offer_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, modified_by_id: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_status_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_status_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_status_id: (encode-path-segment $offer_status_id)} | format pattern "/offer_statuses/{offer_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a offer status
#
# PUT /offer_statuses/{offer_status_id}
export def "offer-statuses update" [
  offer_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_status_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_status_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_status_id: (encode-path-segment $offer_status_id)} | format pattern "/offer_statuses/{offer_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of offers
#
# GET /offers
export def "offers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add new offer
#
# POST /offers
export def "offers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offer-lines: list
  --project-id: string # format: uuid
  --status: string@status-completer-1 # default: draft
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/offers")
  let req_body = {"offer_lines": $offer_lines, "project_id": $project_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an offer
#
# DELETE /offers/{offer_id}
export def "offers delete" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_id: (encode-path-segment $offer_id)} | format pattern "/offers/{offer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View offer
#
# GET /offers/{offer_id}
export def "offers get" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_id: (encode-path-segment $offer_id)} | format pattern "/offers/{offer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an offer
#
# PUT /offers/{offer_id}
export def "offers update" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # default: draft
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_id: (encode-path-segment $offer_id)} | format pattern "/offers/{offer_id}"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get list of changelog history for the offer. Returns offer object with contact and user objects if they are provided
#
# GET /offers/{offer_id}/changelog
export def "offers-changelog get" [
  offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<address: string, all_lines_one_line: bool, all_products_one_line: bool, all_working_hours_one_line: bool, city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, discount_percent: int, erp_payment_term_id: string, expiraton_date: string, id: string, issue_date: string, modified: string, modified_by_id: string, offer_number: int, offer_status_id: string, payment_term_id: string, rejection_reason: string, sender_id: string, show_employee_name: bool, show_offer_lines: bool, show_payment_term: bool, show_prices: bool, show_product_images: bool, show_products_product_bundle: bool, slug: string, status: string, title: string, vat_percent: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($offer_id | is-empty) { error make --unspanned { msg: "path parameter 'offer_id' must be non-empty" } }
  let full_url = (build-url $base ({offer_id: (encode-path-segment $offer_id)} | format pattern "/offers/{offer_id}/changelog"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a statistics data for rejection reasons
#
# GET /overview/rejection_reasons
export def "overview-rejection-reasons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<any>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/overview/rejection_reasons")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of payment term types
#
# GET /payment_term_types
export def "payment-term-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_term_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 payment term type
#
# GET /payment_term_types/{payment_term_type_id}
export def "payment-term-types get" [
  payment_term_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_term_type_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_term_type_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_term_type_id: (encode-path-segment $payment_term_type_id)} | format pattern "/payment_term_types/{payment_term_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of payment terms
#
# GET /payment_terms
export def "payment-terms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_terms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get integration payment terms list
#
# GET /payment_terms/erp
export def "payment-terms-erp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<daysOfCredit: int, id: string, name: string, pretty_string: string, type: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_terms/erp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 payment term
#
# GET /payment_terms/{payment_term_id}
export def "payment-terms get" [
  payment_term_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, days_of_credit: int, deleted: string, id: string, modified: string, payment_term_type_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_term_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_term_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_term_id: (encode-path-segment $payment_term_id)} | format pattern "/payment_terms/{payment_term_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if API is up and API key works
#
# GET /ping
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List products
#
# GET /products
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the products
  --product-number: string # Used to filter on the `product_number` of the products (format: uuid)
  --barcode: string # Used to filter on the `barcode` of the products
  --modified-gte: string # format: datetime
]: nothing -> record<data: table<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "product_number" $product_number "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "modified_gte" $modified_gte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "product_number": $product_number, "barcode": $barcode, "modified_gte": $modified_gte} | compact), body: null}
}

# Add new product
#
# POST /products
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --barcode: string
  --buying-price: float # format: double
  --description: string
  --erp-id: string
  name: string
  --product-number: string
  --selling-price: float # format: double
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let req_body = {"barcode": $barcode, "buying_price": $buying_price, "description": $description, "erp_id": $erp_id, "name": $name, "product_number": $product_number, "selling_price": $selling_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete products
#
# DELETE /products/bulkDelete
# operationId: bulkDeleteProducts
export def "products-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Restore a deleted product
#
# POST /products/undelete/{product_id}
export def "products-undelete create" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/undelete/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a product
#
# DELETE /products/{product_id}
export def "products delete" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View single product
#
# GET /products/{product_id}
export def "products get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<average_cost_price: float, barcode: string, buying_price: float, centiga_id: string, company_id: string, created: string, created_by_id: string, deleted: string, description: string, erp_id: string, id: string, modified: string, name: string, pogo_id: string, product_number: string, project_status_type_id: string, selling_price: float, tripletex_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a product
#
# PUT /products/{product_id}
export def "products update" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload or delete product image
#
# POST /products/{product_id}/uploadImage
# operationId: Upload or delete product image
export def "products-upload-image delete-or" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}/uploadImage"))
  let req_body = {"image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get a product's variants
#
# GET /products/{product_id}/variants
export def "products-variants get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: string, price: float, product_number: string, variant_id: string, variant_type: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}/variants"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new variant to a product
#
# POST /products/{product_id}/variants
export def "products-variants create" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Filters by name
  ratio: float
  variant_id: string # format: uuid
  variant_type: string@variant-type-completer
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/products/{product_id}/variants") $qp)
  let req_body = {"ratio": $ratio, "variant_id": $variant_id, "variant_type": $variant_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: ({"name": $name} | compact), body: $req_body}
}

# Delete a product variant
#
# DELETE /products/{product_id}/variants/{variant_type}/{variant_id}
export def "products-variants delete" [
  product_id: string
  variant_type: string
  variant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  if ($variant_type | is-empty) { error make --unspanned { msg: "path parameter 'variant_type' must be non-empty" } }
  if ($variant_id | is-empty) { error make --unspanned { msg: "path parameter 'variant_id' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), variant_type: (encode-path-segment $variant_type), variant_id: (encode-path-segment $variant_id)} | format pattern "/products/{product_id}/variants/{variant_type}/{variant_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of project custom field attributes
#
# GET /project_custom_field_attributes
export def "project-custom-field-attributes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_custom_field_attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 project custom field attribute
#
# GET /project_custom_field_attributes/{project_custom_field_attribute_id}
export def "project-custom-field-attributes get" [
  project_custom_field_attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_custom_field_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'project_custom_field_attribute_id' must be non-empty" } }
  let full_url = (build-url $base ({project_custom_field_attribute_id: (encode-path-segment $project_custom_field_attribute_id)} | format pattern "/project_custom_field_attributes/{project_custom_field_attribute_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of project status types
#
# GET /project_status_types
export def "project-status-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<_locale: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_status_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of project statuses
#
# GET /project_statuses
export def "project-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new project status
#
# POST /project_statuses
export def "project-statuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  --name: string
  --project-status-type-id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_statuses")
  let req_body = {"description": $description, "name": $name, "project_status_type_id": $project_status_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add default project statuses to company
#
# POST /project_statuses/add_default
export def "project-statuses-add-default create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_statuses/add_default")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Bulk delete project statuses
#
# DELETE /project_statuses/bulkDelete
export def "project-statuses-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/project_statuses/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project status
#
# DELETE /project_statuses/{project_status_id}
export def "project-statuses delete" [
  project_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_status_id | is-empty) { error make --unspanned { msg: "path parameter 'project_status_id' must be non-empty" } }
  let full_url = (build-url $base ({project_status_id: (encode-path-segment $project_status_id)} | format pattern "/project_statuses/{project_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single project status
#
# GET /project_statuses/{project_status_id}
export def "project-statuses get" [
  project_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_status_id | is-empty) { error make --unspanned { msg: "path parameter 'project_status_id' must be non-empty" } }
  let full_url = (build-url $base ({project_status_id: (encode-path-segment $project_status_id)} | format pattern "/project_statuses/{project_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a project status
#
# PUT /project_statuses/{project_status_id}
export def "project-statuses update" [
  project_status_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_status_id | is-empty) { error make --unspanned { msg: "path parameter 'project_status_id' must be non-empty" } }
  let full_url = (build-url $base ({project_status_id: (encode-path-segment $project_status_id)} | format pattern "/project_statuses/{project_status_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of projects
#
# GET /projects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-all: oneof<nothing, bool> # Unless this is set to `true` only open projects will be shown (default: false)
  --qp-sort: string # Sort projects by `not_invoiced_amount`
  --direction: string
  --contact-id: string # Used to filter on the `contact_id` of the projects (format: uuid)
  --company-id: string # Used to filter on the `company_id` of the projects (format: uuid)
  --project-status-id: string # Used to filter on the `project_status_id` of the projects (format: uuid)
  --project-status-ids: list<string> # Used to filter on the `project_status_id` of the projects (match any of the provided values)
  --name: string # Used to search on the `name` of the projects
  --erp-project-id: string # Used to search on the `erp_project_id` of the projects
  --erp-task-id: string # Used to search on the `erp_task_id` of the projects
  --start-time-gte: string # Show projects with start time after than this value
  --start-time-lte: string # Show projects with start time before this value
  --start-time-eq: string # Show only projects with start time on specific date
  --event-start-gt: string # format: datetime
  --event-start-lt: string # format: datetime
  --event-start-eq: string # format: datetime
  --event-end-gt: string # format: datetime
  --event-end-lt: string # format: datetime
  --event-end-eq: string # format: datetime
]: nothing -> record<data: table<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_all" $show_all "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "company_id" $company_id "scalar") (serialize-qp "project_status_id" $project_status_id "scalar") (serialize-qp "project_status_ids" $project_status_ids "csv") (serialize-qp "name" $name "scalar") (serialize-qp "erp_project_id" $erp_project_id "scalar") (serialize-qp "erp_task_id" $erp_task_id "scalar") (serialize-qp "start_time_gte" $start_time_gte "scalar") (serialize-qp "start_time_lte" $start_time_lte "scalar") (serialize-qp "start_time_eq" $start_time_eq "scalar") (serialize-qp "event_start[][gt]" $event_start_gt "scalar") (serialize-qp "event_start[][lt]" $event_start_lt "scalar") (serialize-qp "event_start[][eq]" $event_start_eq "scalar") (serialize-qp "event_end[][gt]" $event_end_gt "scalar") (serialize-qp "event_end[][lt]" $event_end_lt "scalar") (serialize-qp "event_end[][eq]" $event_end_eq "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_all": $show_all, "sort": $qp_sort, "direction": $direction, "contact_id": $contact_id, "company_id": $company_id, "project_status_id": $project_status_id, "project_status_ids": $project_status_ids, "name": $name, "erp_project_id": $erp_project_id, "erp_task_id": $erp_task_id, "start_time_gte": $start_time_gte, "start_time_lte": $start_time_lte, "start_time_eq": $start_time_eq, "event_start[][gt]": $event_start_gt, "event_start[][lt]": $event_start_lt, "event_start[][eq]": $event_start_eq, "event_end[][gt]": $event_end_gt, "event_end[][lt]": $event_end_lt, "event_end[][eq]": $event_end_eq} | compact), body: null}
}

# Add a project
#
# POST /projects
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --child-projects: list
  --city-id: string # format: uuid
  --contact-id: string # format: uuid
  --description: string
  --erp-project-id: string
  --erp-task-id: string
  name: string
  --parent-id: string # format: uuid
  --project-status-id: string # format: uuid
  --start-time: string # format: datetime
  --street-name: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = {"child_projects": $child_projects, "city_id": $city_id, "contact_id": $contact_id, "description": $description, "erp_project_id": $erp_project_id, "erp_task_id": $erp_task_id, "name": $name, "parent_id": $parent_id, "project_status_id": $project_status_id, "start_time": $start_time, "street_name": $street_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check if the company has projects with custom statuses
#
# GET /projects/has_projects_with_custom_statuses
export def "projects-has-projects-with-custom-statuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<has_custom_statuses: bool, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects/has_projects_with_custom_statuses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a project
#
# DELETE /projects/{project_id}
export def "projects delete" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View specific project
#
# GET /projects/{project_id}
export def "projects get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<city_id: string, company_id: string, contact_id: string, created: string, created_by_id: string, deleted: string, description: string, end_time: string, erp_project_id: string, erp_task_id: string, full_name: string, has_final_invoice: bool, id: string, is_fixed_price: bool, is_offer: string, is_rotten: string, latitude: string, longitude: string, modified: string, name: string, not_invoiced_amount: float, offer_id: string, parent_id: string, pre_calculation_id: string, products_total_cost_price: float, project_image_url: string, project_number: float, project_status_id: string, shared_project_id: string, start_time: string, street_name: string, thumbnail: string, total_sales_price: float, working_hours_total_cost_price: float>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a project
#
# PUT /projects/{project_id}
export def "projects update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # format: uuid
  --description: string
  --erp-project-id: string
  --erp-task-id: string
  name: string
  --project-status-id: string # format: uuid
  --start-time: string # format: datetime
  --street-name: string
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let req_body = {"contact_id": $contact_id, "description": $description, "erp_project_id": $erp_project_id, "erp_task_id": $erp_task_id, "name": $name, "project_status_id": $project_status_id, "start_time": $start_time, "street_name": $street_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Show list of all files uploaded to project
#
# GET /projects/{project_id}/all_files
export def "projects-all-files get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/all_files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of files uploaded to project
#
# GET /projects/{project_id}/files
export def "projects-files list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete file
#
# DELETE /projects/{project_id}/files/{file_id}/
export def "projects-files delete" [
  project_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), file_id: (encode-path-segment $file_id)} | format pattern "/projects/{project_id}/files/{file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show file
#
# GET /projects/{project_id}/files/{file_id}/
export def "projects-files get" [
  project_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), file_id: (encode-path-segment $file_id)} | format pattern "/projects/{project_id}/files/{file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit file
#
# PUT /projects/{project_id}/files/{file_id}/
export def "projects-files update" [
  project_id: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), file_id: (encode-path-segment $file_id)} | format pattern "/projects/{project_id}/files/{file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show list of project files uploaded to project
#
# GET /projects/{project_id}/project_files
export def "projects-project-files list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/project_files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add project file to projects
#
# POST /projects/{project_id}/project_files
export def "projects-project-files create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # format: binary
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/project_files"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete project file
#
# DELETE /projects/{project_id}/project_files/{project_file_id}/
export def "projects-project-files delete" [
  project_id: string
  project_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($project_file_id | is-empty) { error make --unspanned { msg: "path parameter 'project_file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), project_file_id: (encode-path-segment $project_file_id)} | format pattern "/projects/{project_id}/project_files/{project_file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Show project file
#
# GET /projects/{project_id}/project_files/{project_file_id}/
export def "projects-project-files get" [
  project_id: string
  project_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($project_file_id | is-empty) { error make --unspanned { msg: "path parameter 'project_file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), project_file_id: (encode-path-segment $project_file_id)} | format pattern "/projects/{project_id}/project_files/{project_file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit project file
#
# PUT /projects/{project_id}/project_files/{project_file_id}/
export def "projects-project-files update" [
  project_id: string
  project_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($project_file_id | is-empty) { error make --unspanned { msg: "path parameter 'project_file_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), project_file_id: (encode-path-segment $project_file_id)} | format pattern "/projects/{project_id}/project_files/{project_file_id}/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send bulk forms pdf by email
#
# POST /projects/{project_id}/send_bulk_pdf
export def "projects-send-bulk-pdf create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/send_bulk_pdf"))
  let req_body = {"form_id": $form_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Show list of users added to project
#
# GET /projects/{project_id}/users/
export def "projects-users list" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/users/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add user to project
#
# POST /projects/{project_id}/users/
export def "projects-users create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/users/"))
  let req_body = {"user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete user from project
#
# DELETE /projects/{project_id}/users/{user_id}
export def "projects-users delete" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), user_id: (encode-path-segment $user_id)} | format pattern "/projects/{project_id}/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View specific user assigned to project
#
# GET /projects/{project_id}/users/{user_id}
export def "projects-users get" [
  project_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), user_id: (encode-path-segment $user_id)} | format pattern "/projects/{project_id}/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of report types
#
# GET /reports
export def "reports get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of roles
#
# GET /roles
export def "roles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List stock_locations
#
# GET /stock_locations
export def "stock-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the stock_locations
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stock_locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name} | compact), body: null}
}

# Add new stock_locations
#
# POST /stock_locations
export def "stock-locations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stock_locations")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete location
#
# DELETE /stock_locations/{location_id}
export def "stock-locations delete" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/stock_locations/{location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View single location
#
# GET /stock_locations/{location_id}
export def "stock-locations get" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/stock_locations/{location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit location
#
# PUT /stock_locations/{location_id}
export def "stock-locations update" [
  location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($location_id | is-empty) { error make --unspanned { msg: "path parameter 'location_id' must be non-empty" } }
  let full_url = (build-url $base ({location_id: (encode-path-segment $location_id)} | format pattern "/stock_locations/{location_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List time entries
#
# GET /time_entries
export def "time-entries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
  --form-id: string
  --project-id: string
  --gt-from-time: string
  --lt-from-time: string
  --gt-to-time: string
  --lt-to-time: string
  --lt-sum: string
  --gt-sum: string
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "form_id" $form_id "scalar") (serialize-qp "project_id" $project_id "scalar") (serialize-qp "gt_from_time" $gt_from_time "scalar") (serialize-qp "lt_from_time" $lt_from_time "scalar") (serialize-qp "gt_to_time" $gt_to_time "scalar") (serialize-qp "lt_to_time" $lt_to_time "scalar") (serialize-qp "lt_sum" $lt_sum "scalar") (serialize-qp "gt_sum" $gt_sum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time_entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"user_id": $user_id, "form_id": $form_id, "project_id": $project_id, "gt_from_time": $gt_from_time, "lt_from_time": $lt_from_time, "gt_to_time": $gt_to_time, "lt_to_time": $lt_to_time, "lt_sum": $lt_sum, "gt_sum": $gt_sum} | compact), body: null}
}

# Add new time entry
#
# POST /time_entries
export def "time-entries create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-time: string # format: dateTime
  --is-all-day: oneof<nothing, bool>
  --project-id: string # format: uuid
  --sum: int # Amount of seconds - should only be included when using is_all_day, otherwise will be calculated from from_time and to_time (format: int32)
  time_entry_type_id: string # format: uuid
  --to-time: string # format: dateTime
  user_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entries")
  let req_body = {"form_id": $form_id, "from_time": $from_time, "is_all_day": $is_all_day, "project_id": $project_id, "sum": $sum, "time_entry_type_id": $time_entry_type_id, "to_time": $to_time, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete time entry
#
# DELETE /time_entries/{time_entry_id}
export def "time-entries delete" [
  time_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_id: (encode-path-segment $time_entry_id)} | format pattern "/time_entries/{time_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry
#
# GET /time_entries/{time_entry_id}
export def "time-entries get" [
  time_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, form_id: string, from_time: string, id: string, is_all_day: bool, modified: string, modified_by_id: string, project_id: string, sum: int, time_entry_type_id: string, to_time: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_id: (encode-path-segment $time_entry_id)} | format pattern "/time_entries/{time_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit time entry
#
# PUT /time_entries/{time_entry_id}
export def "time-entries update" [
  time_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_id: (encode-path-segment $time_entry_id)} | format pattern "/time_entries/{time_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List possible time entry intervals
#
# GET /time_entry_intervals
export def "time-entry-intervals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_intervals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry interval
#
# GET /time_entry_intervals/{time_entry_interval_id}
export def "time-entry-intervals get" [
  time_entry_interval_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_interval_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_interval_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_interval_id: (encode-path-segment $time_entry_interval_id)} | format pattern "/time_entry_intervals/{time_entry_interval_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List time entry rates
#
# GET /time_entry_rates
export def "time-entry-rates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add new time entry rate
#
# POST /time_entry_rates
export def "time-entry-rates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --form-id: string # format: uuid
  --from-time: string # format: dateTime
  --is-all-day: oneof<nothing, bool>
  --project-id: string # format: uuid
  --sum: int # Amount of seconds - should only be included when using is_all_day, otherwise will be calculated from from_time and to_time (format: int32)
  time_entry_type_id: string # format: uuid
  --to-time: string # format: dateTime
  user_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_rates")
  let req_body = {"form_id": $form_id, "from_time": $from_time, "is_all_day": $is_all_day, "project_id": $project_id, "sum": $sum, "time_entry_type_id": $time_entry_type_id, "to_time": $to_time, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete time entry rate
#
# DELETE /time_entry_rates/{time_entry_rate_id}
export def "time-entry-rates delete" [
  time_entry_rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_rate_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_rate_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_rate_id: (encode-path-segment $time_entry_rate_id)} | format pattern "/time_entry_rates/{time_entry_rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry rate
#
# GET /time_entry_rates/{time_entry_rate_id}
export def "time-entry-rates get" [
  time_entry_rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<amount: float, company_id: string, created: string, created_by_id: string, currency_id: string, deleted: string, id: string, modified: string, modified_by_id: string, selling_amount: float, time_entry_type_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_rate_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_rate_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_rate_id: (encode-path-segment $time_entry_rate_id)} | format pattern "/time_entry_rates/{time_entry_rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit time entry rate
#
# PUT /time_entry_rates/{time_entry_rate_id}
export def "time-entry-rates update" [
  time_entry_rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_rate_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_rate_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_rate_id: (encode-path-segment $time_entry_rate_id)} | format pattern "/time_entry_rates/{time_entry_rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List time entry rule groups
#
# GET /time_entry_rule_groups
export def "time-entry-rule-groups get" [
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
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, id: string, modified: string, modified_by_id: string, name: string, salary_period_days: float, salary_period_from: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time_entry_rule_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# List time entries types
#
# GET /time_entry_types
export def "time-entry-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add new time entry type
#
# POST /time_entry_types
export def "time-entry-types create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
  name: string
  time_entry_interval_id: string # format: uuid
  time_entry_value_type_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_types")
  let req_body = {"description": $description, "name": $name, "time_entry_interval_id": $time_entry_interval_id, "time_entry_value_type_id": $time_entry_value_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk activate time entry types
#
# POST /time_entry_types/bulkActivate
# operationId: bulkActivateTimeEntryTypes
export def "time-entry-types-bulk-activate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_types/bulkActivate")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk deactivate time entry types
#
# POST /time_entry_types/bulkDeactivate
# operationId: bulkDeactivateTimeEntryTypes
export def "time-entry-types-bulk-deactivate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_types/bulkDeactivate")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk delete time entry types
#
# DELETE /time_entry_types/bulkDelete
# operationId: bulkDeleteTimeEntryTypes
export def "time-entry-types-bulk-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_types/bulkDelete")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete time entry type
#
# DELETE /time_entry_types/{time_entry_type_id}
export def "time-entry-types delete" [
  time_entry_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_type_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_type_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_type_id: (encode-path-segment $time_entry_type_id)} | format pattern "/time_entry_types/{time_entry_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry type
#
# GET /time_entry_types/{time_entry_type_id}
export def "time-entry-types get" [
  time_entry_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<company_id: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, modified_by_id: string, name: string, time_entry_interval_id: string, time_entry_value_type_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_type_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_type_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_type_id: (encode-path-segment $time_entry_type_id)} | format pattern "/time_entry_types/{time_entry_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit time entry type
#
# PUT /time_entry_types/{time_entry_type_id}
export def "time-entry-types update" [
  time_entry_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_type_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_type_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_type_id: (encode-path-segment $time_entry_type_id)} | format pattern "/time_entry_types/{time_entry_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List possible time entry unit types
#
# GET /time_entry_unit_types
export def "time-entry-unit-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_unit_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry unit type
#
# GET /time_entry_unit_types/{time_entry_unit_type_id}
export def "time-entry-unit-types get" [
  time_entry_unit_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<abbreviation: string, created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_unit_type_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_unit_type_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_unit_type_id: (encode-path-segment $time_entry_unit_type_id)} | format pattern "/time_entry_unit_types/{time_entry_unit_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List possible time entry value types
#
# GET /time_entry_value_types
export def "time-entry-value-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time_entry_value_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View time entry value type
#
# GET /time_entry_value_types/{time_entry_value_type_id}
export def "time-entry-value-types get" [
  time_entry_value_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, description: string, id: string, identifier: string, modified: string, modified_by_id: string, name: string, time_entry_unit_type_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($time_entry_value_type_id | is-empty) { error make --unspanned { msg: "path parameter 'time_entry_value_type_id' must be non-empty" } }
  let full_url = (build-url $base ({time_entry_value_type_id: (encode-path-segment $time_entry_value_type_id)} | format pattern "/time_entry_value_types/{time_entry_value_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of user custom field attributes
#
# GET /user_custom_field_attributes
export def "user-custom-field-attributes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_custom_field_attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Details of 1 user custom field attribute
#
# GET /user_custom_field_attributes/{user_custom_field_attribute_id}
export def "user-custom-field-attributes get" [
  user_custom_field_attribute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<access_type: string, company_id: string, created: string, created_by_id: string, deleted: string, id: string, is_active: bool, modified: string, name: string, placement: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_custom_field_attribute_id | is-empty) { error make --unspanned { msg: "path parameter 'user_custom_field_attribute_id' must be non-empty" } }
  let full_url = (build-url $base ({user_custom_field_attribute_id: (encode-path-segment $user_custom_field_attribute_id)} | format pattern "/user_custom_field_attributes/{user_custom_field_attribute_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of users in company
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string # Used to filter on the `first_name` of the users
  --last-name: string # Used to filter on the `last_name` of the users
  --email: string # Used to filter on the `email` of the users
  --stock-location-id: string # Used to filter on the `stock_location_id` of the users
  --is-active: oneof<nothing, bool> # Filters active/inactive users
]: nothing -> record<data: table<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first_name" $first_name "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "stock_location_id" $stock_location_id "scalar") (serialize-qp "is_active" $is_active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"first_name": $first_name, "last_name": $last_name, "email": $email, "stock_location_id": $stock_location_id, "is_active": $is_active} | compact), body: null}
}

# Add user to company
#
# POST /users
# --roles shape: {_ids?: list<string>}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city-id: string # format: uuid
  --cost-price: float # Cost of salaries (format: float)
  --email: string # format: email
  --expected-billable-hours: float # format: float
  --extra-price: float # Additional cost on this employee (pension, vacation etc.) (format: float)
  first_name: string
  --hide-address: oneof<nothing, bool>
  --hide-phone: oneof<nothing, bool>
  --initials: string
  --is-active: oneof<nothing, bool>
  --language-id: string # format: uuid
  --last-name: string
  --mobile: string
  --mobile-countrycode: string
  --password: string # format: password
  --phone: string
  --phone-countrycode: string
  --receive-form-mails: oneof<nothing, bool> # If `true` the employee will receive an email receipt of every form submitted
  --roles: record # shape: {_ids?: list<string>}
  --sale-price: float # The price this employee costs per hour when working (format: float)
  --street-name: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"city_id": $city_id, "cost_price": $cost_price, "email": $email, "expected_billable_hours": $expected_billable_hours, "extra_price": $extra_price, "first_name": $first_name, "hide_address": $hide_address, "hide_phone": $hide_phone, "initials": $initials, "is_active": $is_active, "language_id": $language_id, "last_name": $last_name, "mobile": $mobile, "mobile_countrycode": $mobile_countrycode, "password": $password, "phone": $phone, "phone_countrycode": $phone_countrycode, "receive_form_mails": $receive_form_mails, "roles": $roles, "sale_price": $sale_price, "street_name": $street_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Activate multiple users
#
# POST /users/bulkActivate
# operationId: usersBulkActivate
export def "users-bulk-activate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/bulkActivate")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deactivate multiple users
#
# POST /users/bulkDeactivate
# operationId: usersBulkDeactivate
export def "users-bulk-deactivate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string>
]: any -> record<data: list<string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/bulkDeactivate")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend Welcome SMS to the user
#
# GET /users/resendWelcomeSms
export def "users-resend-welcome-sms get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/resendWelcomeSms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete user
#
# DELETE /users/{user_id}
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View user
#
# GET /users/{user_id}
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<api_key: string, city_id: string, company_id: string, cost_price: float, created: string, created_by_id: string, deleted: string, email: string, expected_billable_hours: float, extra_price: float, first_name: string, full_name: string, hide_address: bool, hide_phone: bool, id: string, initials: string, is_active: bool, language_id: string, last_name: string, mobile: string, mobile_countrycode: string, modified: string, password: string, phone: string, phone_countrycode: string, receive_form_mails: bool, sale_price: float, street_name: string, website: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit user
#
# PUT /users/{user_id}
export def "users update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of user integration settings
#
# GET /users/{user_id}/integration_settings
export def "users-integration-settings list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/integration_settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a user integration setting
#
# POST /users/{user_id}/integration_settings
export def "users-integration-settings create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integration-setting-id: string # format: uuid
  --value: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/integration_settings"))
  let req_body = {"integration_setting_id": $integration_setting_id, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a user integration setting
#
# DELETE /users/{user_id}/integration_settings/{integration_settings_user_id}
export def "users-integration-settings delete" [
  user_id: string
  integration_settings_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($integration_settings_user_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_settings_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), integration_settings_user_id: (encode-path-segment $integration_settings_user_id)} | format pattern "/users/{user_id}/integration_settings/{integration_settings_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user integration setting
#
# GET /users/{user_id}/integration_settings/{integration_settings_user_id}
export def "users-integration-settings get" [
  user_id: string
  integration_settings_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, created_by_id: string, deleted: string, id: string, integration_setting_id: string, modified: string, user_id: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($integration_settings_user_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_settings_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), integration_settings_user_id: (encode-path-segment $integration_settings_user_id)} | format pattern "/users/{user_id}/integration_settings/{integration_settings_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a user integration setting
#
# PUT /users/{user_id}/integration_settings/{integration_settings_user_id}
export def "users-integration-settings update" [
  user_id: string
  integration_settings_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($integration_settings_user_id | is-empty) { error make --unspanned { msg: "path parameter 'integration_settings_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), integration_settings_user_id: (encode-path-segment $integration_settings_user_id)} | format pattern "/users/{user_id}/integration_settings/{integration_settings_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a new image to a user
#
# POST /users/{user_id}/uploadImage
export def "users-upload-image create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image: string # format: binary
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/uploadImage"))
  let req_body = {"image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["image"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get a list of user custom field values
#
# GET /users/{user_id}/user_custom_field_value
export def "users-user-custom-field-value list" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/user_custom_field_value"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single record of user custom field value
#
# GET /users/{user_id}/user_custom_field_value/{user_custom_field_value_id}
export def "users-user-custom-field-value get" [
  user_id: string
  user_custom_field_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, created_by_id: string, deleted: string, id: string, modified: string, user_custom_field_attribute_id: string, user_id: string, value: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($user_custom_field_value_id | is-empty) { error make --unspanned { msg: "path parameter 'user_custom_field_value_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), user_custom_field_value_id: (encode-path-segment $user_custom_field_value_id)} | format pattern "/users/{user_id}/user_custom_field_value/{user_custom_field_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a single record of user custom field value
#
# PUT /users/{user_id}/user_custom_field_value/{user_custom_field_value_id}
export def "users-user-custom-field-value update" [
  user_id: string
  user_custom_field_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<any>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($user_custom_field_value_id | is-empty) { error make --unspanned { msg: "path parameter 'user_custom_field_value_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), user_custom_field_value_id: (encode-path-segment $user_custom_field_value_id)} | format pattern "/users/{user_id}/user_custom_field_value/{user_custom_field_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of price files
#
# GET /vendor_product_price_files
export def "vendor-product-price-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-name: string
  --vendor-name: string
  --vendor-ids: list<string>
  --status: string@status-completer-2
]: nothing -> record<data: table<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_name" $file_name "scalar") (serialize-qp "vendor_name" $vendor_name "scalar") (serialize-qp "vendor_ids" $vendor_ids "csv") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vendor_product_price_files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"file_name": $file_name, "vendor_name": $vendor_name, "vendor_ids": $vendor_ids, "status": $status} | compact), body: null}
}

# Upload a vendor price file
#
# POST /vendor_product_price_files
export def "vendor-product-price-files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  companies_vendor_id: string
  file: string # format: binary
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vendor_product_price_files")
  let req_body = {"companies_vendor_id": $companies_vendor_id, "file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Get a single price file
#
# GET /vendor_product_price_files/{vendor_product_price_file_id}
export def "vendor-product-price-files get" [
  vendor_product_price_file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<companies_vendor_id: string, created: string, created_by_id: string, deleted: string, dir: string, file: string, finished: bool, id: string, modified: string, original_file_name: string, progress: int, size: int, status: string, type: string, vendor_products_count: int, vendor_products_count_total: int, download_link: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($vendor_product_price_file_id | is-empty) { error make --unspanned { msg: "path parameter 'vendor_product_price_file_id' must be non-empty" } }
  let full_url = (build-url $base ({vendor_product_price_file_id: (encode-path-segment $vendor_product_price_file_id)} | format pattern "/vendor_product_price_files/{vendor_product_price_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List vendor products
#
# GET /vendor_products
export def "vendor-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Used to filter on the `name` of the vendor products
  --product-number: string # Used to filter on the `product_number` of the vendor products (format: uuid)
  --barcode: string # Used to filter on the `barcode` of the vendor products
  --vendor-id: string # Used to filter on the `vendor_id` of the vendor products
]: nothing -> record<data: table<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "product_number" $product_number "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "vendor_id" $vendor_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vendor_products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "product_number": $product_number, "barcode": $barcode, "vendor_id": $vendor_id} | compact), body: null}
}

# View single vendor product
#
# GET /vendor_products/{vendor_product_id}
export def "vendor-products get" [
  vendor_product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<barcode: string, created: string, created_by_id: string, deleted: string, description: string, id: string, modified: string, name: string, price: float, product_category_number: string, product_number: string, vendor_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($vendor_product_id | is-empty) { error make --unspanned { msg: "path parameter 'vendor_product_id' must be non-empty" } }
  let full_url = (build-url $base ({vendor_product_id: (encode-path-segment $vendor_product_id)} | format pattern "/vendor_products/{vendor_product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of vendors
#
# GET /vendors
# operationId: getVendorsList
export def "vendors get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-custom: oneof<nothing, bool>
  --email: string
  --name: string
  --cvr: string
]: nothing -> record<data: table<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_custom" $with_custom "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "cvr" $cvr "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vendors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with_custom": $with_custom, "email": $email, "name": $name, "cvr": $cvr} | compact), body: null}
}

# Add a new vendor
#
# POST /vendors
# operationId: addVendor
export def "vendors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # format: uuid
  --cvr: string
  --email: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vendors")
  let req_body = {"country_id": $country_id, "cvr": $cvr, "email": $email, "identifier": $identifier, "is_custom": $is_custom, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a vendor
#
# DELETE /vendors/{vendor_id}
export def "vendors delete" [
  vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({vendor_id: (encode-path-segment $vendor_id)} | format pattern "/vendors/{vendor_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a vendor
#
# GET /vendors/{vendor_id}
# operationId: getVendor
export def "vendors get" [
  vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, cvr: string, deleted: string, email: string, id: string, identifier: string, is_custom: bool, modified: string, name: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({vendor_id: (encode-path-segment $vendor_id)} | format pattern "/vendors/{vendor_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a vendor
#
# PUT /vendors/{vendor_id}
# operationId: editVendor
export def "vendors update-edit" [
  vendor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-id: string # format: uuid
  --cvr: string
  --email: string
  --identifier: string
  --is-custom: oneof<nothing, bool>
  --name: string
]: any -> record<data: list<record>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($vendor_id | is-empty) { error make --unspanned { msg: "path parameter 'vendor_id' must be non-empty" } }
  let full_url = (build-url $base ({vendor_id: (encode-path-segment $vendor_id)} | format pattern "/vendors/{vendor_id}"))
  let req_body = {"country_id": $country_id, "cvr": $cvr, "email": $email, "identifier": $identifier, "is_custom": $is_custom, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download salary file
#
# GET /wages/downloadSalaryFile
export def "wages-download-salary-file get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # format: date
  --date-to: string # format: date
  --company-id: string # format: uuid
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wages/downloadSalaryFile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "company_id": $company_id} | compact), body: null}
}

# Add wall comment
#
# POST /wall_comments
export def "wall-comments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
  wall_post_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wall_comments")
  let req_body = {"message": $message, "wall_post_id": $wall_post_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View wall comment
#
# GET /wall_comments/{wall_comment_id}
export def "wall-comments get" [
  wall_comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($wall_comment_id | is-empty) { error make --unspanned { msg: "path parameter 'wall_comment_id' must be non-empty" } }
  let full_url = (build-url $base ({wall_comment_id: (encode-path-segment $wall_comment_id)} | format pattern "/wall_comments/{wall_comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View list of wall posts
#
# GET /wall_posts
export def "wall-posts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: string # format: uuid
  --user-id: string # format: uuid
]: nothing -> record<data: table<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wall_posts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"project_id": $project_id, "user_id": $user_id} | compact), body: null}
}

# Add a wall post
#
# POST /wall_posts
export def "wall-posts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
  project_id: string # format: uuid
]: any -> record<data: record<id: string>, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wall_posts")
  let req_body = {"message": $message, "project_id": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View wall post
#
# GET /wall_posts/{wall_post_id}
export def "wall-posts get" [
  wall_post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created: string, deleted: string, id: string, message: string, modified: string, project_id: string, user_id: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($wall_post_id | is-empty) { error make --unspanned { msg: "path parameter 'wall_post_id' must be non-empty" } }
  let full_url = (build-url $base ({wall_post_id: (encode-path-segment $wall_post_id)} | format pattern "/wall_posts/{wall_post_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# See wall comments to a wall post
#
# GET /wall_posts/{wall_post_id}/wall_comments
export def "wall-posts-wall-comments get" [
  wall_post_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<created: string, deleted: string, id: string, message: string, modified: string, user_id: string, wall_post_id: string>, pagination: record<count: int, current_page: string, has_next_page: bool, has_prev_page: bool, limit: int, page_count: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-token"))
  let base = ($base_url | default $BASE_URL)
  if ($wall_post_id | is-empty) { error make --unspanned { msg: "path parameter 'wall_post_id' must be non-empty" } }
  let full_url = (build-url $base ({wall_post_id: (encode-path-segment $wall_post_id)} | format pattern "/wall_posts/{wall_post_id}/wall_comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
