# Auto-generated client for Taxonomy API vv1.0.0
# Source: https://api.apis.guru/v2/specs/ebay.com/commerce-taxonomy/v1.0.0/swagger.json
# Auth: --token flag or $env.TAXONOMY_API_TOKEN

const BASE_URL = "https://api.ebay.com/commerce/taxonomy/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TAXONOMY_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.ebay.com/commerce/taxonomy/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "category-tree get" } } | get name | first)
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

# Get a Category Tree
#
# GET /category_tree/{category_tree_id}
# operationId: getCategoryTree
export def "category-tree get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applicableMarketplaceIds: list<string>, categoryTreeId: string, categoryTreeVersion: string, rootCategoryNode: record<category: record<categoryId: string, categoryName: string>, categoryTreeNodeLevel: int, childCategoryTreeNodes: list<any>, leafCategoryTreeNode: bool, parentCategoryTreeNodeHref: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/category_tree/($category_tree_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Aspects for All Leaf Categories in a Marketplace
#
# GET /category_tree/{category_tree_id}/fetch_item_aspects
# operationId: fetchItemAspects
export def "category-tree-fetch-item-aspects fetchItemAspects" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categoryAspects: table<aspects: list, category: record>, categoryTreeId: string, categoryTreeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/fetch_item_aspects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Category Subtree
#
# GET /category_tree/{category_tree_id}/get_category_subtree
# operationId: getCategorySubtree
export def "category-tree-get-category-subtree get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category-id: string # The unique identifier of the category at the top of the subtree being requested. Note: If the category_id submitted identifies the root node of the tree, this call returns an error. To retrieve the complete tree, use this value with the getCategoryTree call. If the category_id submitted identifies a leaf node of the tree, the call response will contain information about only that leaf node, which is a valid subtree.
]: nothing -> record<categorySubtreeNode: record<category: record<categoryId: string, categoryName: string>, categoryTreeNodeLevel: int, childCategoryTreeNodes: list<any>, leafCategoryTreeNode: bool, parentCategoryTreeNodeHref: string>, categoryTreeId: string, categoryTreeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/get_category_subtree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Suggested Categories
#
# GET /category_tree/{category_tree_id}/get_category_suggestions
# operationId: getCategorySuggestions
export def "category-tree-get-category-suggestions get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # A quoted string that describes or characterizes the item being offered for sale. The string format is free form, and can contain any combination of phrases or keywords. eBay will parse the string and return suggested categories for the item.
]: nothing -> record<categorySuggestions: table<category: record, categoryTreeNodeAncestors: list, categoryTreeNodeLevel: int, relevancy: string>, categoryTreeId: string, categoryTreeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/get_category_suggestions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Compatibility Properties
#
# GET /category_tree/{category_tree_id}/get_compatibility_properties
# operationId: getCompatibilityProperties
export def "category-tree-get-compatibility-properties get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category-id: string # The unique identifier of an eBay category. This eBay category must be a valid eBay category on the specified eBay marketplace, and the category must support parts compatibility for cars, trucks, or motorcyles. The getAutomotivePartsCompatibilityPolicies method of the Selling Metadata API can be used to retrieve all eBay categories for an eBay marketplace that supports parts compatibility cars, trucks, or motorcyles. The getAutomotivePartsCompatibilityPolicies method can also be used to see if one or more specific eBay categories support parts compatibility.
]: nothing -> record<compatibilityProperties: table<localizedName: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/get_compatibility_properties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Compatibility Property Values
#
# GET /category_tree/{category_tree_id}/get_compatibility_property_values
# operationId: getCompatibilityPropertyValues
export def "category-tree-get-compatibility-property-values get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compatibility-property: string # One compatible vehicle property applicable to the specified eBay marketplace and eBay category is specified in this required filter. Compatible vehicle properties are returned in the compatibilityProperties.name field of a getCompatibilityProperties response. For example, if you wanted to retrieve all vehicle trims for a 2018 Toyota Camry, you would set this filter as follows: compatibility_property=Trim; and then include the following three name/value filters through one filter parameter: filter=Year:2018,Make:Toyota,Model:Camry. So, putting this all together, your URI would look something like this: GET https://api.ebay.com/commerce/ taxonomy/v1/category_tree/100/ get_compatibility_property_values? category_id=6016&amp;compatibility_property=Trim &amp;filter=filter=Year:2018,Make:Toyota,Model:Camry
  --category-id: string # The unique identifier of an eBay category. This eBay category must be a valid eBay category on the specified eBay marketplace, and the category must support parts compatibility for cars, trucks, or motorcyles. The getAutomotivePartsCompatibilityPolicies method of the Selling Metadata API can be used to retrieve all eBay categories for an eBay marketplace that supports parts compatibility cars, trucks, or motorcyles. The getAutomotivePartsCompatibilityPolicies method can also be used to see if one or more specific eBay categories support parts compatibility.
  --filter: string # One or more compatible vehicle property name/value pairs are passed in through this query parameter. The compatible vehicle property name and corresponding value are delimited with a colon (:), such as filter=Year:2018, and multiple compatible vehicle property name/value pairs are delimited with a comma (,). For example, if you wanted to retrieve all vehicle trims for a 2018 Toyota Camry, you would set the compatibility_property filter as follows: compatibility_property=Trim; and then include the following three name/value filters through one filter parameter: filter=Year:2018,Make:Toyota,Model:Camry. So, putting this all together, your URI would look something like this: GET https://api.ebay.com/commerce/ taxonomy/v1/category_tree/100/ get_compatibility_property_values? category_id=6016&amp;compatibility_property=Trim &amp;filter=filter=Year:2018,Make:Toyota,Model:Camry For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/commerce/taxonomy/types/txn:ConstraintFilter
]: nothing -> record<compatibilityPropertyValues: table<value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compatibility_property" $compatibility_property "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/get_compatibility_property_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Note: The General Availability (GA) version of the Taxonomy API has been released. Developers currently using the Beta version should make plans to migrate to the new GA version, as the Beta version will be decommissioned on March 31, 2021. Until that date, the Beta version documentation set can be accessed through the All API Documentation page. This call returns a list of aspects that are appropriate or necessary for accurately describing items in the specified leaf category. Each aspect identifies an item attribute (for example, color) for which the seller will be required or encouraged to provide a value (or variation values) when offering an item in that category on eBay. For each aspect, getItemAspectsForCategory provides complete metadata, including: The aspect's data type, format, and entry mode Whether the aspect is required in listings Whether the aspect can be used for item variations Whether the aspect accepts multiple values for an item Allowed values for the aspect Use this information to construct an interface through which sellers can enter or select the appropriate values for their items or item variations. Once you collect those values, include them as product aspects when creating inventory items using the Inventory API.
#
# GET /category_tree/{category_tree_id}/get_item_aspects_for_category
# operationId: getItemAspectsForCategory
export def "category-tree-get-item-aspects-for-category get" [
  category_tree_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category-id: string # The unique identifier of the leaf category for which aspects are being requested. Note: If the category_id submitted does not identify a leaf node of the tree, this call returns an error.
]: nothing -> record<aspects: table<aspectConstraint: record, aspectValues: list, localizedAspectName: string, relevanceIndicator: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/category_tree/($category_tree_id)/get_item_aspects_for_category" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Default Category Tree ID
#
# GET /get_default_category_tree_id
# operationId: getDefaultCategoryTreeId
export def "get-default-category-tree-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marketplace-id: string # The ID of the eBay marketplace for which the category tree ID is being requested. For a list of supported marketplace IDs, see Marketplaces with Default Category Trees.
  --Accept-Language: string # A header used to indicate the natural language the seller prefers for the response. This specifies the language that the seller wants to use when the field values provided in the request body are displayed to consumers. Note: For details, see Accept-Language in HTTP request headers. Valid Values: For EBAY_CA in French: Accept-Language: fr-CA For EBAY_BE in French: Accept-Language: fr-BE
]: nothing -> record<categoryTreeId: string, categoryTreeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/get_default_category_tree_id" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
