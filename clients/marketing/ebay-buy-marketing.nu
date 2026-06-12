# Auto-generated client for Buy Marketing API vv1_beta.2.0
# Source: https://api.apis.guru/v2/specs/ebay.com/buy-marketing/v1_beta.2.0/openapi.json
# Auth: --token flag or $env.BUY_MARKETING_API_TOKEN

const BASE_URL = "https://api.ebay.com/buy/marketing/v1_beta"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUY_MARKETING_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://api.ebay.com/buy/marketing/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "merchandised-product get" } } | get name | first)
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

# This method returns an array of products based on the category and metric specified. This includes details of the product, such as the eBay product ID (EPID), title, and user reviews and ratings for the product. You can use the <code>epid</code> returned by this method in the Browse API <b>search</b> method to retrieve items for this product. <h3><b>Restrictions </b></h3> <ul><li>To test <b> getMerchandisedProducts</b> in Sandbox, you must use category ID 9355 and the response will be mock data.  </li>   <li>For a list of supported sites and other restrictions, see <a href="/api-docs/buy/marketing/overview.html#API">API Restrictions</a>.</li>  </ul>
#
# GET /merchandised_product
# operationId: getMerchandisedProducts
export def "merchandised-product get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aspect-filter: string # The aspect name/value pairs used to further refine product results. <br /><br /> For example: <br />&nbsp;&nbsp;&nbsp;<code>/buy/marketing/v1_beta/merchandised_product?category_id=31388&metric_name=BEST_SELLING&aspect_filter=Brand:Canon</code>  <br /><br />You can use the Browse API <b>search</b> method with the <code>fieldgroups=ASPECT_REFINEMENTS</code> field to return the aspects of a product. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/buy/marketing/types/gct:MarketingAspectFilter
  --category-id: string # This query parameter limits the products returned to a specific eBay category.  <br /> <br />The list of eBay category IDs is not published and category IDs are not all the same across all the eBay maketplace. You can use the following techniques to find a category by site: <ul> <li>Use the <a href="https://pages.ebay.com/sellerinformation/news/categorychanges.html" target="_blank">Category Changes page</a>.</li> <li>Use the Taxonomy API. For details see <a href="/api-docs/buy/buy-categories.html">Get Categories for Buy APIs</a>. </li>  <li>Use the Browse API and submit the following method to get the <b> dominantCategoryId</b> for an item. <br /><code>/buy/browse/v1/item_summary/search?q=<em>keyword</em>&fieldgroups=ASPECT_REFINEMENTS  </code></li></ul>  <b> Maximum: </b> 1 <br /> <b> Required: </b> 1 
  --limit: string # This value specifies the maximum number of products to return in a result set. <br /> <br /><span class="tablenote"> <b>Note:</b> Maximum value means the method will return up <em>to</em> that many products per set, but it can be less than this value. If the number of products found is less than this value, the method will return all of the products matching the criteria.</span>  <br /><br /><b> Default:</b> 8<br /><b> Maximum: </b>100
  --metric-name: string # This value filters the result set by the specified metric. Only products in this metric are returned. Currently, the only metric supported is <code> BEST_SELLING</code>. <br /><br /><b> Default: </b>BEST_SELLING <br /> <b> Maximum: </b> 1 <br /> <b> Required: </b> 1
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aspect_filter" $aspect_filter "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "metric_name" $metric_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchandised_product" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
