# Auto-generated client for Catalog API - Seller Portal v1.0.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Catalog-API-Seller-Portal/1.0.0/openapi.json
# Auth: --token flag or $env.CATALOG_API_SELLER_PORTAL_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CATALOG_API_SELLER_PORTAL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "catalog-seller-portal-brands list" } } | get name | first)
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

# Get List of Brands
#
# GET /api/catalog-seller-portal/brands
# operationId: ListBrand
export def "catalog-seller-portal-brands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search word. (e.g. tshirt)
  --qp-from: string # The first page of the interval of the brand list. (e.g. 1)
  --qp-to: string # The last page of the interval of the brand list. (e.g. 50)
  --order-by: string # The order that the list is displayed. You can select `name`, or `updated_at` to select the order criteria. Then you can add `,` , `asc` or `desc` to define the brands order. (e.g. status,asc;name,asc)
  --name: string # Brand name. (e.g. Zwilling)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<_metadata: record<from: int, orderBy: string, to: int, total: int>, data: table<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/brands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "from": $qp_from, "to": $qp_to, "orderBy": $order_by, "name": $name} | compact), body: null}
}

# Create Brand
#
# POST /api/catalog-seller-portal/brands
# operationId: PostBrand
export def "catalog-seller-portal-brands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-active: oneof<nothing, bool> # The condition defines if the brand is active (`true`) or inactive (`false`). (e.g. true)
  name: string # Brand Name. (e.g. Zwilling)
]: any -> record<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog-seller-portal/brands")
  let req_body = {"isActive": $is_active, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get Brand by ID
#
# GET /api/catalog-seller-portal/brands/{brandId}
# operationId: GetBrand
export def "catalog-seller-portal-brands get" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($brand_id | is-empty) { error make --unspanned { msg: "path parameter 'brandId' must be non-empty" } }
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog-seller-portal/brands/{brand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Brand
#
# PUT /api/catalog-seller-portal/brands/{brandId}
# operationId: PutBrand
export def "catalog-seller-portal-brands update" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  id: string # Brand unique identifier number. (e.g. 20)
  --is-active: oneof<nothing, bool> # The condition defines if the brand is active (`true`) or inactive (`false`). (e.g. true)
  name: string # Brand Name. (e.g. Zwilling)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($brand_id | is-empty) { error make --unspanned { msg: "path parameter 'brandId' must be non-empty" } }
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog-seller-portal/brands/{brand_id}"))
  let req_body = {"id": $id, "isActive": $is_active, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get Category Tree
#
# GET /api/catalog-seller-portal/category-tree
# operationId: GetCategoryTree
export def "catalog-seller-portal-category-tree get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth: int # Category tree level. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<createdAt: string, roots: table<children: list, value: record>, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth" $depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"depth": $depth} | compact), body: null}
}

# Update Category Tree
#
# PUT /api/catalog-seller-portal/category-tree
# operationId: UpdateCategoryTree
# --roots item shape: {children: list, value: record}
export def "catalog-seller-portal-category-tree update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  roots: list # List of all categories of the store. (e.g. [{children: [{value: {id: 2, isActive: false, name: Perfumes}}], value: {id: 1, isActive: false, name: sandboxintegracao}}]) — item shape: {children: list, value: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree")
  let req_body = {"roots": $roots} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Create Category
