# Auto-generated client for Jumpseller API v1.0.0
# Source: https://api.apis.guru/v2/specs/jumpseller.com/1.0.0/openapi.json
# Auth: --token flag or $env.JUMPSELLER_API_TOKEN

const BASE_URL = "https://api.jumpseller.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JUMPSELLER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.jumpseller.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def fields-completer [] { ["barcode" "brand" "custom_fields" "custom_fields_selects" "description" "name" "option_name" "sku" "variants"] }
def plan-name-completer [] { ["plus" "premium" "pro"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "categoriesjson get" } } | get name | first)
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
export def "categoriesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Category.
#
# POST /categories.json
# --category shape: {name?: string, parent_id?: int}
export def "categoriesjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"category": $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Categories.
#
# GET /categories/count.json
export def "categories-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Category.
#
# PUT /categories/{id}.json
# --category shape: {name?: string, parent_id?: int}
export def "categories put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string, parent_id?: int}
]: any -> record<category: record<id: int, name: string, parent_id: int, permalink: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/categories/{id}.json") $qp)
  let body = {"category": $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Checkout Custom Fields.
#
# GET /checkout_custom_fields.json
export def "checkout-custom-fieldsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new CheckoutCustomField.
#
# POST /checkout_custom_fields.json
# --checkout_custom_field shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
export def "checkout-custom-fieldsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/checkout_custom_fields.json" $qp)
  let body = {"checkout_custom_field": $checkout_custom_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a CheckoutCustomField.
#
# PUT /checkout_custom_fields/{id}.json
# --checkout_custom_field shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
export def "checkout-custom-fields put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --checkout-custom-field: record # shape: {area?: "contact"|"billing_shipping"|"other", custom_field_select_options?: list, deletable?: bool, label?: string, position?: int, required?: bool, type?: "text"|"select"|"input"|"checkbox"|"date"}
]: any -> record<checkout_custom_field: record<area: string, custom_field_select_options: list<string>, deletable: bool, id: int, label: string, position: int, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/checkout_custom_fields/{id}.json") $qp)
  let body = {"checkout_custom_field": $checkout_custom_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Countries.
#
# GET /countries.json
export def "countriesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: $country_code} | format pattern "/countries/{country_code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Regions from a single Country.
#
# GET /countries/{country_code}/regions.json
export def "countries-regionsjson get" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: $country_code} | format pattern "/countries/{country_code}/regions.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: $country_code, region_code: $region_code} | format pattern "/countries/{country_code}/regions/{region_code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields.json
export def "custom-fieldsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Custom Field.
#
# POST /custom_fields.json
# --custom_field shape: {label?: string, type?: "text"|"selection"|"input", values?: list}
export def "custom-fieldsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list}
]: any -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/custom_fields.json" $qp)
  let body = {"custom_field": $custom_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/custom_fields/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a CustomField.
#
# PUT /custom_fields/{id}.json
# --custom_field shape: {label?: string, type?: "text"|"selection"|"input", values?: list}
export def "custom-fields put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field: record # shape: {label?: string, type?: "text"|"selection"|"input", values?: list}
]: any -> record<custom_field: record<id: int, label: string, type: string, values: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/custom_fields/{id}.json") $qp)
  let body = {"custom_field": $custom_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Store's Custom Fields.
#
# GET /custom_fields/{id}/select_options.json
export def "custom-fields-select-optionsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<custom_field_select_option: record<id: int, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/custom_fields/{id}/select_options.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Custom Field Select Option.
#
# POST /custom_fields/{id}/select_options.json
# --custom_field_select_option shape: {value?: string}
export def "custom-fields-select-optionsjson post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> record<custom_field_select_option: record<id: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/custom_fields/{id}/select_options.json") $qp)
  let body = {"custom_field_select_option": $custom_field_select_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, custom_field_select_option_id: $custom_field_select_option_id} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<custom_field_select_option: record<id: int, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, custom_field_select_option_id: $custom_field_select_option_id} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a SelectOption from a CustomField.
