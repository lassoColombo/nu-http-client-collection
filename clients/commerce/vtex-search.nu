# Auto-generated client for Legacy Search API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Search-API/1.0/openapi.json
# Auth: --token flag or $env.LEGACY_SEARCH_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LEGACY_SEARCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "https://entelperu.DefaultParameterValue.com.br/api/catalog_system/pub/products/crossselling/accessories" "http://example.com/.DefaultParameterValue.com.br" "https://entelperu.{environment}.com.br/api/catalog_system/pub/products/crossselling/accessories" "http://example.com/.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<Id: int, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog_system/pub/facets/category/($categoryId)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search by Store Facets
#
# GET /api/catalog_system/pub/facets/search/{term}
# operationId: Facetscategory
export def "catalog-system-pub-facets-search Facetscategory" [
  term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --map: string # Mapping of the term. It can be `c` for a category, `b` for a brand, or `specificationFilter_{specificationId}` for a specification. You need to include a map for each term you are searching for in the same term's order. (e.g. c)
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> record<Brands: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, CategoriesTrees: table<Children: list, Id: int, Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, Departments: table<Link: string, LinkEncoded: string, Map: string, Name: string, Position: int, Quantity: int, Value: string>, PriceRanges: list<any>, SpecificationFilters: record, Summary: record<Brands: record<DisplayedItems: int, TotalItems: int>, CategoriesTrees: record<DisplayedItems: int, TotalItems: int>, Departments: record<DisplayedItems: int, TotalItems: int>, PriceRanges: record<DisplayedItems: int, TotalItems: int>, SpecificationFilters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "map" $map "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog_system/pub/facets/search/($term)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Accessories
#
# GET /api/catalog_system/pub/products/crossselling/accessories/{productId}
# operationId: ProductSearchAccessories
export def "catalog-system-pub-products-crossselling-accessories ProductSearchAccessories" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://entelperu.{environment}.com.br/api/catalog_system/pub/products/crossselling/accessories")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/accessories/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Show Together
#
# GET /api/catalog_system/pub/products/crossselling/showtogether/{productId}
# operationId: ProductSearchShowTogether
export def "catalog-system-pub-products-crossselling-showtogether ProductSearchShowTogether" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://entelperu.{environment}.com.br/api/catalog_system/pub/products/crossselling/accessories")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/showtogether/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Similars
#
# GET /api/catalog_system/pub/products/crossselling/similars/{productId}
# operationId: ProductSearchSimilars
export def "catalog-system-pub-products-crossselling-similars ProductSearchSimilars" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/similars/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Suggestions
#
# GET /api/catalog_system/pub/products/crossselling/suggestions/{productId}
# operationId: ProductSearchSuggestions
export def "catalog-system-pub-products-crossselling-suggestions ProductSearchSuggestions" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/suggestions/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Who Bought Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whoboughtalsobought/{productId}
# operationId: ProductSearchWhoBoughtAlsoBought
export def "catalog-system-pub-products-crossselling-whoboughtalsobought ProductSearchWhoBoughtAlsoBought" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/whoboughtalsobought/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Who Saw Also Bought
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsobought/{productId}
# operationId: ProductSearchWhoSawAlsoBought
export def "catalog-system-pub-products-crossselling-whosawalsobought ProductSearchWhoSawAlsoBought" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/whosawalsobought/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Search of Who Saw Also Saw
#
# GET /api/catalog_system/pub/products/crossselling/whosawalsosaw/{productId}
# operationId: ProductSearchWhoSawAlsoSaw
export def "catalog-system-pub-products-crossselling-whosawalsosaw ProductSearchWhoSawAlsoSaw" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/crossselling/whosawalsosaw/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Product offers
#
# GET /api/catalog_system/pub/products/offers/{productId}
export def "catalog-system-pub-products-offers get" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/products/offers/($productId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search SKU offers
#
# GET /api/catalog_system/pub/products/offers/{productId}/sku/{skuId}
export def "catalog-system-pub-products-offers-sku get" [
  productId: string
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<EanId: string, IsActive: bool, LastModified: string, MainImage: record<ImageId: string, ImageLabel: string, ImagePath: string, ImageTag: string, ImageText: string, IsMain: bool, IsZoomSize: bool, LastModified: string>, Name: string, NameComplete: string, Offers: list<record>, ProductId: string, RefId: string, SkuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/products/offers/($productId)/sku/($skuId)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for Products with Filter, Order and Pagination
#
# GET /api/catalog_system/pub/products/search
# operationId: ProductSearchFilteredandOrdered
export def "catalog-system-pub-products-search ProductSearchFilteredandOrdered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Starter page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 1)
  --qp-to: string # Finisher page range. These parameters allow the API to be paginated. Take into account that the initial and final pages cannot have a separation superior to 50 pages. Thus, it will be displayed 50 items per page. (e.g. 50)
  --ft: string # Filter by full text. The form is`ft={searchWord}` (e.g. television)
  --fq: string # General filter. It can be by category (`fq=C:/{a}/{b}`), by specification (`fq=specificationFilter_{a}:{b}`),  by price range (`fq=P:[{a} TO {b}]`), by collection (`fq=productClusterIds:{{productClusterId}}`), by product ID (`fq=productId:{{productId}}`),  by SKU ID (`fq=skuId:{{skuId}}`), by Reference ID (`fq=alternateIds_RefId:{{referenceId}}`), by EAN13 (`fq=alternateIds_Ean:{{ean13}}`), by availability at a specific sales channel (`fq=isAvailablePerSalesChannel_{{sc}}:{{bool}}`), by available at a specific seller (`fq=sellerId:{{sellerId}}`) (e.g. C:/1000041/1000049/)
  --O: string # Sorting method. It can be by Price (`O=OrderByPriceDESC` or `O=OrderByPriceASC`), by Top Selling Products (`O=OrderByTopSaleDESC`), by Best Reviews (`O=OrderByReviewRateDESC`), by Name (`O=OrderByNameASC` or `O=OrderByNameDESC`), by Release Date (`O=OrderByReleaseDateDESC`), by Best Discounts (`O=OrderByBestDiscountDESC`), by Score (`O=OrderByScoreDESC`) (e.g. OrderByNameASC)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let qp = [(serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar") (serialize-qp "ft" $ft "scalar") (serialize-qp "fq" $fq "scalar") (serialize-qp "O" $O "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pub/products/search" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Product by Product URL
#
# GET /api/catalog_system/pub/products/search/{product-text-link}/p
# operationId: Searchbyproducturl
export def "catalog-system-pub-products-search-p Searchbyproducturl" [
  product_text_link: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/search/($product_text_link)/p")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for Products
#
# GET /api/catalog_system/pub/products/search/{search}
# operationId: ProductSearch
export def "catalog-system-pub-products-search ProductSearch" [
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
]: nothing -> table<allSpecifications: list<string>, allSpecificationsGroups: list<string>, brand: string, brandId: int, brandImageUrl: string, categories: list<any>, categoriesIds: list<any>, categoryId: string, clusterHighlights: record, description: string, items: list<record>, link: string, linkText: string, metaTagDescription: string, productClusters: record, productId: string, productName: string, productReference: string, productReferenceCode: int, productTitle: string, releaseDate: string, searchableClusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let full_url = (build-url $base $"/api/catalog_system/pub/products/search/($search)")
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Product Search Autocomplete
#
# GET /buscaautocomplete
# operationId: AutoComplete
export def "buscaautocomplete AutoComplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --productNameContains: string # Part of the string that will be searched. (e.g. jeans)
  --Content-Type: string # Type of the content being sent (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand  (e.g. application/json)
]: nothing -> record<itemsReturned: table<criteria: string, href: string, items: list, name: string, thumb: string, thumbUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br")
  let qp = [(serialize-qp "productNameContains" $productNameContains "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/buscaautocomplete" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
