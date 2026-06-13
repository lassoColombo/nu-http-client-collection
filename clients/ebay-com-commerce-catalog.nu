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

def base-url-completer [] { ["https://api.ebay.com/commerce/catalog/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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

# This method retrieves details of the catalog product identified by the eBay product identifier (ePID) specified in the request. These details include the product's title and description, aspects and their values, associated images, applicable category IDs, and any recognized identifiers that apply to the product. <br /><br /> For a new listing, you can use the <b>search</b> method to identify candidate products on which to base the listing, then use the <b>getProduct</b> method to present the full details of those candidate products to the seller to make a a final selection.
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-EBAY-C-MARKETPLACE-ID: string # This method also uses the <code>X-EBAY-C-MARKETPLACE-ID</code> header to identify the seller's eBay marketplace. It is required for all marketplaces except EBAY_US, which is the default. <b>Note:</b> This method is limited to <code>EBAY_US</code>, <code>EBAY_AU</code>, <code>EBAY_CA</code>, and <code>EBAY_GB</code> values.
]: nothing -> record<additionalImages: table<height: int, imageUrl: string, width: int>, aspects: table<localizedName: string, localizedValues: list>, brand: string, description: string, ean: list<string>, epid: string, gtin: list<string>, image: record<height: int, imageUrl: string, width: int>, isbn: list<string>, mpn: list<string>, otherApplicableCategoryIds: list<string>, primaryCategoryId: string, productWebUrl: string, title: string, upc: list<string>, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($epid)")
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method searches for and retrieves summaries of one or more products in the eBay catalog that match the search criteria provided by a seller. The seller can use the summaries to select the product in the eBay catalog that corresponds to the item that the seller wants to offer for sale. When a corresponding product is found and adopted by the seller, eBay will use the product information to populate the item listing. The criteria supported by <b>search</b> include keywords, product categories, and category aspects. To see the full details of a selected product, use the <b>getProduct</b> call. <br /><br /> In addition to product summaries, this method can also be used to identify <i>refinements</i>, which help you to better pinpoint the product you're looking for. A refinement consists of one or more <i>aspect</i> values and a count of the number of times that each value has been used in previous eBay listings. An aspect is a property (e.g. color or size) of an eBay category, used by sellers to provide details about the items they're listing. The <b>refinement</b> container is returned when you include the <b>fieldGroups</b> query parameter in the request with a value of <code>ASPECT_REFINEMENTS</code> or <code>FULL</code>. <br /><br /> <span style="padding: 15px 20px; display: block; border: 1px solid #cccccc"><b>Example</b> <br />A seller wants to find a product that is "gray" in color, but doesn't know what term the manufacturer uses for that color. It might be <code>Silver</code>, <code>Brushed Nickel</code>, <code>Pewter</code>, or even <code>Grey</code>. The returned <b>refinement</b> container identifies all aspects that have been used in past listings for products that match your search criteria, along with all of the values those aspects have taken, and the number of times each value was used. You can use this data to present the seller with a histogram of the values of each aspect. The seller can see which color values have been used in the past, and how frequently they have been used, and selects the most likely value or values for their product. You issue the <b>search</b> method again with those values in the <b>aspect_filter</b> parameter to narrow down the collection of products returned by the call.</span> <br /><br /> Although all query parameters are optional, this method must include at least the <b>q</b> parameter, or the <b>category_ids</b>, <b>gtin</b>, or <b>mpn</b> parameter with a valid value. If you provide more than one of these parameters, they will be combined with a logical AND to further refine the returned collection of matching products. <br /><br /> <span class="tablenote"><strong>Note:</strong> This method requires that certain special characters in the query parameters be percent-encoded: <br /><br /> &nbsp;&nbsp;&nbsp;&nbsp;<code>(space)</code> = <code>%20</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>,</code> = <code>%2C</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>:</code> = <code>%3A</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>[</code> = <code>%5B</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>]</code> = <code>%5D</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>{</code> = <code>%7B</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>|</code> = <code>%7C</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>}</code> = <code>%7D</code> <br /><br /> This requirement applies to all query parameter values. However, for readability, method examples and samples in this documentation will not use the encoding.</span> <br /><br /> This method returns product summaries rather than the full details of the products. To retrieve the full details of a product, use the <b>getProduct</b> method with an ePID.
#
# GET /product_summary/search
# operationId: search
export def "product-summary-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --aspect-filter: string # An eBay category and one or more aspects of that category, with the values that can be used to narrow down the collection of products returned by this call. <br /><br /> Aspects are product attributes that can represent different types of information for different products. Every product has aspects, but different products have different sets of aspects. <br /><br /> You can determine appropriate values for the aspects by first submitting this method without this parameter. It will return either the <b>productSummaries.aspects</b> container, the <b>refinement.aspectDistributions</b> container, or both, depending on the value of the <b>fieldgroups</b> parameter in the request. The <b>productSummaries.aspects</b> container provides the category aspects and their values that are associated with each returned product. The <b>refinement.aspectDistributions</b> container provides information about the distribution of values of the set of category aspects associated with the specified categories. In both cases sellers can select from among the returned aspects to use with this parameter. <br /><br /> <span class="tablenote"> <strong>Note:</strong> You can also use the Taxonomy API's <b>getItemAspectsForCategory</b> method to retrieve detailed information about aspects and their values that are appropriate for your selected category. </span> <br /><br /> The syntax for the <b>aspect_filter</b> parameter is as follows (on several lines for readability; <b>categoryId</b> is required): <br /><br /> <code>aspect_filter=categoryId:<i>category_id</i>,<br /> <i>aspect1</i>:{<i>valueA</i>|<i>valueB</i>|...},<br /> <i>aspect2</i>:{<i>valueC</i>|<i>valueD</i>|...},.</code> <br /><br /> A matching product must be within the specified category, and it must have least one of the values identified for every specified aspect. <br /><br /> <span class="tablenote"> <strong>Note:</strong> Aspect names and values are case sensitive. </span> <br /><br /> Here is an example of an <b>aspect_filter</b> parameter in which <code>9355</code> is the category ID, <code>Color</code> is an aspect of that category, and <code>Black</code> and <code>White</code> are possible values of that aspect (on several lines for readability): <br /><br /> <code>GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search?<br /> aspect_filter=categoryId:9355,Color:{White|Black}</code>    <br /><br /> Here is the <b>aspect_filter</b> with required URL encoding and a second aspect (on several lines for readability): <br /><br /> <code>GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search?<br /> aspect_filter=categoryId:9355,Color:%7BWhite%7CBlack%7D,<br /> Storage%20Capacity:%128GB%7C256GB%7D</code> <br /><br /> <span class="tablenote"> <strong>Note:</strong> You cannot use the <b>aspect_filter</b> parameter in the same method with either the <b>gtin</b> parameter or the <b>mpn</b> parameter. </span> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/commerce/catalog/types/catal:AspectFilter
  --category-ids: string # <span class="tablenote"> <strong>Important:</strong> Currently, only the first <b>category_id</b> value is accepted. </span> <br /><br /> One or more comma-separated category identifiers for narrowing down the collection of products returned by this call. <br /><br /> <span class="tablenote"> <strong>Note:</strong> This parameter requires a valid category ID value. You can use the Taxonomy API's <b>getCategorySuggestions</b> method to retrieve appropriate category IDs for your product based on keywords. </span> <br /><br /> The syntax for this parameter is as follows: <br /><br /> <code>category_ids=<i>category_id1</i>,<i>category_id2</i>,.</code> <br /><br /> Here is an example of a method with the <b>category_ids</b> parameter: br /><br /> <code>GET https://api.ebay.com/commerce/catalog/v1_beta/product_summary/search?<br /> category_ids=178893</code> <br /><br /> <span class="tablenote"> <strong>Note:</strong> Although all query parameters are optional, this method must include at least the <b>q</b> parameter, or the <b>category_ids</b>, <b>gtin</b>, or <b>mpn</b> parameter with a valid value. <br /><br /> If you provide only the <b>category_ids</b> parameter, you cannot specify a top-level (L1) category. </span>
  --fieldgroups: string # The type of information to return in the response. <br /><br /> <span class="tablenote"> <strong>Important:</strong> This parameter may not produce valid results if you also provide more than one value for the <b>category_ids</b> parameter. It is recommended that you avoid using this combination. </span> <br /><br /> <b> Valid Values: </b> <ul> <li><code>ASPECT_REFINEMENTS</code> &mdash; This returns the <b>refinement</b> container, which includes the category aspect and aspect value distributions that apply to the returned products. For example, if you searched for <code>Ford Mustang</code>, some of the category aspects might be <b>Model Year</b>, <b>Exterior Color</b>, <b>Vehicle Mileage</b>, and so on. <br /> <br /> <span class="tablenote"> <b>Note: </b>Aspects are category specific.</span> </li> <li><code>FULL</code> &mdash; This returns all the refinement containers and all the matching products. This value overrides the other values, which will be ignored.</li> <li><code>MATCHING_PRODUCTS</code> &mdash; This returns summaries for all products that match the values you provide for the <b>q</b> and <b>category_ids</b> parameters. This does not affect your use of the <code>ASPECT_REFINEMENTS</code> value, which you can use in the same call.</li> </ul> Code so that your app gracefully handles any future changes to this list. <br /><br /><b>Default: </b> <code>MATCHING_PRODUCTS</code>
  --gtin: string # A string consisting of one or more comma-separated Global Trade Item Numbers (GTINs) that identify products to search for. Currently the GTIN values can include EAN, ISBN, and UPC identifier types. <br /><br /> <span class="tablenote"> <strong>Note:</strong> Although all query parameters are optional, this method must include at least the <b>q</b> parameter, or the <b>category_ids</b>, <b>gtin</b>, or <b>mpn</b> parameter with a valid value.  <br /><br /> You cannot use the <b>gtin</b> parameter in the same method with either the <b>q</b> parameter or the <b>aspect_filter</b> parameter. </span>
  --limit: string # The number of product summaries to return. This is the <i>result set</i>, a subset of the full collection of products that match the search or filter criteria of this call. <br /><br /> <b>Maximum:</b> <code>200</code> <br /> <b>Default:</b> <code>50</code>
  --mpn: string # A string consisting of one or more comma-separated Manufacturer Part Numbers (MPNs) that identify products to search for. This method will return all products that have one of the specified MPNs. <br /><br /> MPNs are defined by manufacturers for their own products, and are therefore certain to be unique only within a given brand. However, many MPNs do turn out to be globally unique. <br /><br /> <span class="tablenote"> <strong>Note:</strong> Although all query parameters are optional, this method must include at least the <b>q</b> parameter, or the <b>category_ids</b>, <b>gtin</b>, or <b>mpn</b> parameter with a valid value. <br /><br /> You cannot use the <b>mpn</b> parameter in the same method with either the <b>q</b> parameter or the <b>aspect_filter</b> parameter. </span>
  --offset: string # This parameter is reserved for internal or future use.
  --q: string # A string consisting of one or more keywords to use to search for products in the eBay catalog. <br /><br /> <span class="tablenote"> <strong>Note:</strong> This method searches the following product record fields: <b>title</b>, <b>description</b>, <b>brand</b>, and <b>aspects.localizedName</b>, which do not include product IDs. Wildcard characters (e.g. <code>*</code>) are not allowed. </span> <br /><br /> The keywords are handled as follows: <ul> <li>If the keywords are separated by a comma (e.g. <code>iPhone,256GB</code>), the query returns products that have <code>iPhone</code> <b>AND</b> <code>256GB</code>.</li> <li>If the keywords are separated by a space (e.g. <code>"iPhone&nbsp;ipad"</code> or <code>"iPhone,&nbsp;ipad"</code>), the query ignores any commas and returns products that have <code>iPhone</code> <b>OR</b> <code>iPad</code>.</li> </ul> <span class="tablenote"> <strong>Note:</strong> Although all query parameters are optional, this method must include at least the <b>q</b> parameter, or the <b>category_ids</b>, <b>gtin</b>, or <b>mpn</b> parameter with a valid value.  <br /><br /> You cannot use the <b>q</b> parameter in the same method with either the <b>gtin</b> parameter or the <b>mpn</b> parameter. </span>
  --X-EBAY-C-MARKETPLACE-ID: string # This method also uses the <code>X-EBAY-C-MARKETPLACE-ID</code> header to identify the seller's eBay marketplace. It is required for all marketplaces except EBAY_US, which is the default. <b>Note:</b> This method is limited to <code>EBAY_US</code>, <code>EBAY_AU</code>, <code>EBAY_CA</code>, and <code>EBAY_GB</code> values.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, productSummaries: table<additionalImages: list, aspects: list, brand: string, ean: list, epid: string, gtin: list, image: record, isbn: list, mpn: list, productHref: string, productWebUrl: string, title: string, upc: list>, refinement: record<aspectDistributions: list<record>, dominantCategoryId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aspect_filter" $aspect_filter "scalar") (serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "fieldgroups" $fieldgroups "scalar") (serialize-qp "gtin" $gtin "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "mpn" $mpn "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product_summary/search" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