#
# PUT /custom_fields/{id}/select_options/{custom_field_select_option_id}.json
# --custom_field_select_option shape: {value?: string}
export def "custom-fields-select-options put" [
  id: int
  custom_field_select_option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --custom-field-select-option: record # shape: {value?: string}
]: any -> record<custom_field_select_option: record<id: int, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, custom_field_select_option_id: $custom_field_select_option_id} | format pattern "/custom_fields/{id}/select_options/{custom_field_select_option_id}.json") $qp)
  let body = {"custom_field_select_option": $custom_field_select_option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Customer Categories.
#
# GET /customer_categories.json
export def "customer-categoriesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new CustomerCategory.
#
# POST /customer_categories.json
# --category shape: {name?: string}
export def "customer-categoriesjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"category": $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<code: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a CustomerCategory.
#
# PUT /customer_categories/{id}.json
# --category shape: {name?: string}
export def "customer-categories put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --category: record # shape: {name?: string}
]: any -> record<category: record<code: string, id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}.json") $qp)
  let body = {"category": $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Customers from an existing CustomerCategory.
#
# DELETE /customer_categories/{id}/customers.json
# --customers item shape: {email?: string, id?: int}
export def "customer-categories-customersjson delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let body = {"customers": $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the customers in a CustomerCategory.
#
# GET /customer_categories/{id}/customers.json
export def "customer-categories-customersjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds Customers to a CustomerCategory.
#
# POST /customer_categories/{id}/customers.json
# --customers item shape: {email?: string, id?: int}
export def "customer-categories-customersjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customers: list # item shape: {email?: string, id?: int}
]: any -> table<customer: record<billing_address: record, customer_additional_fields: list, customer_categories: list, email: string, id: int, name: string, phone: string, shipping_address: record, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customer_categories/{id}/customers.json") $qp)
  let body = {"customers": $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Customers.
#
# GET /customers.json
export def "customersjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Customer.
#
# POST /customers.json
# --customer shape: {billing_address?: any, customer_category?: list, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
export def "customersjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers.json" $qp)
  let body = {"customer": $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Customers.
#
# GET /customers/count.json
export def "customers-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({email: $email} | format pattern "/customers/email/{email}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customers/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customers/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a new Customer.
#
# PUT /customers/{id}.json
# --customer shape: {billing_address?: any, customer_category?: list, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
export def "customers put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer: record # shape: {billing_address?: any, customer_category?: list, email?: string, password?: string, phone?: string, shipping_address?: any, status?: "approved"|"pending"|"disabled"}
]: any -> record<customer: record<billing_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string, taxid: string>, customer_additional_fields: list<record>, customer_categories: list<record>, email: string, id: int, name: string, phone: string, shipping_address: record<address: string, city: string, country: string, municipality: string, name: string, postal: string, region: string, surname: string>, status: string, surname: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customers/{id}.json") $qp)
  let body = {"customer": $customer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customers/{id}/fields") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds Customer Additional Fields to a Customer.
#
# POST /customers/{id}/fields
# --customer_additional_field shape: {checkout_custom_field_id?: int, value?: string}
export def "customers-fields post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/customers/{id}/fields") $qp)
  let body = {"customer_additional_field": $customer_additional_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, field_id: $field_id} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, field_id: $field_id} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Customer Additional Field.
