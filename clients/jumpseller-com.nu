# Auto-generated client for Jumpseller API v1.0.0
# Source: https://api.apis.guru/v2/specs/jumpseller.com/1.0.0/openapi.json
# Auth: --token flag or $env.JUMPSELLER_API_TOKEN

const BASE_URL = "https://api.jumpseller.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JUMPSELLER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.jumpseller.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def fields-completer [] { ["barcode" "brand" "custom_fields" "custom_fields_selects" "description" "name" "option_name" "sku" "variants"] }
def plan-name-completer [] { ["plus" "premium" "pro"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "categories-json get" } } | get name | first)
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

# Retrieve all Categories.
#
# GET /categories.json
export def "categories-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Category.
#
# POST /categories.json
# --category shape: {name?: string, parent_id?: int}
export def "categories-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string, parent_id?: int}
]: any -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories.json" $qp)
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Categories.
#
# GET /categories/count.json
export def "categories-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete an existing Category.
#
# DELETE /categories/{id}.json
export def "categories delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Category.
#
# GET /categories/{id}.json
export def "categories get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Modify an existing Category.
#
# PUT /categories/{id}.json
# --category shape: {name?: string, parent_id?: int}
export def "categories update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string, parent_id?: int}
]: any -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}.json") $qp)
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Checkout Custom Fields.
#
# GET /checkout_custom_fields.json
export def "checkout-custom-fields-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<checkout_custom_field: record<area: string, custom_field_select_options: list, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checkout_custom_fields.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new CheckoutCustomField.
#
# POST /checkout_custom_fields.json
# --checkout_custom_field shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
export def "checkout-custom-fields-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checkout_custom_fields.json" $qp)
  let req_body = {"checkout_custom_field": $checkout_custom_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing CheckoutCustomField.
#
# DELETE /checkout_custom_fields/{id}.json
export def "checkout-custom-fields delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single CheckoutCustomField.
#
# GET /checkout_custom_fields/{id}.json
export def "checkout-custom-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a CheckoutCustomField.
#
# PUT /checkout_custom_fields/{id}.json
# --checkout_custom_field shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
export def "checkout-custom-fields update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list<string>, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let req_body = {"checkout_custom_field": $checkout_custom_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Countries.
#
# GET /countries.json
export def "countries-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/countries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Country information.
#
# GET /countries/{country_code}.json
export def "countries get" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'country_code' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: (encode-path-segment $country_code)} | format pattern "/countries/{country_code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Regions from a single Country.
#
# GET /countries/{country_code}/regions.json
export def "countries-regions-json get" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'country_code' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: (encode-path-segment $country_code)} | format pattern "/countries/{country_code}/regions.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Region information object.
#
# GET /countries/{country_code}/regions/{region_code}.json
export def "countries-regions get" [
  country_code: string
  region_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'country_code' must be non-empty" } }
  if ($region_code | is-empty) { error make --unspanned { msg: "path parameter 'region_code' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: (encode-path-segment $country_code), region_code: (encode-path-segment $region_code)} | format pattern "/countries/{country_code}/regions/{region_code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields.json
export def "custom-fields-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<custom_field: record<id: int, label: string, type: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_fields.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Custom Field.
#
# POST /custom_fields.json
# --custom_field shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
export def "custom-fields-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
]: any -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_fields.json" $qp)
  let req_body = {"custom_field": $custom_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing CustomField.
#
# DELETE /custom_fields/{id}.json
export def "custom-fields delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single CustomField.
#
# GET /custom_fields/{id}.json
export def "custom-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a CustomField.
#
# PUT /custom_fields/{id}.json
# --custom_field shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
export def "custom-fields update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list<string>}
]: any -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_fields/{id}.json") $qp)
  let req_body = {"custom_field": $custom_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields/{id}/select_options.json
export def "custom-fields-select-options-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<custom_field_select_option: record<id: int, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_fields/{id}/select_options.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Custom Field Select Option.
#
# POST /custom_fields/{id}/select_options.json
# --custom_field_select_option shape: {value?: string}
export def "custom-fields-select-options-json create" [
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
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> record<custom_field_select_option: record<id: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/custom_fields/{id}/select_options.json") $qp)
  let req_body = {"custom_field_select_option": $custom_field_select_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing CustomFieldSelectOption.
#
# DELETE /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
export def "custom-fields-select-options delete" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($custom_field_select_option_id | is-empty) { error make --unspanned { msg: "path parameter 'custom_field_select_option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), custom_field_select_option_id: (encode-path-segment $custom_field_select_option_id)} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single SelectOption from a CustomField.
#
# GET /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
export def "custom-fields-select-options get" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<custom_field_select_option: record<id: int, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($custom_field_select_option_id | is-empty) { error make --unspanned { msg: "path parameter 'custom_field_select_option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), custom_field_select_option_id: (encode-path-segment $custom_field_select_option_id)} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a SelectOption from a CustomField.
#
# PUT /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
# --custom_field_select_option shape: {value?: string}
export def "custom-fields-select-options update" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> record<custom_field_select_option: record<id: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($custom_field_select_option_id | is-empty) { error make --unspanned { msg: "path parameter 'custom_field_select_option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), custom_field_select_option_id: (encode-path-segment $custom_field_select_option_id)} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let req_body = {"custom_field_select_option": $custom_field_select_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Customer Categories.
#
# GET /customer_categories.json
export def "customer-categories-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<category: record<code: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer_categories.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new CustomerCategory.
#
# POST /customer_categories.json
# --category shape: {name?: string}
export def "customer-categories-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string}
]: any -> record<category: record<code: string, id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer_categories.json" $qp)
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing CustomerCategory.
#
# DELETE /customer_categories/{id}.json
export def "customer-categories delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single CustomerCategory.
#
# GET /customer_categories/{id}.json
export def "customer-categories get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<code: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a CustomerCategory.
#
# PUT /customer_categories/{id}.json
# --category shape: {name?: string}
export def "customer-categories update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string}
]: any -> record<category: record<code: string, id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}.json") $qp)
  let req_body = {"category": $category} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete Customers from an existing CustomerCategory.
#
# DELETE /customer_categories/{id}/customers.json
# --customers item shape: {email?: string, id?: int}
export def "customer-categories-customers-json delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let req_body = {"customers": $customers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieves the customers in a CustomerCategory.
#
# GET /customer_categories/{id}/customers.json
export def "customer-categories-customers-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Adds Customers to a CustomerCategory.
#
# POST /customer_categories/{id}/customers.json
# --customers item shape: {email?: string, id?: int}
export def "customer-categories-customers-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let req_body = {"customers": $customers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Customers.
#
# GET /customers.json
export def "customers-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new Customer.
#
# POST /customers.json
# --customer shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
export def "customers-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers.json" $qp)
  let req_body = {"customer": $customer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Customers.
#
# GET /customers/count.json
export def "customers-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Customer by email.
#
# GET /customers/email/{email}.json
export def "customers-email get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($email | is-empty) { error make --unspanned { msg: "path parameter 'email' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({email: (encode-path-segment $email)} | format pattern "/customers/email/{email}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete an existing Customer.
#
# DELETE /customers/{id}.json
export def "customers delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Customer by id.
#
# GET /customers/{id}.json
export def "customers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a new Customer.
#
# PUT /customers/{id}.json
# --customer shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
export def "customers update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list<int>, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}.json") $qp)
  let req_body = {"customer": $customer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieves the Customer Additional Field of a Customer.
#
# GET /customers/{id}/fields
export def "customers-fields list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Adds Customer Additional Fields to a Customer.
#
# POST /customers/{id}/fields
# --customer_additional_field shape: {checkout_custom_field_id?: int, value?: string}
export def "customers-fields create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/customers/{id}/fields") $qp)
  let req_body = {"customer_additional_field": $customer_additional_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete a Customer Additional Field.
#
# DELETE /customers/{id}/fields/{field_id}
export def "customers-fields delete" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), field_id: (encode-path-segment $field_id)} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Customer Additional Field.
#
# GET /customers/{id}/fields/{field_id}
export def "customers-fields get" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), field_id: (encode-path-segment $field_id)} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a Customer Additional Field.
#
# PUT /customers/{id}/fields/{field_id}
# --customer_additional_field shape: {checkout_custom_field_id?: int, value?: string}
export def "customers-fields update" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), field_id: (encode-path-segment $field_id)} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let req_body = {"customer_additional_field": $customer_additional_field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Fulfillments.
#
# GET /fulfillments.json
export def "fulfillments-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fulfillments.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Count all Fulfillments.
#
# GET /fulfillments/count.json
export def "fulfillments-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fulfillments/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Fulfillment.
#
# GET /fulfillments/{id}.json
export def "fulfillments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fulfillments/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Hooks.
#
# GET /hooks.json
export def "hooks-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new Hook.
#
# POST /hooks.json
# --hook shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
export def "hooks-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --hook: record # shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
]: any -> record<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks.json" $qp)
  let req_body = {"hook": $hook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing Hook.
#
# DELETE /hooks/{id}.json
export def "hooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/hooks/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Hook.
#
# GET /hooks/{id}.json
export def "hooks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/hooks/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a Hook.
#
# PUT /hooks/{id}.json
# --hook shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
export def "hooks update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --hook: record # shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
]: any -> record<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/hooks/{id}.json") $qp)
  let req_body = {"hook": $hook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all the Store's JSApps.
#
# GET /jsapps.json
export def "jsapps-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<apps: table<author: string, code: string, description: string, js: bool, name: string, page: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jsapps.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a Store JSApp.
#
# POST /jsapps.json
# --app shape: {element?: string, template?: string, url?: string}
export def "jsapps-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --app: record # shape: {element?: string, template?: string, url?: string}
]: any -> record<element: string, template: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jsapps.json" $qp)
  let req_body = {"app": $app} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing JSApp.
#
# DELETE /jsapps/{code}.json
export def "jsapps delete" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/jsapps/{code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a JSApp.
#
# GET /jsapps/{code}.json
export def "jsapps get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<element: string, template: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($code | is-empty) { error make --unspanned { msg: "path parameter 'code' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/jsapps/{code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve the Fulfillments associated with the Order.
#
# GET /order/{id}/fulfillments.json
export def "order-fulfillments-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/order/{id}/fulfillments.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Orders.
#
# GET /orders.json
export def "orders-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new Order.
#
# POST /orders.json
# --order shape: {customer?: record, products?: list, shipping_method_id?: int, shipping_method_name?: string, shipping_price?: float, status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid"}
export def "orders-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --order: any # shape: {customer?: record, products?: list, shipping_method_id?: int, shipping_method_name?: string, shipping_price?: float, status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid"}
]: any -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders.json" $qp)
  let req_body = {"order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve orders filtered by Order Id.
#
# GET /orders/after/{id}.json
export def "orders-after get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/after/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Count all Orders.
#
# GET /orders/count.json
export def "orders-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve orders filtered by status.
#
# GET /orders/status/{status}.json
export def "orders-status get" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($status | is-empty) { error make --unspanned { msg: "path parameter 'status' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: (encode-path-segment $status)} | format pattern "/orders/status/{status}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Order.
#
# GET /orders/{id}.json
export def "orders get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Modify an existing Order.
#
# PUT /orders/{id}.json
# --order shape: {additional_fields?: list, additional_information?: string, shipment_status?: "requested"|"in_transit"|"delivered"|"failed"|"pickup_available", status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid", tracking_company?: string, tracking_number?: string, tracking_url?: string}
export def "orders update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --order: any # shape: {additional_fields?: list, additional_information?: string, shipment_status?: "requested"|"in_transit"|"delivered"|"failed"|"pickup_available", status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid", tracking_company?: string, tracking_number?: string, tracking_url?: string}
]: any -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}.json") $qp)
  let req_body = {"order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Order History.
#
# GET /orders/{id}/history.json
export def "orders-history-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<order_history: record<created_at: string, id: int, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}/history.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Order History Entry.
#
# POST /orders/{id}/history.json
# --order_history shape: {message?: string}
export def "orders-history-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --order-history: record # shape: {message?: string}
]: any -> record<order_history: record<created_at: string, id: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}/history.json") $qp)
  let req_body = {"order_history": $order_history} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Pages.
#
# GET /pages.json
export def "pages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
]: nothing -> table<page: record<body: string, categories: list, id: int, image: record, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new Page.
#
# POST /pages.json
# --page shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
export def "pages-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --page: record # shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
]: any -> record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pages.json" $qp)
  let req_body = {"page": $page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Pages.
#
# GET /pages/count.json
export def "pages-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pages/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete an existing Page.
#
# DELETE /pages/{id}.json
export def "pages delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/pages/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Page by id.
#
# GET /pages/{id}.json
export def "pages get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/pages/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a Page.
#
# PUT /pages/{id}.json
# --page shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
export def "pages update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --page: record # shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
]: any -> record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/pages/{id}.json") $qp)
  let req_body = {"page": $page} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve statistics.
