# Auto-generated client for Crossbrowsertesting.com Screenshot Comparisons API v3.0.0
# Source: https://api.apis.guru/v2/specs/crossbrowsertesting.com/3.0.0/openapi.json
# Auth: --token flag or $env.CROSSBROWSERTESTING_COM_SCREENSHOT_COMPARISONS_API_TOKEN

const BASE_URL = "https://crossbrowsertesting.com/api/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CROSSBROWSERTESTING_COM_SCREENSHOT_COMPARISONS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://crossbrowsertesting.com/api/v3"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "screenshots-comparison-parallel get" } } | get name | first)
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

# Compare Screenshot Test Versions
#
# GET /screenshots/{target_screenshot_test_id}/{target_version_id}/comparison/parallel/{base_version_id}
export def "screenshots-comparison-parallel get" [
  target_screenshot_test_id: int
  target_version_id: int
  base_version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The format of the returned data. Possible values are "json" or "jsonp". (default: json)
  --callback: string # Name of callback method for JSONP requests.
  --tolerance: float # Used as the basis for detecting box model differences in element positioning and dimensions that should be flagged and reported back to the comparison results. The default is 30px which is a good basis for finding notable layout differences. (format: integer 0-100, default: 30)
]: nothing -> table<base: record<screenshot: record>, target: record<comparison: record, screenshot: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($target_screenshot_test_id | is-empty) { error make --unspanned { msg: "path parameter 'target_screenshot_test_id' must be non-empty" } }
  if ($target_version_id | is-empty) { error make --unspanned { msg: "path parameter 'target_version_id' must be non-empty" } }
  if ($base_version_id | is-empty) { error make --unspanned { msg: "path parameter 'base_version_id' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tolerance" $tolerance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({target_screenshot_test_id: (encode-path-segment $target_screenshot_test_id), target_version_id: (encode-path-segment $target_version_id), base_version_id: (encode-path-segment $base_version_id)} | format pattern "/screenshots/{target_screenshot_test_id}/{target_version_id}/comparison/parallel/{base_version_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "callback": $callback, "tolerance": $tolerance} | compact), body: null}
}

# Compare Full Screenshot Test
#
# GET /screenshots/{target_screenshot_test_id}/{target_version_id}/comparison/{base_result_id}
export def "screenshots-comparison list" [
  target_screenshot_test_id: int
  target_version_id: int
  base_result_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The format of the returned data. Possible values are "json" or "jsonp". (default: json)
  --callback: string # Name of callback method for JSONP requests.
  --tolerance: float # Used as the basis for detecting box model differences in element positioning and dimensions that should be flagged and reported back to the comparison results. The default is 30px which is a good basis for finding notable layout differences. (format: integer 0-100, default: 30)
]: nothing -> record<base: record<screenshot: record<screenshot_id: int>>, targets: table<comparison: record, screenshot: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($target_screenshot_test_id | is-empty) { error make --unspanned { msg: "path parameter 'target_screenshot_test_id' must be non-empty" } }
  if ($target_version_id | is-empty) { error make --unspanned { msg: "path parameter 'target_version_id' must be non-empty" } }
  if ($base_result_id | is-empty) { error make --unspanned { msg: "path parameter 'base_result_id' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tolerance" $tolerance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({target_screenshot_test_id: (encode-path-segment $target_screenshot_test_id), target_version_id: (encode-path-segment $target_version_id), base_result_id: (encode-path-segment $base_result_id)} | format pattern "/screenshots/{target_screenshot_test_id}/{target_version_id}/comparison/{base_result_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "callback": $callback, "tolerance": $tolerance} | compact), body: null}
}

# Compare Single Screenshot
#
# GET /screenshots/{target_screenshot_test_id}/{target_version_id}/{target_result_id}/comparison/{base_result_id}
export def "screenshots-comparison get" [
  target_screenshot_test_id: int
  target_version_id: int
  target_result_id: int
  base_result_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # The format of the returned data. Possible values are "json" or "jsonp". (default: json)
  --callback: string # Name of callback method for JSONP requests.
  --tolerance: float # Used as the basis for detecting box model differences in element positioning and dimensions that should be flagged and reported back to the comparison results. The default is 30px which is a good basis for finding notable layout differences. (format: integer 0-100, default: 30)
]: nothing -> record<base: record<screenshot: record<screenshot_id: int>>, target: record<comparison: record<differences: int, elements: list, error: bool, message: string, show_comparisons_public_url: string, show_comparisons_web_url: string, tolerance: int>, screenshot: record<screenshot_id: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($target_screenshot_test_id | is-empty) { error make --unspanned { msg: "path parameter 'target_screenshot_test_id' must be non-empty" } }
  if ($target_version_id | is-empty) { error make --unspanned { msg: "path parameter 'target_version_id' must be non-empty" } }
  if ($target_result_id | is-empty) { error make --unspanned { msg: "path parameter 'target_result_id' must be non-empty" } }
  if ($base_result_id | is-empty) { error make --unspanned { msg: "path parameter 'base_result_id' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "tolerance" $tolerance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({target_screenshot_test_id: (encode-path-segment $target_screenshot_test_id), target_version_id: (encode-path-segment $target_version_id), target_result_id: (encode-path-segment $target_result_id), base_result_id: (encode-path-segment $base_result_id)} | format pattern "/screenshots/{target_screenshot_test_id}/{target_version_id}/{target_result_id}/comparison/{base_result_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "callback": $callback, "tolerance": $tolerance} | compact), body: null}
}