#
# PUT /customers/{id}/fields/{field_id}
# --customer_additional_field shape: {checkout_custom_field_id?: int, value?: string}
export def "customers-fields put" [
  id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --customer-additional-field: record # shape: {checkout_custom_field_id?: int, value?: string}
]: any -> record<customer_additional_field: record<area: string, checkout_custom_field_id: int, customer_id: int, id: int, label: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, field_id: $field_id} | format pattern "/customers/{id}/fields/{field_id}") $qp)
  let body = {"customer_additional_field": $customer_additional_field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Fulfillments.
#
# GET /fulfillments.json
export def "fulfillmentsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count all Fulfillments.
#
# GET /fulfillments/count.json
export def "fulfillments-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/fulfillments/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Hooks.
#
# GET /hooks.json
export def "hooksjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Hook.
#
# POST /hooks.json
# --hook shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
export def "hooksjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"hook": $hook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hooks/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hooks/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Hook.
#
# PUT /hooks/{id}.json
# --hook shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
export def "hooks put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --hook: record # shape: {event: "order_updated"|"order_pending_payment"|"order_paid"|"order_shipped"|"order_canceled"|"order_abandoned"|"product_created"|"product_updated"|"product_deleted"|"customer_created"|"customer_updated"|"customer_deleted", url: string}
]: any -> record<hook: record<created_at: string, event: string, id: int, name: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/hooks/{id}.json") $qp)
  let body = {"hook": $hook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all the Store's JSApps.
#
# GET /jsapps.json
export def "jsappsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Store JSApp.
#
# POST /jsapps.json
# --app shape: {element?: string, template?: string, url?: string}
export def "jsappsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"app": $app} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/jsapps/{code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<element: string, template: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/jsapps/{code}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the Fulfillments associated with the Order.
#
# GET /order/{id}/fulfillments.json
export def "order-fulfillmentsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<category: record<external_id: string, id: int, order_id: string, service_type: string, shipment_status: string, tracking_company: string, tracking_number: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/order/{id}/fulfillments.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Orders.
#
# GET /orders.json
export def "ordersjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Order.
#
# POST /orders.json
# --order shape: {customer?: record, products?: list, shipping_method_id?: int, shipping_method_name?: string, shipping_price?: float, status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid"}
export def "ordersjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"order": $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/after/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count all Orders.
#
# GET /orders/count.json
export def "orders-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<order: record<additional_fields: list, additional_information: string, billing_address: record, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list, source: record, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: $status} | format pattern "/orders/status/{status}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Order.
#
# PUT /orders/{id}.json
# --order shape: {additional_fields?: list, additional_information?: string, shipment_status?: "requested"|"in_transit"|"delivered"|"failed"|"pickup_available", status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid", tracking_company?: string, tracking_number?: string, tracking_url?: string}
export def "orders put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --order: any # shape: {additional_fields?: list, additional_information?: string, shipment_status?: "requested"|"in_transit"|"delivered"|"failed"|"pickup_available", status?: "Abandoned"|"Canceled"|"Pending Payment"|"Paid", tracking_company?: string, tracking_number?: string, tracking_url?: string}
]: any -> record<order: record<additional_fields: list<record>, additional_information: string, billing_address: record<address: string, city: string, country: string, country_name: string, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, checkout_url: string, coupons: string, created_at: string, currency: string, customer: record<customer: record>, discount: float, duplicate_url: string, external_shipping_rate_id: string, id: int, payment_information: string, payment_method_name: string, payment_method_type: string, products: list<record>, recovery_url: string, shipment_status: string, shipping: float, shipping_address: record<address: string, city: string, country: string, country_name: string, latitude: float, longitude: float, municipality: string, name: string, postal: string, region: string, street_number: float, surname: string>, shipping_discount: float, shipping_method_id: int, shipping_method_name: string, shipping_option: string, shipping_required: bool, shipping_tax: float, shipping_taxes: list<record>, source: record<campaign: string, first_page_visited: string, first_page_visited_at: string, medium: string, referral_code: string, referral_source: string, referral_url: string, source_name: string, user_agent: string>, status: string, subtotal: float, tax: float, total: float, tracking_company: string, tracking_number: string, tracking_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}.json") $qp)
  let body = {"order": $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Order History.
#
# GET /orders/{id}/history.json
export def "orders-historyjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<order_history: record<created_at: string, id: int, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}/history.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Order History Entry.
#
# POST /orders/{id}/history.json
# --order_history shape: {message?: string}
export def "orders-historyjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --order-history: record # shape: {message?: string}
]: any -> record<order_history: record<created_at: string, id: int, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}/history.json") $qp)
  let body = {"order_history": $order_history} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Pages.