#
# GET /partners/stores.json
export def "partners-stores-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (format: string)
  --auth-token: string # Partner authentication token. (format: string)
  --page: int # List page (format: integer, default: 1)
  --qp-from: string # Statistics start date. Should be in format 'Y-m-d'. (format: string)
  --qp-to: string # Statistics end date. Should be in format 'Y-m-d'. (format: sting)
]: nothing -> table<code: string, stats: record<best_sold: list, conversions: record, currency: string, daily_visits: list, from: string, new_vs_returning_customers: record, new_vs_returning_orders: record, orders: record, payment_methods: list, referrers: list, region_orders: record, search_frequencies_all: list, search_frequencies_without_results: list, shipping_methods: list, to: string, traffic_type: list, visits: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partner_code" $partner_code "scalar") (serialize-qp "auth_token" $auth_token "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/partners/stores.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"partner_code": $partner_code, "auth_token": $auth_token, "page": $page, "from": $qp_from, "to": $qp_to} | compact), body: null}
}

# Retrieve all Store's Payment Methods.
#
# GET /payment_methods.json
export def "payment-methods-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<payment_method: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_methods.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Payment Method.
#
# GET /payment_methods/{id}.json
export def "payment-methods get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<payment_method: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Products.
#
# GET /products.json
export def "products-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # List restriction (format: integer, default: 50)
  --page: int # List page (format: integer, default: 1)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page, "locale": $locale} | compact), body: null}
}

