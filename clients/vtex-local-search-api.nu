# Auto-generated client for Legacy Search API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Search-API/1.0/openapi.json
# Auth: --token flag or $env.LEGACY_SEARCH_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LEGACY_SEARCH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories" "http://example.com/.DefaultParameterValue.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "catalog-system-pub-facets-category get" } } | get name | first)
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

# Get Category Facets
#
# GET /api/catalog_system/pub/facets/category/{categoryId}
export def "catalog-system-pub-facets-category get" [
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
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog_system/pub/facets/category/{category_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_from": $qp_from, "_to": $qp_to} | compact), body: null}
}

# Search by Store Facets
#
# GET /api/catalog_system/pub/facets/search/{term}
# operationId: Facetscategory
export def "catalog-system-pub-facets-search get-facetscategory" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --map: string # Mapping of the term. It can be `c` for a category, `b` for a brand, or `specificationFilter_{specificationId}` for a specification. You need to include a map for each term you are searching for in the same term's order. (e.g. c)
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> record<Brands: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, CategoriesTrees: table<Children: list, Id: int, Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, Departments: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, PriceRanges: list<any>, SpecificationFilters: record, Summary: record<Brands: record<DisplayedItems: int, TotalItems: int>, CategoriesTrees: record<DisplayedItems: int, TotalItems: int>, Departments: record<DisplayedItems: int, TotalItems: int>, PriceRanges: record<DisplayedItems: int, TotalItems: int>, SpecificationFilters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($term | is-empty) { error make --unspanned { msg: "path parameter 'term' must be non-empty" } }
  let qp = [(serialize-qp "map" $map "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({term: (encode-path-segment $term)} | format pattern "/api/catalog_system/pub/facets/search/{term}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"map": $map, "_from": $qp_from, "_to": $qp_to} | compact), body: null}
}

# Get Product Search of Accessories
#
# GET /api/catalog_system/pub/products/crossselling/accessories/{productId}
# operationId: ProductSearchAccessories
export def "catalog-system-pub-products-crossselling-accessories list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/accessories/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Show Together
#
# GET /api/catalog_system/pub/products/crossselling/showtogether/{productId}
# operationId: ProductSearchShowTogether
export def "catalog-system-pub-products-crossselling-showtogether list-show-together" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/showtogether/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Similars
#
# GET /api/catalog_system/pub/products/crossselling/similars/{productId}
# operationId: ProductSearchSimilars
export def "catalog-system-pub-products-crossselling-similars list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/similars/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Suggestions
#
# GET /api/catalog_system/pub/products/crossselling/suggestions/{productId}
# operationId: ProductSearchSuggestions
export def "catalog-system-pub-products-crossselling-suggestions list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/suggestions/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Who Bought Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whoboughtalsobought/{productId}
# operationId: ProductSearchWhoBoughtAlsoBought
export def "catalog-system-pub-products-crossselling-whoboughtalsobought list-who-bought-also-bought" [
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
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whoboughtalsobought/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Who Saw Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsobought/{productId}
# operationId: ProductSearchWhoSawAlsoBought
export def "catalog-system-pub-products-crossselling-whosawalsobought list-who-saw-also-bought" [
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
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whosawalsobought/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Product Search of Who Saw Also Saw
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsosaw/{productId}
# operationId: ProductSearchWhoSawAlsoSaw
export def "catalog-system-pub-products-crossselling-whosawalsosaw list-who-saw-also-saw" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/crossselling/whosawalsosaw/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search Product offers
#
# GET /api/catalog_system/pub/products/offers/{productId}
export def "catalog-system-pub-products-offers get" [
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
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/offers/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search SKU offers
#
# GET /api/catalog_system/pub/products/offers/{productId}/sku/{skuId}
export def "catalog-system-pub-products-offers-sku get" [
  product_id: string
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($product_id | is-empty) { error make --unspanned { msg: "path parameter 'productId' must be non-empty" } }
  if ($sku_id | is-empty) { error make --unspanned { msg: "path parameter 'skuId' must be non-empty" } }
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog_system/pub/products/offers/{product_id}/sku/{sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for Products with Filter, Order and Pagination
#
# GET /api/catalog_system/pub/products/search
# operationId: ProductSearchFilteredandOrdered
export def "catalog-system-pub-products-search list-filteredand-ordered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --ft: string # Filter by full text. The form is`ft={searchWord}` (e.g. television)
  --fq: string # General filter. It can be by category (`fq=C:/{a}/{b}`), by specification (`fq=specificationFilter_{a}:{b}`), by price range (`fq=P:[{a} TO {b}]`), by collection (`fq=productClusterIds:{{productClusterId}}`), by product ID (`fq=productId:{{productId}}`), by SKU ID (`fq=skuId:{{skuId}}`), by Reference ID (`fq=alternateIds_RefId:{{referenceId}}`), by EAN13 (`fq=alternateIds_Ean:{{ean13}}`), by availability at a specific sales channel (`fq=isAvailablePerSalesChannel_{{sc}}:{{bool}}`), by available at a specific seller (`fq=sellerId:{{sellerId}}`) (e.g. C:/1000041/1000049/)
  --o: string # Sorting method. It can be by Price (`O=OrderByPriceDESC` or `O=OrderByPriceASC`), by Top Selling Products (`O=OrderByTopSaleDESC`), by Best Reviews (`O=OrderByReviewRateDESC`), by Name (`O=OrderByNameASC` or `O=OrderByNameDESC`), by Release Date (`O=OrderByReleaseDateDESC`), by Best Discounts (`O=OrderByBestDiscountDESC`), by Score (`O=OrderByScoreDESC`) (e.g. OrderByNameASC)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "ft" $ft "scalar") (serialize-qp "fq" $fq "scalar") (serialize-qp "O" $o "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pub/products/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"_from": $qp_from, "_to": $qp_to, "ft": $ft, "fq": $fq, "O": $o} | compact), body: null}
}

# Search Product by Product URL
#
# GET /api/catalog_system/pub/products/search/{product-text-link}/p
# operationId: Searchbyproducturl
export def "catalog-system-pub-products-search-p get-searchbyproducturl" [
  product_text_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($product_text_link | is-empty) { error make --unspanned { msg: "path parameter 'product-text-link' must be non-empty" } }
  let full_url = (build-url $base ({product_text_link: (encode-path-segment $product_text_link)} | format pattern "/api/catalog_system/pub/products/search/{product_text_link}/p"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for Products
#
# GET /api/catalog_system/pub/products/search/{search}
# operationId: ProductSearch
export def "catalog-system-pub-products-search list" [
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  if ($search | is-empty) { error make --unspanned { msg: "path parameter 'search' must be non-empty" } }
  let full_url = (build-url $base ({search: (encode-path-segment $search)} | format pattern "/api/catalog_system/pub/products/search/{search}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Product Search Autocomplete
#
# GET /buscaautocomplete
# operationId: AutoComplete
export def "buscaautocomplete complete-auto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-name-contains: string # Part of the string that will be searched. (e.g. jeans)
  --content-type: string # Type of the content being sent (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand (e.g. application/json)
]: nothing -> record<itemsReturned: table<criteria: string, href: string, items: list, name: string, thumb: string, thumbUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.DefaultParameterValue.com.br")
  let qp = [(serialize-qp "productNameContains" $product_name_contains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buscaautocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"productNameContains": $product_name_contains} | compact), body: null}
}