#
# GET /pages.json
export def "pagesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Page.
#
# POST /pages.json
# --page shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
export def "pagesjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"page": $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Pages.
#
# GET /pages/count.json
export def "pages-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/pages/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/pages/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Page.
#
# PUT /pages/{id}.json
# --page shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
export def "pages put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --page: record # shape: {body?: string, categories?: list, image?: record, meta_description?: string, page_title?: string, permalink?: string, status?: "public"|"draft"|"hidden", template?: int, title?: string}
]: any -> record<page: record<body: string, categories: list<record>, id: int, image: record<id: int, url: string>, legal: bool, meta_description: string, page_title: string, permalink: string, status: string, template: record<id: int, name: string>, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/pages/{id}.json") $qp)
  let body = {"page": $page} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics.
#
# GET /partners/stores.json
export def "partners-storesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Store's Payment Methods.
#
# GET /payment_methods.json
export def "payment-methodsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<payment_method: record<id: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/payment_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Products.
#
# GET /products.json
export def "productsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product.
#
# POST /products.json
# --product shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
export def "productsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"product": $product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/after/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: $category_id} | format pattern "/products/category/{category_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count Products filtered by category.
#
# GET /products/category/{category_id}/count.json
export def "products-category-countjson get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: $category_id} | format pattern "/products/category/{category_id}/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count all Products.
#
# GET /products/count.json
export def "products-countjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a Product List from a query.
#
# GET /products/search.json
export def "products-searchjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> table<product: record<barcode: string, categories: list, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: $status} | format pattern "/products/status/{status}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count Products filtered by status.
#
# GET /products/status/{status}/count.json
export def "products-status-countjson get" [
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({status: $status} | format pattern "/products/status/{status}/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --locale: string # Locale code of the translation (format: string)
]: nothing -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Product.
#
# PUT /products/{id}.json
# --product shape: {barcode?: string, categories?: list, description?: string, diameter?: float, featured?: bool, google_product_category?: string, height?: float, length?: float, meta_description?: string, name: string, package_format?: "box"|"cylinder", page_title?: string, permalink?: string, price: float, shipping_required?: bool, sku?: string, status?: "available"|"not-available"|"disabled", stock?: int, stock_unlimited?: bool, weight?: float, width?: float}
export def "products put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}.json") $qp)
  let body = {"product": $product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Product Attachments.
#
# GET /products/{id}/attachments.json
export def "products-attachmentsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<attachment: record<id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/attachments.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product Attachment.
#
# POST /products/{id}/attachments.json
# --attachment shape: {filename?: string, url?: string}
export def "products-attachmentsjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --attachment: record # shape: {filename?: string, url?: string}
]: any -> record<attachment: record<id: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/attachments.json") $qp)
  let body = {"attachment": $attachment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Attachments.
#
# GET /products/{id}/attachments/count.json
export def "products-attachments-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/attachments/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, attachment_id: $attachment_id} | format pattern "/products/{id}/attachments/{attachment_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<attachment: record<id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, attachment_id: $attachment_id} | format pattern "/products/{id}/attachments/{attachment_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Product DigitalProducts.
#
# GET /products/{id}/digital_products.json
export def "products-digital-productsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/digital_products.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product DigitalProduct.
#
# POST /products/{id}/digital_products.json
# --digital_product shape: {filename?: string, url?: string}
export def "products-digital-productsjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --digital-product: record # shape: {filename?: string, url?: string}
]: any -> record<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/digital_products.json") $qp)
  let body = {"digital_product": $digital_product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product DigitalProducts.
#
# GET /products/{id}/digital_products/count.json
export def "products-digital-products-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/digital_products/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, digital_product_id: $digital_product_id} | format pattern "/products/{id}/digital_products/{digital_product_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<digital_product: record<expiration_seconds: int, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, digital_product_id: $digital_product_id} | format pattern "/products/{id}/digital_products/{digital_product_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Product Custom Fields
#
# GET /products/{id}/fields.json
export def "products-fieldsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/fields.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an existing Custom Field to a Product.
#
# POST /products/{id}/fields.json
# --field shape: {id?: int, value?: string}
export def "products-fieldsjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --field: record # shape: {id?: int, value?: string}
]: any -> record<product: record<barcode: string, categories: list<record>, created_at: string, description: string, diameter: float, discount: float, featured: bool, google_product_category: string, height: float, id: int, images: list<record>, length: float, name: string, package_format: string, permalink: string, price: float, sku: string, status: string, stock: int, stock_unlimited: bool, variants: list<record>, weight: float, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/fields.json") $qp)
  let body = {"field": $field} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Custom Fields.
