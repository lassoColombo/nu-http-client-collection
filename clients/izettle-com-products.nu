# Auto-generated client for Product Library API v1.0.0
# Source: https://api.apis.guru/v2/specs/izettle.com/products/1.0.0/openapi.json
# Auth: --token flag or $env.PRODUCT_LIBRARY_API_TOKEN

const BASE_URL = "https://products.izettle.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PRODUCT_LIBRARY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://products.izettle.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def taxation-mode-completer [] { ["EXCLUSIVE" "INCLUSIVE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organizations-categories get-product-types" } } | get name | first)
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

# Retrieve all categories
#
# GET /organizations/{organizationUuid}/categories/v2
# operationId: getProductTypes
export def "organizations-categories get-product-types" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categories: table<name: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/categories/v2"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new category
#
# POST /organizations/{organizationUuid}/categories/v2
# operationId: createCategories
# --categories item shape: {name: string, uuid: string}
export def "organizations-categories create" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # item shape: {name: string, uuid: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/categories/v2"))
  let req_body = {"categories": $categories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a category
#
# DELETE /organizations/{organizationUuid}/categories/v2/{categoryUuid}
# operationId: deleteCategory
export def "organizations-categories delete-category" [
  organization_uuid: string
  category_uuid: string
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
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($category_uuid | is-empty) { error make --unspanned { msg: "path parameter 'categoryUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), category_uuid: (encode-path-segment $category_uuid)} | format pattern "/organizations/{organization_uuid}/categories/v2/{category_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Rename a category
#
# PATCH /organizations/{organizationUuid}/categories/v2/{categoryUuid}
# operationId: renameCategory
export def "organizations-categories rename-category" [
  organization_uuid: string
  category_uuid: string
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($category_uuid | is-empty) { error make --unspanned { msg: "path parameter 'categoryUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), category_uuid: (encode-path-segment $category_uuid)} | format pattern "/organizations/{organization_uuid}/categories/v2/{category_uuid}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve all discounts
#
# GET /organizations/{organizationUuid}/discounts
# operationId: getAllDiscounts
export def "organizations-discounts get-list" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/discounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a discount
#
# POST /organizations/{organizationUuid}/discounts
# operationId: createDiscount
# --amount shape: {amount: int, ... (1 more fields)}
export def "organizations-discounts create" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: record # shape: {amount: int, ... (1 more fields)}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --name: string
  --percentage: float
  uuid: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/discounts"))
  let req_body = {"amount": $amount, "description": $description, "externalReference": $external_reference, "imageLookupKeys": $image_lookup_keys, "name": $name, "percentage": $percentage, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a single discount
#
# DELETE /organizations/{organizationUuid}/discounts/{discountUuid}
# operationId: deleteDiscount
export def "organizations-discounts delete" [
  organization_uuid: string
  discount_uuid: string
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
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($discount_uuid | is-empty) { error make --unspanned { msg: "path parameter 'discountUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), discount_uuid: (encode-path-segment $discount_uuid)} | format pattern "/organizations/{organization_uuid}/discounts/{discount_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a single discount
#
# GET /organizations/{organizationUuid}/discounts/{discountUuid}
# operationId: getDiscount
export def "organizations-discounts get" [
  organization_uuid: string
  discount_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string
]: nothing -> record<amount: record<amount: int, currencyId: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, name: string, percentage: float, updated: string, updatedBy: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($discount_uuid | is-empty) { error make --unspanned { msg: "path parameter 'discountUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), discount_uuid: (encode-path-segment $discount_uuid)} | format pattern "/organizations/{organization_uuid}/discounts/{discount_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a single discount
#
# PUT /organizations/{organizationUuid}/discounts/{discountUuid}
# operationId: updateDiscount
# --amount shape: {amount: int, ... (1 more fields)}
export def "organizations-discounts update" [
  organization_uuid: string
  discount_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string
  --amount: record # shape: {amount: int, ... (1 more fields)}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --name: string
  --percentage: float
  uuid: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($discount_uuid | is-empty) { error make --unspanned { msg: "path parameter 'discountUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), discount_uuid: (encode-path-segment $discount_uuid)} | format pattern "/organizations/{organization_uuid}/discounts/{discount_uuid}"))
  let req_body = {"amount": $amount, "description": $description, "externalReference": $external_reference, "imageLookupKeys": $image_lookup_keys, "name": $name, "percentage": $percentage, "uuid": $uuid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve all library item images
#
# GET /organizations/{organizationUuid}/images
# operationId: getAllImageUrls
export def "organizations-images get-list-urls" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<imageUrls: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/images"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get status for latest import
#
# GET /organizations/{organizationUuid}/import/status
# operationId: getLatestImportStatus
export def "organizations-import-status get-latest" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/import/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get status for an import
#
# GET /organizations/{organizationUuid}/import/status/{importUuid}
# operationId: getStatusByUuid
export def "organizations-import-status get-by-uuid" [
  organization_uuid: string
  import_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($import_uuid | is-empty) { error make --unspanned { msg: "path parameter 'importUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), import_uuid: (encode-path-segment $import_uuid)} | format pattern "/organizations/{organization_uuid}/import/status/{import_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import library items
#
# POST /organizations/{organizationUuid}/import/v2
# operationId: importLibraryV2
# --products item shape: {categories?: list<string>, category?: record, description?: string, externalReference?: string, imageLookupKeys?: list<string>, metadata?: record, name: string, online?: record, presentation?: record, taxCode?: string, taxExempt?: bool, taxRates?: list<string>, unitName?: string, uuid: string, variantOptionDefinitions?: record, variants?: list, vatPercentage?: float}
export def "organizations-import import-library" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  products: list # item shape: {categories?: list<string>, category?: record, description?: string, externalReference?: string, imageLookupKeys?: list<string>, metadata?: record, name: string, online?: record, presentation?: record, taxCode?: string, taxExempt?: bool, taxRates?: list<string>, unitName?: string, uuid: string, variantOptionDefinitions?: record, variants?: list, vatPercentage?: float}
]: any -> record<created: string, errorMessage: string, finished: string, items: int, state: string, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/import/v2"))
  let req_body = {"products": $products} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve the entire library
#
# GET /organizations/{organizationUuid}/library
# operationId: getLibrary
export def "organizations-library get" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-log-uuid: string # format: uuid
  --limit: int # format: int32, default: 500
  --offset: string
  --all: oneof<nothing, bool>
]: nothing -> record<deletedDiscounts: list<string>, deletedProducts: list<string>, discounts: table<amount: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, name: string, percentage: float, updated: string, updatedBy: string, uuid: string>, fromEventLogUuid: string, products: table<categories: list, category: record, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list, metadata: record, name: string, online: record, presentation: record, taxCode: string, taxExempt: bool, taxRates: list, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record, variants: list, vatPercentage: float>, untilEventLogUuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let qp = [(serialize-qp "eventLogUuid" $event_log_uuid "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "all" $all "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/library") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eventLogUuid": $event_log_uuid, "limit": $limit, "offset": $offset, "all": $all} | compact), body: null}
}

# Delete a list of products
#
# DELETE /organizations/{organizationUuid}/products
# operationId: deleteProducts
export def "organizations-products delete-by-organization-uuid" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uuid: list<string> # List of product UUIDs to be deleted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let qp = [(serialize-qp "uuid" $uuid "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"uuid": $uuid} | compact), body: null}
}

# Retrieve all products visible in POS
#
# GET /organizations/{organizationUuid}/products
# operationId: getAllProductsInPos
export def "organizations-products get-list-in-pos" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new product
#
# POST /organizations/{organizationUuid}/products
# operationId: createProduct
# --category shape: {name: string, uuid: string}
# --metadata shape: {inPos: bool, source?: record}
# --online shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
# --presentation shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
# --variantOptionDefinitions shape: {definitions: list}
# --variants item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
export def "organizations-products create" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-entity: oneof<nothing, bool> # default: false
  --categories: list<string>
  --category: record # shape: {name: string, uuid: string}
  --create-with-default-tax: oneof<nothing, bool>
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --metadata: record # shape: {inPos: bool, source?: record}
  name: string
  --online: record # shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
  --presentation: record # shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
  --tax-code: string
  --tax-exempt: oneof<nothing, bool>
  --tax-rates: list<string>
  --unit-name: string
  uuid: string # format: uuid
  --variant-option-definitions: record # shape: {definitions: list}
  --variants: list # item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
  --vat-percentage: float
]: any -> record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let qp = [(serialize-qp "returnEntity" $return_entity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products") $qp)
  let req_body = {"categories": $categories, "category": $category, "createWithDefaultTax": $create_with_default_tax, "description": $description, "externalReference": $external_reference, "imageLookupKeys": $image_lookup_keys, "metadata": $metadata, "name": $name, "online": $online, "presentation": $presentation, "taxCode": $tax_code, "taxExempt": $tax_exempt, "taxRates": $tax_rates, "unitName": $unit_name, "uuid": $uuid, "variantOptionDefinitions": $variant_option_definitions, "variants": $variants, "vatPercentage": $vat_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"returnEntity": $return_entity} | compact), body: $req_body}
}

# Create a product identifier
#
# POST /organizations/{organizationUuid}/products/online/slug
# operationId: createProductSlug
export def "organizations-products-online-slug create" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  product_name: string
]: any -> record<productName: string, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products/online/slug"))
  let req_body = {"productName": $product_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve an aggregate of active Options in the library
#
# GET /organizations/{organizationUuid}/products/options
# operationId: getAllOptions
export def "organizations-products-options get-list" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<options: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products/options"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve all products visible in POS – v2
#
# GET /organizations/{organizationUuid}/products/v2
# operationId: getAllProductsV2
export def "organizations-products get-list" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: oneof<nothing, bool> # If true, sorts response by created date
]: nothing -> table<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record>, name: string, online: record<description: string, presentation: record, seo: record, shipping: record, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list>, variants: list<record>, vatPercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products/v2") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort} | compact), body: null}
}

# Retrieve the count of existing products
#
# GET /organizations/{organizationUuid}/products/v2/count
# operationId: countAllProducts
export def "organizations-products-count list" [
  organization_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<productCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid)} | format pattern "/organizations/{organization_uuid}/products/v2/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a single product
#
# PUT /organizations/{organizationUuid}/products/v2/{productUuid}
# operationId: updateProduct
# --category shape: {name: string, uuid: string}
# --metadata shape: {inPos: bool, source?: record}
# --online shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
# --presentation shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
# --variantOptionDefinitions shape: {definitions: list}
# --variants item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
export def "organizations-products update" [
  organization_uuid: string
  product_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-match: string
  --categories: list<string>
  --category: record # shape: {name: string, uuid: string}
  --description: string
  --external-reference: string
  --image-lookup-keys: list<string>
  --metadata: record # shape: {inPos: bool, source?: record}
  name: string
  --online: record # shape: {description?: string, presentation?: record, seo?: record, shipping?: record, status: "ACTIVE"|"HIDDEN", title?: string}
  --presentation: record # shape: {backgroundColor?: string, imageUrl?: string, textColor?: string}
  --tax-code: string
  --tax-exempt: oneof<nothing, bool>
  --tax-rates: list<string>
  --unit-name: string
  uuid: string # format: uuid
  --variant-option-definitions: record # shape: {definitions: list}
  --variants: list # item shape: {barcode?: string, costPrice?: record, description?: string, name?: string, options?: list, presentation?: record, price?: record, sku?: string, uuid: string, vatPercentage?: float}
  --vat-percentage: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($product_uuid | is-empty) { error make --unspanned { msg: "path parameter 'productUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), product_uuid: (encode-path-segment $product_uuid)} | format pattern "/organizations/{organization_uuid}/products/v2/{product_uuid}"))
  let req_body = {"categories": $categories, "category": $category, "description": $description, "externalReference": $external_reference, "imageLookupKeys": $image_lookup_keys, "metadata": $metadata, "name": $name, "online": $online, "presentation": $presentation, "taxCode": $tax_code, "taxExempt": $tax_exempt, "taxRates": $tax_rates, "unitName": $unit_name, "uuid": $uuid, "variantOptionDefinitions": $variant_option_definitions, "variants": $variants, "vatPercentage": $vat_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a single product
#
# DELETE /organizations/{organizationUuid}/products/{productUuid}
# operationId: deleteProduct
export def "organizations-products delete-by-organization-uuid-product-uuid" [
  organization_uuid: string
  product_uuid: string
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
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($product_uuid | is-empty) { error make --unspanned { msg: "path parameter 'productUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), product_uuid: (encode-path-segment $product_uuid)} | format pattern "/organizations/{organization_uuid}/products/{product_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a single product
#
# GET /organizations/{organizationUuid}/products/{productUuid}
# operationId: getProduct
export def "organizations-products get" [
  organization_uuid: string
  product_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string
]: nothing -> record<categories: list<string>, category: record<name: string, uuid: string>, created: string, description: string, etag: string, externalReference: string, imageLookupKeys: list<string>, metadata: record<inPos: bool, source: record<external: bool, name: string>>, name: string, online: record<description: string, presentation: record<additionalImageUrls: list, displayImageUrl: string, mediaUrls: list>, seo: record<metaDescription: string, slug: string, title: string>, shipping: record<shippingPricingModel: string, weight: record, weightInGrams: int>, status: string, title: string>, presentation: record<backgroundColor: string, imageUrl: string, textColor: string>, taxCode: string, taxExempt: bool, taxRates: list<string>, unitName: string, updated: string, updatedBy: string, uuid: string, variantOptionDefinitions: record<definitions: list<record>>, variants: table<barcode: string, costPrice: record, description: string, name: string, options: list, presentation: record, price: record, sku: string, uuid: string, vatPercentage: float>, vatPercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($organization_uuid | is-empty) { error make --unspanned { msg: "path parameter 'organizationUuid' must be non-empty" } }
  if ($product_uuid | is-empty) { error make --unspanned { msg: "path parameter 'productUuid' must be non-empty" } }
  let full_url = (build-url $base ({organization_uuid: (encode-path-segment $organization_uuid), product_uuid: (encode-path-segment $product_uuid)} | format pattern "/organizations/{organization_uuid}/products/{product_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all available tax rates
#
# GET /v1/taxes
# operationId: getTaxRates
export def "taxes get-tax-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<taxRates: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/taxes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create new tax rates
#
# POST /v1/taxes
# operationId: createTaxRates
# --taxRates item shape: {default?: bool, label: string, percentage?: float, uuid: string}
export def "taxes create-tax-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tax_rates: list # item shape: {default?: bool, label: string, percentage?: float, uuid: string}
]: any -> record<taxRates: table<default: bool, label: string, percentage: float, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/taxes")
  let req_body = {"taxRates": $tax_rates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all tax rates and a count of products associated with each
#
# GET /v1/taxes/count
# operationId: getProductCountForAllTaxes
export def "taxes-count get-product-for-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<counts: table<count: int, taxRateUuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/taxes/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the organization tax settings
#
# GET /v1/taxes/settings
# operationId: getTaxSettings
export def "taxes-settings get-tax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<organizationUuid: string, taxationMode: string, taxationType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/taxes/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the organization tax settings
#
# PUT /v1/taxes/settings
# operationId: setTaxationMode
export def "taxes-settings update-taxation-mode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  taxation_mode: string@taxation-mode-completer
]: any -> record<organizationUuid: string, taxationMode: string, taxationType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/taxes/settings")
  let req_body = {"taxationMode": $taxation_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a single tax rate
#
# DELETE /v1/taxes/{taxRateUuid}
# operationId: deleteTaxRate
export def "taxes delete-tax-rate" [
  tax_rate_uuid: string
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
  if ($tax_rate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'taxRateUuid' must be non-empty" } }
  let full_url = (build-url $base ({tax_rate_uuid: (encode-path-segment $tax_rate_uuid)} | format pattern "/v1/taxes/{tax_rate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a single tax rate
#
# GET /v1/taxes/{taxRateUuid}
# operationId: getTaxRate
export def "taxes get-tax-rate" [
  tax_rate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<default: bool, label: string, percentage: float, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tax_rate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'taxRateUuid' must be non-empty" } }
  let full_url = (build-url $base ({tax_rate_uuid: (encode-path-segment $tax_rate_uuid)} | format pattern "/v1/taxes/{tax_rate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a single tax rate
#
# PUT /v1/taxes/{taxRateUuid}
# operationId: updateTaxRate
export def "taxes update-tax-rate" [
  tax_rate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool>
  --label: string
  --percentage: float
]: any -> record<default: bool, label: string, percentage: float, uuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tax_rate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'taxRateUuid' must be non-empty" } }
  let full_url = (build-url $base ({tax_rate_uuid: (encode-path-segment $tax_rate_uuid)} | format pattern "/v1/taxes/{tax_rate_uuid}"))
  let req_body = {"default": $default, "label": $label, "percentage": $percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
