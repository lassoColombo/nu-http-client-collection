# Auto-generated client for Intel Product Catalogue Service v0.1.0
# Source: https://api.apis.guru/v2/specs/intel.com/product-catalogue/0.1.0/swagger.json
# Auth: --token flag or $env.INTEL_PRODUCT_CATALOGUE_SERVICE_TOKEN

const BASE_URL = "https://productapi.intel.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INTEL_PRODUCT_CATALOGUE_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "client_id" => { {headers: {client_id: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://productapi.intel.com"] }
def auth-scheme-completer [] { ["basic" "client_id"] }

# Completers for enum parameters
def locale-geo-id-completer [] { ["bn-BD" "de-DE" "en-AR" "en-AU" "en-CA" "en-CO" "en-EG" "en-HK" "en-IE" "en-IN" "en-MY" "en-NE" "en-NZ" "en-PE" "en-PH" "en-SG" "en-UK" "en-US" "en-VE" "en-XA" "en-XR" "en-ZA" "es-CL" "es-ES" "es-MX" "es-XL" "fr-CA" "fr-FR" "id-ID" "it-IT" "ja-JP" "ko-KR" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ru-RU" "si-LK" "sv-SE" "th-TH" "tr-TR" "uk-UA" "ur-PK" "vi-VN" "zh-CN" "zh-TW"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "products-get-codename get" } } | get name | first)
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
export def "products-get-codename get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.<br/><br/>
]: nothing -> record<result: table<CodeNameId: string, CodeNameText: string, CodeNameType: string, UrlText: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-codename" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-id: string # Filter ordering info details based on one or multiple product id's. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. <br/><br/>Example: ["123003"]
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.<br/><br/>
]: nothing -> record<result: table<attributes: list, product_id: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_id" $product_id "scalar") (serialize-qp "locale_geo_id" $locale_geo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-ordering-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 1. Find products by product id or category id
#
# GET /api/products/get-products
# operationId: getProductList
export def "products-get-products get-product-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.<br/><br/>
  --category-id: string # Filter products based on one or multiple category id. Either category id or product id is mandatory for any request. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. <br/><br/>Example: ["873"]<br/><br/>Categories Available:<br/> Processors = 873, Server Products = 1201, Mini PC's = 98414, Wireless Networking = 59485, Ethernet Products = 36773, Fabric products = 70021, Memory and Storage = 35125, Chipsets = 53, Graphics Drivers = 80939 <br/><br/>
  --product-id: string # Filter products based on one or multiple product id. Either category id or product id is mandatory for any request. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. <br/><br/>Example: ["123003"]<br/><br/>
  --highlights: string # Specification values which needs to be pulled from product data. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values. <br/><br/>Example: ["CoreCount", "StatusCodeText"]<br/><br/>
  --qp-sort: string # Indicates sorting fields. Accepts array of objects in format like: [{"field":"name","order":"ASC"}].<br/><br/>Any specification that we get from get-product-info can be used to sort result. Other generic sort field is "name".<br/><br/>
  --filters: string # Allows to filter data.<br/><br/>Format of filter: [{"type":"specvalue","name":"ThreadCount","gteq":"4"}]<br/><br/><b>Available operators are:</b> "eq": equal to, "neq": not equal to, "lteq": less than or equal to, "gteq": greater than or equal to, "swc": starts with characters, "nswc": not starting with characters, "cts": contains, "ncts": not contains<br/><br/><b>Conditions:</b> By default all objects works on an AND condition. But inside an object we have the capability to put an "OR" or "AND" condition.<br/>Example conditions: [{"type":"specvalue","name":"ThreadCount","ncts":"4,5","cond":"AND"}]<br/><br/><br/>
  --per-page: int # Filter number of products in response to desired size.
  --page-no: int # Indicates page number for pagination of results.
]: nothing -> record<page_no: string, per_page: int, result: table<created_date: string, highlights_info: list, mktg_prd_type: string, product_category: list, product_description: string, product_id: string, product_manufacturer: string, product_name: string, product_name_raw: string, product_on_market_date: string, updated_date: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "highlights" $highlights "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page_no" $page_no "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale-geo-id: string@locale-geo-id-completer # Locale and Geo code used to get localised data.<br/><br/>
  --product-id: string # Product id's that needs to be filtered. Only max of 40 products are supported now. Values must be enclosed in [ square brackets ] and each value must be in "double quotes". Use comma to add multiple values.<br/><br/>Example: ["223","224"]
  --include-reference: string # If send "true", this will fetch variant/compatible info into result set. Default is false.
]: nothing -> record<result: table<created_date: string, media_asset: record, mktg_prd_type: string, product_category: list, product_description: string, product_id: string, product_manufacturer: string, product_name: string, product_name_raw: string, product_on_market_date: string, product_picture: string, reference: list, tech_spec: list, updated_date: string>, status: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale_geo_id" $locale_geo_id "scalar") (serialize-qp "product_id" $product_id "scalar") (serialize-qp "include_reference" $include_reference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/products/get-products-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