#
# GET /products/{id}/fields/count.json
export def "products-fields-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/fields/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Product Images.
#
# GET /products/{id}/images.json
export def "products-imagesjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<image: record<id: int, position: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/images.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product Image.
#
# POST /products/{id}/images.json
# --image shape: {url?: string}
export def "products-imagesjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --image: record # shape: {url?: string}
]: any -> record<image: record<id: int, position: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/images.json") $qp)
  let body = {"image": $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Images.
#
# GET /products/{id}/images/count.json
export def "products-images-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/images/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, image_id: $image_id} | format pattern "/products/{id}/images/{image_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<image: record<id: int, position: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, image_id: $image_id} | format pattern "/products/{id}/images/{image_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Product Options.
#
# GET /products/{id}/options.json
export def "products-optionsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<option: record<id: int, name: string, option_type: string, position: int, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/options.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product Option.
#
# POST /products/{id}/options.json
# --option shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
export def "products-optionsjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/options.json") $qp)
  let body = {"option": $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Options.
#
# GET /products/{id}/options/count.json
export def "products-options-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/options/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Product Option.
#
# PUT /products/{id}/options/{option_id}.json
# --option shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
export def "products-options put" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --option: record # shape: {name?: string, option_type?: "option"|"input"|"text"|"file", position?: int}
]: any -> record<option: record<id: int, name: string, option_type: string, position: int, values: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}.json") $qp)
  let body = {"option": $option} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values.json
export def "products-options-valuesjson get" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<value: record<id: int, name: string, position: int, product_option: record, variants: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}/values.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product Option Value.
#
# POST /products/{id}/options/{option_id}/values.json
# --value shape: {name?: string, position?: int}
export def "products-options-valuesjson post" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}/values.json") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Option Values.
#
# GET /products/{id}/options/{option_id}/values/count.json
export def "products-options-values-countjson get" [
  id: int
  option_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id} | format pattern "/products/{id}/options/{option_id}/values/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id, value_id: $value_id} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id, value_id: $value_id} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Product Option Value.
#
# PUT /products/{id}/options/{option_id}/values/{value_id}.json
# --value shape: {name?: string, position?: int}
export def "products-options-values put" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --value: record # shape: {name?: string, position?: int}
]: any -> record<value: record<id: int, name: string, position: int, product_option: record<option: record>, variants: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, option_id: $option_id, value_id: $value_id} | format pattern "/products/{id}/options/{option_id}/values/{value_id}.json") $qp)
  let body = {"value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Product Variants.
#
# GET /products/{id}/variants.json
export def "products-variantsjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> table<variant: record<id: int, image: record, options: list, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/variants.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Product Variant.
#
# POST /products/{id}/variants.json
# --variant shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
export def "products-variantsjson post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/variants.json") $qp)
  let body = {"variant": $variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count all Product Variants.
#
# GET /products/{id}/variants/count.json
export def "products-variants-countjson get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}/variants/count.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, variant_id: $variant_id} | format pattern "/products/{id}/variants/{variant_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an existing Product Variant.
#
# PUT /products/{id}/variants/{variant_id}.json
# --variant shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
export def "products-variants put" [
  id: int
  variant_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --variant: record # shape: {image_id?: int, options?: list, price?: float, sku?: string, stock?: int, stock_unlimited?: bool}
]: any -> record<variant: record<id: int, image: record<id: int, position: int, url: string>, options: list<record>, price: float, sku: string, stock: int, stock_unlimited: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id, variant_id: $variant_id} | format pattern "/products/{id}/variants/{variant_id}.json") $qp)
  let body = {"variant": $variant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: $product_id, field_id: $field_id} | format pattern "/products/{product_id}/fields/{field_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update value of Product Custom Field
