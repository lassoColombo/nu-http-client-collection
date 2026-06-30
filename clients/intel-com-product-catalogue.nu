# Auto-generated client for Intel Product Catalogue Service v0.1.0
# Source: https://api.apis.guru/v2/specs/intel.com/product-catalogue/0.1.0/swagger.json
# Auth: --token flag or $env.INTEL_PRODUCT_CATALOGUE_SERVICE_TOKEN

const BASE_URL = "https://productapi.intel.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o INTEL_PRODUCT_CATALOGUE_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "client_id" => { {scheme: $scheme, headers: {client_id: $token_val}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://productapi.intel.com"] }
def auth-scheme-completer [] { ["basic" "client_id" "basic-credentials"] }

# Completers for enum parameters
def locale-geo-id-completer [] { ["bn-BD" "de-DE" "en-AR" "en-AU" "en-CA" "en-CO" "en-EG" "en-HK" "en-IE" "en-IN" "en-MY" "en-NE" "en-NZ" "en-PE" "en-PH" "en-SG" "en-UK" "en-US" "en-VE" "en-XA" "en-XR" "en-ZA" "es-CL" "es-ES" "es-MX" "es-XL" "fr-CA" "fr-FR" "id-ID" "it-IT" "ja-JP" "ko-KR" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ru-RU" "si-LK" "sv-SE" "th-TH" "tr-TR" "uk-UA" "ur-PK" "vi-VN" "zh-CN" "zh-TW"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "products-get-codename get-code-name" } } | get name | first)
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

# 5. Get list of codename details for Intel products.
#
# GET /api/products/get-codename
# operationId: getCodeName
export def "products-get-codename get-code-name" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.
]: nothing -> record<result: table<CodeNameId: string, CodeNameText: string, CodeNameType: string, UrlText: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-codename" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale_geo_id": $locale_geo_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# 3. Get ordering info for product id's requested.
#
# GET /api/products/get-ordering-info
# operationId: getorderinginfo
export def "products-get-ordering-info get-orderinginfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Filter ordering info details based on one or multiple product id's. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. Example: ["123003"]
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.
]: nothing -> record<result: table<attributes: list, product_id: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "locale_geo_id" $locale_geo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-ordering-info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"product_id": $product_id, "locale_geo_id": $locale_geo_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# 1. Find products by product id or category id
#
# GET /api/products/get-products
# operationId: getProductList
export def "products-get-products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.
  --category-id: string # Filter products based on one or multiple category id. Either category id or product id is mandatory for any request. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. Example: ["873"]Categories Available: Processors = 873, Server Products = 1201, Mini PC's = 98414, Wireless Networking = 59485, Ethernet Products = 36773, Fabric products = 70021, Memory and Storage = 35125, Chipsets = 53, Graphics Drivers = 80939
  --product-id: string # Filter products based on one or multiple product id. Either category id or product id is mandatory for any request. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. Example: ["123003"]
  --highlights: string # Specification values which needs to be pulled from product data. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. Example: ["CoreCount", "StatusCodeText"]
  --qp-sort: string # Indicates sorting fields. Accepts array of objects in format like: [{"field":"name","order":"ASC"}].Any specification that we get from get-product-info can be used to sort result. Other generic sort field is "name".
  --filters: string # Allows to filter data.Format of filter: [{"type":"specvalue","name":"ThreadCount","gteq":"4"}]Available operators are: "eq": equal to, "neq": not equal to, "lteq": less than or equal to, "gteq": greater than or equal to, "swc": starts with characters, "nswc": not starting with characters, "cts": contains, "ncts": not containsConditions: By default all objects works on an AND condition. But inside an object we have the capability to put an "OR" or "AND" condition.Example conditions: [{"type":"specvalue","name":"ThreadCount","ncts":"4,5","cond":"AND"}]
  --per-page: int # Filter number of products in response to desired size.
  --page-no: int # Indicates page number for pagination of results.
]: nothing -> record<page_no: string, per_page: int, result: table<created_date: string, highlights_info: list, mktg_prd_type: string, product_category: list, product_description: string, product_id: string, product_manufacturer: string, product_name: string, product_name_raw: string, product_on_market_date: string, updated_date: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "highlights" $highlights "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page_no" $page_no "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-products" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale_geo_id": $locale_geo_id, "category_id": $category_id, "product_id": $product_id, "highlights": $highlights, "sort": $qp_sort, "filters": $filters, "per_page": $per_page, "page_no": $page_no} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# 2. Get complete product info with product id.
#
# GET /api/products/get-products-info
# operationId: getProductInfo
export def "products-get-products-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.
  --product-id: string # Product id's that needs to be filtered. Only max of 40 products are supported now. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values.Example: ["223","224"]
  --include-reference: string # If send "true", this will fetch variant/compatible info into result set. Default is false.
]: nothing -> record<result: table<created_date: string, media_asset: record, mktg_prd_type: string, product_category: list, product_description: string, product_id: string, product_manufacturer: string, product_name: string, product_name_raw: string, product_on_market_date: string, product_picture: string, reference: list, tech_spec: list, updated_date: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "include_reference" $include_reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-products-info" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"locale_geo_id": $locale_geo_id, "product_id": $product_id, "include_reference": $include_reference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
