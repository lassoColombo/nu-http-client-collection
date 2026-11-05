# Auto-generated client for Catalog API - Seller Portal v1.0.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Catalog-API-Seller-Portal/1.0.0/openapi.json
# Auth (appKey): --token-appkey flag or $env.CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN
# Auth (appToken): --token-apptoken flag or $env.CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CATALOG_API_SELLER_PORTAL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {"X-VTEX-API-AppKey": $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {"X-VTEX-API-AppToken": $token_val}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help" "token-appkey" "token-apptoken"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-brand" "post-brand" "get-brand" "put-brand" "get-category-tree" "update-category-tree" "create-category" "getbyid" "post-product" "get-product-query" "get-product" "put-product" "get-product-description" "put-product-description" "search-sku" "list-sku" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "list-brand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search word. (e.g. tshirt)
  --from: string # The first page of the interval of the brand list. (e.g. 1)
  --to: string # The last page of the interval of the brand list. (e.g. 50)
  --order-by: string # The order that the list is displayed. You can select `name`, or `updated_at` to select the order criteria. Then you can add `,` , `asc` or `desc` to define the brands order. (e.g. status,asc;name,asc)
  --name: string # Brand name. (e.g. Zwilling)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<_metadata: record<from: int, orderBy: string, to: int, total: int>, data: table<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string>>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/brands" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"q": $q, "from": $from, "to": $to, "orderBy": $order_by, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Brand