#
# PUT /products/{product_id}/fields/{field_id}.json
export def "products-fields put" [
  product_id: int
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<field: record<custom_field_id: int, id: int, label: string, type: string, value: string, value_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product_id: $product_id, field_id: $field_id} | format pattern "/products/{product_id}/fields/{field_id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Promotions.
#
# GET /promotions.json
export def "promotionsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Promotion.
#
# POST /promotions.json
# --promotion shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
export def "promotionsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"promotion": $promotion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/promotions/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/promotions/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Promotion.
#
# PUT /promotions/{id}.json
# --promotion shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
export def "promotions put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --promotion: record # shape: {begins_at?: string, buys_at_least?: string, categories?: list, code?: string, condition_price?: float, condition_qty?: int, cumulative?: bool, customer_categories?: list, customers?: string, discount_amount_fix?: float, discount_amount_percent?: float, discount_target?: string, enabled?: bool, expires_at?: string, lasts?: string, max_times_used?: int, name?: string, products?: list, products_x?: list, quantity_x?: int, type?: string}
]: any -> record<promotion: record<begins_at: string, categories: list<record>, code: string, condition_price: float, condition_qty: int, cumulative: bool, customer_categories: list<record>, discount_amount_fix: float, discount_amount_percent: float, discount_target: string, enabled: bool, expires_at: string, id: int, lasts: string, max_times_used: int, name: string, products: list<record>, products_x: list<record>, quantity_x: int, status: string, times_used: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/promotions/{id}.json") $qp)
  let body = {"promotion": $promotion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve all Store's Shipping Methods.
#
# GET /shipping_methods.json
export def "shipping-methodsjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Shipping Method.
#
# POST /shipping_methods.json
# --shipping_method shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
export def "shipping-methodsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"shipping_method": $shipping_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/shipping_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/shipping_methods/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Shipping Method.
#
# PUT /shipping_methods/{id}.json
# --shipping_method shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
export def "shipping-methods put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
  --shipping-method: record # shape: {callback_url?: string, city?: string, fetch_services_url?: string, name?: string, postal?: string, state?: string, token?: string}
]: any -> record<shipping_method: record<callback_url: string, city: string, fetch_services_url: string, id: int, name: string, postal: string, services: list<record>, state: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/shipping_methods/{id}.json") $qp)
  let body = {"shipping_method": $shipping_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrive store creation status.
#
# GET /store/check_status.json
export def "store-check-statusjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Partnered Store
#
# POST /store/create.json
export def "store-createjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"aff": $aff, "email": $email, "locale": $locale, "password": $password, "plan_name": $plan_name, "reject_duplicates": $reject_duplicates, "store_name": $store_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Store Information.
#
# GET /store/info.json
export def "store-infojson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Store Languages.
#
# GET /store/languages.json
export def "store-languagesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all Taxes.
#
# GET /taxes.json
export def "taxesjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Tax.
#
# POST /taxes.json
# --tax shape: {category_id?: int, country?: string, fixed?: bool, name?: string, region?: string, shipping?: bool, tax?: float}
export def "taxesjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let body = {"tax": $tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # API OAuth login. (format: string)
  --authtoken: string # API OAuth token. (format: string)
]: nothing -> record<tax: record<category_id: int, country: string, fixed: bool, id: int, name: string, region: string, shipping: bool, tax_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "login" $login "scalar") (serialize-qp "authtoken" $authtoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/taxes/{id}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
