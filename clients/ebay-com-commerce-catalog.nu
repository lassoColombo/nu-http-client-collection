# Auto-generated client for Catalog API vv1_beta.5.0
# Source: https://api.apis.guru/v2/specs/ebay.com/commerce-catalog/v1_beta.5.0/openapi.json
# Auth: --token flag or $env.CATALOG_API_TOKEN

const BASE_URL = "https://api.ebay.com/commerce/catalog/v1_beta"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CATALOG_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.ebay.com/commerce/catalog/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "product get" } } | get name | first)
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

# This method retrieves details of the catalog product identified by the eBay product identifier (ePID) specified in the request. These details include the product's title and description, aspects and their values, associated images, applicable category IDs, and any recognized identifiers that apply to the product. For a new listing, you can use the search method to identify candidate products on which to base the listing, then use the getProduct method to present the full details of those candidate products to the seller to make a a final selection.
#
# GET /product/{epid}
# operationId: getProduct
export def "product get" [
  epid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-ebay-c-marketplace-id: string # This method also uses the X-EBAY-C-MARKETPLACE-ID header to identify the seller's eBay marketplace. It is required for all marketplaces except EBAY_US, which is the default. Note: This method is limited to EBAY_US, EBAY_AU, EBAY_CA, and EBAY_GB values.
]: nothing -> record<additionalImages: table<height: int, imageUrl: string, width: int>, aspects: table<localizedName: string, localizedValues: list>, brand: string, description: string, ean: list<string>, epid: string, gtin: list<string>, image: record<height: int, imageUrl: string, width: int>, isbn: list<string>, mpn: list<string>, otherApplicableCategoryIds: list<string>, primaryCategoryId: string, productWebUrl: string, title: string, upc: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({epid: (encode-path-segment $epid)} | format pattern "/product/{epid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# This method searches for and retrieves summaries of one or more products in the eBay catalog that match the search criteria provided by a seller. The seller can use the summaries to select the product in the eBay catalog that corresponds to the item that the seller wants to offer for sale. When a corresponding product is found and adopted by the seller, eBay will use the product information to populate the item listing. The criteria supported by search include keywords, product categories, and category aspects. To see the full details of a selected product, use the getProduct call. In addition to product summaries, this method can also be used to identify refinements, which help you to better pinpoint the product you're looking for. A refinement consists of one or more aspect values and a count of the number of times that each value has been used in previous eBay listings. An aspect is a property (e.g. color or size) of an eBay category, used by sellers to provide details about the items they're listing. The refinement container is returned when you include the fieldGroups query parameter in the request with a value of ASPECT_REFINEMENTS or FULL. Example A seller wants to find a product that is "gray" in color, but doesn't know what term the manufacturer uses for that color. It might be Silver, Brushed Nickel, Pewter, or even Grey. The returned refinement container identifies all aspects that have been used in past listings for products that match your search criteria, along with all of the values those aspects have taken, and the number of times each value was used. You can use this data to present the seller with a histogram of the values of each aspect. The seller can see which color values have been used in the past, and how frequently they have been used, and selects the most likely value or values for their product. You issue the search method again with those values in the aspect_filter parameter to narrow down the collection of products returned by the call. Although all query parameters are optional, this method must include at least the q parameter, or the category_ids, gtin, or mpn parameter with a valid value. If you provide more than one of these parameters, they will be combined with a logical AND to further refine the returned collection of matching products. Note: This method requires that certain special characters in the query parameters be percent-encoded: (space) = %20 , = %2C : = %3A [ = %5B ] = %5D { = %7B | = %7C } = %7D This requirement applies to all query parameter values. However, for readability, method examples and samples in this documentation will not use the encoding. This method returns product summaries rather than the full details of the products. To retrieve the full details of a product, use the getProduct method with an ePID.
#
# GET /product_summary/search
# operationId: search
export def "product-summary-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect-filter: string # An eBay category and one or more aspects of that category, with the values that can be used to narrow down the collection of products returned by this call. Aspects are product attributes that can represent different types of information for different products. Every product has aspects, but different products have different sets of aspects. You can determine appropriate values for the aspects by first submitting this method without this parameter. It will return either the productSummaries.aspects container, the refinement.aspectDistributions container, or both, depending on the value of the fieldgroups parameter in the request. The productSummaries.aspects container provides the category aspects and their values that are associated with each returned product. The refinement.aspectDistributions container provides information about the distribution of values of the set of category aspects associated with the specified categories. In both cases sellers can select from among the returned aspects to use with this parameter. Note: You can also use the Taxonomy API's getItemAspectsForCategory method to retrieve detailed information about aspects and their values that are appropriate for your selected category. The syntax for the aspect_filter parameter is as follows (on several lines for readability; categoryId is required): aspect_filter=categoryId:category_id, aspect1:{valueA|valueB|...}, aspect2:{valueC|valueD|...},. A matching product must be within the specified category, and it must have least one of the values identified for every specified aspect. Note: Aspect names and values are case sensitive. Here is an example of an aspect_filter parameter in which 9355 is the category ID, Color is an aspect of that category, and Black and White are possible values of that aspect (on several lines for readability): GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search? aspect_filter=categoryId:9355,Color:{White|Black} Here is the aspect_filter with required URL encoding and a second aspect (on several lines for readability): GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search? aspect_filter=categoryId:9355,Color:%7BWhite%7CBlack%7D, Storage%20Capacity:%128GB%7C256GB%7D Note: You cannot use the aspect_filter parameter in the same method with either the gtin parameter or the mpn parameter. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/commerce/catalog/types/catal:AspectFilter
  --category-ids: string # Important: Currently, only the first category_id value is accepted. One or more comma-separated category identifiers for narrowing down the collection of products returned by this call. Note: This parameter requires a valid category ID value. You can use the Taxonomy API's getCategorySuggestions method to retrieve appropriate category IDs for your product based on keywords. The syntax for this parameter is as follows: category_ids=category_id1,category_id2,. Here is an example of a method with the category_ids parameter: br /> GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search? category_ids=178893 Note: Although all query parameters are optional, this method must include at least the q parameter, or the category_ids, gtin, or mpn parameter with a valid value. If you provide only the category_ids parameter, you cannot specify a top-level (L1) category.
  --fieldgroups: string # The type of information to return in the response. Important: This parameter may not produce valid results if you also provide more than one value for the category_ids parameter. It is recommended that you avoid using this combination. Valid Values: ASPECT_REFINEMENTS &mdash; This returns the refinement container, which includes the category aspect and aspect value distributions that apply to the returned products. For example, if you searched for Ford Mustang, some of the category aspects might be Model Year, Exterior Color, Vehicle Mileage, and so on. Note: Aspects are category specific. FULL &mdash; This returns all the refinement containers and all the matching products. This value overrides the other values, which will be ignored. MATCHING_PRODUCTS &mdash; This returns summaries for all products that match the values you provide for the q and category_ids parameters. This does not affect your use of the ASPECT_REFINEMENTS value, which you can use in the same call. Code so that your app gracefully handles any future changes to this list. Default: MATCHING_PRODUCTS
  --gtin: string # A string consisting of one or more comma-separated Global Trade Item Numbers (GTINs) that identify products to search for. Currently the GTIN values can include EAN, ISBN, and UPC identifier types. Note: Although all query parameters are optional, this method must include at least the q parameter, or the category_ids, gtin, or mpn parameter with a valid value. You cannot use the gtin parameter in the same method with either the q parameter or the aspect_filter parameter.
  --limit: string # The number of product summaries to return. This is the result set, a subset of the full collection of products that match the search or filter criteria of this call. Maximum: 200 Default: 50
  --mpn: string # A string consisting of one or more comma-separated Manufacturer Part Numbers (MPNs) that identify products to search for. This method will return all products that have one of the specified MPNs. MPNs are defined by manufacturers for their own products, and are therefore certain to be unique only within a given brand. However, many MPNs do turn out to be globally unique. Note: Although all query parameters are optional, this method must include at least the q parameter, or the category_ids, gtin, or mpn parameter with a valid value. You cannot use the mpn parameter in the same method with either the q parameter or the aspect_filter parameter.
  --offset: string # This parameter is reserved for internal or future use.
  --q: string # A string consisting of one or more keywords to use to search for products in the eBay catalog. Note: This method searches the following product record fields: title, description, brand, and aspects.localizedName, which do not include product IDs. Wildcard characters (e.g. *) are not allowed. The keywords are handled as follows: If the keywords are separated by a comma (e.g. iPhone,256GB), the query returns products that have iPhone AND 256GB. If the keywords are separated by a space (e.g. "iPhone ipad" or "iPhone, ipad"), the query ignores any commas and returns products that have iPhone OR iPad. Note: Although all query parameters are optional, this method must include at least the q parameter, or the category_ids, gtin, or mpn parameter with a valid value. You cannot use the q parameter in the same method with either the gtin parameter or the mpn parameter.
  --x-ebay-c-marketplace-id: string # This method also uses the X-EBAY-C-MARKETPLACE-ID header to identify the seller's eBay marketplace. It is required for all marketplaces except EBAY_US, which is the default. Note: This method is limited to EBAY_US, EBAY_AU, EBAY_CA, and EBAY_GB values.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, productSummaries: table<additionalImages: list, aspects: list, brand: string, ean: list, epid: string, gtin: list, image: record, isbn: list, mpn: list, productHref: string, productWebUrl: string, title: string, upc: list>, refinement: record<aspectDistributions: list<record>, dominantCategoryId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aspect_filter" $aspect_filter "scalar") (serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "fieldgroups" $fieldgroups "scalar") (serialize-qp "gtin" $gtin "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mpn" $mpn "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product_summary/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