#
# POST /api/catalog-seller-portal/category-tree/categories
# operationId: CreateCategory
export def "catalog-seller-portal-category-tree-categories create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  name: string # Category name. (e.g. Beauty)
  parent_id: string # Parent category unique identifier number. (e.g. 567)
]: any -> record<children: table<value: record>, value: record<id: string, isActive: bool, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree/categories")
  let req_body = {"Name": $name, "parentId": $parent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get Category by ID
#
# GET /api/catalog-seller-portal/category-tree/categories/{categoryId}
# operationId: Getbyid
export def "catalog-seller-portal-category-tree-categories get" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<children: table<value: record>, value: record<id: string, isActive: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog-seller-portal/category-tree/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Product
#
# POST /api/catalog-seller-portal/products
# operationId: PostProduct
# --attributes item shape: {name: string, value: string}
# --images item shape: {alt?: string, id: string, url: string}
# --skus item shape: {dimensions: record, ean?: string, externalId?: string, images: list, isActive: bool, manufacturerCode?: string, name: string, specs: list, weight: int}
# --specs item shape: {name: string, values: list<string>}
export def "catalog-seller-portal-products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  attributes: list # Attributes of the product. Attributes are additional properties used to create site browsing filters. (e.g. [{name: Fabric, value: Cotton}, {name: Gender, value: Feminine}]) — item shape: {name: string, value: string}
  brand_id: string # Product's Brand unique identifier number. (e.g. 1)
  category_ids: list<string> # Product's Categories unique identifier numbers. It can have multiples IDs for each Category and Subcategories. (e.g. [732])
  --description: string # Description of the primary information related to the product. A simple and easy-to-understand summary for the customer. (e.g. Descrição camiseta VTEX)
  --external-id: string # Product reference unique identifier number in the store. (e.g. sandboxintegracao-310117347)
  images: list # Information of the images of the product. (e.g. [{alt: imagem, id: vtex_logo.jpg, url: https://vtxleo7778.vtexassets.com/assets/vtex.catalog-images/products/vtex_logo.jpg}]) — item shape: {alt?: string, id: string, url: string}
  name: string # Product Name. Use simple words and avoid other languages or complex writing. This field is essential for SEO and must respect the 150 character limit. (e.g. VTEX Shirt)
  origin: string # Origin account of the product. It is not possible to alter products where the origin is `marketplace`. (e.g. vtxleo7778)
  skus: list # SKUs of the product. (e.g. [{dimensions: {height: 2.1, length: 1.6, width: 1.5}, ean: 978-1909621862, externalId: 1909621862, images: [https://mystore.vtexassets.com/assets/vtex.catalog-images/products/vtex_logo.jpg], isActive: true, manufacturerCode: 1234567, name: VTEX Shirt Black Size S, specs: [{name: Color, value: Black}, {name: Size, value: S}], weight: 300}, {dimensions: {height: 2.1, length: 1.6, width: 1.5}, ean: 978-1909621862, externalId: 1909621862, images: [vtex_logo.jpg], isActive: true, manufacturerCode: 1234568, name: VTEX Shirt White Size L, specs: [{name: Color, value: White}, {name: Size, value: L}], weight: 300}]) — item shape: {dimensions: record, ean?: string, externalId?: string, images: list, isActive: bool, manufacturerCode?: string, name: string, specs: list, weight: int}
  slug: string # Reference of the product in the URL of the store. (e.g. /vtex-shirt)
  specs: list # Specifications that will differentiate the possible product SKUs. (e.g. [{name: Color, values: [Black, White]}, {name: Size, values: [S, M, L]}]) — item shape: {name: string, values: list<string>}
  status: string # Status of the product. Its values can be `active` or `inactive`. (e.g. active)
  --tax-code: string # Product tax code. (nullable, e.g. 123)
  --transport-modal: string # Transport modal of the product. (nullable, e.g. 1)
]: any -> record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, name: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog-seller-portal/products")
  let req_body = {"attributes": $attributes, "brandId": $brand_id, "categoryIds": $category_ids, "description": $description, "externalId": $external_id, "images": $images, "name": $name, "origin": $origin, "skus": $skus, "slug": $slug, "specs": $specs, "status": $status, "taxCode": $tax_code, "transportModal": $transport_modal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get Product by external ID, SKU ID, SKU external ID or slug
#
# GET /api/catalog-seller-portal/products/{param}
# operationId: GetProductQuery
export def "catalog-seller-portal-products get-list" [
  param: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($param | is-empty) { error make --unspanned { msg: "path parameter 'param' must be non-empty" } }
  let full_url = (build-url $base ({param: (encode-path-segment $param)} | format pattern "/api/catalog-seller-portal/products/{param}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product by ID
#
# GET /api/catalog-seller-portal/products/{productId}
# operationId: GetProduct
export def "catalog-seller-portal-products get" [
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
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Product
#
# PUT /api/catalog-seller-portal/products/{productId}
# operationId: PutProduct
# --attributes item shape: {name: string, value: string}
# --images item shape: {alt?: string, id: string, url: string}
# --skus item shape: {dimensions: record, ean?: string, externalId?: string, id?: string, images: list, isActive: bool, manufacturerCode?: string, name?: string, specs: list, weight: int}
# --specs item shape: {name: string, values: list<string>}
export def "catalog-seller-portal-products update" [
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
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  attributes: list # Attributes of the product. Attributes are additional properties used to create site browsing filters. (e.g. [{name: Fabric, value: Cotton}, {name: Gender, value: Feminine}]) — item shape: {name: string, value: string}
  brand_id: string # Product's Brand unique identifier number. (e.g. 1)
  category_ids: list<string> # Product's Categories unique identifier numbers. It can have multiples IDs for each Category and Subcategories. (e.g. [732])
  --external-id: string # Product reference unique identifier number in the store. (e.g. sandboxintegracao-310117347)
  --id: string # Product's unique identifier number. (e.g. 189371)
  images: list # Information of the images of the product. (e.g. [{alt: imagem, id: vtex_logo.jpg, url: https://vtxleo7778.vtexassets.com/assets/vtex.catalog-images/products/vtex_logo.jpg}]) — item shape: {alt?: string, id: string, url: string}
  name: string # Product Name. Use simple words and avoid other languages or complex writing. This field is essential for SEO and must respect the 150 character limit. (e.g. Camiseta VTEX 10)
  origin: string # Origin account of the product. It is not possible to alter products where the origin is `marketplace`. (e.g. vtxleo7778)
  skus: list # SKUs of the product. (e.g. [{dimensions: {height: 2.1, length: 1.6, width: 1.5}, ean: 978-1909621862, externalId: 1909621862, id: 182907, images: [vtex_logo.jpg], isActive: true, manufacturerCode: 1234567, name: VTEX Shirt Black Size S, specs: [{name: Color, value: Black}, {name: Size, value: S}], weight: 300}, {dimensions: {height: 2.1, length: 1.6, width: 1.5}, ean: 978-1909621862, externalId: 1909621862, id: 182908, images: [vtex_logo.jpg], isActive: true, manufacturerCode: 1234568, name: VTEX Shirt White Size L, specs: [{name: Color, value: White}, {name: Size, value: L}], weight: 300}]) — item shape: {dimensions: record, ean?: string, externalId?: string, id?: string, images: list, isActive: bool, manufacturerCode?: string, name?: string, specs: list, weight: int}
  slug: string # Reference of the product in the URL of the store. (e.g. /vtex-shirt)
  specs: list # Specifications that will differentiate the possible product SKUs. (e.g. [{name: Color, values: [Black, White]}, {name: Size, values: [S, M, L]}]) — item shape: {name: string, values: list<string>}
  status: string # Status of the product. Its values can be `active` or `inactive`. (e.g. active)
  --tax-code: string # Product tax code. (nullable, e.g. 123)
  --transport-modal: string # Transport modal of the product. (nullable, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}"))
  let req_body = {"attributes": $attributes, "brandId": $brand_id, "categoryIds": $category_ids, "externalId": $external_id, "id": $id, "images": $images, "name": $name, "origin": $origin, "skus": $skus, "slug": $slug, "specs": $specs, "status": $status, "taxCode": $tax_code, "transportModal": $transport_modal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Get Product Description by Product ID
#
# GET /api/catalog-seller-portal/products/{productId}/description
# operationId: GetProductDescription
export def "catalog-seller-portal-products-description get" [
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
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<createdAt: string, productId: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}/description"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Product Description by Product ID
#
# PUT /api/catalog-seller-portal/products/{productId}/description
# operationId: PutProductDescription
export def "catalog-seller-portal-products-description update" [
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
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  description: string # Product description. (e.g. White shirt.)
  --body-product-id: string # Product's unique identifier number. (e.g. 71)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}/description"))
  let req_body = {"description": $description, "productId": $body_product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Search for SKU
#
# GET /api/catalog-seller-portal/skus/_search
# operationId: SearchSKU
export def "catalog-seller-portal-skus-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The first page of the interval of the product list. (e.g. 1)
  --qp-to: string # The last page of the interval of the product list. (e.g. 50)
  --id: int # SKU unique idenfier number. (e.g. 1)
  --externalid: int # SKU reference unique identifier number in the store. (e.g. 123456789)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<_metadata: record<from: int, to: int, total: int>, data: table<externalId: string, id: string, productId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "externalid" $externalid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/skus/_search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "to": $qp_to, "id": $id, "externalid": $externalid} | compact), body: null}
}

# Get List of SKUs
#
# GET /api/catalog-seller-portal/skus/ids
# operationId: ListSKU
export def "catalog-seller-portal-skus-ids list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The first page of the interval of the product list. (e.g. 1)
  --qp-to: string # The last page of the interval of the product list. (e.g. 50)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<_metadata: record<from: int, to: int, total: int>, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/skus/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "to": $qp_to} | compact), body: null}
}