# Create a new Product.
#
# POST /products.json
# --product shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
export def "products-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
  --product: record # shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
]: any -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products.json" $qp)
  let req_body = {"product": $product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: $req_body}
}

# Retrieves Products after the given id.
#
# GET /products/after/{id}.json
export def "products-after get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/after/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Retrieve Products filtered by category.
#
# GET /products/category/{category_id}.json
export def "products-category get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'category_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/products/category/{category_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Count Products filtered by category.
#
# GET /products/category/{category_id}/count.json
export def "products-category-count-json get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'category_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/products/category/{category_id}/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Count all Products.
#
# GET /products/count.json
export def "products-count-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/count.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a Product List from a query.
#
# GET /products/search.json
export def "products-search-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
  --query: string # Text to query for the Product (format: string)
  --fields: string@fields-completer # Comma separated values of the fields to query for the Product (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale, "query": $query, "fields": $fields} | compact), body: null}
}

# Retrieve Products filtered by status.
#
# GET /products/status/{status}.json
export def "products-status get" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($status | is-empty) { error make --unspanned { msg: "path parameter 'status' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: (encode-path-segment $status)} | format pattern "/products/status/{status}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Count Products filtered by status.
#
# GET /products/status/{status}/count.json
export def "products-status-count-json get" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($status | is-empty) { error make --unspanned { msg: "path parameter 'status' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: (encode-path-segment $status)} | format pattern "/products/status/{status}/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Delete an existing Product.
#
# DELETE /products/{id}.json
export def "products delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product.
#
# GET /products/{id}.json
export def "products get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: null}
}

# Modify an existing Product.
#
# PUT /products/{id}.json
# --product shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
export def "products update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
  --product: record # shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
]: any -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}.json") $qp)
  let req_body = {"product": $product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken, "locale": $locale} | compact), body: $req_body}
}