#
# POST /api/catalog-seller-portal/brands
# operationId: PostBrand
export def "post-brand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
  --is-active: oneof<nothing, bool> # The condition defines if the brand is active (`true`) or inactive (`false`). (e.g. true)
  name: string # Brand Name. (e.g. Zwilling)
]: any -> oneof<record<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string>, string, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base "/api/catalog-seller-portal/brands" $auth.query)
  let req_body = {"isActive": $is_active, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "isActive") == null) { error make --unspanned { msg: "required body field 'isActive' missing: pass --is-active or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get Brand by ID
#
# GET /api/catalog-seller-portal/brands/{brandId}
# operationId: GetBrand
export def "get-brand" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<createdAt: string, id: string, isActive: bool, name: string, updatedAt: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($brand_id | is-empty) { error make --unspanned { msg: "path parameter 'brandId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog-seller-portal/brands/{brand_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Brand
#
# PUT /api/catalog-seller-portal/brands/{brandId}
# operationId: PutBrand
export def "put-brand" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
  id: string # Brand unique identifier number. (e.g. 20)
  --is-active: oneof<nothing, bool> # The condition defines if the brand is active (`true`) or inactive (`false`). (e.g. true)
  name: string # Brand Name. (e.g. Zwilling)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($brand_id | is-empty) { error make --unspanned { msg: "path parameter 'brandId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog-seller-portal/brands/{brand_id}") $auth.query)
  let req_body = {"id": $id, "isActive": $is_active, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "isActive") == null) { error make --unspanned { msg: "required body field 'isActive' missing: pass --is-active or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Get Category Tree
#
# GET /api/catalog-seller-portal/category-tree
# operationId: GetCategoryTree
export def "get-category-tree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth: int # Category tree level. (e.g. 1)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<createdAt: string, roots: table<children: list, value: record>, updatedAt: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let qp = [(serialize-qp "depth" $depth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"depth": $depth} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Category Tree
#
# PUT /api/catalog-seller-portal/category-tree
# operationId: UpdateCategoryTree
export def "update-category-tree" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
  roots: list # List of all categories of the store. (e.g. [{children: [{value: {id: 2, isActive: false, name: Perfumes}}], value: {id: 1, isActive: false, name: sandboxintegracao}}]) — item shape: {children: list, value: record}
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree" $auth.query)
  let req_body = {"roots": $roots} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Create Category
#
# POST /api/catalog-seller-portal/category-tree/categories
# operationId: CreateCategory
export def "create-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
  name: string # Category name. (e.g. Beauty)
  parent_id: string # Parent category unique identifier number. (e.g. 567)
]: any -> oneof<record<children: table<value: record>, value: record<id: string, isActive: bool, name: string>>, string, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base "/api/catalog-seller-portal/category-tree/categories" $auth.query)
  let req_body = {"Name": $name, "parentId": $parent_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Get Category by ID
#
# GET /api/catalog-seller-portal/category-tree/categories/{categoryId}
# operationId: Getbyid
export def "getbyid" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<children: table<value: record>, value: record<id: string, isActive: bool, name: string>>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog-seller-portal/category-tree/categories/{category_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Product
#
# POST /api/catalog-seller-portal/products
# operationId: PostProduct
export def "post-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
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
]: any -> oneof<record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, name: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string>, string, nothing> {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base "/api/catalog-seller-portal/products" $auth.query)
  let req_body = {"attributes": $attributes, "brandId": $brand_id, "categoryIds": $category_ids, "description": $description, "externalId": $external_id, "images": $images, "name": $name, "origin": $origin, "skus": $skus, "slug": $slug, "specs": $specs, "status": $status, "taxCode": $tax_code, "transportModal": $transport_modal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200 204]
}

# Get Product by external ID, SKU ID, SKU external ID or slug
#
# GET /api/catalog-seller-portal/products/{param}
# operationId: GetProductQuery
export def "get-product-query" [
  param: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($param | is-empty) { error make --unspanned { msg: "path parameter 'param' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({param: (encode-path-segment $param)} | format pattern "/api/catalog-seller-portal/products/{param}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Product by ID
#
# GET /api/catalog-seller-portal/products/{productId}
# operationId: GetProduct
export def "get-product" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<attributes: table<name: string, value: string>, brandId: string, brandName: string, categoryIds: list<string>, categoryNames: list<string>, createdAt: string, externalId: string, id: string, images: table<alt: string, id: string, url: string>, name: string, origin: string, skus: table<dimensions: record, ean: string, externalId: string, id: string, images: list, isActive: bool, manufacturerCode: string, specs: list, weight: int>, slug: string, specs: table<name: string, values: list>, status: string, taxCode: string, transportModal: string, updatedAt: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Product
#
# PUT /api/catalog-seller-portal/products/{productId}
# operationId: PutProduct
export def "put-product" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
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
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}") $auth.query)
  let req_body = {"attributes": $attributes, "brandId": $brand_id, "categoryIds": $category_ids, "externalId": $external_id, "id": $id, "images": $images, "name": $name, "origin": $origin, "skus": $skus, "slug": $slug, "specs": $specs, "status": $status, "taxCode": $tax_code, "transportModal": $transport_modal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Get Product Description by Product ID
#
# GET /api/catalog-seller-portal/products/{productId}/description
# operationId: GetProductDescription
export def "get-product-description" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<createdAt: string, productId: string, updatedAt: string>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}/description") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update Product Description by Product ID
#
# PUT /api/catalog-seller-portal/products/{productId}/description
# operationId: PutProductDescription
export def "put-product-description" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
  description: string # Product description. (e.g. White shirt.)
  --body-product-id: string # Product's unique identifier number. (e.g. 71)
]: any -> any {
  let input = $in
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog-seller-portal/products/{product_id}/description") $auth.query)
  let req_body = {"description": $description, "productId": $body_product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  if (($req_body | get -o "productId") == null) { error make --unspanned { msg: "required body field 'productId' missing: pass --body-product-id or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { (if (($req_body | describe) | str starts-with "record") { $req_body | compact | url build-query } else if ($req_body == null) { "" } else { $req_body | into string }) } else { $req_body }
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $effective_ct
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Search for SKU
#
# GET /api/catalog-seller-portal/skus/_search
# operationId: SearchSKU
export def "search-sku" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The first page of the interval of the product list. (e.g. 1)
  --to: string # The last page of the interval of the product list. (e.g. 50)
  --id: int # SKU unique idenfier number. (e.g. 1)
  --externalid: int # SKU reference unique identifier number in the store. (e.g. 123456789)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<_metadata: record<from: int, to: int, total: int>, data: table<externalId: string, id: string, productId: string>>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let qp = [(serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "externalid" $externalid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/skus/_search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $from, "to": $to, "id": $id, "externalid": $externalid} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get List of SKUs
#
# GET /api/catalog-seller-portal/skus/ids
# operationId: ListSKU
export def "list-sku" [
  --base-url(-b): string@base-url-completer # API base URL
  --token-appkey: string # Auth token for appKey (X-VTEX-API-AppKey)
  --token-apptoken: string # Auth token for appToken (X-VTEX-API-AppToken)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from: string # The first page of the interval of the product list. (e.g. 1)
  --to: string # The last page of the interval of the product list. (e.g. 50)
  --content-type: string # Type of the content being sent. (required, default: application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (required, default: application/json)
]: nothing -> oneof<record<_metadata: record<from: int, to: int, total: int>, data: list<string>>, string, nothing> {
  let auth = (merge-auth [(build-auth ($token_appkey | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPKEY_TOKEN | default "")) "x-vtex-api-appkey") (build-auth ($token_apptoken | default ($env | get -o CATALOG_API_SELLER_PORTAL_APPTOKEN_TOKEN | default "")) "x-vtex-api-apptoken")])
  let base = ($base_url | default $BASE_URL)
  let content_type = ($content_type | default "application/json")
  let hdr_accept = ($hdr_accept | default "application/json")
  let qp = [(serialize-qp "from" $from "scalar") (serialize-qp "to" $to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-seller-portal/skus/ids" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"from": $from, "to": $to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
