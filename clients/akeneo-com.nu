# Auto-generated client for Akeneo PIM REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/akeneo.com/1.0.0/swagger.json
# Auth: --token flag or $env.AKENEO_PIM_REST_API_TOKEN

const BASE_URL = "http://demo.akeneo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AKENEO_PIM_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://demo.akeneo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def media-type-completer [] { ["image" "other" "pdf" "vimeo" "youtube"] }
def type-completer [] { ["boolean" "media_file" "media_link" "multiple_options" "number" "reference_entity_multiple_links" "reference_entity_single_link" "single_option" "text"] }
def validation-rule-completer [] { ["email" "none" "regexp" "url"] }
def pagination-type-completer [] { ["page" "search_after"] }
def type-completer-1 [] { ["akeneo_reference_entity" "akeneo_reference_entity_collection" "pim_catalog_asset_collection" "pim_catalog_boolean" "pim_catalog_date" "pim_catalog_file" "pim_catalog_identifier" "pim_catalog_image" "pim_catalog_metric" "pim_catalog_multiselect" "pim_catalog_number" "pim_catalog_price_collection" "pim_catalog_reference_data_multi_select" "pim_catalog_reference_data_simple_select" "pim_catalog_simpleselect" "pim_catalog_text" "pim_catalog_textarea"] }
def type-completer-2 [] { ["image" "multiple_options" "number" "reference_entity_multiple_links" "reference_entity_single_link" "single_option" "text"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oauth-token token" } } | get name | first)
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

# Get authentication token
#
# POST /api/oauth/v1/token
# operationId: post_token
export def "oauth-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'application/json' or 'application/x-www-form-urlencoded', no other value allowed
  --authorization: string # Equal to 'Basic xx', where 'xx' is the base 64 encoding of the client id and secret. Find out how to generate them in the <a href="/documentation/authentication.html#client-idsecret-generation">Client ID/secret generation</a> section.
  grant_type: string # Always equal to "password"
  password: string # Your PIM password
  username: string # Your PIM username
]: any -> record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/oauth/v1/token")
  let body = {"grant_type": $grant_type, "password": $password, "username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type, "Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of all endpoints
#
# GET /api/rest/v1
# operationId: get_endpoints
export def "rest endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authentication: record, host: string, routes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of PAM asset categories
#
# GET /api/rest/v1/asset-categories
# operationId: get_asset_categories
export def "rest-asset-categories categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/asset-categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several PAM asset categories
#
# PATCH /api/rest/v1/asset-categories
# operationId: patch_asset_categories
# --labels shape: {localeCode?: string}
export def "rest-asset-categories categories-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # PAM asset category code
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/asset-categories")
  let body = {"code": $code, "labels": $labels, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new PAM asset category
#
# POST /api/rest/v1/asset-categories
# operationId: post_asset_categories
# --labels shape: {localeCode?: string}
export def "rest-asset-categories categories-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # PAM asset category code
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/asset-categories")
  let body = {"code": $code, "labels": $labels, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a PAM asset category
#
# GET /api/rest/v1/asset-categories/{code}
# operationId: get_asset_categories__code_
export def "rest-asset-categories get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, labels: record<localeCode: string>, parent: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-categories/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a PAM asset category
#
# PATCH /api/rest/v1/asset-categories/{code}
# operationId: patch_asset_categories__code_
# --labels shape: {localeCode?: string}
export def "rest-asset-categories patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # PAM asset category code
  --labels: record # PAM asset category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # PAM ssset category code of the parent's asset category (default: null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-categories/{code}"))
  let body = {"code": $body_code, "labels": $labels, "parent": $parent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of asset families
#
# GET /api/rest/v1/asset-families
# operationId: get_asset_families
export def "rest-asset-families families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_after" $search_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/asset-families" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the assets of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/assets
# operationId: get_assets
export def "rest-asset-families-assets assets-by-asset_family_code" [
  asset_family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter assets, for more details see the <a href="/documentation/filter.html#filter-assets">Asset filters</a> section
  --channel: string # Filter asset values to return scopable asset attributes for the given channel as well as the non localizable/non scopable asset attributes, for more details see the <a href="/documentation/filter.html#asset-values-by-channel">Filter asset values by channel</a> section
  --locales: string # Filter asset values to return localizable attributes for the given locales as well as the non localizable/non scopable asset attributes, for more details see the <a href="/documentation/filter.html#asset-values-by-locale">Filter asset values by locale</a> section
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "search_after" $search_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asset_family_code: $asset_family_code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/assets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several assets
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/assets
# operationId: patch_assets
export def "rest-asset-families-assets assets-by-asset_family_code-1" [
  asset_family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<code: string, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/assets"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an asset
#
# DELETE /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# operationId: delete_assets__code_
export def "rest-asset-families-assets delete" [
  asset_family_code: string
  code: string
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
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an asset of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# operationId: get_assets__code_
export def "rest-asset-families-assets get" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an asset
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/assets/{code}
# operationId: patch_asset__code_
# --values shape: {attributeCode?: list}
export def "rest-asset-families-assets patch" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Code of the asset
  --created: string # Date of creation (format: dateTime)
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Asset attributes values, see the <a href='/concepts/asset-manager.html#focus-on-the-asset-values'>Focus on the asset values</a> section for more details. — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/assets/{code}"))
  let body = {"code": $body_code, "created": $created, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of attributes of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes
# operationId: get_asset_families__code__attributes
export def "rest-asset-families-attributes attributes" [
  asset_family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of attribute options of a given attribute for a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options
# operationId: get_asset_family_attributes__attribute_code__options
export def "rest-asset-families-attributes-options options" [
  asset_family_code: string
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, attribute_code: $attribute_code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an attribute option for a given attribute of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}
# operationId: get_asset_attributes__attribute_code__options__code_
export def "rest-asset-families-attributes-options get" [
  asset_family_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an asset attribute option for a given asset family
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}
# operationId: patch_asset_attributes__attribute_code__options__code_
# --labels shape: {localeCode?: string}
export def "rest-asset-families-attributes-options patch" [
  asset_family_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Attribute's option code
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes/{attribute_code}/options/{code}"))
  let body = {"code": $body_code, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an attribute of a given asset family
#
# GET /api/rest/v1/asset-families/{asset_family_code}/attributes/{code}
# operationId: get_asset_family_attributes__code_
export def "rest-asset-families-attributes get" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_read_only: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, media_type: string, min_value: string, prefix: string, suffix: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an attribute of a given asset family
#
# PATCH /api/rest/v1/asset-families/{asset_family_code}/attributes/{code}
# operationId: patch_asset_family_attributes__code_
# --labels shape: {localeCode?: string}
export def "rest-asset-families-attributes patch" [
  asset_family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list # Extensions allowed when the attribute type is `media_file` (default: [])
  --body-code: string # Attribute code
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `number` (default: false)
  --is-read-only: oneof<nothing, bool> # Whether the attribute should be in read only mode only in the UI, but you can still update it with the API (default: false)
  --is-required-for-completeness: oneof<nothing, bool> # Whether the attribute should be part of the record's completeness calculation (default: false)
  --is-rich-text-editor: oneof<nothing, bool> # Whether the UI should display a rich text editor instead of a simple text area when the attribute type is `text`
  --is-textarea: oneof<nothing, bool> # Whether the UI should display a text area instead of a simple field when the attribute type is `text` (default: false)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --max-characters: int # Maximum number of characters allowed for the value of the attribute when the attribute type is `text`
  --max-file-size: string # Max file size in MB when the attribute type is `media_file`
  --max-value: string # Maximum value allowed when the attribute type is `number`
  media_type: string@media-type-completer # For the `media_link` attribute type, it is the type of the media behind the url, to allow its preview in the PIM. For the `media_file` attribute type, it is the type of the file.
  --min-value: string # Minimum value allowed when the attribute type is `number`
  --prefix: string # Prefix of the `media_link` attribute type. The common url root that prefixes the link to the media
  --suffix: string # Suffix of the `media_link` attribute type. The common url suffix for the media
  type: string@type-completer # Attribute type. See <a href='/concepts/asset-manager.html#asset-attribute'>type</a> section for more details.
  --validation-regexp: string # Regexp expression used to validate the attribute value when the attribute type is `text`
  --validation-rule: string@validation-rule-completer # Validation rule type used to validate the attribute value when the attribute type is `text` (default: none)
  --value-per-channel: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --value-per-locale: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_family_code: $asset_family_code, code: $code} | format pattern "/api/rest/v1/asset-families/{asset_family_code}/attributes/{code}"))
  let body = {"allowed_extensions": $allowed_extensions, "code": $body_code, "decimals_allowed": $decimals_allowed, "is_read_only": $is_read_only, "is_required_for_completeness": $is_required_for_completeness, "is_rich_text_editor": $is_rich_text_editor, "is_textarea": $is_textarea, "labels": $labels, "max_characters": $max_characters, "max_file_size": $max_file_size, "max_value": $max_value, "media_type": $media_type, "min_value": $min_value, "prefix": $prefix, "suffix": $suffix, "type": $type, "validation_regexp": $validation_regexp, "validation_rule": $validation_rule, "value_per_channel": $value_per_channel, "value_per_locale": $value_per_locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an asset family
#
# GET /api/rest/v1/asset-families/{code}
# operationId: get_asset_family__code_
export def "rest-asset-families get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribute_as_main_media: string, code: string, labels: record<localeCode: string>, naming_convention: record<abort_asset_creation_on_error: bool, pattern: string, source: record>, product_link_rules: table<assign_assets_to: list, product_selections: list>, transformations: table<filename_prefix: string, filename_suffix: string, label: string, operations: record, source: record, target: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-families/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an asset family
#
# PATCH /api/rest/v1/asset-families/{code}
# operationId: patch_asset_family__code_
# --labels shape: {localeCode?: string}
# --naming_convention shape: {abort_asset_creation_on_error?: bool, pattern?: string, source?: record}
# --product_link_rules item shape: {assign_assets_to?: list, product_selections?: list}
# --transformations item shape: {filename_prefix?: string, filename_suffix?: string, label: string, operations: record, source: record, target: record}
export def "rest-asset-families patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-main-media: string # Attribute code that is used as the main media of the asset family. (default: First media file or media link attribute that was created)
  --body-code: string # Asset family code
  --labels: record # Asset family labels for each locale (default: {}) — shape: {localeCode?: string}
  --naming-convention: record # The naming convention ran over the asset code or the main media filename upon each asset creation, in order to automatically set several values in asset attributes. To learn more and see the format of this property, take a look at <a href='/concepts/asset-manager.html#focus-on-the-naming-convention'>here</a>. (default: {}) — shape: {abort_asset_creation_on_error?: bool, pattern?: string, source?: record}
  --product-link-rules: list # The rules that will be run after the asset creation, in order to automatically link the assets of this family to a set of products. To understand the format of this property, see <a href='/concepts/asset-manager.html#focus-on-the-product-link-rule'>here</a>. (default: []) — item shape: {assign_assets_to?: list, product_selections?: list}
  --transformations: list # The transformations to perform on source files in order to generate new files into your asset attributes (only available since v4.0). To understand the format of this property, see <a href='/concepts/asset-manager.html#focus-on-the-transformations'>here</a>. (default: []) — item shape: {filename_prefix?: string, filename_suffix?: string, label: string, operations: record, source: record, target: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-families/{code}"))
  let body = {"attribute_as_main_media": $attribute_as_main_media, "code": $body_code, "labels": $labels, "naming_convention": $naming_convention, "product_link_rules": $product_link_rules, "transformations": $transformations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new media file for an asset
#
# POST /api/rest/v1/asset-media-files
# operationId: post_asset_media_files
export def "rest-asset-media-files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed
  file: string # The binary of the media file (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/asset-media-files")
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the media file associated to an asset
#
# GET /api/rest/v1/asset-media-files/{code}
# operationId: get_asset_media_files__code
export def "rest-asset-media-files code" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-media-files/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of PAM asset tags
#
# GET /api/rest/v1/asset-tags
# operationId: get_asset_tags
export def "rest-asset-tags tag-s" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/asset-tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a PAM asset tag
#
# GET /api/rest/v1/asset-tags/{code}
# operationId: get_asset_tags__code_
export def "rest-asset-tags get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-tags/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a PAM asset tag
#
# PATCH /api/rest/v1/asset-tags/{code}
# operationId: patch_asset_tags__code_
export def "rest-asset-tags patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # PAM asset tag code
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/asset-tags/{code}"))
  let body = {"code": $body_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of PAM assets
#
# GET /api/rest/v1/assets
# operationId: get_pam_assets
export def "rest-assets assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagination-type: string@pagination-type-completer # Pagination method type, see <a href="/documentation/pagination.html">Pagination</a> section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagination_type" $pagination_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several PAM assets
#
# PATCH /api/rest/v1/assets
# operationId: patch_pam_assets
# --reference_files item shape: {_link?: record, code?: string, locale?: string}
# --variation_files item shape: {_link?: record, code?: string, locale?: string, scope?: string}
export def "rest-assets assets-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # Codes of the PAM asset categories in which the asset is classified (default: [])
  code: string # PAM asset code
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/assets")
  let body = {"categories": $categories, "code": $code, "description": $description, "end_of_use": $end_of_use, "localizable": $localizable, "reference_files": $reference_files, "tags": $tags, "variation_files": $variation_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new PAM asset
#
# POST /api/rest/v1/assets
# operationId: post_pam_assets
# --reference_files item shape: {_link?: record, code?: string, locale?: string}
# --variation_files item shape: {_link?: record, code?: string, locale?: string, scope?: string}
export def "rest-assets assets-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # Codes of the PAM asset categories in which the asset is classified (default: [])
  code: string # PAM asset code
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/assets")
  let body = {"categories": $categories, "code": $code, "description": $description, "end_of_use": $end_of_use, "localizable": $localizable, "reference_files": $reference_files, "tags": $tags, "variation_files": $variation_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a reference file
#
# GET /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}
# operationId: get_reference_files__locale_code_
export def "rest-assets-reference-files get" [
  asset_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_link: record<download: record<href: string>>, code: string, locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_code: $asset_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a new reference file
#
# POST /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}
# operationId: post_reference_files__locale_code_
export def "rest-assets-reference-files post" [
  asset_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed
  file: string # The binaries of the file (format: binary)
]: any -> record<errors: table<channel: string, locale: string, message: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_code: $asset_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a reference file
#
# GET /api/rest/v1/assets/{asset_code}/reference-files/{locale_code}/download
# operationId: get_reference_files__channel_code__locale_code__download
export def "rest-assets-reference-files-download download" [
  asset_code: string
  locale_code: string
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
  let full_url = (build-url $base ({asset_code: $asset_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/reference-files/{locale_code}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a variation file
#
# GET /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}
# operationId: get_variation_files__channel_code__locale_code
export def "rest-assets-variation-files code" [
  asset_code: string
  channel_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_link: record<download: record<href: string>>, code: string, locale: string, scope: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a new variation file
#
# POST /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}
# operationId: post_variation_files__channel_code__locale_code_
export def "rest-assets-variation-files post" [
  asset_code: string
  channel_code: string
  locale_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed
  file: string # The binaries of the file (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a variation file
#
# GET /api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}/download
# operationId: get_variation_files__channel_code__locale_code__download
export def "rest-assets-variation-files-download download" [
  asset_code: string
  channel_code: string
  locale_code: string
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
  let full_url = (build-url $base ({asset_code: $asset_code, channel_code: $channel_code, locale_code: $locale_code} | format pattern "/api/rest/v1/assets/{asset_code}/variation-files/{channel_code}/{locale_code}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a PAM asset
#
# GET /api/rest/v1/assets/{code}
# operationId: get_pam_assets__code_
export def "rest-assets get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categories: list<string>, code: string, description: string, end_of_use: string, localizable: bool, reference_files: table<_link: record, code: string, locale: string>, tags: list<string>, variation_files: table<_link: record, code: string, locale: string, scope: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/assets/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a PAM asset
#
# PATCH /api/rest/v1/assets/{code}
# operationId: patch_pam_assets__code_
# --reference_files item shape: {_link?: record, code?: string, locale?: string}
# --variation_files item shape: {_link?: record, code?: string, locale?: string, scope?: string}
export def "rest-assets patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # Codes of the PAM asset categories in which the asset is classified (default: [])
  --body-code: string # PAM asset code
  --description: string # Description of the PAM asset
  --end-of-use: string # Date on which the PAM asset expire (format: dateTime)
  --localizable: oneof<nothing, bool> # Whether the asset is localized or not, meaning if you want to have different reference files for each of your locale (default: false)
  --reference-files: list # Reference files of the PAM asset — item shape: {_link?: record, code?: string, locale?: string}
  --tags: list # Tags of the PAM asset (default: [])
  --variation-files: list # Variations of the PAM asset — item shape: {_link?: record, code?: string, locale?: string, scope?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/assets/{code}"))
  let body = {"categories": $categories, "code": $body_code, "description": $description, "end_of_use": $end_of_use, "localizable": $localizable, "reference_files": $reference_files, "tags": $tags, "variation_files": $variation_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of association types
#
# GET /api/rest/v1/association-types
# operationId: association_types_get_list
export def "rest-association-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/association-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several association types
#
# PATCH /api/rest/v1/association-types
# operationId: several_association_types_patch
# --labels shape: {localeCode?: string}
export def "rest-association-types patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Association type code
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/association-types")
  let body = {"code": $code, "is_quantified": $is_quantified, "is_two_way": $is_two_way, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new association type
#
# POST /api/rest/v1/association-types
# operationId: association_types_post
# --labels shape: {localeCode?: string}
export def "rest-association-types post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Association type code
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/association-types")
  let body = {"code": $code, "is_quantified": $is_quantified, "is_two_way": $is_two_way, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an association type
#
# GET /api/rest/v1/association-types/{code}
# operationId: association_types_get
export def "rest-association-types get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, is_quantified: bool, is_two_way: bool, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/association-types/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an association type
#
# PATCH /api/rest/v1/association-types/{code}
# operationId: association_types_patch
# --labels shape: {localeCode?: string}
export def "rest-association-types patch-by-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Association type code
  --is-quantified: oneof<nothing, bool> # When true, the association is a quantified association (Only available in the PIM Serenity version.) (default: false)
  --is-two-way: oneof<nothing, bool> # When true, the association is a two-way association (Only available in the PIM Serenity version.) (default: false)
  --labels: record # Association type labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/association-types/{code}"))
  let body = {"code": $body_code, "is_quantified": $is_quantified, "is_two_way": $is_two_way, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of attribute groups
#
# GET /api/rest/v1/attribute-groups
# operationId: attribute_groups_get_list
export def "rest-attribute-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter attribute groups, for more details see the <a href="/documentation/filter.html#filter-attribute-groups">Filters</a> section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/attribute-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several attribute groups
#
# PATCH /api/rest/v1/attribute-groups
# operationId: several_attribute_groups_patch
# --labels shape: {localeCode?: string}
export def "rest-attribute-groups patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attribute codes that compose the attribute group (default: [])
  code: string # Attribute group code
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/attribute-groups")
  let body = {"attributes": $attributes, "code": $code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new attribute group
#
# POST /api/rest/v1/attribute-groups
# operationId: attribute_groups_post
# --labels shape: {localeCode?: string}
export def "rest-attribute-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attribute codes that compose the attribute group (default: [])
  code: string # Attribute group code
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/attribute-groups")
  let body = {"attributes": $attributes, "code": $code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an attribute group
#
# GET /api/rest/v1/attribute-groups/{code}
# operationId: attribute_groups_get
export def "rest-attribute-groups get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: list<string>, code: string, labels: record<localeCode: string>, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/attribute-groups/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an attribute group
#
# PATCH /api/rest/v1/attribute-groups/{code}
# operationId: attribute_groups_patch
# --labels shape: {localeCode?: string}
export def "rest-attribute-groups patch-by-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: list # Attribute codes that compose the attribute group (default: [])
  --body-code: string # Attribute group code
  --labels: record # Attribute group labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Attribute group order among other attribute groups (default: 0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/attribute-groups/{code}"))
  let body = {"attributes": $attributes, "code": $body_code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of attributes
#
# GET /api/rest/v1/attributes
# operationId: get_attributes
export def "rest-attributes attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter attributes, for more details see the <a href="/documentation/filter.html#filter-attributes">Filters</a> section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-table-select-options: oneof<nothing, bool> # Return the options of 'select' column types (of a table attribute) in the response. (Only available since the 7.0 version) (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar") (serialize-qp "with_table_select_options" $with_table_select_options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several attributes
#
# PATCH /api/rest/v1/attributes
# operationId: patch_attributes
# --group_labels shape: {localeCode?: string}
# --labels shape: {localeCode?: string}
# --table_configuration item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
export def "rest-attributes attributes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list # To make the attribute locale specfic, specify here for which locales it is specific
  code: string # Attribute code
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See <a href='/concepts/catalog-structure.html#attribute'>type</a> section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/attributes")
  let body = {"allowed_extensions": $allowed_extensions, "available_locales": $available_locales, "code": $code, "date_max": $date_max, "date_min": $date_min, "decimals_allowed": $decimals_allowed, "default_metric_unit": $default_metric_unit, "default_value": $default_value, "group": $group, "group_labels": $group_labels, "labels": $labels, "localizable": $localizable, "max_characters": $max_characters, "max_file_size": $max_file_size, "metric_family": $metric_family, "negative_allowed": $negative_allowed, "number_max": $number_max, "number_min": $number_min, "reference_data_name": $reference_data_name, "scopable": $scopable, "sort_order": $sort_order, "table_configuration": $table_configuration, "type": $type, "unique": $unique, "useable_as_grid_filter": $useable_as_grid_filter, "validation_regexp": $validation_regexp, "validation_rule": $validation_rule, "wysiwyg_enabled": $wysiwyg_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new attribute
#
# POST /api/rest/v1/attributes
# operationId: post_attributes
# --group_labels shape: {localeCode?: string}
# --labels shape: {localeCode?: string}
# --table_configuration item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
export def "rest-attributes attributes-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list # To make the attribute locale specfic, specify here for which locales it is specific
  code: string # Attribute code
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See <a href='/concepts/catalog-structure.html#attribute'>type</a> section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/attributes")
  let body = {"allowed_extensions": $allowed_extensions, "available_locales": $available_locales, "code": $code, "date_max": $date_max, "date_min": $date_min, "decimals_allowed": $decimals_allowed, "default_metric_unit": $default_metric_unit, "default_value": $default_value, "group": $group, "group_labels": $group_labels, "labels": $labels, "localizable": $localizable, "max_characters": $max_characters, "max_file_size": $max_file_size, "metric_family": $metric_family, "negative_allowed": $negative_allowed, "number_max": $number_max, "number_min": $number_min, "reference_data_name": $reference_data_name, "scopable": $scopable, "sort_order": $sort_order, "table_configuration": $table_configuration, "type": $type, "unique": $unique, "useable_as_grid_filter": $useable_as_grid_filter, "validation_regexp": $validation_regexp, "validation_rule": $validation_rule, "wysiwyg_enabled": $wysiwyg_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of attribute options
#
# GET /api/rest/v1/attributes/{attribute_code}/options
# operationId: get_attributes__attribute_code__options
export def "rest-attributes-options options-by-attribute_code" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attribute_code: $attribute_code} | format pattern "/api/rest/v1/attributes/{attribute_code}/options") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several attribute options
#
# PATCH /api/rest/v1/attributes/{attribute_code}/options
# operationId: patch_attributes__attribute_code__options
# --labels shape: {localeCode?: string}
export def "rest-attributes-options options-by-attribute_code-1" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  code: string # Code of option
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: $attribute_code} | format pattern "/api/rest/v1/attributes/{attribute_code}/options"))
  let body = {"attribute": $attribute, "code": $code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new attribute option
#
# POST /api/rest/v1/attributes/{attribute_code}/options
# operationId: post_attributes__attribute_code__options
# --labels shape: {localeCode?: string}
export def "rest-attributes-options options-by-attribute_code-2" [
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  code: string # Code of option
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: $attribute_code} | format pattern "/api/rest/v1/attributes/{attribute_code}/options"))
  let body = {"attribute": $attribute, "code": $code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an attribute option
#
# GET /api/rest/v1/attributes/{attribute_code}/options/{code}
# operationId: get_attributes__attribute_code__options__code_
export def "rest-attributes-options get" [
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribute: string, code: string, labels: record<localeCode: string>, sort_order: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/attributes/{attribute_code}/options/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an attribute option
#
# PATCH /api/rest/v1/attributes/{attribute_code}/options/{code}
# operationId: patch_attributes__attribute_code__options__code_
# --labels shape: {localeCode?: string}
export def "rest-attributes-options patch" [
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute: string # Code of attribute related to the attribute option
  --body-code: string # Code of option
  --labels: record # Attribute option labels for each locale (default: {}) — shape: {localeCode?: string}
  --sort-order: int # Order of attribute option
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/attributes/{attribute_code}/options/{code}"))
  let body = {"attribute": $attribute, "code": $body_code, "labels": $labels, "sort_order": $sort_order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an attribute
#
# GET /api/rest/v1/attributes/{code}
# operationId: get_attributes__code_
export def "rest-attributes get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-table-select-options: oneof<nothing, bool> # Return the options of 'select' column types (of a table attribute) in the response. (Only available since the 7.0 version) (default: false)
]: nothing -> record<allowed_extensions: list<string>, available_locales: list<string>, code: string, date_max: string, date_min: string, decimals_allowed: bool, default_metric_unit: string, default_value: bool, group: string, group_labels: record<localeCode: string>, labels: record<localeCode: string>, localizable: bool, max_characters: int, max_file_size: string, metric_family: string, negative_allowed: bool, number_max: string, number_min: string, reference_data_name: string, scopable: bool, sort_order: int, table_configuration: table<code: string, data_type: string, is_required_for_completeness: bool, labels: record, validations: record>, type: string, unique: bool, useable_as_grid_filter: bool, validation_regexp: string, validation_rule: string, wysiwyg_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_table_select_options" $with_table_select_options "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/attributes/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an attribute
#
# PATCH /api/rest/v1/attributes/{code}
# operationId: patch_attributes__code_
# --group_labels shape: {localeCode?: string}
# --labels shape: {localeCode?: string}
# --table_configuration item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
export def "rest-attributes patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list # Extensions allowed when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --available-locales: list # To make the attribute locale specfic, specify here for which locales it is specific
  --body-code: string # Attribute code
  --date-max: string # Maximum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --date-min: string # Minimum date allowed when the attribute type is `pim_catalog_date` (format: date-time)
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --default-metric-unit: string # Default metric unit when the attribute type is `pim_catalog_metric`
  --default-value: oneof<nothing, bool> # Default value for a Yes/No attribute, applied when creating a new product or product model (only available since the 5.0)
  group: string # Attribute group
  --group-labels: record # Group labels for each locale (default: {}) — shape: {localeCode?: string}
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --localizable: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
  --max-characters: int # Number maximum of characters allowed for the value of the attribute when the attribute type is `pim_catalog_text`, `pim_catalog_textarea` or `pim_catalog_identifier`
  --max-file-size: string # Max file size in MB when the attribute type is `pim_catalog_file` or `pim_catalog_image`
  --metric-family: string # Metric family when the attribute type is `pim_catalog_metric`
  --negative-allowed: oneof<nothing, bool> # Whether negative values are allowed when the attribute type is `pim_catalog_metric` or `pim_catalog_number`
  --number-max: string # Maximum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --number-min: string # Minimum integer value allowed when the attribute type is `pim_catalog_metric`, `pim_catalog_price` or `pim_catalog_number`
  --reference-data-name: string # Reference entity code when the attribute type is `akeneo_reference_entity` or `akeneo_reference_entity_collection` OR Asset family code when the attribute type is `pim_catalog_asset_collection`
  --scopable: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --sort-order: int # Order of the attribute in its group (default: 0)
  --table-configuration: list # Configuration of the Table attribute (columns) — item shape: {code: string, data_type: "select"|"text"|"number"|"boolean", is_required_for_completeness?: bool, labels?: record, validations?: record}
  type: string@type-completer-1 # Attribute type. See <a href='/concepts/catalog-structure.html#attribute'>type</a> section for more details.
  --unique: oneof<nothing, bool> # Whether two values for the attribute cannot be the same
  --useable-as-grid-filter: oneof<nothing, bool> # Whether the attribute can be used as a filter for the product grid in the PIM user interface
  --validation-regexp: string # Regexp expression used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --validation-rule: string # Validation rule type used to validate any attribute value when the attribute type is `pim_catalog_text` or `pim_catalog_identifier`
  --wysiwyg-enabled: oneof<nothing, bool> # Whether the WYSIWYG interface is shown when the attribute type is `pim_catalog_textarea`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/attributes/{code}"))
  let body = {"allowed_extensions": $allowed_extensions, "available_locales": $available_locales, "code": $body_code, "date_max": $date_max, "date_min": $date_min, "decimals_allowed": $decimals_allowed, "default_metric_unit": $default_metric_unit, "default_value": $default_value, "group": $group, "group_labels": $group_labels, "labels": $labels, "localizable": $localizable, "max_characters": $max_characters, "max_file_size": $max_file_size, "metric_family": $metric_family, "negative_allowed": $negative_allowed, "number_max": $number_max, "number_min": $number_min, "reference_data_name": $reference_data_name, "scopable": $scopable, "sort_order": $sort_order, "table_configuration": $table_configuration, "type": $type, "unique": $unique, "useable_as_grid_filter": $useable_as_grid_filter, "validation_regexp": $validation_regexp, "validation_rule": $validation_rule, "wysiwyg_enabled": $wysiwyg_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of owned catalogs
#
# GET /api/rest/v1/catalogs
# operationId: get_app_catalogs
export def "rest-catalogs catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 100)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/catalogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new catalog
#
# POST /api/rest/v1/catalogs
# operationId: post_app_catalog
export def "rest-catalogs catalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Catalog name
]: any -> record<enabled: bool, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/catalogs")
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a catalog
#
# DELETE /api/rest/v1/catalogs/{id}
# operationId: delete_app_catalog
export def "rest-catalogs catalog-by-id" [
  id: string
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/rest/v1/catalogs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a catalog
#
# GET /api/rest/v1/catalogs/{id}
# operationId: get_app_catalog
export def "rest-catalogs catalog-by-id-1" [
  id: string
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
  let full_url = (build-url $base ({id: $id} | format pattern "/api/rest/v1/catalogs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a catalog
#
# PATCH /api/rest/v1/catalogs/{id}
# operationId: patch_app_catalog
export def "rest-catalogs catalog-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Catalog name
]: any -> record<enabled: bool, id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/rest/v1/catalogs/{id}"))
  let body = {"name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of product uuids
#
# GET /api/rest/v1/catalogs/{id}/product-uuids
# operationId: get_app_catalog_product_uuids
export def "rest-catalogs-product-uuids uuids" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 100)
  --updated-before: string # Filter products that have been updated BEFORE the provided date (Only available on Catalogs endpoints) (format: date)
  --updated-after: string # Filter products that have been updated AFTER the provided date (Only available on Catalogs endpoints) (format: date)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "updated_after" $updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/rest/v1/catalogs/{id}/product-uuids") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of products related to a catalog
#
# GET /api/rest/v1/catalogs/{id}/products
# operationId: get_app_catalog_products
export def "rest-catalogs-products products" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 100)
  --updated-before: string # Filter products that have been updated BEFORE the provided date (Only available on Catalogs endpoints) (format: date)
  --updated-after: string # Filter products that have been updated AFTER the provided date (Only available on Catalogs endpoints) (format: date)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "updated_before" $updated_before "scalar") (serialize-qp "updated_after" $updated_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/rest/v1/catalogs/{id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product related to a catalog
#
# GET /api/rest/v1/catalogs/{id}/products/{uuid}
# operationId: get_app_catalog_products_uuid
export def "rest-catalogs-products uuid" [
  id: string
  uuid: string
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
  let full_url = (build-url $base ({id: $id, uuid: $uuid} | format pattern "/api/rest/v1/catalogs/{id}/products/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of categories
#
# GET /api/rest/v1/categories
# operationId: get_categories
export def "rest-categories categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter categories, for more details see the <a href="/documentation/filter.html#filter-categories">Filters</a> section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-position: oneof<nothing, bool> # Return information about category position into its category tree (only available since the 7.0 version)
  --with-enriched-attributes: oneof<nothing, bool> # Return attribute values of the category (only available on SaaS platforms)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar") (serialize-qp "with_position" $with_position "scalar") (serialize-qp "with_enriched_attributes" $with_enriched_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several categories
#
# PATCH /api/rest/v1/categories
# operationId: patch_categories
# --labels shape: {localeCode?: string}
# --values shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
export def "rest-categories categories-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Category code
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/categories")
  let body = {"code": $code, "labels": $labels, "parent": $parent, "position": $position, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new category
#
# POST /api/rest/v1/categories
# operationId: post_categories
# --labels shape: {localeCode?: string}
# --values shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
export def "rest-categories categories-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Category code
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/categories")
  let body = {"code": $code, "labels": $labels, "parent": $parent, "position": $position, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a category
#
# GET /api/rest/v1/categories/{code}
# operationId: get_categories__code_
export def "rest-categories get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-position: oneof<nothing, bool> # Return information about category position into its category tree (only available since the 7.0 version)
  --with-enriched-attributes: oneof<nothing, bool> # Return attribute values of the category (only available on SaaS platforms) <strong>[COMING SOON]<strong>
]: nothing -> record<code: string, labels: record<localeCode: string>, parent: string, position: int, updated: string, values: record<attributeCode_attributeUuid_channelCode_localeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_position" $with_position "scalar") (serialize-qp "with_enriched_attributes" $with_enriched_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/categories/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a category
#
# PATCH /api/rest/v1/categories/{code}
# operationId: patch_categories__code_
# --labels shape: {localeCode?: string}
# --values shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
export def "rest-categories patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Category code
  --labels: record # Category labels for each locale (default: {}) — shape: {localeCode?: string}
  --parent: string # Category code of the parent's category (default: null)
  --position: int # Position of the category in its level, start from 1 (only available since the 7.0 version and when query parameter "with_position" is set to "true")
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Attribute values — shape: {attributeCode|attributeUuid|channelCode|localeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/categories/{code}"))
  let body = {"code": $body_code, "labels": $labels, "parent": $parent, "position": $position, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a category media file [COMING SOON]
#
# GET /api/rest/v1/category-media-files/{code}/download
# operationId: get_category_media_files__code__download
export def "rest-category-media-files-download download" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/category-media-files/{code}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of channels
#
# GET /api/rest/v1/channels
# operationId: get_channels
export def "rest-channels channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several channels
#
# PATCH /api/rest/v1/channels
# operationId: several_channels_patch
# --conversion_units shape: {attributeCode?: string}
# --labels shape: {localeCode?: string}
export def "rest-channels patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  code: string # Channel code
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list # Codes of activated locales for the channel
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/channels")
  let body = {"category_tree": $category_tree, "code": $code, "conversion_units": $conversion_units, "currencies": $currencies, "labels": $labels, "locales": $locales} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new channel
#
# POST /api/rest/v1/channels
# operationId: channels_post
# --conversion_units shape: {attributeCode?: string}
# --labels shape: {localeCode?: string}
export def "rest-channels post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  code: string # Channel code
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list # Codes of activated locales for the channel
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/channels")
  let body = {"category_tree": $category_tree, "code": $code, "conversion_units": $conversion_units, "currencies": $currencies, "labels": $labels, "locales": $locales} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a channel
#
# GET /api/rest/v1/channels/{code}
# operationId: get_channels__code_
export def "rest-channels get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category_tree: string, code: string, conversion_units: record<attributeCode: string>, currencies: list<string>, labels: record<localeCode: string>, locales: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/channels/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a channel
#
# PATCH /api/rest/v1/channels/{code}
# operationId: channels_patch
# --conversion_units shape: {attributeCode?: string}
# --labels shape: {localeCode?: string}
export def "rest-channels patch-by-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category_tree: string # Code of the category tree linked to the channel
  --body-code: string # Channel code
  --conversion-units: record # Units to which the given metric attributes should be converted when exporting products — shape: {attributeCode?: string}
  currencies: list # Codes of activated currencies for the channel
  --labels: record # Channel labels for each locale (default: {}) — shape: {localeCode?: string}
  locales: list # Codes of activated locales for the channel
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/channels/{code}"))
  let body = {"category_tree": $category_tree, "code": $body_code, "conversion_units": $conversion_units, "currencies": $currencies, "labels": $labels, "locales": $locales} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of currencies
#
# GET /api/rest/v1/currencies
# operationId: currencies_get_list
export def "rest-currencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a currency
#
# GET /api/rest/v1/currencies/{code}
# operationId: currencies_get
export def "rest-currencies get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/currencies/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of families
#
# GET /api/rest/v1/families
# operationId: get_families
export def "rest-families families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter families, for more details see the <a href="/documentation/filter.html#filter-families">Filters</a> section.
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/families" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several families
#
# PATCH /api/rest/v1/families
# operationId: patch_families
# --attribute_requirements shape: {channelCode?: list}
# --labels shape: {localeCode?: string}
export def "rest-families families-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list}
  --attributes: list # Attributes codes that compose the family (default: [])
  code: string # Family code
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/families")
  let body = {"attribute_as_image": $attribute_as_image, "attribute_as_label": $attribute_as_label, "attribute_requirements": $attribute_requirements, "attributes": $attributes, "code": $code, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new family
#
# POST /api/rest/v1/families
# operationId: post_families
# --attribute_requirements shape: {channelCode?: list}
# --labels shape: {localeCode?: string}
export def "rest-families families-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list}
  --attributes: list # Attributes codes that compose the family (default: [])
  code: string # Family code
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/families")
  let body = {"attribute_as_image": $attribute_as_image, "attribute_as_label": $attribute_as_label, "attribute_requirements": $attribute_requirements, "attributes": $attributes, "code": $code, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a family
#
# GET /api/rest/v1/families/{code}
# operationId: get_families__code_
export def "rest-families get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attribute_as_image: string, attribute_as_label: string, attribute_requirements: record<channelCode: list<string>>, attributes: list<string>, code: string, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/families/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a family
#
# PATCH /api/rest/v1/families/{code}
# operationId: patch_families__code_
# --attribute_requirements shape: {channelCode?: list}
# --labels shape: {localeCode?: string}
export def "rest-families patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attribute-as-image: string # Attribute code used as the main picture in the user interface (only since v2.0) (default: null)
  attribute_as_label: string # Attribute code used as label
  --attribute-requirements: record # Attributes codes of the family that are required for the completeness calculation for each channel — shape: {channelCode?: list}
  --attributes: list # Attributes codes that compose the family (default: [])
  --body-code: string # Family code
  --labels: record # Family labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/families/{code}"))
  let body = {"attribute_as_image": $attribute_as_image, "attribute_as_label": $attribute_as_label, "attribute_requirements": $attribute_requirements, "attributes": $attributes, "code": $body_code, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of family variants
#
# GET /api/rest/v1/families/{family_code}/variants
# operationId: get_families__family_code__variants
export def "rest-families-variants variants-by-family_code" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({family_code: $family_code} | format pattern "/api/rest/v1/families/{family_code}/variants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several family variants
#
# PATCH /api/rest/v1/families/{family_code}/variants
# operationId: patch_families__family_code__variants
# --labels shape: {localeCode?: string}
# --variant_attribute_sets item shape: {attributes?: list, axes: list, level: int}
export def "rest-families-variants variants-by-family_code-1" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Family variant code
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list, axes: list, level: int}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({family_code: $family_code} | format pattern "/api/rest/v1/families/{family_code}/variants"))
  let body = {"code": $code, "labels": $labels, "variant_attribute_sets": $variant_attribute_sets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new family variant
#
# POST /api/rest/v1/families/{family_code}/variants
# operationId: post_families__family_code__variants
# --labels shape: {localeCode?: string}
# --variant_attribute_sets item shape: {attributes?: list, axes: list, level: int}
export def "rest-families-variants variants-by-family_code-2" [
  family_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Family variant code
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list, axes: list, level: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({family_code: $family_code} | format pattern "/api/rest/v1/families/{family_code}/variants"))
  let body = {"code": $code, "labels": $labels, "variant_attribute_sets": $variant_attribute_sets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a family variant
#
# GET /api/rest/v1/families/{family_code}/variants/{code}
# operationId: get_families__family_code__variants__code__
export def "rest-families-variants get" [
  family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, labels: record<localeCode: string>, variant_attribute_sets: table<attributes: list, axes: list, level: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({family_code: $family_code, code: $code} | format pattern "/api/rest/v1/families/{family_code}/variants/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a family variant
#
# PATCH /api/rest/v1/families/{family_code}/variants/{code}
# operationId: patch_families__family_code__variants__code__
# --labels shape: {localeCode?: string}
# --variant_attribute_sets item shape: {attributes?: list, axes: list, level: int}
export def "rest-families-variants patch" [
  family_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Family variant code
  --labels: record # Family variant labels for each locale (default: {}) — shape: {localeCode?: string}
  variant_attribute_sets: list # Attributes distribution according to the enrichment level — item shape: {attributes?: list, axes: list, level: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({family_code: $family_code, code: $code} | format pattern "/api/rest/v1/families/{family_code}/variants/{code}"))
  let body = {"code": $body_code, "labels": $labels, "variant_attribute_sets": $variant_attribute_sets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of locales
#
# GET /api/rest/v1/locales
# operationId: get_locales
export def "rest-locales locales" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter locales, for more details see the <a href="/documentation/filter.html">Filters</a> section
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/locales" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a locale
#
# GET /api/rest/v1/locales/{code}
# operationId: get_locales__code_
export def "rest-locales get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/locales/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of measure familiy
#
# GET /api/rest/v1/measure-families
# operationId: measure_families_get_list
export def "rest-measure-families list" [
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
  let full_url = (build-url $base "/api/rest/v1/measure-families")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a measure family
#
# GET /api/rest/v1/measure-families/{code}
# operationId: measure_families_get
export def "rest-measure-families get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, standard: string, units: table<code: string, convert: record, symbol: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/measure-families/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of measurement families
#
# GET /api/rest/v1/measurement-families
# operationId: measurement_families_get_list
export def "rest-measurement-families list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, labels: record<localeCode: string>, standard_unit_code: string, units: record<unitCode: record<code: string, convert_from_standard: list, labels: record, symbol: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/measurement-families")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several measurement families
#
# PATCH /api/rest/v1/measurement-families
# operationId: patch_measurement_families
export def "rest-measurement-families families" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<code: string, errors: list<record>, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/measurement-families")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of product media files
#
# GET /api/rest/v1/media-files
# operationId: get_media_files
export def "rest-media-files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/media-files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new product media file
#
# POST /api/rest/v1/media-files
# operationId: post_media_files
export def "rest-media-files files-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed
  file: string # The binaries of the file (format: binary)
  --product: string # The product to which the media file will be associated. It is a JSON string that follows this format '{"identifier":"product_identifier", "attribute":"attribute_code", "scope":"channel_code","locale":"locale_code"}'. You have to either use this field or the `product_model` field, but not both at the same time.
  --product-model: string # The product model to which the media file will be associated. It is a JSON string that follows this format '{"code":"product_model_code", "attribute":"attribute_code", "scope":"channel_code","locale":"locale_code"}'. You have to either use this field or the `product` field, but not both at the same time.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/media-files")
  let body = {"file": $file, "product": $product, "product_model": $product_model} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a product media file
#
# GET /api/rest/v1/media-files/{code}
# operationId: get_media_files__code_
export def "rest-media-files get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<download: record<href: string>>, code: string, extension: string, mime_type: string, original_filename: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/media-files/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a product media file
#
# GET /api/rest/v1/media-files/{code}/download
# operationId: get_media_files__code__download
export def "rest-media-files-download download" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/media-files/{code}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of product models
#
# GET /api/rest/v1/product-models
# operationId: get_product_models
export def "rest-product-models models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter product models, for more details see the <a href="/documentation/filter.html">Filters</a> section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-channel">Filter product values via channel</a> section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-locale">Filter product values via locale</a> section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the <a href="/documentation/filter.html#filter-product-values">Filter on product values</a> section and the <a href="/documentation/filter.html#filter-on-product-model-properties">Filter on product model properties</a> section
  --pagination-type: string@pagination-type-completer # Pagination method type, see <a href="/documentation/pagination.html">Pagination</a> section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product model quality scores in the response. <strong>(Only available since the 6.0 version)</strong>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "pagination_type" $pagination_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar") (serialize-qp "with_quality_scores" $with_quality_scores "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/product-models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several product models
#
# PATCH /api/rest/v1/product-models
# operationId: patch_product_models
# --associations shape: {associationTypeCode?: record}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-product-models models-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product model is categorized (default: [])
  code: string # Product model code
  --created: string # Date of creation (format: dateTime)
  --family: string # <a href='api-reference.html#Family'>Family</a> code  from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a>. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (<strong>only available since the 7.0 version</strong> and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/product-models")
  let body = {"associations": $associations, "categories": $categories, "code": $code, "created": $created, "family": $family, "family_variant": $family_variant, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new product model
#
# POST /api/rest/v1/product-models
# operationId: post_product_models
# --associations shape: {associationTypeCode?: record}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-product-models models-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product model is categorized (default: [])
  code: string # Product model code
  --created: string # Date of creation (format: dateTime)
  --family: string # <a href='api-reference.html#Family'>Family</a> code  from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a>. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (<strong>only available since the 7.0 version</strong> and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/product-models")
  let body = {"associations": $associations, "categories": $categories, "code": $code, "created": $created, "family": $family, "family_variant": $family_variant, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a product model
#
# DELETE /api/rest/v1/product-models/{code}
# operationId: delete_product_models__code_
export def "rest-product-models delete" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/product-models/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product model
#
# GET /api/rest/v1/product-models/{code}
# operationId: get_product_models__code_
export def "rest-product-models get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-quality-scores: oneof<nothing, bool> # Return product model quality scores in the response. <strong>(Only available since the 6.0 version)</strong>
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_quality_scores" $with_quality_scores "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/product-models/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a product model
#
# PATCH /api/rest/v1/product-models/{code}
# operationId: patch_product_models__code_
# --associations shape: {associationTypeCode?: record}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-product-models patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product and/or other product models, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product model is categorized (default: [])
  --body-code: string # Product model code
  --created: string # Date of creation (format: dateTime)
  --family: string # <a href='api-reference.html#Family'>Family</a> code  from which the product inherits its attributes and attributes requirements (since the 3.2)
  family_variant: string # Family variant code from which the product model inherits its attributes and variant attributes
  --metadata: record # More information around the product model (only available since the v2.3 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a>. This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product model quality scores for each channel/locale combination (<strong>only available since the 7.0 version</strong> and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --values: record # Product model attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/product-models/{code}"))
  let body = {"associations": $associations, "categories": $categories, "code": $body_code, "created": $created, "family": $family, "family_variant": $family_variant, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a draft
#
# GET /api/rest/v1/product-models/{code}/draft
# operationId: get_product_model_draft__code_
export def "rest-product-models-draft get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, code: string, created: string, family: string, family_variant: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/product-models/{code}/draft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a draft for approval
#
# POST /api/rest/v1/product-models/{code}/proposal
# operationId: post_product_model_proposal
export def "rest-product-models-proposal proposal" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/product-models/{code}/proposal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of products
#
# GET /api/rest/v1/products
# operationId: get_products
export def "rest-products products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter products, for more details see the <a href="/documentation/filter.html">Filters</a> section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-channel">Filter product values via channel</a> section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-locale">Filter product values via locale</a> section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the <a href="/documentation/filter.html#filter-product-values">Filter on product values</a> section
  --pagination-type: string@pagination-type-completer # Pagination method type, see <a href="/documentation/pagination.html">Pagination</a> section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "pagination_type" $pagination_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar") (serialize-qp "with_attribute_options" $with_attribute_options "scalar") (serialize-qp "with_quality_scores" $with_quality_scores "scalar") (serialize-qp "with_completenesses" $with_completenesses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several products
#
# PATCH /api/rest/v1/products
# operationId: patch_products
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products products-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> record<code: string, identifier: string, line: int, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/products")
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "identifier": $identifier, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new product
#
# POST /api/rest/v1/products
# operationId: post_products
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products products-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/products")
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "identifier": $identifier, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of products
#
# GET /api/rest/v1/products-uuid
# operationId: get_products_uuid
export def "rest-products-uuid uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter products, for more details see the <a href="/documentation/filter.html">Filters</a> section
  --scope: string # Filter product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-channel">Filter product values via channel</a> section
  --locales: string # Filter product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#via-locale">Filter product values via locale</a> section
  --attributes: string # Filter product values to only return those concerning the given attributes, for more details see the <a href="/documentation/filter.html#filter-product-values">Filter on product values</a> section
  --pagination-type: string@pagination-type-completer # Pagination method type, see <a href="/documentation/pagination.html">Pagination</a> section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "pagination_type" $pagination_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar") (serialize-qp "with_attribute_options" $with_attribute_options "scalar") (serialize-qp "with_quality_scores" $with_quality_scores "scalar") (serialize-qp "with_completenesses" $with_completenesses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/products-uuid" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several products
#
# PATCH /api/rest/v1/products-uuid
# operationId: patch_products_uuid
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products-uuid uuid-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  uuid: string # Product uuid
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> record<line: int, message: string, status_code: int, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/products-uuid")
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new product
#
# POST /api/rest/v1/products-uuid
# operationId: post_products_uuid
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products-uuid uuid-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product uuid
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/products-uuid")
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a product
#
# DELETE /api/rest/v1/products-uuid/{uuid}
# operationId: delete_products_uuid__uuid_
export def "rest-products-uuid delete" [
  uuid: string
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
  let full_url = (build-url $base ({uuid: $uuid} | format pattern "/api/rest/v1/products-uuid/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product
#
# GET /api/rest/v1/products-uuid/{uuid}
# operationId: get_products_uuid__uuid_
export def "rest-products-uuid get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_attribute_options" $with_attribute_options "scalar") (serialize-qp "with_quality_scores" $with_quality_scores "scalar") (serialize-qp "with_completenesses" $with_completenesses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({uuid: $uuid} | format pattern "/api/rest/v1/products-uuid/{uuid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a product
#
# PATCH /api/rest/v1/products-uuid/{uuid}
# operationId: patch_products_uuid__uuid_
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products-uuid patch" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --body-uuid: string # Product uuid
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uuid: $uuid} | format pattern "/api/rest/v1/products-uuid/{uuid}"))
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $body_uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a draft
#
# GET /api/rest/v1/products-uuid/{uuid}/draft
# operationId: get_draft_uuid__uuid_
export def "rest-products-uuid-draft get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({uuid: $uuid} | format pattern "/api/rest/v1/products-uuid/{uuid}/draft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a draft for approval
#
# POST /api/rest/v1/products-uuid/{uuid}/proposal
# operationId: post_proposal_uuid
export def "rest-products-uuid-proposal uuid" [
  uuid: string
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
  let full_url = (build-url $base ({uuid: $uuid} | format pattern "/api/rest/v1/products-uuid/{uuid}/proposal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a product
#
# DELETE /api/rest/v1/products/{code}
# operationId: delete_products__code_
export def "rest-products delete" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/products/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a product
#
# GET /api/rest/v1/products/{code}
# operationId: get_products__code_
export def "rest-products get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-attribute-options: oneof<nothing, bool> # Return labels of attribute options in the response. (Only available since the 5.0 version) (default: false)
  --with-quality-scores: oneof<nothing, bool> # Return product quality scores in the response. (Only available since the 5.0 version) (default: false)
  --with-completenesses: oneof<nothing, bool> # Return product completenesses in the response. (Only available since the 6.0 version) (default: false)
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_attribute_options" $with_attribute_options "scalar") (serialize-qp "with_quality_scores" $with_quality_scores "scalar") (serialize-qp "with_completenesses" $with_completenesses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/products/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a product
#
# PATCH /api/rest/v1/products/{code}
# operationId: patch_products__code_
# --associations shape: {associationTypeCode?: record}
# --completenesses item shape: {data?: int, locale?: string, scope?: string}
# --metadata shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
# --quantified_associations shape: {quantifiedAssociationTypeCode?: record}
# --values shape: {attributeCode?: list}
export def "rest-products patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --associations: record # Several associations related to groups, product models and/or other products, grouped by association types — shape: {associationTypeCode?: record}
  --categories: list # Codes of the <a href='api-reference.html#Category'>categories</a> in which the product is classified (default: [])
  --completenesses: list # Product completenesses for each channel/locale combination (only available since the 7.0 version, and when the "with_completenesses" query parameter is set to "true") — item shape: {data?: int, locale?: string, scope?: string}
  --created: string # Date of creation (format: dateTime)
  --enabled: oneof<nothing, bool> # Whether the product is enabled (default: true)
  --family: string # <a href='api-reference.html#Family'>Family</a> code from which the product inherits its attributes and attributes requirements. (default: null only in the case of a non variant product)
  --groups: list # Codes of the groups to which the product belong (default: [])
  identifier: string # Product identifier, i.e. the value of the only `pim_catalog_identifier` attribute
  --metadata: record # More information around the product (only available since the v2.0 in the Enterprise Edition) — shape: {workflow_status?: "read_only"|"draft_in_progress"|"proposal_waiting_for_approval"|"working_copy"}
  --parent: string # Code of the parent <a href='api-reference.html#Productmodel'>product model</a> when the product is a variant (only available since the 2.0). This parent can be modified since the 2.3. (default: null)
  --quality-scores: record # Product quality scores for each channel/locale combination (only available since the 5.0 and when the "with_quality_scores" query parameter is set to "true")
  --quantified-associations: record # Several quantified associations related to products and/or product models, grouped by quantified association types (only available since the 5.0) — shape: {quantifiedAssociationTypeCode?: record}
  --updated: string # Date of the last update (format: dateTime)
  --uuid: string # Product UUID
  --values: record # Product attributes values, see <a href='/concepts/products.html#focus-on-the-product-values'>Product values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/products/{code}"))
  let body = {"associations": $associations, "categories": $categories, "completenesses": $completenesses, "created": $created, "enabled": $enabled, "family": $family, "groups": $groups, "identifier": $identifier, "metadata": $metadata, "parent": $parent, "quality_scores": $quality_scores, "quantified_associations": $quantified_associations, "updated": $updated, "uuid": $uuid, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a draft
#
# GET /api/rest/v1/products/{code}/draft
# operationId: get_draft__code_
export def "rest-products-draft get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, completenesses: table<data: int, locale: string, scope: string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, metadata: record<workflow_status: string>, parent: string, quality_scores: record, quantified_associations: record<quantifiedAssociationTypeCode: record<product_models: list, products: list>>, updated: string, uuid: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/products/{code}/draft"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a draft for approval
#
# POST /api/rest/v1/products/{code}/proposal
# operationId: post_proposal
export def "rest-products-proposal proposal" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/products/{code}/proposal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of published products
#
# GET /api/rest/v1/published-products
# operationId: get_published_products
export def "rest-published-products products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter published products, for more details see the <a href="/documentation/filter.html">Filters</a> section
  --scope: string # Filter published product values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#filter-published-product-values">Filter on published product values</a> section
  --locales: string # Filter published product values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#filter-published-product-values">Filter on published product values</a> section
  --attributes: string # Filter published product values to only return those concerning the given attributes, for more details see the <a href="/documentation/filter.html#filter-product-values">Filter on product values</a> section
  --pagination-type: string@pagination-type-completer # Pagination method type, see <a href="/documentation/pagination.html">Pagination</a> section (default: page)
  --page: int # Number of the page to retrieve when using the `page` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html#pagination">Pagination</a> section (default: 1)
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
  --limit: int # Number of results by page, see <a href="/documentation/pagination.html">Pagination</a> section (default: 10)
  --with-count: oneof<nothing, bool> # Return the count of items in the response. Be carefull with that, on a big catalog, it can decrease performance in a significative way (default: false)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "pagination_type" $pagination_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "search_after" $search_after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_count" $with_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/published-products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a published product
#
# GET /api/rest/v1/published-products/{code}
# operationId: get_published_products__code_
export def "rest-published-products get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<associations: record<associationTypeCode: record<groups: list, product_models: list, products: list>>, categories: list<string>, created: string, enabled: bool, family: string, groups: list<string>, identifier: string, quantified_associations: record, updated: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/published-products/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of reference entities
#
# GET /api/rest/v1/reference-entities
# operationId: get_reference_entities
export def "rest-reference-entities entities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_after" $search_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rest/v1/reference-entities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new media file for a reference entity or a record
#
# POST /api/rest/v1/reference-entities-media-files
# operationId: post_reference_entity_media_files
export def "rest-reference-entities-media-files files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Equal to 'multipart/form-data', no other value allowed
  file: string # The binary of the media file (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/reference-entities-media-files")
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the media file associated to a reference entity or a record
#
# GET /api/rest/v1/reference-entities-media-files/{code}
# operationId: get_reference_entity_media_files__code
export def "rest-reference-entities-media-files code" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/reference-entities-media-files/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a reference entity
#
# GET /api/rest/v1/reference-entities/{code}
# operationId: get_reference_entities__code_
export def "rest-reference-entities get" [
  code: string
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
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/reference-entities/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a reference entity
#
# PATCH /api/rest/v1/reference-entities/{code}
# operationId: patch_reference_entity__code_
# --labels shape: {localeCode?: string}
export def "rest-reference-entities patch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Reference entity code
  --image: string # Code of the reference entity image
  --labels: record # Reference entity labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({code: $code} | format pattern "/api/rest/v1/reference-entities/{code}"))
  let body = {"code": $body_code, "image": $image, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of attributes of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes
# operationId: get_reference_entities__code__attributes
export def "rest-reference-entities-attributes attributes" [
  reference_entity_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of attribute options of a given attribute for a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options
# operationId: get_reference_entity_attributes__attribute_code__options
export def "rest-reference-entities-attributes-options options" [
  reference_entity_code: string
  attribute_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, attribute_code: $attribute_code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an attribute option for a given attribute of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}
# operationId: get_reference_entity_attributes__attribute_code__options__code_
export def "rest-reference-entities-attributes-options get" [
  reference_entity_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, labels: record<localeCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a reference entity attribute option
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}
# operationId: patch_reference_entity_attributes__attribute_code__options__code_
# --labels shape: {localeCode?: string}
export def "rest-reference-entities-attributes-options patch" [
  reference_entity_code: string
  attribute_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Attribute's option code
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, attribute_code: $attribute_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{attribute_code}/options/{code}"))
  let body = {"code": $body_code, "labels": $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an attribute of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}
# operationId: get_reference_entity_attributes__code_
export def "rest-reference-entities-attributes get" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowed_extensions: list<string>, code: string, decimals_allowed: bool, is_required_for_completeness: bool, is_rich_text_editor: bool, is_textarea: bool, labels: record<localeCode: string>, max_characters: int, max_file_size: string, max_value: string, min_value: string, reference_entity_code: string, type: string, validation_regexp: string, validation_rule: string, value_per_channel: bool, value_per_locale: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create an attribute of a given reference entity
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}
# operationId: patch_reference_entity_attributes__code_
# --labels shape: {localeCode?: string}
export def "rest-reference-entities-attributes patch" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-extensions: list # Extensions allowed when the attribute type is `image` (default: [])
  --body-code: string # Attribute code
  --decimals-allowed: oneof<nothing, bool> # Whether decimals are allowed when the attribute type is `number` (default: false)
  --is-required-for-completeness: oneof<nothing, bool> # Whether the attribute should be part of the record's completeness calculation (default: false)
  --is-rich-text-editor: oneof<nothing, bool> # Whether the UI should display a rich text editor instead of a simple text area when the attribute type is `text`
  --is-textarea: oneof<nothing, bool> # Whether the UI should display a text area instead of a simple field when the attribute type is `text` (default: false)
  --labels: record # Attribute labels for each locale (default: {}) — shape: {localeCode?: string}
  --max-characters: int # Maximum number of characters allowed for the value of the attribute when the attribute type is `text`
  --max-file-size: string # Max file size in MB when the attribute type is `image`
  --max-value: string # Maximum value allowed when the attribute type is `number`
  --min-value: string # Minimum value allowed when the attribute type is `number`
  --body-reference-entity-code: string # Code of the linked reference entity when the attribute type is `reference_entity_single_link` or `reference_entity_multiple_links`
  type: string@type-completer-2 # Attribute type. See <a href='/concepts/reference-entities.html#reference-entity-attribute'>type</a> section for more details.
  --validation-regexp: string # Regexp expression used to validate the attribute value when the attribute type is `text`
  --validation-rule: string@validation-rule-completer # Validation rule type used to validate the attribute value when the attribute type is `text` (default: none)
  --value-per-channel: oneof<nothing, bool> # Whether the attribute is scopable, i.e. can have one value by channel (default: false)
  --value-per-locale: oneof<nothing, bool> # Whether the attribute is localizable, i.e. can have one value by locale (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/attributes/{code}"))
  let body = {"allowed_extensions": $allowed_extensions, "code": $body_code, "decimals_allowed": $decimals_allowed, "is_required_for_completeness": $is_required_for_completeness, "is_rich_text_editor": $is_rich_text_editor, "is_textarea": $is_textarea, "labels": $labels, "max_characters": $max_characters, "max_file_size": $max_file_size, "max_value": $max_value, "min_value": $min_value, "reference_entity_code": $body_reference_entity_code, "type": $type, "validation_regexp": $validation_regexp, "validation_rule": $validation_rule, "value_per_channel": $value_per_channel, "value_per_locale": $value_per_locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of the records of a reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/records
# operationId: get_reference_entity_records
export def "rest-reference-entities-records records-by-reference_entity_code" [
  reference_entity_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter records of the reference entity, for more details see the <a href="/documentation/filter.html#filter-reference-entity-records">Filters</a> section
  --channel: string # Filter attribute values to return scopable attributes for the given channel as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#record-values-by-channel">Filter attribute values by channel</a> section
  --locales: string # Filter attribute values to return localizable attributes for the given locales as well as the non localizable/non scopable attributes, for more details see the <a href="/documentation/filter.html#record-values-by-locale">Filter attribute values by locale</a> section
  --search-after: string # Cursor when using the `search_after` pagination method type. <strong>Should never be set manually</strong>, see <a href="/documentation/pagination.html">Pagination</a> section (default: cursor to the first page)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "locales" $locales "scalar") (serialize-qp "search_after" $search_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/records") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create several reference entity records
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/records
# operationId: patch_reference_entity_records
export def "rest-reference-entities-records records-by-reference_entity_code-1" [
  reference_entity_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<code: string, message: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/records"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a record of a given reference entity
#
# GET /api/rest/v1/reference-entities/{reference_entity_code}/records/{code}
# operationId: get_reference_entity_records__code_
export def "rest-reference-entities-records get" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, created: string, updated: string, values: record<attributeCode: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/records/{code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update/create a record of a given reference entity
#
# PATCH /api/rest/v1/reference-entities/{reference_entity_code}/records/{code}
# operationId: patch_reference_entity_records__code_
# --values shape: {attributeCode?: list}
export def "rest-reference-entities-records patch" [
  reference_entity_code: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-code: string # Code of the record
  --created: string # Date of creation. (format: dateTime)
  --updated: string # Date of the last update. (format: dateTime)
  --values: record # Record attributes values, see <a href='/concepts/reference-entities.html#focus-on-the-reference-entity-record-values'>Reference entity record values</a> section for more details — shape: {attributeCode?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_entity_code: $reference_entity_code, code: $code} | format pattern "/api/rest/v1/reference-entities/{reference_entity_code}/records/{code}"))
  let body = {"code": $body_code, "created": $created, "updated": $updated, "values": $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get system information
#
# GET /api/rest/v1/system-information
# operationId: get_system_information
export def "rest-system-information get-rmation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<edition: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rest/v1/system-information")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