# Retrieve all Product Attachments.
#
# GET /products/{id}/attachments.json
export def "products-attachments-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<attachment: record<id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/attachments.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product Attachment.
#
# POST /products/{id}/attachments.json
# --attachment shape: {filename?: string, url?: string}
export def "products-attachments-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --attachment: record # shape: {filename?: string, url?: string}
]: any -> record<attachment: record<id: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/attachments.json") $qp)
  let req_body = {"attachment": $attachment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Attachments.
#
# GET /products/{id}/attachments/count.json
export def "products-attachments-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/attachments/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete a Product Attachment.
#
# DELETE /products/{id}/attachments/{attachment_id}.json
export def "products-attachments delete" [
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/products/{id}/attachments/{attachment_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product Attachment.
#
# GET /products/{id}/attachments/{attachment_id}.json
export def "products-attachments get" [
  id: int
  attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<attachment: record<id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachment_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/products/{id}/attachments/{attachment_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Product DigitalProducts.
#
# GET /products/{id}/digital_products.json
export def "products-digital-products-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/digital_products.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product DigitalProduct.
#
# POST /products/{id}/digital_products.json
# --digital_product shape: {filename?: string, url?: string}
export def "products-digital-products-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --digital-product: record # shape: {filename?: string, url?: string}
]: any -> record<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/digital_products.json") $qp)
  let req_body = {"digital_product": $digital_product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product DigitalProducts.
#
# GET /products/{id}/digital_products/count.json
export def "products-digital-products-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/digital_products/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete a Product DigitalProduct.
#
# DELETE /products/{id}/digital_products/{digital_product_id}.json
export def "products-digital-products delete" [
  id: int
  digital_product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($digital_product_id | is-empty) { error make --unspanned { msg: "path parameter 'digital_product_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), digital_product_id: (encode-path-segment $digital_product_id)} | format pattern "/products/{id}/digital_products/{digital_product_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product DigitalProduct.
#
# GET /products/{id}/digital_products/{digital_product_id}.json
export def "products-digital-products get" [
  id: int
  digital_product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($digital_product_id | is-empty) { error make --unspanned { msg: "path parameter 'digital_product_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), digital_product_id: (encode-path-segment $digital_product_id)} | format pattern "/products/{id}/digital_products/{digital_product_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Product Custom Fields
#
# GET /products/{id}/fields.json
export def "products-fields-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/fields.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Add an existing Custom Field to a Product.
#
# POST /products/{id}/fields.json
# --field shape: {id?: int, value?: string}
export def "products-fields-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --field: record # shape: {id?: int, value?: string}
]: any -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/fields.json") $qp)
  let req_body = {"field": $field} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Custom Fields.
#
# GET /products/{id}/fields/count.json
export def "products-fields-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/fields/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Product Images.
#
# GET /products/{id}/images.json
export def "products-images-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<image: record<id: int, position: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/images.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product Image.
#
# POST /products/{id}/images.json
# --image shape: {url?: string}
export def "products-images-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --image: record # shape: {url?: string}
]: any -> record<image: record<id: int, position: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/images.json") $qp)
  let req_body = {"image": $image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Images.
#
# GET /products/{id}/images/count.json
export def "products-images-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/images/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete a Product Image.
#
# DELETE /products/{id}/images/{image_id}.json
export def "products-images delete" [
  id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), image_id: (encode-path-segment $image_id)} | format pattern "/products/{id}/images/{image_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product Image.
#
# GET /products/{id}/images/{image_id}.json
export def "products-images get" [
  id: int
  image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<image: record<id: int, position: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($image_id | is-empty) { error make --unspanned { msg: "path parameter 'image_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), image_id: (encode-path-segment $image_id)} | format pattern "/products/{id}/images/{image_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Product Options.
#
# GET /products/{id}/options.json
export def "products-options-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<option: record<id: int, name: string, option_type: string, position: int, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/options.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product Option.
#
# POST /products/{id}/options.json
# --option shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
export def "products-options-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/options.json") $qp)
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Options.
#
# GET /products/{id}/options/count.json
export def "products-options-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/options/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete a Product Option.
#
# DELETE /products/{id}/options/{option_id}.json
export def "products-options delete" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product Option.
#
# GET /products/{id}/options/{option_id}.json
export def "products-options get" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Modify an existing Product Option.
#
# PUT /products/{id}/options/{option_id}.json
# --option shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
export def "products-options update" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let req_body = {"option": $option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values.json
export def "products-options-values-json get" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<value: record<id: int, name: string, position: int, product_option: record, variants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}/values.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product Option Value.
#
# POST /products/{id}/options/{option_id}/values.json
# --value shape: {name?: string, position?: int}
export def "products-options-values-json create" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}/values.json") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values/count.json
export def "products-options-values-count-json get" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id)} | format pattern "/products/{id}/options/{option_id}/values/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Delete a Product Option Value.
#
# DELETE /products/{id}/options/{option_id}/values/{value_id}.json
export def "products-options-values delete" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  if ($value_id | is-empty) { error make --unspanned { msg: "path parameter 'value_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id), value_id: (encode-path-segment $value_id)} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product Option Value.
#
# GET /products/{id}/options/{option_id}/values/{value_id}.json
export def "products-options-values get" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  if ($value_id | is-empty) { error make --unspanned { msg: "path parameter 'value_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id), value_id: (encode-path-segment $value_id)} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Modify an existing Product Option Value.
#
# PUT /products/{id}/options/{option_id}/values/{value_id}.json
# --value shape: {name?: string, position?: int}
export def "products-options-values update" [
  id: int
  option_id: int
  value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($option_id | is-empty) { error make --unspanned { msg: "path parameter 'option_id' must be non-empty" } }
  if ($value_id | is-empty) { error make --unspanned { msg: "path parameter 'value_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), option_id: (encode-path-segment $option_id), value_id: (encode-path-segment $value_id)} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Product Variants.
#
# GET /products/{id}/variants.json
export def "products-variants-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<variant: record<id: int, image: record, options: list, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/variants.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Product Variant.
#
# POST /products/{id}/variants.json
# --variant shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
export def "products-variants-json create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/variants.json") $qp)
  let req_body = {"variant": $variant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Count all Product Variants.
#
# GET /products/{id}/variants/count.json
export def "products-variants-count-json get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}/variants/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Product Variant.
#
# GET /products/{id}/variants/{variant_id}.json
export def "products-variants get" [
  id: int
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($variant_id | is-empty) { error make --unspanned { msg: "path parameter 'variant_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), variant_id: (encode-path-segment $variant_id)} | format pattern "/products/{id}/variants/{variant_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Modify an existing Product Variant.
#
# PUT /products/{id}/variants/{variant_id}.json
# --variant shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
export def "products-variants update" [
  id: int
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($variant_id | is-empty) { error make --unspanned { msg: "path parameter 'variant_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), variant_id: (encode-path-segment $variant_id)} | format pattern "/products/{id}/variants/{variant_id}.json") $qp)
  let req_body = {"variant": $variant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete value of Product Custom Field
#
# DELETE /products/{product_id}/fields/{field_id}.json
export def "products-fields delete" [
  product_id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), field_id: (encode-path-segment $field_id)} | format pattern "/products/{product_id}/fields/{field_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update value of Product Custom Field
#
# PUT /products/{product_id}/fields/{field_id}.json
export def "products-fields update" [
  product_id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'product_id' must be non-empty" } }
  if ($field_id | is-empty) { error make --unspanned { msg: "path parameter 'field_id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), field_id: (encode-path-segment $field_id)} | format pattern "/products/{product_id}/fields/{field_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Promotions.
#
# GET /promotions.json
export def "promotions-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --limit: int # Promotions' list restriction (default: 50 | max: 200). (format: integer)
  --page: int # Promotions' list page (default: 1). (format: integer)
]: nothing -> table<promotion: record<begins_at: string, categories: list, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list, products_x: list, quantity_x: int, status: string, times_used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotions.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken, "limit": $limit, "page": $page} | compact), body: null}
}

# Create a new Promotion.
#
# POST /promotions.json
# --promotion shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
export def "promotions-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --promotion: record # shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
]: any -> record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotions.json" $qp)
  let req_body = {"promotion": $promotion} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing Promotion.
#
# DELETE /promotions/{id}.json
export def "promotions delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/promotions/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Promotion.
#
# GET /promotions/{id}.json
export def "promotions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/promotions/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a Promotion.
#
# PUT /promotions/{id}.json
# --promotion shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
export def "promotions update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --promotion: record # shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
]: any -> record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/promotions/{id}.json") $qp)
  let req_body = {"promotion": $promotion} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve all Store's Shipping Methods.
#
# GET /shipping_methods.json
export def "shipping-methods-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipping_methods.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Creates a Shipping Method.
#
# POST /shipping_methods.json
# --shipping_method shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
export def "shipping-methods-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --shipping-method: record # shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
]: any -> record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shipping_methods.json" $qp)
  let req_body = {"shipping_method": $shipping_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Delete an existing Shipping Method.
#
# DELETE /shipping_methods/{id}.json
export def "shipping-methods delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve a single Shipping Method.
#
# GET /shipping_methods/{id}.json
export def "shipping-methods get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Update a Shipping Method.
#
# PUT /shipping_methods/{id}.json
# --shipping_method shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
export def "shipping-methods update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --shipping-method: record # shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
]: any -> record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shipping_methods/{id}.json") $qp)
  let req_body = {"shipping_method": $shipping_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrive store creation status.
#
# GET /store/check_status.json
export def "store-check-status-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (format: string)
  --auth-token: string # Partner authentication token. (format: string)
  --store-code: string # Store Code (format: string)
  --locale: string # ISO 3166-2 code of the language used in the response messages. (format: string, default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partner_code" $partner_code "scalar") (serialize-qp "auth_token" $auth_token "scalar") (serialize-qp "store_code" $store_code "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/store/check_status.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"partner_code": $partner_code, "auth_token": $auth_token, "store_code": $store_code, "locale": $locale} | compact), body: null}
}

# Create a Partnered Store
#
# POST /store/create.json
export def "store-create-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partner-code: string # Partner code. (format: string)
  --auth-token: string # Partner authentication token. (format: string)
  --aff: string # Partner code.
  --email: string # New Store administrator email. (format: email)
  --locale: string # ISO3166-2 code for the store langauge. (default: en)
  --password: string # New Store administrator password. (format: string)
  --plan-name: string@plan-name-completer # New Store plan name. (default: pro)
  --reject-duplicates: oneof<nothing, bool> # Indicates whether the request should fail if the Store name provided is already in use. (default: false)
  --store-name: string # New Store name.
]: any -> record<store: record<code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partner_code" $partner_code "scalar") (serialize-qp "auth_token" $auth_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/store/create.json" $qp)
  let req_body = {"aff": $aff, "email": $email, "locale": $locale, "password": $password, "plan_name": $plan_name, "reject_duplicates": $reject_duplicates, "store_name": $store_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"partner_code": $partner_code, "auth_token": $auth_token} | compact), body: $req_body}
}

# Retrieve Store Information.
#
# GET /store/info.json
export def "store-info-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<address: record<address: string, city: string, country: string, country_code: string, postal: string, region: string, region_code: string>, code: string, country: string, currency: string, email: string, hooks_token: string, logo: string, name: string, timezone: string, url: string, weight_unit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/store/info.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve Store Languages.
#
# GET /store/languages.json
export def "store-languages-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/store/languages.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Retrieve all Taxes.
#
# GET /taxes.json
export def "taxes-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxes.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}

# Create a new Tax.
#
# POST /taxes.json
# --tax shape: {category_id?: int, country?: string, fixed?: bool, name?: string, region?: string, shipping?: bool, tax?: float}
export def "taxes-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --tax: record # shape: {category_id?: int, country?: string, fixed?: bool, name?: string, region?: string, shipping?: bool, tax?: float}
]: any -> record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/taxes.json" $qp)
  let req_body = {"tax": $tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"login": $login, "authtoken": $authtoken} | compact), body: $req_body}
}

# Retrieve a single Tax information.
#
# GET /taxes/{id}.json
export def "taxes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/taxes/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"login": $login, "authtoken": $authtoken} | compact), body: null}
}
