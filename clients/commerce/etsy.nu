# Auto-generated client for Etsy Open API v3 v3.0.0
# Source: https://www.etsy.com/openapi/generated/oas/3.0.0.json
# Auth: --token flag or $env.ETSY_OPEN_API_V3_TOKEN

const BASE_URL = "https://openapi.etsy.com"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ETSY_OPEN_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://openapi.etsy.com"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def who-made-completer [] { ["collective" "i_did" "someone_else"] }
def when-made-completer [] { ["1700s" "1800s" "1900s" "1910s" "1920s" "1930s" "1940s" "1950s" "1960s" "1970s" "1980s" "1990s" "2000_2006" "2007_2009" "2010_2019" "2020_2026" "before_1700" "before_2007" "made_to_order"] }
def item-weight-unit-completer [] { ["g" "kg" "lb" "oz"] }
def item-dimensions-unit-completer [] { ["cm" "ft" "in" "inches" "m" "mm" "yd"] }
def type-completer [] { ["both" "download" "physical"] }
def state-completer [] { ["active" "draft" "expired" "inactive" "sold_out"] }
def sort-on-completer [] { ["created" "price" "score" "updated"] }
def sort-order-completer [] { ["asc" "ascending" "desc" "descending" "down" "up"] }
def includes-completer [] { ["Listing"] }
def max-variations-supported-completer [] { ["2" "3"] }
def item-weight-unit-completer-1 [] { ["" "g" "kg" "lb" "oz"] }
def item-dimensions-unit-completer-1 [] { ["" "cm" "ft" "in" "inches" "m" "mm" "yd"] }
def state-completer-1 [] { ["active" "inactive"] }
def sort-on-completer-1 [] { ["created" "receipt_id" "updated"] }
def readiness-state-completer [] { ["made_to_order" "ready_to_ship"] }
def processing-time-unit-completer [] { ["days" "weeks"] }
def processing-time-unit-completer-1 [] { ["business_days" "weeks"] }
def destination-region-completer [] { ["eu" "non_eu" "none"] }
def type-completer-1 [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application-buyer-taxonomy-nodes get" } } | get name | first)
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

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the full hierarchy tree of buyer taxonomy nodes.
#
# GET /v3/application/buyer-taxonomy/nodes
# operationId: getBuyerTaxonomyNodes
export def "application-buyer-taxonomy-nodes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/buyer-taxonomy/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of product properties, with applicable scales and values, supported for a specific buyer taxonomy ID.
#
# GET /v3/application/buyer-taxonomy/nodes/{taxonomy_id}/properties
# operationId: getPropertiesByBuyerTaxonomyId
export def "application-buyer-taxonomy-nodes-properties get" [
  taxonomy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/buyer-taxonomy/nodes/($taxonomy_id)/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a physical draft [listing](/documentation/reference#tag/ShopListing) product in a shop on the Etsy channel.
#
# POST /v3/application/shops/{shop_id}/listings
# operationId: createDraftListing
export def "application-shops-listings createDraftListing" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  quantity: int # The positive non-zero number of products available for purchase in the listing. Note: The listing quantity is the sum of available offering quantities. You can request the quantities for individual offerings from the ListingInventory resource using the [getListingInventory](/documentation/reference#operation/getListingInventory) endpoint. (format: int64)
  title: string # The listing's title string. When creating or updating a listing, valid title strings contain only letters, numbers, punctuation marks, mathematical symbols, whitespace characters, ™, ©, and ®. (regex: /[^\p{L}\p{Nd}\p{P}\p{Sm}\p{Zs}™©®]/u) You can only use the %, :, & and + characters once each.
  description: string # A description string of the product for sale in the listing.
  price: float # The positive non-zero price of the product. (Sold product listings are private) Note: The price is the minimum possible price. The [`getListingInventory`](/documentation/reference/#operation/getListingInventory) method requests exact prices for available offerings. (format: float)
  who_made: string@who-made-completer # An enumerated string indicating who made the product. Helps buyers locate the listing under the Handmade heading. Requires 'is_supply' and 'when_made'.
  when_made: string@when-made-completer # An enumerated string for the era in which the maker made the product in this listing. Helps buyers locate the listing under the Vintage heading. Requires 'is_supply' and 'who_made'.
  taxonomy_id: int # The numerical taxonomy ID of the listing. See [SellerTaxonomy](/documentation/reference#tag/SellerTaxonomy) and [BuyerTaxonomy](/documentation/reference#tag/BuyerTaxonomy) for more information. (format: int64)
  --shipping-profile-id: int # The numeric ID of the [shipping profile](/documentation/reference#operation/getShopShippingProfile) associated with the listing. Required when listing type is `physical`. (nullable, format: int64)
  --return-policy-id: int # The numeric ID of the [Return Policy](/documentation/reference#operation/getShopReturnPolicies). (nullable, format: int64)
  --materials: list # A list of material strings for materials used in the product. Valid materials strings contain only letters, numbers, and whitespace characters. (regex: /[^\p{L}\p{Nd}\p{Zs}]/u) Default value is null. (nullable)
  --shop-section-id: int # The numeric ID of the [shop section](/documentation/reference#tag/Shop-Section) for this listing. Default value is null. (nullable, format: int64)
  --processing-min: int # The minimum number of days required to process this listing. Default value is null. (nullable, format: int64)
  --processing-max: int # The maximum number of days required to process this listing. Default value is null. (nullable, format: int64)
  --readiness-state-id: int # The numeric ID of the [processing profile](/documentation/reference#operation/getShopReadinessStateDefinition) associated with the listing. Returned only when the listing is `active` and of type `physical`, and the endpoint is either shop-scoped (path contains `shop_id`) or a single-listing request such as `getListing`. For every other case this field can be null. (nullable, format: int64)
  --tags: list # A comma-separated list of tag strings for the listing. When creating or updating a listing, valid tag strings contain only letters, numbers, whitespace characters, -, ', ™, ©, and ®. (regex: /[^\p{L}\p{Nd}\p{Zs}\-'™©®]/u) Default value is null. (nullable)
  --styles: list # An array of style strings for this listing, each of which is free-form text string such as "Formal", or "Steampunk". When creating or updating a listing, the listing may have up to two styles. Valid style strings contain only letters, numbers, and whitespace characters. (regex: /[^\p{L}\p{Nd}\p{Zs}]/u) Each style string is limited to 45 characters. Default value is null. (nullable)
  --item-weight: float # The numeric weight of the product measured in units set in 'item_weight_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-length: float # The numeric length of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-width: float # The numeric width of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-height: float # The numeric height of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-weight-unit: string@item-weight-unit-completer # A string defining the units used to measure the weight of the product. Default value is null. (nullable)
  --item-dimensions-unit: string@item-dimensions-unit-completer # A string defining the units used to measure the dimensions of the product. Default value is null. (nullable)
  --is-personalizable: oneof<nothing, bool> # [DEPRECATED] When true, this listing is personalizable. The default value is false. NOTE: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --personalization-is-required: oneof<nothing, bool> # [DEPRECATED] When true, this listing requires personalization. The default value is false. NOTE: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --personalization-char-count-max: int # [DEPRECATED] This is an integer value representing the maximum length for the personalization message entered by the buyer. Will only change if is_personalizable is 'true'. Note: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details. (format: int64)
  --personalization-instructions: string # [DEPRECATED] A string representing instructions for the buyer to enter the personalization. Will only change if is_personalizable is 'true'. Note: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --production-partner-ids: list # An array of unique IDs of production partner ids. (nullable)
  --image-ids: list # An array of numeric image IDs of the images in a listing, which can include up to 20 images. (nullable)
  --is-supply: oneof<nothing, bool> # When true, tags the listing as a supply product, else indicates that it's a finished product. Helps buyers locate the listing under the Supplies heading. Requires 'who_made' and 'when_made'.
  --is-customizable: oneof<nothing, bool> # When true, a buyer may contact the seller for a customized order. The default value is true when a shop accepts custom orders. Does not apply to shops that do not accept custom orders.
  --should-auto-renew: oneof<nothing, bool> # When true, renews a listing for four months upon expiration.
  --is-taxable: oneof<nothing, bool> # When true, applicable [shop](/documentation/reference#tag/Shop) tax rates apply to this listing at checkout.
  --type: string@type-completer # An enumerated type string that indicates whether the listing is physical or a digital download.
]: any -> record<listing_id: int, user_id: int, shop_id: int, title: string, description: string, state: string, creation_timestamp: int, created_timestamp: int, ending_timestamp: int, original_creation_timestamp: int, last_modified_timestamp: int, updated_timestamp: int, state_timestamp: int, quantity: int, shop_section_id: int, featured_rank: int, url: string, num_favorers: int, non_taxable: bool, is_taxable: bool, is_customizable: bool, is_personalizable: bool, listing_type: string, tags: list<string>, materials: list<string>, shipping_profile_id: int, return_policy_id: int, processing_min: int, processing_max: int, who_made: string, when_made: string, is_supply: bool, item_weight: float, item_weight_unit: string, item_length: float, item_width: float, item_height: float, item_dimensions_unit: string, is_private: bool, style: list<string>, file_data: string, has_variations: bool, should_auto_renew: bool, language: string, price: any, converted_price: any, taxonomy_id: int, readiness_state_id: int, suggested_title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings" $qp)
  let body = {quantity: $quantity, title: $title, description: $description, price: $price, who_made: $who_made, when_made: $when_made, taxonomy_id: $taxonomy_id, shipping_profile_id: $shipping_profile_id, return_policy_id: $return_policy_id, materials: $materials, shop_section_id: $shop_section_id, processing_min: $processing_min, processing_max: $processing_max, readiness_state_id: $readiness_state_id, tags: $tags, styles: $styles, item_weight: $item_weight, item_length: $item_length, item_width: $item_width, item_height: $item_height, item_weight_unit: $item_weight_unit, item_dimensions_unit: $item_dimensions_unit, is_personalizable: $is_personalizable, personalization_is_required: $personalization_is_required, personalization_char_count_max: $personalization_char_count_max, personalization_instructions: $personalization_instructions, production_partner_ids: $production_partner_ids, image_ids: $image_ids, is_supply: $is_supply, is_customizable: $is_customizable, should_auto_renew: $should_auto_renew, is_taxable: $is_taxable, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Endpoint to list Listings that belong to a Shop. Listings can be filtered using the 'state' param.
#
# GET /v3/application/shops/{shop_id}/listings
# operationId: getListingsByShop
export def "application-shops-listings get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # When _updating_ a listing, this value can be either `active` or `inactive`. Note: Setting a `draft` listing to `active` will also publish the listing on etsy.com and requires that the listing have an image set. Setting a `sold_out` listing to active will update the quantity to 1 and renew the listing on etsy.com. (default: active)
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --sort-on: string@sort-on-completer # The value to sort a search result of listings on. NOTES: a) `sort_on` only works when combined with one of the search options (keywords, region, etc.). b) when using `score` the returned results will always be in _descending_ order, regardless of the `sort_order` parameter. (default: created)
  --sort-order: string@sort-order-completer # The ascending(up) or descending(down) order to sort listings by. NOTE: sort_order only works when combined with one of the search options (keywords, region, etc.). (default: desc)
  --includes: list # An enumerated string that attaches a valid association. Acceptable inputs are 'Shipping', 'Shop', 'Images', 'User', 'Translations', 'Videos', 'Inventory' and 'Personalization'.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_on" $sort_on "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "includes" $includes "multi") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to delete a ShopListing. A ShopListing can be deleted only if the state is one of the following:  SOLD_OUT, DRAFT, EXPIRED, INACTIVE, ACTIVE and is_available or ACTIVE and has seller flags:  SUPRESSED (frozen), VACATION, CUSTOM_SHOPS (pattern), SELL_ON_FACEBOOK
#
# DELETE /v3/application/listings/{listing_id}
# operationId: deleteListing
export def "application-listings delete" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a listing record by listing ID.
#
# GET /v3/application/listings/{listing_id}
# operationId: getListing
export def "application-listings get" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includes: list # An enumerated string that attaches a valid association. Acceptable inputs are 'Shipping', 'Shop', 'Images', 'User', 'Translations', 'Videos', 'Inventory' and 'Personalization'.
  --language: string # The IETF language tag for the language of this translation. Ex: `de`, `en`, `es`, `fr`, `it`, `ja`, `nl`, `pl`, `pt`.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  --allow-suggested-title: oneof<nothing, bool> # This parameter will include in the response a suggested title for the listing, if one is available. Since suggestions are only available to the listing's owner, client must submit an oauth_access_token scoped to the owner of the listing.
]: nothing -> record<listing_id: int, user_id: int, shop_id: int, title: string, description: string, state: string, creation_timestamp: int, created_timestamp: int, ending_timestamp: int, original_creation_timestamp: int, last_modified_timestamp: int, updated_timestamp: int, state_timestamp: int, quantity: int, shop_section_id: int, featured_rank: int, url: string, num_favorers: int, non_taxable: bool, is_taxable: bool, is_customizable: bool, is_personalizable: bool, listing_type: string, tags: list<string>, materials: list<string>, shipping_profile_id: int, return_policy_id: int, processing_min: int, processing_max: int, who_made: string, when_made: string, is_supply: bool, item_weight: float, item_weight_unit: string, item_length: float, item_width: float, item_height: float, item_dimensions_unit: string, is_private: bool, style: list<string>, file_data: string, has_variations: bool, should_auto_renew: bool, language: string, price: any, converted_price: any, taxonomy_id: int, readiness_state_id: int, suggested_title: string, shipping_profile: any, user: any, shop: any, images: list<any>, videos: list<any>, inventory: any, production_partners: list<any>, skus: list<string>, translations: any, views: int, personalization: any, buyer_price: any> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includes" $includes "multi") (serialize-qp "language" $language "scalar") (serialize-qp "legacy" $legacy "scalar") (serialize-qp "allow_suggested_title" $allow_suggested_title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a file from a specific listing. When you delete the final file for a digital listing, the listing converts into a physical listing. The response to a delete request returns a list of the remaining file records associated with the given listing.
#
# DELETE /v3/application/shops/{shop_id}/listings/{listing_id}/files/{listing_file_id}
# operationId: deleteListingFile
export def "application-shops-listings-files delete" [
  shop_id: int
  listing_id: int
  listing_file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/files/($listing_file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a single file associated with the given digital listing. Requesting a file from a physical listing returns an empty result.
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/files/{listing_file_id}
# operationId: getListingFile
export def "application-shops-listings-files get" [
  shop_id: int
  listing_id: int
  listing_file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<listing_file_id: int, listing_id: int, rank: int, filename: string, filesize: string, size_bytes: int, filetype: string, create_timestamp: int, created_timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/files/($listing_file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves all the files associated with the given digital listing. Requesting files from a physical listing returns an empty result.
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/files
# operationId: getAllListingFiles
export def "application-shops-listings-files list" [
  listing_id: int
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/files")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Uploads a new file for a digital listing, or associates an existing file with a specific listing. You must either provide the `listing_file_id` of an existing file, or the name and binary file data for a file to upload. Associating an existing file to a physical listing converts the physical listing into a digital listing, which removes all shipping costs and any product and inventory variations.
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/files
# operationId: uploadListingFile
export def "application-shops-listings-files uploadListingFile" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listing-file-id: int # The unique numeric ID of a file associated with a digital listing. (format: int64)
  --file: string # A binary file to upload. (nullable, format: binary)
  --name: string # The file name string of a file to upload
  --rank: int # The positive non-zero numeric position in the images displayed in a listing, with rank 1 images appearing in the left-most position in a listing. (format: int64, default: 1)
]: any -> record<listing_file_id: int, listing_id: int, rank: int, filename: string, filesize: string, size_bytes: int, filetype: string, create_timestamp: int, created_timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/files")
  let body = {listing_file_id: $listing_file_id, file: $file, name: $name, rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  A list of all active listings on Etsy paginated by their creation date. Without sort_order listings will be returned newest-first by default.
#
# GET /v3/application/listings/active
# operationId: findAllListingsActive
export def "application-listings-active findAllListingsActive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --keywords: string # Search term or phrase that must appear in all results.
  --sort-on: string@sort-on-completer # The value to sort a search result of listings on. NOTES: a) `sort_on` only works when combined with one of the search options (keywords, region, etc.). b) when using `score` the returned results will always be in _descending_ order, regardless of the `sort_order` parameter. (default: created)
  --sort-order: string@sort-order-completer # The ascending(up) or descending(down) order to sort listings by. NOTE: sort_order only works when combined with one of the search options (keywords, region, etc.). (default: desc)
  --min-price: float # The minimum price of listings to be returned by a search result. (format: float)
  --max-price: float # The maximum price of listings to be returned by a search result. (format: float)
  --taxonomy-id: int # The numerical taxonomy ID of the listing. See [SellerTaxonomy](/documentation/reference#tag/SellerTaxonomy) and [BuyerTaxonomy](/documentation/reference#tag/BuyerTaxonomy) for more information. (format: int64)
  --shop-location: string # Filters by shop location. If location cannot be parsed, Etsy responds with an error.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  --is-safe: oneof<nothing, bool> # When true, filters out mature/adult content from search results.
  --currency: string # The ISO 4217 alphabetic currency code (e.g., EUR, MXN) for price conversion. If provided, the listing price will be converted to this currency.
  --buyer-country: string # The ISO 3166-1 alpha-2 country code (e.g., DE, MX). Filters results to listings that ship to this country. (format: ISO 3166-1 alpha-2)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "sort_on" $sort_on "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "min_price" $min_price "scalar") (serialize-qp "max_price" $max_price "scalar") (serialize-qp "taxonomy_id" $taxonomy_id "scalar") (serialize-qp "shop_location" $shop_location "scalar") (serialize-qp "legacy" $legacy "scalar") (serialize-qp "is_safe" $is_safe "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "buyer_country" $buyer_country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/application/listings/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of all active listings on Etsy in a specific shop, paginated by listing creation date.
#
# GET /v3/application/shops/{shop_id}/listings/active
# operationId: findAllActiveListingsByShop
export def "application-shops-listings-active findAllActiveListingsByShop" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --sort-on: string@sort-on-completer # The value to sort a search result of listings on. NOTES: a) `sort_on` only works when combined with one of the search options (keywords, region, etc.). b) when using `score` the returned results will always be in _descending_ order, regardless of the `sort_order` parameter. (default: created)
  --sort-order: string@sort-order-completer # The ascending(up) or descending(down) order to sort listings by. NOTE: sort_order only works when combined with one of the search options (keywords, region, etc.). (default: desc)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --keywords: string # Search term or phrase that must appear in all results.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "sort_on" $sort_on "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "keywords" $keywords "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/active" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to delete a listing image. A copy of the file remains on our servers, and so a deleted image may be re-associated with the listing without re-uploading the original image; see uploadListingImage.
#
# DELETE /v3/application/shops/{shop_id}/listings/{listing_id}/images/{listing_image_id}
# operationId: deleteListingImage
export def "application-shops-listings-images delete" [
  shop_id: int
  listing_id: int
  listing_image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/images/($listing_image_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the references and metadata for a listing image with a specific image ID.
#
# GET /v3/application/listings/{listing_id}/images/{listing_image_id}
# operationId: getListingImage
export def "application-listings-images get" [
  listing_id: int
  listing_image_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<listing_id: int, listing_image_id: int, hex_code: string, red: int, green: int, blue: int, hue: int, saturation: int, brightness: int, is_black_and_white: bool, creation_tsz: int, created_timestamp: int, rank: int, url_75x75: string, url_170x135: string, url_570xN: string, url_fullxfull: string, full_height: int, full_width: int, alt_text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/images/($listing_image_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves all listing image resources for a listing with a specific listing ID.
#
# GET /v3/application/listings/{listing_id}/images
# operationId: getListingImages
export def "application-listings-images list" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Uploads or assigns an image to a listing identified by a shop ID with a listing ID. To upload a new image, set the image file as the value for the `image` parameter. You can assign a previously deleted image to a listing using the deleted image's image ID in the `listing_image_id` parameter. When a request contains both `image` and `listing_image_id` parameter values, the endpoint uploads the image in the `image` parameter only. Note: When uploading a new image, data such as colors and size may return as null values due to asynchronous processing of the image. Use getListingImage endpoint to fetch these values.
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/images
# operationId: uploadListingImage
export def "application-shops-listings-images uploadListingImage" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --image: string # The file name string of a file to upload (nullable, format: binary)
  --listing-image-id: int # The numeric ID of the primary [listing image](/documentation/reference#tag/ShopListing-Image) for this transaction. (format: int64)
  --rank: int # The positive non-zero numeric position in the images displayed in a listing, with rank 1 images appearing in the left-most position in a listing. (format: int64, default: 1)
  --overwrite: oneof<nothing, bool> # When true, this request replaces the existing image at a given rank. (default: false)
  --is-watermarked: oneof<nothing, bool> # When true, indicates that the uploaded image has a watermark. (default: false)
  --alt-text: string # Alt text for the listing image. Max length 500 characters. (default: )
]: any -> record<listing_id: int, listing_image_id: int, hex_code: string, red: int, green: int, blue: int, hue: int, saturation: int, brightness: int, is_black_and_white: bool, creation_tsz: int, created_timestamp: int, rank: int, url_75x75: string, url_170x135: string, url_570xN: string, url_fullxfull: string, full_height: int, full_width: int, alt_text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/images")
  let body = {image: $image, listing_image_id: $listing_image_id, rank: $rank, overwrite: $overwrite, is_watermarked: $is_watermarked, alt_text: $alt_text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the inventory record for a listing. Listings you did not edit using the Etsy.com inventory tools have no inventory records. This endpoint returns SKU data if you are the owner of the inventory records being fetched.
#
# GET /v3/application/listings/{listing_id}/inventory
# operationId: getListingInventory
export def "application-listings-inventory get" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-deleted: oneof<nothing, bool> # A boolean value for inventory whether to include deleted products and their offerings. Default value is false.
  --includes: string@includes-completer # An enumerated string that attaches a valid association. Default value is null.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<products: list<any>, price_on_property: list<int>, quantity_on_property: list<int>, sku_on_property: list<int>, readiness_state_on_property: list<int>, listing: any> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_deleted" $show_deleted "scalar") (serialize-qp "includes" $includes "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates the inventory for a listing identified by a listing ID. The update fails if the supplied values for product sku, offering quantity, price, and/or processing profile are incompatible with values in `*_on_property` fields. When setting a price, assign a float equal to amount divided by divisor as specified in the Money resource.
#
# PUT /v3/application/listings/{listing_id}/inventory
# operationId: updateListingInventory
# --products item shape: {sku?: string, property_values?: list, offerings: list}
export def "application-listings-inventory updateListingInventory" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  --max-variations-supported: string@max-variations-supported-completer # Coming soon: This parameter determines whether a third variation can be added to or updated for a listing. It accepts values of 2 or 3, where 3 enables third-variation support.
  products: list # A JSON array of products available in a listing, even if only one product. All field names in the JSON blobs are lowercase. — item shape: {sku?: string, property_values?: list, offerings: list}
  --price-on-property: list # An array of unique [listing property](/documentation/reference#operation/getListingInventory) ID integers for the properties that change product prices, if any. For example, if you charge specific prices for different sized products in the same listing, then this array contains the property ID for size.
  --quantity-on-property: list # An array of unique [listing property](/documentation/reference#operation/getListingInventory) ID integers for the properties that change the quantity of the products, if any. For example, if you stock specific quantities of different colored products in the same listing, then this array contains the property ID for color.
  --sku-on-property: list # An array of unique [listing property](/documentation/reference#operation/getListingInventory) ID integers for the properties that change the product SKU, if any. For example, if you use specific skus for different colored products in the same listing, then this array contains the property ID for color.
  --readiness-state-on-property: list # An array of unique [listing property](/documentation/reference#operation/getListingInventory) ID integers for the properties that change processing profile, if any. For example, if you need specific processing profiles for different colored products in the same listing, then this array contains the property ID for color. (nullable)
]: any -> record<products: list<any>, price_on_property: list<int>, quantity_on_property: list<int>, sku_on_property: list<int>, readiness_state_on_property: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar") (serialize-qp "max_variations_supported" $max_variations_supported "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/inventory" $qp)
  let body = {products: $products, price_on_property: $price_on_property, quantity_on_property: $quantity_on_property, sku_on_property: $sku_on_property, readiness_state_on_property: $readiness_state_on_property} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to retrieve a ListingProduct by ID.
#
# GET /v3/application/listings/{listing_id}/inventory/products/{product_id}
# operationId: getListingProduct
export def "application-listings-inventory-products get" [
  listing_id: int
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<product_id: int, sku: string, is_deleted: bool, offerings: list<any>, property_values: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/inventory/products/($product_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get an Offering for a Listing
#
# GET /v3/application/listings/{listing_id}/products/{product_id}/offerings/{product_offering_id}
# operationId: getListingOffering
export def "application-listings-products-offerings get" [
  listing_id: int
  product_id: int
  product_offering_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<offering_id: int, quantity: int, is_enabled: bool, is_deleted: bool, price: any, readiness_state_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/products/($product_id)/offerings/($product_offering_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Allows to query multiple listing ids at once. Limit 100 ids maximum per query.
#
# GET /v3/application/listings/batch
# operationId: getListingsByListingIds
export def "application-listings-batch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listing-ids: list # The list of numeric IDS for the listings in a specific Etsy shop.
  --includes: list # An enumerated string that attaches a valid association. Acceptable inputs are 'Shipping', 'Shop', 'Images', 'User', 'Translations', 'Videos', 'Inventory' and 'Personalization'.
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  --currency: string # The ISO 4217 alphabetic currency code (e.g., EUR, MXN) for price conversion. If provided, the listing price will be converted to this currency.
  --buyer-country: string # The ISO 3166-1 alpha-2 country code (e.g., GB, DE). Used for buyer-facing price calculations (VAT, inclusive shipping). Does not filter listings. (format: ISO 3166-1 alpha-2)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listing_ids" $listing_ids "multi") (serialize-qp "includes" $includes "multi") (serialize-qp "legacy" $legacy "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "buyer_country" $buyer_country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/application/listings/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves Listings associated to a Shop that are featured.
#
# GET /v3/application/shops/{shop_id}/listings/featured
# operationId: getFeaturedListingsByShop
export def "application-shops-listings-featured get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/featured" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes personalization for a listing.
#
# DELETE /v3/application/shops/{shop_id}/listings/{listing_id}/personalization
# operationId: deleteListingPersonalization
export def "application-shops-listings-personalization delete" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/personalization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates or updates personalization settings for a listing, allowing the seller to collect personalization from the buyer. This endpoint will fully replace any existing personalization on the listing.
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/personalization
# operationId: updateListingPersonalization
# --personalization_questions item shape: {question_id?: int, question_text: string, instructions?: string, question_type: "text_input"|"dropdown"|"unlabeled_upload"|"labeled_upload", required: bool, max_allowed_files?: int, max_allowed_characters?: int, options?: list}
export def "application-shops-listings-personalization updateListingPersonalization" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --supports-multiple-personalization-questions: oneof<nothing, bool> # This query parameter indicates that the caller supports up to 5 personalization questions and the following question types: 'text_input', 'dropdown', 'unlabeled_upload', 'labeled_upload'. Sending this param without updating your application can lead to inadvertently deleting seller-entered data. (nullable)
  personalization_questions: list # item shape: {question_id?: int, question_text: string, instructions?: string, question_type: "text_input"|"dropdown"|"unlabeled_upload"|"labeled_upload", required: bool, max_allowed_files?: int, max_allowed_characters?: int, options?: list}
]: any -> record<personalization_questions: table<question_id: int, question_text: string, instructions: string, question_type: string, required: bool, max_allowed_characters: int, max_allowed_files: int, options: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "supports_multiple_personalization_questions" $supports_multiple_personalization_questions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/personalization" $qp)
  let body = {personalization_questions: $personalization_questions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a listing's personalization questions by listing ID.
#
# GET /v3/application/listings/{listing_id}/personalization
# operationId: getListingPersonalization
export def "application-listings-personalization get" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<personalization_questions: table<question_id: int, question_text: string, instructions: string, question_type: string, required: bool, max_allowed_characters: int, max_allowed_files: int, options: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/personalization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a property for a Listing.
#
# DELETE /v3/application/shops/{shop_id}/listings/{listing_id}/properties/{property_id}
# operationId: deleteListingProperty
export def "application-shops-listings-properties delete" [
  shop_id: int
  listing_id: int
  property_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/properties/($property_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates or populates the properties list defining product offerings for a listing. Each offering requires both a `value` and a `value_id` that are valid for a `scale_id` assigned to the listing or that you assign to the listing with this request.
#
# PUT /v3/application/shops/{shop_id}/listings/{listing_id}/properties/{property_id}
# operationId: updateListingProperty
export def "application-shops-listings-properties updateListingProperty" [
  shop_id: int
  listing_id: int
  property_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  value_ids: list # An array of unique IDs of multiple Etsy [listing property](/documentation/reference#operation/getListingProperties) values. For example, if your listing is composed of different materials, then the value ID list contains value IDs for each material.
  values: list # An array of value strings for multiple Etsy [listing property](/documentation/reference#operation/getListingProperties) values. For example, if your listing is painted in different colors, then the values array contains the color strings for each color. Note: parenthesis characters (`(` and `)`) are not allowed.
  --scale-id: int # The numeric ID of a single Etsy.com measurement scale. For example, for shoe size, there are three `scale_id`s available - `UK`, `US/Canada`, and `EU`, where `US/Canada` has `scale_id` 19. (format: int64)
]: any -> record<property_id: int, property_name: string, scale_id: int, scale_name: string, value_ids: list<int>, values: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/properties/($property_id)")
  let body = {value_ids: $value_ids, values: $values, scale_id: $scale_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationTertiary wt-mr-xs-2"> Feedback only </span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Give feedback</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">Development for this endpoint is in progress. It will only return a 501 response.</p></div>  Retrieves a listing's property
#
# GET /v3/application/listings/{listing_id}/properties/{property_id}
# operationId: getListingProperty
export def "application-listings-properties get" [
  listing_id: int
  property_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<property_id: int, property_name: string, scale_id: int, scale_name: string, value_ids: list<int>, values: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/properties/($property_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get a listing's properties
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/properties
# operationId: getListingProperties
export def "application-shops-listings-properties get" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: table<property_id: int, property_name: string, scale_id: int, scale_name: string, value_ids: list, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the list of transactions associated with a listing.
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/transactions
# operationId: getShopReceiptTransactionsByListing
export def "application-shops-listings-transactions get" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a ListingTranslation by listing_id and language
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/translations/{language}
# operationId: createListingTranslation
export def "application-shops-listings-translations createListingTranslation" [
  shop_id: int
  listing_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the Listing of this Translation.
  description: string # The description of the Listing of this Translation.
  --tags: list # The tags of the Listing of this Translation.
]: any -> record<listing_id: int, language: string, title: string, description: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/translations/($language)")
  let body = {title: $title, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get a Translation for a Listing in the given language
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/translations/{language}
# operationId: getListingTranslation
export def "application-shops-listings-translations get" [
  shop_id: int
  listing_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<listing_id: int, language: string, title: string, description: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/translations/($language)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates a ListingTranslation by listing_id and language
#
# PUT /v3/application/shops/{shop_id}/listings/{listing_id}/translations/{language}
# operationId: updateListingTranslation
export def "application-shops-listings-translations updateListingTranslation" [
  shop_id: int
  listing_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the Listing of this Translation.
  description: string # The description of the Listing of this Translation.
  --tags: list # The tags of the Listing of this Translation.
]: any -> record<listing_id: int, language: string, title: string, description: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/translations/($language)")
  let body = {title: $title, description: $description, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates a listing, identified by a listing ID, for a specific shop identified by a shop ID. Note that this is a PATCH method type. When activating, or manually renewing a physical listing, the shipping profile referenced by the `shipping_profile_id`, and all of its fields, along with its entries and upgrades must be complete and valid. If the shipping profile is not complete and valid, we will throw an exception with an error message that guides the request sender to update whatever data is bad.   Digital listings that are not made to order must have a file upload associated with it to be activated. While the listing is a draft, shipping profile and file upload are not required in any case.
#
# PATCH /v3/application/shops/{shop_id}/listings/{listing_id}
# operationId: updateListing
export def "application-shops-listings updateListing" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
  --image-ids: list # An array of numeric image IDs of the images in a listing, which can include up to 20 images.
  --title: string # The listing's title string. When creating or updating a listing, valid title strings contain only letters, numbers, punctuation marks, mathematical symbols, whitespace characters, ™, ©, and ®. (regex: /[^\p{L}\p{Nd}\p{P}\p{Sm}\p{Zs}™©®]/u) You can only use the %, :, & and + characters once each.
  --description: string # A description string of the product for sale in the listing.
  --materials: list # A list of material strings for materials used in the product. Valid materials strings contain only letters, numbers, and whitespace characters. (regex: /[^\p{L}\p{Nd}\p{Zs}]/u) Default value is null. (nullable)
  --should-auto-renew: oneof<nothing, bool> # When true, renews a listing for four months upon expiration.
  --shipping-profile-id: int # The numeric ID of the [shipping profile](/documentation/reference#operation/getShopShippingProfile) associated with the listing. Required when listing type is `physical`. (nullable, format: int64)
  --return-policy-id: int # The numeric ID of the [Return Policy](/documentation/reference#operation/getShopReturnPolicies). Required for active physical listings. This requirement does not apply to listings of EU-based shops. (nullable, format: int64)
  --shop-section-id: int # The numeric ID of the [shop section](/documentation/reference#tag/Shop-Section) for this listing. Default value is null. (nullable, format: int64)
  --item-weight: float # The numeric weight of the product measured in units set in 'item_weight_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-length: float # The numeric length of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-width: float # The numeric width of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-height: float # The numeric height of the product measured in units set in 'item_dimensions_unit'. Default value is null. If set, the value must be greater than 0. (nullable, format: float)
  --item-weight-unit: string@item-weight-unit-completer-1 # A string defining the units used to measure the weight of the product. Default value is null. (nullable)
  --item-dimensions-unit: string@item-dimensions-unit-completer-1 # A string defining the units used to measure the dimensions of the product. Default value is null. (nullable)
  --is-taxable: oneof<nothing, bool> # When true, applicable [shop](/documentation/reference#tag/Shop) tax rates apply to this listing at checkout.
  --taxonomy-id: int # The numerical taxonomy ID of the listing. See [SellerTaxonomy](/documentation/reference#tag/SellerTaxonomy) and [BuyerTaxonomy](/documentation/reference#tag/BuyerTaxonomy) for more information. (format: int64)
  --tags: list # A comma-separated list of tag strings for the listing. When creating or updating a listing, valid tag strings contain only letters, numbers, whitespace characters, -, ', ™, ©, and ®. (regex: /[^\p{L}\p{Nd}\p{Zs}\-'™©®]/u) Default value is null. (nullable)
  --who-made: string@who-made-completer # An enumerated string indicating who made the product. Helps buyers locate the listing under the Handmade heading. Requires 'is_supply' and 'when_made'.
  --when-made: string@when-made-completer # An enumerated string for the era in which the maker made the product in this listing. Helps buyers locate the listing under the Vintage heading. Requires 'is_supply' and 'who_made'.
  --featured-rank: int # The positive non-zero numeric position in the featured listings of the shop, with rank 1 listings appearing in the left-most position in featured listing on a shop's home page. (nullable, format: int64)
  --is-personalizable: oneof<nothing, bool> # [DEPRECATED] When true, this listing is personalizable. The default value is false. NOTE: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --personalization-is-required: oneof<nothing, bool> # [DEPRECATED] When true, this listing requires personalization. The default value is false. NOTE: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --personalization-char-count-max: int # [DEPRECATED] This is an integer value representing the maximum length for the personalization message entered by the buyer. Will only change if is_personalizable is 'true'. Note: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details. (format: int64)
  --personalization-instructions: string # [DEPRECATED] A string representing instructions for the buyer to enter the personalization. Will only change if is_personalizable is 'true'. Note: This field will be removed on Apr. 9th, 2026. See https://developers.etsy.com/documentation/tutorials/personalization-migration for migration details.
  --state: string@state-completer-1 # When _updating_ a listing, this value can be either `active` or `inactive`. Note: Setting a `draft` listing to `active` will also publish the listing on etsy.com and requires that the listing have an image set. Setting a `sold_out` listing to active will update the quantity to 1 and renew the listing on etsy.com.
  --is-supply: oneof<nothing, bool> # When true, tags the listing as a supply product, else indicates that it's a finished product. Helps buyers locate the listing under the Supplies heading. Requires 'who_made' and 'when_made'.
  --production-partner-ids: list # An array of unique IDs of production partner ids. (nullable)
  --type: string@type-completer # An enumerated type string that indicates whether the listing is physical or a digital download. (nullable)
]: any -> record<listing_id: int, user_id: int, shop_id: int, title: string, description: string, state: string, creation_timestamp: int, created_timestamp: int, ending_timestamp: int, original_creation_timestamp: int, last_modified_timestamp: int, updated_timestamp: int, state_timestamp: int, quantity: int, shop_section_id: int, featured_rank: int, url: string, num_favorers: int, non_taxable: bool, is_taxable: bool, is_customizable: bool, is_personalizable: bool, listing_type: string, tags: list<string>, materials: list<string>, shipping_profile_id: int, return_policy_id: int, processing_min: int, processing_max: int, who_made: string, when_made: string, is_supply: bool, item_weight: float, item_weight_unit: string, item_length: float, item_width: float, item_height: float, item_dimensions_unit: string, is_private: bool, style: list<string>, file_data: string, has_variations: bool, should_auto_renew: bool, language: string, price: any, converted_price: any, taxonomy_id: int, readiness_state_id: int, suggested_title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)" $qp)
  let body = {image_ids: $image_ids, title: $title, description: $description, materials: $materials, should_auto_renew: $should_auto_renew, shipping_profile_id: $shipping_profile_id, return_policy_id: $return_policy_id, shop_section_id: $shop_section_id, item_weight: $item_weight, item_length: $item_length, item_width: $item_width, item_height: $item_height, item_weight_unit: $item_weight_unit, item_dimensions_unit: $item_dimensions_unit, is_taxable: $is_taxable, taxonomy_id: $taxonomy_id, tags: $tags, who_made: $who_made, when_made: $when_made, featured_rank: $featured_rank, is_personalizable: $is_personalizable, personalization_is_required: $personalization_is_required, personalization_char_count_max: $personalization_char_count_max, personalization_instructions: $personalization_instructions, state: $state, is_supply: $is_supply, production_partner_ids: $production_partner_ids, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Gets all variation images on a listing.
#
# GET /v3/application/shops/{shop_id}/listings/{listing_id}/variation-images
# operationId: getListingVariationImages
export def "application-shops-listings-variation-images get" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: table<property_id: int, value_id: int, value: string, image_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/variation-images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates variation images on a listing. `variation_images` is an array with inputs for the `property_id`, `value_id`, and `image_id` fields. `image_ids` are associated with a `ListingImage` on the listing associated with the provided `listing_id`. `property_id` and `value_id` pairs are associated with a `ListingProduct` on the listing associated with the provided `listing_id`. `variation_images` should not contain any duplicates. `variation_images` does not contain more than one `property_id` as variation images can only be associated on one property. The update overwrites all existing variation images on a listing, so if your request is successful, the variation images on the listing will be exactly those you specify. 
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/variation-images
# operationId: updateVariationImages
# --variation_images item shape: {property_id: int, value_id: int, image_id: int}
export def "application-shops-listings-variation-images updateVariationImages" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  variation_images: list # A list of variation image data. — item shape: {property_id: int, value_id: int, image_id: int}
]: any -> record<count: int, results: table<property_id: int, value_id: int, value: string, image_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/variation-images")
  let body = {variation_images: $variation_images} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to delete a listing video. A copy of the video remains on our servers, and so a deleted video may be re-associated with the listing without re-uploading the original video; see uploadListingVideo.
#
# DELETE /v3/application/shops/{shop_id}/listings/{listing_id}/videos/{video_id}
# operationId: deleteListingVideo
export def "application-shops-listings-videos delete" [
  shop_id: int
  listing_id: int
  video_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a single video associated with the given listing. Requesting a video from a listing returns an empty result.
#
# GET /v3/application/listings/{listing_id}/videos/{video_id}
# operationId: getListingVideo
export def "application-listings-videos get" [
  video_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<video_id: int, height: int, width: int, thumbnail_url: string, video_url: string, video_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves all listing video resources for a listing with a specific listing ID.
#
# GET /v3/application/listings/{listing_id}/videos
# operationId: getListingVideos
export def "application-listings-videos list" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/videos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Uploads a new video for a listing, or associates an existing video with a specific listing. You must either provide the `video_id` of an existing video, or the name and binary file data for a video to upload. If providing a `video_id`, the video must already be associated with the same shop as the listing, but it does not need to be currently associated with the listing. 
#
# POST /v3/application/shops/{shop_id}/listings/{listing_id}/videos
# operationId: uploadListingVideo
export def "application-shops-listings-videos uploadListingVideo" [
  shop_id: int
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-id: int # The unique ID of a video associated with a listing. (format: int64)
  --video: string # A video file to upload. (nullable, format: binary)
  --name: string # The file name string for the video to upload.
]: any -> record<video_id: int, height: int, width: int, thumbnail_url: string, video_url: string, video_state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/listings/($listing_id)/videos")
  let body = {video_id: $video_id, video: $video, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get a single Shop Payment Account Ledger's Entry
#
# GET /v3/application/shops/{shop_id}/payment-account/ledger-entries/{ledger_entry_id}
# operationId: getShopPaymentAccountLedgerEntry
export def "application-shops-payment-account-ledger-entries get" [
  shop_id: int
  ledger_entry_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<entry_id: int, ledger_id: int, sequence_number: int, amount: int, currency: string, description: string, balance: int, create_date: int, created_timestamp: int, ledger_type: string, reference_type: string, reference_id: string, parent_entry_id: int, payment_adjustments: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/payment-account/ledger-entries/($ledger_entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get a Shop Payment Account Ledger's Entries
#
# GET /v3/application/shops/{shop_id}/payment-account/ledger-entries
# operationId: getShopPaymentAccountLedgerEntries
export def "application-shops-payment-account-ledger-entries list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-created: int # The earliest unix timestamp for when a record was created. (format: int64)
  --max-created: int # The latest unix timestamp for when a record was created. (format: int64)
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_created" $min_created "scalar") (serialize-qp "max_created" $max_created "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/payment-account/ledger-entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Get a Payment from a PaymentAccount Ledger Entry ID, if applicable
#
# GET /v3/application/shops/{shop_id}/payment-account/ledger-entries/payments
# operationId: getPaymentAccountLedgerEntryPayments
export def "application-shops-payment-account-ledger-entries-payments get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ledger-entry-ids: list
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ledger_entry_ids" $ledger_entry_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/payment-account/ledger-entries/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a payment from a specific receipt, identified by `receipt_id`, from a specific shop, identified by `shop_id`
#
# GET /v3/application/shops/{shop_id}/receipts/{receipt_id}/payments
# operationId: getShopPaymentByReceiptId
export def "application-shops-receipts-payments get" [
  shop_id: int
  receipt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)/payments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of payments from a shop identified by `shop_id`. You can also filter results using a list of payment IDs.
#
# GET /v3/application/shops/{shop_id}/payments
# operationId: getPayments
export def "application-shops-payments get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payment-ids: list # A comma-separated array of Payment IDs numbers.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payment_ids" $payment_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Check to confirm connectivity to the Etsy API with an application
#
# GET /v3/application/openapi-ping
# operationId: ping
export def "application-openapi-ping ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<application_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/openapi-ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a receipt, identified by a receipt id, from an Etsy shop. **NOTE** Access to ShopReceipt's first_line, second_line, city, state, zip, country_iso and formatted_address is contingent in some regions to a preferred partnership status with Etsy
#
# GET /v3/application/shops/{shop_id}/receipts/{receipt_id}
# operationId: getShopReceipt
export def "application-shops-receipts get" [
  shop_id: int
  receipt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<receipt_id: int, receipt_type: int, seller_user_id: int, seller_email: string, buyer_user_id: int, buyer_email: string, name: string, first_line: string, second_line: string, city: string, state: string, zip: string, status: string, formatted_address: string, country_iso: string, payment_method: string, payment_email: string, message_from_seller: string, message_from_buyer: string, message_from_payment: string, is_paid: bool, is_shipped: bool, create_timestamp: int, created_timestamp: int, update_timestamp: int, updated_timestamp: int, is_gift: bool, gift_message: string, gift_sender: string, grandtotal: any, subtotal: any, total_price: any, total_shipping_cost: any, total_tax_cost: any, total_vat_cost: any, discount_amt: any, gift_wrap_price: any, shipments: list<any>, transactions: list<any>, refunds: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates the status of a receipt, identified by a receipt id, from an Etsy shop. **NOTE** Access to ShopReceipt's first_line, second_line, city, state, zip, country_iso and formatted_address is contingent in some regions to a preferred partnership status with Etsy
#
# PUT /v3/application/shops/{shop_id}/receipts/{receipt_id}
# operationId: updateShopReceipt
export def "application-shops-receipts updateShopReceipt" [
  shop_id: int
  receipt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
  --was-shipped: oneof<nothing, bool> # When `true`, returns receipts where the seller shipped the product(s) in this receipt. When `false`, returns receipts where shipment has not been set. (nullable)
  --was-paid: oneof<nothing, bool> # When `true`, returns receipts where the seller has received payment for the receipt. When `false`, returns receipts where payment has not been received. (nullable)
]: any -> record<receipt_id: int, receipt_type: int, seller_user_id: int, seller_email: string, buyer_user_id: int, buyer_email: string, name: string, first_line: string, second_line: string, city: string, state: string, zip: string, status: string, formatted_address: string, country_iso: string, payment_method: string, payment_email: string, message_from_seller: string, message_from_buyer: string, message_from_payment: string, is_paid: bool, is_shipped: bool, create_timestamp: int, created_timestamp: int, update_timestamp: int, updated_timestamp: int, is_gift: bool, gift_message: string, gift_sender: string, grandtotal: any, subtotal: any, total_price: any, total_shipping_cost: any, total_tax_cost: any, total_vat_cost: any, discount_amt: any, gift_wrap_price: any, shipments: list<any>, transactions: list<any>, refunds: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)" $qp)
  let body = {was_shipped: $was_shipped, was_paid: $was_paid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Requests the Shop Receipts from a specific Shop, unfiltered or filtered by receipt id range or offset, date, paid, and/or shipped purchases. **NOTE** Access to ShopReceipt's first_line, second_line, city, state, zip, country_iso and formatted_address is contingent in some regions to a preferred partnership status with Etsy
#
# GET /v3/application/shops/{shop_id}/receipts
# operationId: getShopReceipts
export def "application-shops-receipts list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-created: int # The earliest unix timestamp for when a record was created. (format: int64)
  --max-created: int # The latest unix timestamp for when a record was created. (format: int64)
  --min-last-modified: int # The earliest unix timestamp for when a record last changed. (format: int64)
  --max-last-modified: int # The latest unix timestamp for when a record last changed. (format: int64)
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --sort-on: string@sort-on-completer-1 # The value to sort a search result of listings on. (default: created)
  --sort-order: string@sort-order-completer # The ascending(up) or descending(down) order to sort receipts by. (default: desc)
  --was-paid: oneof<nothing, bool> # When `true`, returns receipts where the seller has received payment for the receipt. When `false`, returns receipts where payment has not been received. (nullable)
  --was-shipped: oneof<nothing, bool> # When `true`, returns receipts where the seller shipped the product(s) in this receipt. When `false`, returns receipts where shipment has not been set. (nullable)
  --was-delivered: oneof<nothing, bool> # When `true`, returns receipts that have been marked as delivered. When `false`, returns receipts where shipment has not been marked as delivered. (nullable)
  --was-canceled: oneof<nothing, bool> # When `true`, the endpoint will only return the canceled receipts. When `false`, the endpoint will only return non-canceled receipts. (nullable)
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min_created" $min_created "scalar") (serialize-qp "max_created" $max_created "scalar") (serialize-qp "min_last_modified" $min_last_modified "scalar") (serialize-qp "max_last_modified" $max_last_modified "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_on" $sort_on "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "was_paid" $was_paid "scalar") (serialize-qp "was_shipped" $was_shipped "scalar") (serialize-qp "was_delivered" $was_delivered "scalar") (serialize-qp "was_canceled" $was_canceled "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Gets all listings associated with a receipt.
#
# GET /v3/application/shops/{shop_id}/receipts/{receipt_id}/listings
# operationId: getListingsByShopReceipt
export def "application-shops-receipts-listings get" [
  receipt_id: int
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Submits tracking information for a Shop Receipt, which creates a Shop Receipt Shipment entry for the given receipt_id. Each time you successfully submit tracking info, Etsy sends a notification email to the buyer User. When send_bcc is true, Etsy sends shipping notifications to the seller as well. When tracking_code and carrier_name aren't sent, the receipt is marked as shipped only. If the carrier is not supported, you may use `other` as the carrier name so you can provide the tracking code. **NOTES** When shipping within the United States AND the order is over $10 _or_ when shipping to India, tracking code and carrier name ARE required. Access to ShopReceipt's first_line, second_line, city, state, zip, country_iso and formatted_address is contingent in some regions to a preferred partnership status with Etsy
#
# POST /v3/application/shops/{shop_id}/receipts/{receipt_id}/tracking
# operationId: createReceiptShipment
# --customs_data item shape: {country_of_origin: string, declared_value: float, HS_code: string}
export def "application-shops-receipts-tracking createReceiptShipment" [
  shop_id: int
  receipt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
  --tracking-code: string # The tracking code for this receipt.
  --carrier-name: string # The carrier name for this receipt.
  --send-bcc: oneof<nothing, bool> # If true, the shipping notification will be sent to the seller as well
  --note-to-buyer: string # Message to include in notification to the buyer.
  --mail-class: string # The service level of postal or carrier service selected for the shipment (e.g., First-Class, Priority, Ground, Express). (nullable)
  --weight: float # The total weight of the package. (nullable, format: float)
  --weight-units: string # Unit of measurement used for package weight (oz, grams, etc.). (nullable)
  --length: float # Longest side of the package. (nullable, format: float)
  --width: float # Second longest side of the package. (nullable, format: float)
  --height: float # Third longest side of the package. (nullable, format: float)
  --dimension-units: string # Unit of measurement used for package dimensions (in, cm...). (nullable)
  --shipping-label-cost: float # The purchase price the seller paid for the shipping label. (nullable, format: float)
  --shipping-label-currency: string # The currency in which the shipping label was purchased. (nullable)
  --revenue-eligibility: string # A flag indicating if the shipment is tied to a revenue share agreement between Etsy and the vendor. (nullable)
  --ship-from-country: string # Where the package ships from. (nullable)
  --ship-to-country: string # Package destination. (nullable)
  --incoterm: string # The specific incoterm (e.g., DDU, DDP) designated for the shipment. (nullable)
  --customs-data: list # Contains custom data like country of origin, declared value and HS code. (nullable) — item shape: {country_of_origin: string, declared_value: float, HS_code: string}
  --duty-amount: float # The estimated or actual amount of import duties and taxes assessed by customs for the shipment. (nullable, format: float)
  --duty-currency: string # The currency in which the duty was paid. (nullable)
  --ship-date: string # The date package was shipped. (nullable)
]: any -> record<receipt_id: int, receipt_type: int, seller_user_id: int, seller_email: string, buyer_user_id: int, buyer_email: string, name: string, first_line: string, second_line: string, city: string, state: string, zip: string, status: string, formatted_address: string, country_iso: string, payment_method: string, payment_email: string, message_from_seller: string, message_from_buyer: string, message_from_payment: string, is_paid: bool, is_shipped: bool, create_timestamp: int, created_timestamp: int, update_timestamp: int, updated_timestamp: int, is_gift: bool, gift_message: string, gift_sender: string, grandtotal: any, subtotal: any, total_price: any, total_shipping_cost: any, total_tax_cost: any, total_vat_cost: any, discount_amt: any, gift_wrap_price: any, shipments: list<any>, transactions: list<any>, refunds: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)/tracking" $qp)
  let body = {tracking_code: $tracking_code, carrier_name: $carrier_name, send_bcc: $send_bcc, note_to_buyer: $note_to_buyer, mail_class: $mail_class, weight: $weight, weight_units: $weight_units, length: $length, width: $width, height: $height, dimension_units: $dimension_units, shipping_label_cost: $shipping_label_cost, shipping_label_currency: $shipping_label_currency, revenue_eligibility: $revenue_eligibility, ship_from_country: $ship_from_country, ship_to_country: $ship_to_country, incoterm: $incoterm, customs_data: $customs_data, duty_amount: $duty_amount, duty_currency: $duty_currency, ship_date: $ship_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the list of transactions associated with a specific receipt.
#
# GET /v3/application/shops/{shop_id}/receipts/{receipt_id}/transactions
# operationId: getShopReceiptTransactionsByReceipt
export def "application-shops-receipts-transactions get" [
  shop_id: int
  receipt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/receipts/($receipt_id)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 to retrieve the reviews for a listing given its ID.
#
# GET /v3/application/listings/{listing_id}/reviews
# operationId: getReviewsByListing
export def "application-listings-reviews get" [
  listing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --min-created: int # The earliest unix timestamp for when a record was created. (nullable, format: int64)
  --max-created: int # The latest unix timestamp for when a record was created. (nullable, format: int64)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_created" $min_created "scalar") (serialize-qp "max_created" $max_created "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/listings/($listing_id)/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 to retrieve the reviews from a shop given its ID.
#
# GET /v3/application/shops/{shop_id}/reviews
# operationId: getReviewsByShop
export def "application-shops-reviews get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --min-created: int # The earliest unix timestamp for when a record was created. (nullable, format: int64)
  --max-created: int # The latest unix timestamp for when a record was created. (nullable, format: int64)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "min_created" $min_created "scalar") (serialize-qp "max_created" $max_created "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/reviews" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the full hierarchy tree of seller taxonomy nodes.
#
# GET /v3/application/seller-taxonomy/nodes
# operationId: getSellerTaxonomyNodes
export def "application-seller-taxonomy-nodes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/seller-taxonomy/nodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of product properties, with applicable scales and values, supported for a specific seller taxonomy ID.
#
# GET /v3/application/seller-taxonomy/nodes/{taxonomy_id}/properties
# operationId: getPropertiesByTaxonomyId
export def "application-seller-taxonomy-nodes-properties get" [
  taxonomy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/seller-taxonomy/nodes/($taxonomy_id)/properties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of available shipping carriers and the mail classes associated with them for a given country
#
# GET /v3/application/shipping-carriers
# operationId: getShippingCarriers
export def "application-shipping-carriers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin-country-iso: string # The ISO code of the country from which the listing ships. (format: ISO 3166-1 alpha-2)
]: nothing -> record<count: int, results: table<shipping_carrier_id: int, name: string, domestic_classes: list, international_classes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin_country_iso" $origin_country_iso "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/application/shipping-carriers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the shop identified by a specific shop ID.
#
# GET /v3/application/shops/{shop_id}
# operationId: getShop
export def "application-shops get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shop_id: int, user_id: int, shop_name: string, create_date: int, created_timestamp: int, title: string, announcement: string, currency_code: string, is_vacation: bool, vacation_message: string, sale_message: string, digital_sale_message: string, update_date: int, updated_timestamp: int, listing_active_count: int, digital_listing_count: int, login_name: string, accepts_custom_requests: bool, policy_welcome: string, policy_payment: string, policy_shipping: string, policy_refunds: string, policy_additional: string, policy_seller_info: string, policy_update_date: int, policy_has_private_receipt_info: bool, has_unstructured_policies: bool, policy_privacy: string, vacation_autoreply: string, url: string, image_url_760x100: string, num_favorers: int, languages: list<string>, icon_url_fullxfull: string, is_using_structured_policies: bool, has_onboarded_structured_policies: bool, include_dispute_form_link: bool, is_direct_checkout_onboarded: bool, is_etsy_payments_onboarded: bool, is_calculated_eligible: bool, is_opted_in_to_buyer_promise: bool, is_shop_us_based: bool, transaction_sold_count: int, shipping_from_country_iso: string, shop_location_country_iso: string, review_count: int, review_average: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates a shop. Assumes that all string parameters are provided in the shop's primary language. Please note that the policy_additional field should only be set for shops located in the EU. Passing a value for this field for shops outside of the EU, will result in an error.
#
# PUT /v3/application/shops/{shop_id}
# operationId: updateShop
export def "application-shops updateShop" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # A brief heading string for the shop's main page.
  --announcement: string # An announcement string to buyers that displays on the shop's homepage.
  --sale-message: string # A message string sent to users who complete a purchase from this shop.
  --digital-sale-message: string # A message string sent to users who purchase a digital item from this shop.
  --policy-additional: string # The shop's additional policies string (may be blank).
]: any -> record<shop_id: int, user_id: int, shop_name: string, create_date: int, created_timestamp: int, title: string, announcement: string, currency_code: string, is_vacation: bool, vacation_message: string, sale_message: string, digital_sale_message: string, update_date: int, updated_timestamp: int, listing_active_count: int, digital_listing_count: int, login_name: string, accepts_custom_requests: bool, policy_welcome: string, policy_payment: string, policy_shipping: string, policy_refunds: string, policy_additional: string, policy_seller_info: string, policy_update_date: int, policy_has_private_receipt_info: bool, has_unstructured_policies: bool, policy_privacy: string, vacation_autoreply: string, url: string, image_url_760x100: string, num_favorers: int, languages: list<string>, icon_url_fullxfull: string, is_using_structured_policies: bool, has_onboarded_structured_policies: bool, include_dispute_form_link: bool, is_direct_checkout_onboarded: bool, is_etsy_payments_onboarded: bool, is_calculated_eligible: bool, is_opted_in_to_buyer_promise: bool, is_shop_us_based: bool, transaction_sold_count: int, shipping_from_country_iso: string, shop_location_country_iso: string, review_count: int, review_average: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)")
  let body = {title: $title, announcement: $announcement, sale_message: $sale_message, digital_sale_message: $digital_sale_message, policy_additional: $policy_additional} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the shop identified by the shop owner's user ID.
#
# GET /v3/application/users/{user_id}/shops
# operationId: getShopByOwnerUserId
export def "application-users-shops get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shop_id: int, user_id: int, shop_name: string, create_date: int, created_timestamp: int, title: string, announcement: string, currency_code: string, is_vacation: bool, vacation_message: string, sale_message: string, digital_sale_message: string, update_date: int, updated_timestamp: int, listing_active_count: int, digital_listing_count: int, login_name: string, accepts_custom_requests: bool, policy_welcome: string, policy_payment: string, policy_shipping: string, policy_refunds: string, policy_additional: string, policy_seller_info: string, policy_update_date: int, policy_has_private_receipt_info: bool, has_unstructured_policies: bool, policy_privacy: string, vacation_autoreply: string, url: string, image_url_760x100: string, num_favorers: int, languages: list<string>, icon_url_fullxfull: string, is_using_structured_policies: bool, has_onboarded_structured_policies: bool, include_dispute_form_link: bool, is_direct_checkout_onboarded: bool, is_etsy_payments_onboarded: bool, is_calculated_eligible: bool, is_opted_in_to_buyer_promise: bool, is_shop_us_based: bool, transaction_sold_count: int, shipping_from_country_iso: string, shop_location_country_iso: string, review_count: int, review_average: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/users/($user_id)/shops")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of holidays that are available to a shop to set a preference for. Currently only supported in the US and CA
#
# GET /v3/application/shops/{shop_id}/holiday-preferences
# operationId: getHolidayPreferences
export def "application-shops-holiday-preferences get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<shop_id: int, holiday_id: int, country_iso: string, is_working: bool, holiday_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/holiday-preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates the preference for whether the seller will process orders or not on the holiday. Currently only supported in the US and CA
#
# PUT /v3/application/shops/{shop_id}/holiday-preferences/{holiday_id}
# operationId: updateHolidayPreferences
export def "application-shops-holiday-preferences updateHolidayPreferences" [
  shop_id: int
  holiday_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-working: oneof<nothing, bool> # A boolean value for whether the shop will process orders on a particular holiday.
]: any -> record<shop_id: int, holiday_id: int, country_iso: string, is_working: bool, holiday_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/holiday-preferences/($holiday_id)")
  let body = {is_working: $is_working} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint for searching shops by name. Note: We make every effort to ensure that frozen or removed shops are not included in the search results. However, rarely, due to timing issues, they may appear.
#
# GET /v3/application/shops
# operationId: findShops
export def "application-shops findShops" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shop-name: string # The shop's name string.
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shop_name" $shop_name "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/application/shops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Consolidates Return Policies by moving all listings from a source return policy to a destination return policy, and deleting the source return policy. This is commonly used in the event that a user attempts to update a Return Policy such that its data is a duplicate of some other Return Policy, which is prevented.
#
# POST /v3/application/shops/{shop_id}/policies/return/consolidate
# operationId: consolidateShopReturnPolicies
export def "application-shops-policies-return-consolidate consolidateShopReturnPolicies" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  source_return_policy_id: int # The numeric ID of the [Return Policy](/documentation/reference#operation/getShopReturnPolicies). (format: int64)
  destination_return_policy_id: int # The numeric ID of the [Return Policy](/documentation/reference#operation/getShopReturnPolicies). (format: int64)
]: any -> record<return_policy_id: int, shop_id: int, accepts_returns: bool, accepts_exchanges: bool, return_deadline: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return/consolidate")
  let body = {source_return_policy_id: $source_return_policy_id, destination_return_policy_id: $destination_return_policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new Return Policy. Note: if either accepts_returns or accepts_exchanges is true, then a return_deadline is required.
#
# POST /v3/application/shops/{shop_id}/policies/return
# operationId: createShopReturnPolicy
export def "application-shops-policies-return createShopReturnPolicy" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-returns: oneof<nothing, bool>
  --accepts-exchanges: oneof<nothing, bool>
  --return-deadline: int # The deadline for the Return Policy, measured in days. The value must be one of the following: [7, 14, 21, 30, 45, 60, 90]. (nullable, format: int64)
]: any -> record<return_policy_id: int, shop_id: int, accepts_returns: bool, accepts_exchanges: bool, return_deadline: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return")
  let body = {accepts_returns: $accepts_returns, accepts_exchanges: $accepts_exchanges, return_deadline: $return_deadline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Returns a shop's list of existing Return Policies
#
# GET /v3/application/shops/{shop_id}/policies/return
# operationId: getShopReturnPolicies
export def "application-shops-policies-return list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: table<return_policy_id: int, shop_id: int, accepts_returns: bool, accepts_exchanges: bool, return_deadline: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes an existing Return Policy. Deletion is only allowed for policies which have no associated listings – move them to another policy before attempting deletion.
#
# DELETE /v3/application/shops/{shop_id}/policies/return/{return_policy_id}
# operationId: deleteShopReturnPolicy
export def "application-shops-policies-return delete" [
  shop_id: int
  return_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return/($return_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves an existing Return Policy.
#
# GET /v3/application/shops/{shop_id}/policies/return/{return_policy_id}
# operationId: getShopReturnPolicy
export def "application-shops-policies-return get" [
  shop_id: int
  return_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<return_policy_id: int, shop_id: int, accepts_returns: bool, accepts_exchanges: bool, return_deadline: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return/($return_policy_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates an existing Return Policy. Note: if either accepts_returns or accepts_exchanges is true, then a return_deadline is required.
#
# PUT /v3/application/shops/{shop_id}/policies/return/{return_policy_id}
# operationId: updateShopReturnPolicy
export def "application-shops-policies-return updateShopReturnPolicy" [
  shop_id: int
  return_policy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepts-returns: oneof<nothing, bool>
  --accepts-exchanges: oneof<nothing, bool>
  --return-deadline: int # The deadline for the Return Policy, measured in days. The value must be one of the following: [7, 14, 21, 30, 45, 60, 90]. (nullable, format: int64)
]: any -> record<return_policy_id: int, shop_id: int, accepts_returns: bool, accepts_exchanges: bool, return_deadline: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return/($return_policy_id)")
  let body = {accepts_returns: $accepts_returns, accepts_exchanges: $accepts_exchanges, return_deadline: $return_deadline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Gets all listings associated with a Return Policy.
#
# GET /v3/application/shops/{shop_id}/policies/return/{return_policy_id}/listings
# operationId: getListingsByShopReturnPolicy
export def "application-shops-policies-return-listings get" [
  return_policy_id: int
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/policies/return/($return_policy_id)/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of production partners available in the specific Etsy shop identified by its shop ID.
#
# GET /v3/application/shops/{shop_id}/production-partners
# operationId: getShopProductionPartners
export def "application-shops-production-partners get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/production-partners")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new ReadinessStateDefinition. If an existing definition matches the input values, this endpoint will throw a Conflict error, please refer to the Content-Location header to obtain the get endpoint url for the values of the existing definition. Does not affect the product offering-readiness states definition relationship.
#
# POST /v3/application/shops/{shop_id}/readiness-state-definitions
# operationId: createShopReadinessStateDefinition
export def "application-shops-readiness-state-definitions createShopReadinessStateDefinition" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  readiness_state: string@readiness-state-completer # The readiness state of a product: \"1\" means \"ready_to_ship\", and \"2\" means \"made_to_order\"
  min_processing_time: int # The minimum number of days or weeks for processing a specific product. (format: int64)
  max_processing_time: int # The maximum number of days or weeks for processing a specific product. (format: int64)
  --processing-time-unit: string@processing-time-unit-completer # The unit used to represent how long a processing time is. A week is equivalent to how many days the seller works per week as stated in their processing schedule. If none is provided, the unit is set to \"days\". (default: days)
]: any -> record<shop_id: int, readiness_state_id: int, readiness_state: string, min_processing_days: int, max_processing_days: int, processing_days_display_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/readiness-state-definitions")
  let body = {readiness_state: $readiness_state, min_processing_time: $min_processing_time, max_processing_time: $max_processing_time, processing_time_unit: $processing_time_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of ProcessingProfiles available in the specific Etsy shop identified by its shop ID.
#
# GET /v3/application/shops/{shop_id}/readiness-state-definitions
# operationId: getShopReadinessStateDefinitions
export def "application-shops-readiness-state-definitions list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
]: nothing -> record<count: int, results: table<shop_id: int, readiness_state_id: int, readiness_state: string, min_processing_days: int, max_processing_days: int, processing_days_display_label: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/readiness-state-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a ReadinessStateDefinition by given readiness state definition ID. If there any active offerings linked to the definition, this endpoint will throw a Bad Request error. If you want to delete a ReadinessStateDefinition that is linked to active offerings, you must link the offerings to a different readiness state definition.
#
# DELETE /v3/application/shops/{shop_id}/readiness-state-definitions/{readiness_state_definition_id}
# operationId: deleteShopReadinessStateDefinition
export def "application-shops-readiness-state-definitions delete" [
  shop_id: int
  readiness_state_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/readiness-state-definitions/($readiness_state_definition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a ProcessingProfile referenced by readiness state definition ID.
#
# GET /v3/application/shops/{shop_id}/readiness-state-definitions/{readiness_state_definition_id}
# operationId: getShopReadinessStateDefinition
export def "application-shops-readiness-state-definitions get" [
  shop_id: int
  readiness_state_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shop_id: int, readiness_state_id: int, readiness_state: string, min_processing_days: int, max_processing_days: int, processing_days_display_label: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/readiness-state-definitions/($readiness_state_definition_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates an existing ReadinessStateDefinition. If an existing definition matches the input values, this endpoint will throw a Conflict error, please refer to the Content-Location header to obtain the get endpoint url for the values of the existing definition. Does not affect the product offering-readiness states definition relationship.
#
# PUT /v3/application/shops/{shop_id}/readiness-state-definitions/{readiness_state_definition_id}
# operationId: updateShopReadinessStateDefinition
export def "application-shops-readiness-state-definitions updateShopReadinessStateDefinition" [
  shop_id: int
  readiness_state_definition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --readiness-state: string@readiness-state-completer # The readiness state of a product: \"1\" means \"ready_to_ship\", and \"2\" means \"made_to_order\"
  --min-processing-time: int # The minimum number of days or weeks for processing a specific product. (format: int64)
  --max-processing-time: int # The maximum number of days or weeks for processing a specific product. (format: int64)
  --processing-time-unit: string@processing-time-unit-completer # The unit used to represent how long a processing time is. A week is equivalent to how many days the seller works per week as stated in their processing schedule. If none is provided, the unit is set to \"days\". (default: days)
]: any -> record<shop_id: int, readiness_state_id: int, readiness_state: string, min_processing_days: int, max_processing_days: int, processing_days_display_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/readiness-state-definitions/($readiness_state_definition_id)")
  let body = {readiness_state: $readiness_state, min_processing_time: $min_processing_time, max_processing_time: $max_processing_time, processing_time_unit: $processing_time_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new section in a specific shop.
#
# POST /v3/application/shops/{shop_id}/sections
# operationId: createShopSection
export def "application-shops-sections createShopSection" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title string for a shop section.
]: any -> record<shop_section_id: int, title: string, rank: int, user_id: int, active_listing_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/sections")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the list of shop sections in a specific shop identified by shop ID.
#
# GET /v3/application/shops/{shop_id}/sections
# operationId: getShopSections
export def "application-shops-sections list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/sections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a section in a specific shop given a valid shop_section_id.
#
# DELETE /v3/application/shops/{shop_id}/sections/{shop_section_id}
# operationId: deleteShopSection
export def "application-shops-sections delete" [
  shop_id: int
  shop_section_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/sections/($shop_section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a shop section, referenced by section ID and shop ID.
#
# GET /v3/application/shops/{shop_id}/sections/{shop_section_id}
# operationId: getShopSection
export def "application-shops-sections get" [
  shop_id: int
  shop_section_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shop_section_id: int, title: string, rank: int, user_id: int, active_listing_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/sections/($shop_section_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates a section in a specific shop given a valid shop_section_id.
#
# PUT /v3/application/shops/{shop_id}/sections/{shop_section_id}
# operationId: updateShopSection
export def "application-shops-sections updateShopSection" [
  shop_id: int
  shop_section_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title string for a shop section.
]: any -> record<shop_section_id: int, title: string, rank: int, user_id: int, active_listing_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/sections/($shop_section_id)")
  let body = {title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves all the listings from the section of a specific shop.
#
# GET /v3/application/shops/{shop_id}/shop-sections/listings
# operationId: getListingsByShopSectionId
export def "application-shops-shop-sections-listings get" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shop-section-ids: list # A list of numeric IDS for all sections in a specific Etsy shop.
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --sort-on: string@sort-on-completer # The value to sort a search result of listings on. NOTES: a) `sort_on` only works when combined with one of the search options (keywords, region, etc.). b) when using `score` the returned results will always be in _descending_ order, regardless of the `sort_order` parameter. (default: created)
  --sort-order: string@sort-order-completer # The ascending(up) or descending(down) order to sort listings by. NOTE: sort_order only works when combined with one of the search options (keywords, region, etc.). (default: desc)
  --legacy: oneof<nothing, bool> # This parameter is needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shop_section_ids" $shop_section_ids "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_on" $sort_on "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shop-sections/listings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new ShippingProfile. You can pass a country iso code or a region when creating a ShippingProfile, but not both. Only one is required. You must pass either a shipping_carrier_id AND mail_class, or both min and max_delivery_days.
#
# POST /v3/application/shops/{shop_id}/shipping-profiles
# operationId: createShopShippingProfile
export def "application-shops-shipping-profiles createShopShippingProfile" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The name string of this shipping profile.
  origin_country_iso: string # The ISO code of the country from which the listing ships. (format: ISO 3166-1 alpha-2)
  primary_cost: float # The cost of shipping to this country/region alone, measured in the store's default currency. (format: float)
  secondary_cost: float # The cost of shipping to this country/region with another item, measured in the store's default currency. (format: float)
  --min-processing-time: int # The minimum time required to process to ship listings with this shipping profile. (format: int64)
  --max-processing-time: int # The maximum processing time the listing needs to ship. (format: int64)
  --processing-time-unit: string@processing-time-unit-completer-1 # The unit used to represent how long a processing time is. A week is equivalent to the set processing schedule (default to 5 business days). If none is provided, the unit is set to "business_days". (default: business_days)
  --destination-country-iso: string # The ISO code of the country to which the listing ships. If null, request sets destination to destination_region. Required if destination_region is null or not provided. (format: ISO 3166-1 alpha-2)
  --destination-region: string@destination-region-completer # The code of the region to which the listing ships. A region represents a set of countries. Supported regions are Europe Union and Non-Europe Union (countries in Europe not in EU). If `none`, request sets destination to destination_country_iso. Required if destination_country_iso is null or not provided. (default: none)
  --origin-postal-code: string # The postal code string (not necessarily a number) for the location from which the listing ships. Required if the `origin_country_iso` supports postal codes. See the [Fulfillment Tutorial docs](https://developer.etsy.com/documentation/tutorials/fulfillment/#countries-requiring-postal-codes) for more info (default: )
  --shipping-carrier-id: int # The unique ID of a supported shipping carrier, which is used to calculate an Estimated Delivery Date. **Required with `mail_class`** if `min_delivery_days` and `max_delivery_days` are null. (format: int64, default: 0)
  --mail-class: string # The unique ID string of a shipping carrier's mail class, which is used to calculate an estimated delivery date. **Required with `shipping_carrier_id`** if `min_delivery_days` and `max_delivery_days` are null.
  --min-delivery-days: int # The minimum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `max_delivery_days`** if `mail_class` is null. (format: int64)
  --max-delivery-days: int # The maximum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `min_delivery_days`** if `mail_class` is null. (format: int64)
]: any -> record<shipping_profile_id: int, title: string, user_id: int, origin_country_iso: string, is_deleted: bool, shipping_profile_destinations: list<any>, shipping_profile_upgrades: list<any>, origin_postal_code: string, profile_type: string, domestic_handling_fee: float, international_handling_fee: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles")
  let body = {title: $title, origin_country_iso: $origin_country_iso, primary_cost: $primary_cost, secondary_cost: $secondary_cost, min_processing_time: $min_processing_time, max_processing_time: $max_processing_time, processing_time_unit: $processing_time_unit, destination_country_iso: $destination_country_iso, destination_region: $destination_region, origin_postal_code: $origin_postal_code, shipping_carrier_id: $shipping_carrier_id, mail_class: $mail_class, min_delivery_days: $min_delivery_days, max_delivery_days: $max_delivery_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of shipping profiles available in the specific Etsy shop identified by its shop ID.
#
# GET /v3/application/shops/{shop_id}/shipping-profiles
# operationId: getShopShippingProfiles
export def "application-shops-shipping-profiles list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: table<shipping_profile_id: int, title: string, user_id: int, origin_country_iso: string, is_deleted: bool, shipping_profile_destinations: list, shipping_profile_upgrades: list, origin_postal_code: string, profile_type: string, domestic_handling_fee: float, international_handling_fee: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a ShippingProfile by given id.
#
# DELETE /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}
# operationId: deleteShopShippingProfile
export def "application-shops-shipping-profiles delete" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a Shipping Profile referenced by shipping profile ID.
#
# GET /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}
# operationId: getShopShippingProfile
export def "application-shops-shipping-profiles get" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<shipping_profile_id: int, title: string, user_id: int, origin_country_iso: string, is_deleted: bool, shipping_profile_destinations: list<any>, shipping_profile_upgrades: list<any>, origin_postal_code: string, profile_type: string, domestic_handling_fee: float, international_handling_fee: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Changes the settings in a shipping profile. You can pass a country iso code or a region when updating a ShippingProfile, but not both. Only one is required. You must pass either a shipping_carrier_id AND mail_class, or both min and max_delivery_days.
#
# PUT /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}
# operationId: updateShopShippingProfile
export def "application-shops-shipping-profiles updateShopShippingProfile" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The name string of this shipping profile.
  --origin-country-iso: string # The ISO code of the country from which the listing ships. (format: ISO 3166-1 alpha-2)
  --min-processing-time: int # The minimum time required to process to ship listings with this shipping profile. (format: int64)
  --max-processing-time: int # The maximum processing time the listing needs to ship. (format: int64)
  --processing-time-unit: string@processing-time-unit-completer-1 # The unit used to represent how long a processing time is. A week is equivalent to the set processing schedule (default to 5 business days). If none is provided, the unit is set to "business_days". (default: business_days)
  --origin-postal-code: string # The postal code string (not necessarily a number) for the location from which the listing ships. Required if the `origin_country_iso` supports postal codes. See the [Fulfillment Tutorial docs](https://developer.etsy.com/documentation/tutorials/fulfillment/#countries-requiring-postal-codes) for more info
]: any -> record<shipping_profile_id: int, title: string, user_id: int, origin_country_iso: string, is_deleted: bool, shipping_profile_destinations: list<any>, shipping_profile_upgrades: list<any>, origin_postal_code: string, profile_type: string, domestic_handling_fee: float, international_handling_fee: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)")
  let body = {title: $title, origin_country_iso: $origin_country_iso, min_processing_time: $min_processing_time, max_processing_time: $max_processing_time, processing_time_unit: $processing_time_unit, origin_postal_code: $origin_postal_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new shipping destination, which sets the shipping cost, carrier, and class for a destination in a [shipping profile](/documentation/reference/#tag/Shop-ShippingProfile). createShopShippingProfileDestination assigns costs using the currency of the associated shop. Set the destination using either `destination_country_iso` or `destination_region`; `destination_country_iso` and `destination_region` are mutually exclusive — set one or the other. Setting both triggers error 400. If the request sets neither `destination_country_iso` nor `destination_region`, the default destination is "everywhere". You must also either assign both a `shipping_carrier_id` AND `mail_class` or both `min_delivery_days` AND `max_delivery_days`.
#
# POST /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/destinations
# operationId: createShopShippingProfileDestination
export def "application-shops-shipping-profiles-destinations createShopShippingProfileDestination" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  primary_cost: float # The cost of shipping to this country/region alone, measured in the store's default currency. (format: float)
  secondary_cost: float # The cost of shipping to this country/region with another item, measured in the store's default currency. (format: float)
  --destination-country-iso: string # The ISO code of the country to which the listing ships. If null, request sets destination to destination_region. Required if destination_region is null or not provided. (format: ISO 3166-1 alpha-2)
  --destination-region: string@destination-region-completer # The code of the region to which the listing ships. A region represents a set of countries. Supported regions are Europe Union and Non-Europe Union (countries in Europe not in EU). If `none`, request sets destination to destination_country_iso. Required if destination_country_iso is null or not provided. (default: none)
  --shipping-carrier-id: int # The unique ID of a supported shipping carrier, which is used to calculate an Estimated Delivery Date. **Required with `mail_class`** if `min_delivery_days` and `max_delivery_days` are null. (format: int64, default: 0)
  --mail-class: string # The unique ID string of a shipping carrier's mail class, which is used to calculate an estimated delivery date. **Required with `shipping_carrier_id`** if `min_delivery_days` and `max_delivery_days` are null.
  --min-delivery-days: int # The minimum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `max_delivery_days`** if `mail_class` is null. (format: int64)
  --max-delivery-days: int # The maximum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `min_delivery_days`** if `mail_class` is null. (format: int64)
]: any -> record<shipping_profile_destination_id: int, shipping_profile_id: int, origin_country_iso: string, destination_country_iso: string, destination_region: string, primary_cost: any, secondary_cost: any, shipping_carrier_id: int, mail_class: string, min_delivery_days: int, max_delivery_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/destinations")
  let body = {primary_cost: $primary_cost, secondary_cost: $secondary_cost, destination_country_iso: $destination_country_iso, destination_region: $destination_region, shipping_carrier_id: $shipping_carrier_id, mail_class: $mail_class, min_delivery_days: $min_delivery_days, max_delivery_days: $max_delivery_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a list of shipping destination objects associated with a shipping profile.
#
# GET /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/destinations
# operationId: getShopShippingProfileDestinationsByShippingProfile
export def "application-shops-shipping-profiles-destinations get" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/destinations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a shipping destination and removes the destination option from every listing that uses the associated shipping profile. A shipping profile requires at least one shipping destination, so this endpoint cannot delete the final shipping destination for any shipping profile. To delete the final shipping destination from a shipping profile, you must [delete the entire shipping profile](/documentation/reference/#operation/deleteShopShippingProfile).
#
# DELETE /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/destinations/{shipping_profile_destination_id}
# operationId: deleteShopShippingProfileDestination
export def "application-shops-shipping-profiles-destinations delete" [
  shop_id: int
  shipping_profile_id: int
  shipping_profile_destination_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/destinations/($shipping_profile_destination_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates an existing shipping destination, which can set or reassign the shipping cost, carrier, and class for a destination.
#
# PUT /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/destinations/{shipping_profile_destination_id}
# operationId: updateShopShippingProfileDestination
export def "application-shops-shipping-profiles-destinations updateShopShippingProfileDestination" [
  shop_id: int
  shipping_profile_id: int
  shipping_profile_destination_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --primary-cost: float # The cost of shipping to this country/region alone, measured in the store's default currency. (format: float)
  --secondary-cost: float # The cost of shipping to this country/region with another item, measured in the store's default currency. (format: float)
  --destination-country-iso: string # The ISO code of the country to which the listing ships. If null, request sets destination to destination_region. Required if destination_region is null or not provided. (format: ISO 3166-1 alpha-2)
  --destination-region: string@destination-region-completer # The code of the region to which the listing ships. A region represents a set of countries. Supported regions are Europe Union and Non-Europe Union (countries in Europe not in EU). If `none`, request sets destination to destination_country_iso. Required if destination_country_iso is null or not provided. (default: none)
  --shipping-carrier-id: int # The unique ID of a supported shipping carrier, which is used to calculate an Estimated Delivery Date. **Required with `mail_class`** if `min_delivery_days` and `max_delivery_days` are null. (format: int64)
  --mail-class: string # The unique ID string of a shipping carrier's mail class, which is used to calculate an estimated delivery date. **Required with `shipping_carrier_id`** if `min_delivery_days` and `max_delivery_days` are null.
  --min-delivery-days: int # The minimum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `max_delivery_days`** if `mail_class` is null. (format: int64)
  --max-delivery-days: int # The maximum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `min_delivery_days`** if `mail_class` is null. (format: int64)
]: any -> record<shipping_profile_destination_id: int, shipping_profile_id: int, origin_country_iso: string, destination_country_iso: string, destination_region: string, primary_cost: any, secondary_cost: any, shipping_carrier_id: int, mail_class: string, min_delivery_days: int, max_delivery_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/destinations/($shipping_profile_destination_id)")
  let body = {primary_cost: $primary_cost, secondary_cost: $secondary_cost, destination_country_iso: $destination_country_iso, destination_region: $destination_region, shipping_carrier_id: $shipping_carrier_id, mail_class: $mail_class, min_delivery_days: $min_delivery_days, max_delivery_days: $max_delivery_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Creates a new shipping profile upgrade, which can establish a price for a shipping option, such as an alternate carrier or faster delivery.
#
# POST /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/upgrades
# operationId: createShopShippingProfileUpgrade
export def "application-shops-shipping-profiles-upgrades createShopShippingProfileUpgrade" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  type: int@type-completer-1 # The type of the shipping upgrade. Domestic (0) or international (1). (format: int64)
  upgrade_name: string # Name for the shipping upgrade shown to shoppers at checkout, e.g. USPS Priority.
  price: float # Additional cost of adding the shipping upgrade. (format: float)
  secondary_price: float # Additional cost of adding the shipping upgrade for each additional item. (format: float)
  --shipping-carrier-id: int # The unique ID of a supported shipping carrier, which is used to calculate an Estimated Delivery Date. **Required with `mail_class`** if `min_delivery_days` and `max_delivery_days` are null. (format: int64, default: 0)
  --mail-class: string # The unique ID string of a shipping carrier's mail class, which is used to calculate an estimated delivery date. **Required with `shipping_carrier_id`** if `min_delivery_days` and `max_delivery_days` are null.
  --min-delivery-days: int # The minimum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `max_delivery_days`** if `mail_class` is null. (format: int64)
  --max-delivery-days: int # The maximum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `min_delivery_days`** if `mail_class` is null. (format: int64)
]: any -> record<shipping_profile_id: int, upgrade_id: int, upgrade_name: string, type: int, rank: int, language: string, price: any, secondary_price: any, shipping_carrier_id: int, mail_class: string, min_delivery_days: int, max_delivery_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/upgrades")
  let body = {type: $type, upgrade_name: $upgrade_name, price: $price, secondary_price: $secondary_price, shipping_carrier_id: $shipping_carrier_id, mail_class: $mail_class, min_delivery_days: $min_delivery_days, max_delivery_days: $max_delivery_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the list of shipping profile upgrades assigned to a specific shipping profile.
#
# GET /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/upgrades
# operationId: getShopShippingProfileUpgrades
export def "application-shops-shipping-profiles-upgrades get" [
  shop_id: int
  shipping_profile_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/upgrades")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Deletes a shipping profile upgrade and removes the upgrade option from every listing that uses the associated shipping profile.
#
# DELETE /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/upgrades/{upgrade_id}
# operationId: deleteShopShippingProfileUpgrade
export def "application-shops-shipping-profiles-upgrades delete" [
  shop_id: int
  shipping_profile_id: int
  upgrade_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/upgrades/($upgrade_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Updates a shipping profile upgrade and updates any listings that use the shipping profile.
#
# PUT /v3/application/shops/{shop_id}/shipping-profiles/{shipping_profile_id}/upgrades/{upgrade_id}
# operationId: updateShopShippingProfileUpgrade
export def "application-shops-shipping-profiles-upgrades updateShopShippingProfileUpgrade" [
  shop_id: int
  shipping_profile_id: int
  upgrade_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upgrade-name: string # Name for the shipping upgrade shown to shoppers at checkout, e.g. USPS Priority.
  --type: int@type-completer-1 # The type of the shipping upgrade. Domestic (0) or international (1). (format: int64)
  --price: float # Additional cost of adding the shipping upgrade. (format: float)
  --secondary-price: float # Additional cost of adding the shipping upgrade for each additional item. (format: float)
  --shipping-carrier-id: int # The unique ID of a supported shipping carrier, which is used to calculate an Estimated Delivery Date. **Required with `mail_class`** if `min_delivery_days` and `max_delivery_days` are null. (format: int64)
  --mail-class: string # The unique ID string of a shipping carrier's mail class, which is used to calculate an estimated delivery date. **Required with `shipping_carrier_id`** if `min_delivery_days` and `max_delivery_days` are null.
  --min-delivery-days: int # The minimum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `max_delivery_days`** if `mail_class` is null. (format: int64)
  --max-delivery-days: int # The maximum number of business days a buyer can expect to wait to receive their purchased item once it has shipped. **Required with `min_delivery_days`** if `mail_class` is null. (format: int64)
]: any -> record<shipping_profile_id: int, upgrade_id: int, upgrade_name: string, type: int, rank: int, language: string, price: any, secondary_price: any, shipping_carrier_id: int, mail_class: string, min_delivery_days: int, max_delivery_days: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/shipping-profiles/($shipping_profile_id)/upgrades/($upgrade_id)")
  let body = {upgrade_name: $upgrade_name, type: $type, price: $price, secondary_price: $secondary_price, shipping_carrier_id: $shipping_carrier_id, mail_class: $mail_class, min_delivery_days: $min_delivery_days, max_delivery_days: $max_delivery_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Check the scopes of the provided token
#
# POST /v3/application/scopes
# operationId: tokenScopes
export def "application-scopes tokenScopes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/scopes")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a transaction by transaction ID.
#
# GET /v3/application/shops/{shop_id}/transactions/{transaction_id}
# operationId: getShopReceiptTransaction
export def "application-shops-transactions get" [
  shop_id: int
  transaction_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transaction_id: int, title: string, description: string, seller_user_id: int, buyer_user_id: int, create_timestamp: int, created_timestamp: int, paid_timestamp: int, shipped_timestamp: int, quantity: int, listing_image_id: int, receipt_id: int, is_digital: bool, file_data: string, listing_id: int, transaction_type: string, product_id: int, sku: string, price: any, shipping_cost: any, variations: list<any>, product_data: list<any>, shipping_profile_id: int, min_processing_days: int, max_processing_days: int, shipping_method: string, shipping_upgrade: string, expected_ship_date: int, buyer_coupon: float, shop_coupon: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/transactions/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves the list of transactions associated with a shop.
#
# GET /v3/application/shops/{shop_id}/transactions
# operationId: getShopReceiptTransactionsByShop
export def "application-shops-transactions list" [
  shop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
  --legacy: oneof<nothing, bool> # This parameter needed to enable new parameters and response values related to processing profiles.
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "legacy" $legacy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/application/shops/($shop_id)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to delete a UserAddress for a User.
#
# DELETE /v3/application/user/addresses/{user_address_id}
# operationId: deleteUserAddress
export def "application-user-addresses delete" [
  user_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/user/addresses/($user_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to retrieve a UserAddress for a User.
#
# GET /v3/application/user/addresses/{user_address_id}
# operationId: getUserAddress
export def "application-user-addresses get" [
  user_address_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_address_id: int, user_id: int, name: string, first_line: string, second_line: string, city: string, state: string, zip: string, iso_country_code: string, country_name: string, is_default_shipping_address: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/user/addresses/($user_address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Open API V3 endpoint to retrieve UserAddresses for a User.
#
# GET /v3/application/user/addresses
# operationId: getUserAddresses
export def "application-user-addresses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of results to return. (format: int64, default: 25)
  --offset: int # The number of records to skip before selecting the first result. (format: int64, default: 0)
]: nothing -> record<count: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/application/user/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Retrieves a user profile based on a unique user ID.                 Access is limited to profiles of the authenticated user                 or linked buyers. For the primary_email field, specific                 app-based permissions are required and granted case-by-case.
#
# GET /v3/application/users/{user_id}
# operationId: getUser
export def "application-users get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: int, primary_email: string, first_name: string, last_name: string, image_url_75x75: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/application/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><span class="wt-badge wt-badge--notificationPrimary wt-bg-slime-tint wt-mr-xs-2">General Release</span><a class="wt-text-link" href="https://github.com/etsy/open-api/discussions" target="_blank" rel="noopener noreferrer">Report bug</a></div><div class="wt-display-flex-xs wt-align-items-center wt-mt-xs-2 wt-mb-xs-3"><p class="wt-text-body-01 banner-text">This endpoint is ready for production use.</p></div>  Returns basic info for the user making the request.
#
# GET /v3/application/users/me
# operationId: getMe
export def "application-users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user_id: int, shop_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
