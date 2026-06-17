# Auto-generated client for Promotions & Taxes API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Promotions-/1.0/openapi.json
# Auth: --token flag or $env.PROMOTIONS_TAXES_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROMOTIONS_TAXES_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "http://example.com/.exampleParameterValue.com.br/api/rnb" "https://rnb.vtexcommercestable.com.br/api/pricing/pvt" "https://rnb.exampleParameterValue.com.br/api/pricing/pvt" "http://example.com/.vtexcommercestable.com.br/api/rnb" "http://example.com/.{environment}.com.br/api/rnb" "https://rnb.{environment}.com.br/api/pricing/pvt"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["Promotion" "Tax"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rnb-pub-notifications post" } } | get name | first)
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

# Usage notification
#
# POST /api/rnb/pub/notifications
# operationId: Usagenotification
export def "rnb-pub-notifications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  account_id: string
  calculator_ids: list
  coupon: string
  items_count: int # format: int32
  order_id: string
  profile_id: string
  --used: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br/api/rnb")
  let full_url = (build-url $base "/api/rnb/pub/notifications")
  let body = {"accountId": $account_id, "calculatorIds": $calculator_ids, "coupon": $coupon, "itemsCount": $items_count, "orderId": $order_id, "profileId": $profile_id, "used": $used} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Archived Promotions
#
# GET /api/rnb/pvt/archive/benefits/calculatorConfiguration
# operationId: GetArchivedPromotions
export def "rnb-pvt-archive-benefits-calculator-configuration get-archived-promotions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/benefits/calculatorConfiguration")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive Promotion or Tax
#
# POST /api/rnb/pvt/archive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: ArchivePromotion
export def "rnb-pvt-archive-calculator-configuration archive-promotion" [
  id_calculator_configuration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_calculator_configuration: $id_calculator_configuration} | format pattern "/api/rnb/pvt/archive/calculatorConfiguration/{id_calculator_configuration}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get archived coupon by coupon code
#
# GET /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Getarchivedbycouponcode
export def "rnb-pvt-archive-coupon get-archivedbycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: $coupon_code} | format pattern "/api/rnb/pvt/archive/coupon/{coupon_code}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Archive coupon by coupon code
#
# POST /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Archivebycouponcode
export def "rnb-pvt-archive-coupon archive-bycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: $coupon_code} | format pattern "/api/rnb/pvt/archive/coupon/{coupon_code}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Archived Taxes
#
# GET /api/rnb/pvt/archive/taxes/calculatorConfiguration
# operationId: GetArchivedTaxes
export def "rnb-pvt-archive-taxes-calculator-configuration get-archived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/taxes/calculatorConfiguration")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Promotions
#
# GET /api/rnb/pvt/benefits/calculatorconfiguration
# operationId: GetAllBenefits
export def "rnb-pvt-benefits-calculatorconfiguration get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<archivedItems: list<string>, disabledItems: list<any>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>, limitConfigurationMaxPrice: record<activesCount: int, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/benefits/calculatorconfiguration")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Promotion or Tax
#
# POST /api/rnb/pvt/calculatorconfiguration
# operationId: CreateOrUpdateCalculatorConfiguration
# --affiliates item shape: {id?: string, name?: string}
# --brands item shape: {id?: string, name?: string}
# --categories item shape: {id?: string, name?: string}
# --collections item shape: {id?: string, name?: string}
# --paymentsMethods item shape: {id?: string, name?: string}
# --products item shape: {id?: string, name?: string}
# --skus item shape: {id?: string, name?: string}
# --skusGift shape: {gifts?: list, quantitySelectable?: int}
# --zipCodeRanges item shape: {inclusive?: bool}
@deprecated --flag card-issuers
@deprecated --flag collections2-buy-together
@deprecated --flag coupon
@deprecated --flag disable-deal
@deprecated --flag installment
@deprecated --flag max-prices-per-items
@deprecated --flag merchants
@deprecated --flag payments-rules
@deprecated --flag products-specifications
@deprecated --flag stores
@deprecated --flag stores-are-inclusive
@deprecated --flag total-value-include-all-items
export def "rnb-pvt-calculatorconfiguration create-or-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --absolute-shipping-discount-value: float # Maximum shipping value. (e.g. 0)
  --accumulate-with-manual-price: oneof<nothing, bool> # Allows the promotion to apply to products whose prices have been manually added by a call-center operator. (e.g. false)
  --activate-gifts-multiplier: oneof<nothing, bool> # If set as `true`, it activates gifts Multiplier. (e.g. false)
  --active-days-of-week: list # Defines which days of the week the Promotion or Tax will applied.
  --affiliates: list # Marketplace order identifier. The discount will apply to selected affiliates. — item shape: {id?: string, name?: string}
  --apply-to-all-shippings: oneof<nothing, bool> # Promotion or Tax will be applied to all kind of shipping. (e.g. false)
  --are-sales-channel-ids-exclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any trade policies present on the `idsSalesChannel` field. If set to `true`, trade policies present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --begin-date-utc: string # Promotion or Tax Begin Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --brands: list # Object composed by the brands that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --brands-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any brand present on the `brands` field. If set to `false`, brands present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --campaigns: list # Campaign Audiences that activate this Promotion or Tax. (e.g. [Campaign Audience test])
  --card-issuers: list # DEPRECATED
  --categories: list # Object composed by the categories that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --categories-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any category present on the `categories` field. If set to `false`, categories present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --cluster-expressions: list # An expression to use with clusters.
  --collections: list # Object composed by the collections that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --collections1-buy-together: list # Collections that will generate the Promotion, type **Buy Together**, **More for less**, **Progressive Discount**, **Buy One Get One**.
  --collections2-buy-together: list # DEPRECATED
  --collections-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any collection present on the `collections` field. If set to `false`, collections present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --compare-list-price-and-price: oneof<nothing, bool> # If the **List Price** and **Price** are the same. (e.g. false)
  --conditions-ids: list # Array with conditions IDs.
  --coupon: list # DEPRECATED
  --cumulative: oneof<nothing, bool> # Defines if a Promotion or Tax can accumulate with another one. (`true`) or not (`false`). (e.g. false)
  --days-ago-of-purchases: int # Number of days that are considered to add the purchase history. (e.g. 0)
  --description: string # Internal description of the Promotion or Tax. (e.g. Description of the promotion.)
  --disable-deal: oneof<nothing, bool> # DEPRECATED
  --discount-type: string # The type of discount that will apply to the promotion. (e.g. percentual)
  --enable-buy-together-per-sku: oneof<nothing, bool> # Enable **Buy Together** per SKU. (e.g. false)
  --end-date-utc: string # Promotion or Tax End Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --first-buy-is-profile-optimistic: oneof<nothing, bool> # Applies the discount even if the user is not logged. (e.g. false)
  --gift-list-types: list # Gifts List Type.
  --id-calculator-configuration: string # Promotion ID or Tax ID. (e.g. ba087fa9-8587-44b3-8ef1-ade8d053e9e9)
  --id-seller: string # Seller Name. (e.g. 1)
  --id-seller-is-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any seller present on the `idSeller` field. If set to `false`, sellers present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --ids-sales-channel: list # List of Trade Policies that activate this Promotion or Tax.
  --installment: int # DEPRECATED
  --is-active: oneof<nothing, bool> # If set as `true` the Promotion or Tax is activated. If set as `false` the Promotion or Tax is deactivated. (e.g. true)
  --is-archived: oneof<nothing, bool> # If set as `true` the Promotion or Tax is archived. If set as `false` the Promotion or Tax is not archived. (e.g. false)
  --is-different-list-price-and-price: oneof<nothing, bool> # Applies the Promotion or Tax only if the list price and price is different. (e.g. false)
  --is-featured: oneof<nothing, bool> # Insert a flag with the promotion name used in the product's window display and page. (e.g. true)
  --is-first-buy: oneof<nothing, bool> # Applies the discount only if it's a first buy. (e.g. false)
  --is-min-max-installments: oneof<nothing, bool> # Set if the Promotion or Tax will be applied considering a minimum and maximum values for installments. (e.g. false)
  --is-sla-selected: oneof<nothing, bool> # Applies selected discount only when one of the defined shipping method is selected by the customer. (e.g. false)
  --item-max-price: float # Maximum price of the item. (e.g. 0)
  --item-min-price: float # Minimum price of the item. (e.g. 0)
  --last-modified: string # Date when the Promotion or Tax was last modified. (e.g. 2021-02-23T20:58:38.7963862Z)
  --list-sku1-buy-together: list # SKU first list for the promotion **Buy Together**. (e.g. [SKU])
  --list-sku2-buy-together: list # SKU second list for the promotion **Buy Together**. (e.g. [SKU])
  --marketing-tags: list # Promotion or Tax Marketing tags.
  --marketing-tags-are-not-inclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any marketing tag present on the `marketingTags` field. If set to `true`, marketing tags present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --max-installment: int # Maximum value for installment. (e.g. 0)
  --max-number-of-affected-items: int # The maximum number of affected items for a promotion. (e.g. 0)
  --max-number-of-affected-items-group-key: string # The maximum number of affected items by group key for a promotion. (e.g. perCart)
  --max-prices-per-items: list # DEPRECATED
  --max-usage: int # Defines how many times the Promotion or Tax can be used. (e.g. 0)
  --max-usage-per-client: int # Defines if the promotion can be used multiple times per client. (e.g. 0)
  --maximum-unit-price-discount: float # The maximum price for each item of the purchase will be the price set up. (e.g. 0)
  --merchants: list # DEPRECATED
  --min-installment: int # Minimum value for installment. (e.g. 0)
  --minimum-quantity-buy-together: int # Minimum quantity for **Buy Together** promotion. (e.g. 0)
  --multiple-use-per-client: oneof<nothing, bool> # Defines if the promotion can be used multiple times per client. (e.g. false)
  --name: string # Promotion name or Tax name. (e.g. Promoção Social Seller)
  --new-offset: float # New time offset from UTC in seconds. (e.g. -3)
  --nominal-discount-value: float # Exact discount to be applied for the total purchase value. (e.g. 0)
  --nominal-reward-value: float # Nominal value for rewards program. (e.g. 0)
  --nominal-shipping-discount-value: float # Exact discount to be applied for the shipping value. (e.g. 0)
  --nominal-tax: float # Nominal Tax. (e.g. 0)
  --offset: int # Time offset from UTC in seconds. (e.g. -3)
  --order-status-reward-value: string # Order status reward value. (e.g. invoiced)
  --origin: string # Origin of the Promotion or Tax, `marketplace` or `Fulfillment`.  Read [Difference between orders with marketplace and fulfillment sources](https://help.vtex.com/en/tutorial/what-are-orders-with-marketplace-source-and-orders-with-fulfillment-source--6eVYrmUAwMOeKICU2KuG06) for more information. (e.g. marketplace)
  --payments-methods: list # Array composed by all the Payments Methods that activate this Promotion or Tax. — item shape: {id?: string, name?: string}
  --payments-rules: list # DEPRECATED
  --percentual-discount-value: float # Percentage discount to be applied for total purchase value. (e.g. 10)
  --percentual-discount-value-list: list # Percentual discount value list.
  --percentual-discount-value-list1: float # Valid discounts for the SKUs in `listSku1BuyTogether`, discount list used for Buy Together Promotions. (e.g. 0)
  --percentual-discount-value-list2: float # Equivalent to `percentualDiscountValueList1`. (e.g. 0)
  --percentual-reward-value: float # Percentage value for rewards program. (e.g. 0)
  --percentual-shipping-discount-value: float # Percentage discount to be applied for shipping value. (e.g. 0)
  --percentual-tax: float # Percentual Tax over purchase total value. (e.g. 0)
  --products: list # Object composed by the products that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --products-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any product present on the `products` field. If set to `false`, products present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --products-specifications: list # DEPRECATED
  --quantity-to-affect-buy-together: int # Quantity to affect **Buy Together** promotion. (e.g. 0)
  --rebate-percentual-discount-value: float # Percentual Shipping Discount Value. (e.g. 0)
  --restrictions-bins: list # The discount will be granted if the card's BIN is given.
  --shipping-percentual-tax: float # Shipping Percentual Tax over purchase total value. (e.g. 0)
  --should-distribute-discount-among-matched-items: oneof<nothing, bool> # Should distribute discount among matched items. (e.g. false)
  --skus: list # Object composed by the SKUs that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --skus-are-inclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any SKU present on the `skus` field. If set to `false`, SKUs present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --skus-gift: record # SKU Gift Object. Total discount on the product value set as a gift. — shape: {gifts?: list, quantitySelectable?: int}
  --slas-ids: list # The discount will be granted if the shipping method is the same as the one given.
  --stores: list # DEPRECATED
  --stores-are-inclusive: oneof<nothing, bool> # DEPRECATED
  --total-value-celing: float # Maximum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-floor: float # Minimum chart value to activate the Promotion or Tax. (e.g. 0)
  --total-value-include-all-items: oneof<nothing, bool> # DEPRECATED
  --total-value-mode: string # Defines if products that already are receiving a promotion will be considered on the chart total value. There are three options available: `IncludeMatchedItems`, `ExcludeMatchedItems`, `AllItems`. (e.g. IncludeMatchedItems)
  --total-value-purchase: float # Total value a client must have in past orders to activate the Promotion or Tax. (e.g. 0)
  --type: string # Defines what is the type of the promotion or indicates if it is a tax. Possible values: `regular` ([Regular Promotion](https://help.vtex.com/tutorial/regular-promotion--tutorials_327)), `combo` ([Buy Together](https://help.vtex.com/en/tutorial/buy-together--tutorials_323)), `forThePriceOf` ([More for Less](https://help.vtex.com/en/tutorial/creating-a-more-for-less-promotion--tutorials_325)), `progressive` ([Progressive Discount](https://help.vtex.com/en/tutorial/progressive-discount--tutorials_324)), `buyAndWin` ([Buy One Get One](https://help.vtex.com/en/tutorial/buy-one-get-one--tutorials_322)), `maxPricePerItem` (Deprecated), `campaign` ([Campaign Promotion](https://help.vtex.com/en/tutorial/campaign-promotion--1ChYXhK2AQGuS6wAqS8Ume)), `tax` (Tax), `multipleEffects` (Multiple Effects). (e.g. regular)
  --use-new-progressive-algorithm: oneof<nothing, bool> # Use new progressive algorithm. (e.g. false)
  --utm-campaign: string # Coupon utmCampaign code. (e.g. testSource)
  --utm-source: string # Coupon utmSource code. (e.g. testSource)
  --zip-code-ranges: list # Range of the zip code that applies the promotion. — item shape: {inclusive?: bool}
]: any -> record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/calculatorconfiguration")
  let body = {"absoluteShippingDiscountValue": $absolute_shipping_discount_value, "accumulateWithManualPrice": $accumulate_with_manual_price, "activateGiftsMultiplier": $activate_gifts_multiplier, "activeDaysOfWeek": $active_days_of_week, "affiliates": $affiliates, "applyToAllShippings": $apply_to_all_shippings, "areSalesChannelIdsExclusive": $are_sales_channel_ids_exclusive, "beginDateUtc": $begin_date_utc, "brands": $brands, "brandsAreInclusive": $brands_are_inclusive, "campaigns": $campaigns, "cardIssuers": $card_issuers, "categories": $categories, "categoriesAreInclusive": $categories_are_inclusive, "clusterExpressions": $cluster_expressions, "collections": $collections, "collections1BuyTogether": $collections1_buy_together, "collections2BuyTogether": $collections2_buy_together, "collectionsIsInclusive": $collections_is_inclusive, "compareListPriceAndPrice": $compare_list_price_and_price, "conditionsIds": $conditions_ids, "coupon": $coupon, "cumulative": $cumulative, "daysAgoOfPurchases": $days_ago_of_purchases, "description": $description, "disableDeal": $disable_deal, "discountType": $discount_type, "enableBuyTogetherPerSku": $enable_buy_together_per_sku, "endDateUtc": $end_date_utc, "firstBuyIsProfileOptimistic": $first_buy_is_profile_optimistic, "giftListTypes": $gift_list_types, "idCalculatorConfiguration": $id_calculator_configuration, "idSeller": $id_seller, "idSellerIsInclusive": $id_seller_is_inclusive, "idsSalesChannel": $ids_sales_channel, "installment": $installment, "isActive": $is_active, "isArchived": $is_archived, "isDifferentListPriceAndPrice": $is_different_list_price_and_price, "isFeatured": $is_featured, "isFirstBuy": $is_first_buy, "isMinMaxInstallments": $is_min_max_installments, "isSlaSelected": $is_sla_selected, "itemMaxPrice": $item_max_price, "itemMinPrice": $item_min_price, "lastModified": $last_modified, "listSku1BuyTogether": $list_sku1_buy_together, "listSku2BuyTogether": $list_sku2_buy_together, "marketingTags": $marketing_tags, "marketingTagsAreNotInclusive": $marketing_tags_are_not_inclusive, "maxInstallment": $max_installment, "maxNumberOfAffectedItems": $max_number_of_affected_items, "maxNumberOfAffectedItemsGroupKey": $max_number_of_affected_items_group_key, "maxPricesPerItems": $max_prices_per_items, "maxUsage": $max_usage, "maxUsagePerClient": $max_usage_per_client, "maximumUnitPriceDiscount": $maximum_unit_price_discount, "merchants": $merchants, "minInstallment": $min_installment, "minimumQuantityBuyTogether": $minimum_quantity_buy_together, "multipleUsePerClient": $multiple_use_per_client, "name": $name, "newOffset": $new_offset, "nominalDiscountValue": $nominal_discount_value, "nominalRewardValue": $nominal_reward_value, "nominalShippingDiscountValue": $nominal_shipping_discount_value, "nominalTax": $nominal_tax, "offset": $offset, "orderStatusRewardValue": $order_status_reward_value, "origin": $origin, "paymentsMethods": $payments_methods, "paymentsRules": $payments_rules, "percentualDiscountValue": $percentual_discount_value, "percentualDiscountValueList": $percentual_discount_value_list, "percentualDiscountValueList1": $percentual_discount_value_list1, "percentualDiscountValueList2": $percentual_discount_value_list2, "percentualRewardValue": $percentual_reward_value, "percentualShippingDiscountValue": $percentual_shipping_discount_value, "percentualTax": $percentual_tax, "products": $products, "productsAreInclusive": $products_are_inclusive, "productsSpecifications": $products_specifications, "quantityToAffectBuyTogether": $quantity_to_affect_buy_together, "rebatePercentualDiscountValue": $rebate_percentual_discount_value, "restrictionsBins": $restrictions_bins, "shippingPercentualTax": $shipping_percentual_tax, "shouldDistributeDiscountAmongMatchedItems": $should_distribute_discount_among_matched_items, "skus": $skus, "skusAreInclusive": $skus_are_inclusive, "skusGift": $skus_gift, "slasIds": $slas_ids, "stores": $stores, "storesAreInclusive": $stores_are_inclusive, "totalValueCeling": $total_value_celing, "totalValueFloor": $total_value_floor, "totalValueIncludeAllItems": $total_value_include_all_items, "totalValueMode": $total_value_mode, "totalValuePurchase": $total_value_purchase, "type": $type, "useNewProgressiveAlgorithm": $use_new_progressive_algorithm, "utmCampaign": $utm_campaign, "utmSource": $utm_source, "zipCodeRanges": $zip_code_ranges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Promotion or Tax by ID
#
# GET /api/rnb/pvt/calculatorconfiguration/{idCalculatorConfiguration}
# operationId: GetCalculatorConfigurationById
export def "rnb-pvt-calculatorconfiguration get" [
  id_calculator_configuration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_calculator_configuration: $id_calculator_configuration} | format pattern "/api/rnb/pvt/calculatorconfiguration/{id_calculator_configuration}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "Promotion")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all campaign audiences
#
# GET /api/rnb/pvt/campaignConfiguration
# operationId: Getcampaignaudiences
export def "rnb-pvt-campaign-configuration get-campaignaudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> table<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create campaign audience
#
# POST /api/rnb/pvt/campaignConfiguration
# operationId: Setcampaignconfiguration
# --lastModified shape: {dateUtc?: string, user?: string}
# --targetConfigurations item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list, clusterOperator?: string, collections?: list, collections1BuyTogether?: list, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, firstBuyIsProfileOptimistic?: bool, giftListTypes?: list, id?: string, idSellerIsInclusive?: bool, idsSalesChannel?: list, installment?: int, isDifferentListPriceAndPrice?: bool, isFirstBuy?: bool, isMinMaxInstallments?: bool, isSlaSelected?: bool, itemMaxPrice?: float, itemMinPrice?: float, listBrand1BuyTogether?: list, listCategory1BuyTogether?: list, listSku1BuyTogether?: list, listSku2BuyTogether?: list, marketingTags?: list, marketingTagsAreNotInclusive?: bool, maxInstallment?: int, maxUsage?: int, maxUsagePerClient?: int, merchants?: list, minInstallment?: int, minimumQuantityBuyTogether?: int, multipleUsePerClient?: bool, name?: string, origin?: string, paymentsMethods?: list, paymentsRules?: list, percentualDiscountValueList?: list, products?: list, productsAreInclusive?: bool, productsSpecifications?: list, quantityToAffectBuyTogether?: int, restrictionsBins?: list, shouldDistributeDiscountAmongMatchedItems?: bool, skus?: list, skusAreInclusive?: bool, slasIds?: list, stores?: list, storesAreInclusive?: bool, totalValueCeling?: float, totalValueFloor?: float, totalValueIncludeAllItems?: bool, totalValueMode?: string, totalValuePurchase?: float, useNewProgressiveAlgorithm?: bool, zipCodeRanges?: list}
export def "rnb-pvt-campaign-configuration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --begin-date-utc: string # Start date of the campaign audience in UTC format. (e.g. 2020-05-01T21:30:00Z)
  --end-date-utc: string # End date of the campaign audience in UTC format. (e.g. 2020-05-02T01:30:00Z)
  --id: string # Campaign audience ID. (e.g. dd270d06-1ed1-47fc-b04e-a2431121b5a4)
  --is-active: oneof<nothing, bool> # Defines if the campaign audience is active (`true`) or not (`false`). (e.g. true)
  --is-and-operator: oneof<nothing, bool> # When `true`, determines that all the `targetConfigurations` need to be valid for the campaign audience to be active. When `false`, determines that if at least one of the `targetConfigurations` is valid, the campaign audience will be active. (e.g. true)
  --is-archived: oneof<nothing, bool> # Defines if the campaign audience is archived (`true`) or not (`false`). (e.g. false)
  --last-modified: record # Object with information about the last update of the campaign audience. — shape: {dateUtc?: string, user?: string}
  --name: string # Campaign audience name. (e.g. Interna)
  --target-configurations: list # Array that contains all target audience that the campaign audience will be valid. — item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list, clusterOperator?: string, collections?: list, collections1BuyTogether?: list, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, firstBuyIsProfileOptimistic?: bool, giftListTypes?: list, id?: string, idSellerIsInclusive?: bool, idsSalesChannel?: list, installment?: int, isDifferentListPriceAndPrice?: bool, isFirstBuy?: bool, isMinMaxInstallments?: bool, isSlaSelected?: bool, itemMaxPrice?: float, itemMinPrice?: float, listBrand1BuyTogether?: list, listCategory1BuyTogether?: list, listSku1BuyTogether?: list, listSku2BuyTogether?: list, marketingTags?: list, marketingTagsAreNotInclusive?: bool, maxInstallment?: int, maxUsage?: int, maxUsagePerClient?: int, merchants?: list, minInstallment?: int, minimumQuantityBuyTogether?: int, multipleUsePerClient?: bool, name?: string, origin?: string, paymentsMethods?: list, paymentsRules?: list, percentualDiscountValueList?: list, products?: list, productsAreInclusive?: bool, productsSpecifications?: list, quantityToAffectBuyTogether?: int, restrictionsBins?: list, shouldDistributeDiscountAmongMatchedItems?: bool, skus?: list, skusAreInclusive?: bool, slasIds?: list, stores?: list, storesAreInclusive?: bool, totalValueCeling?: float, totalValueFloor?: float, totalValueIncludeAllItems?: bool, totalValueMode?: string, totalValuePurchase?: float, useNewProgressiveAlgorithm?: bool, zipCodeRanges?: list}
]: any -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, clusterOperator: string, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration")
  let body = {"beginDateUtc": $begin_date_utc, "endDateUtc": $end_date_utc, "id": $id, "isActive": $is_active, "isAndOperator": $is_and_operator, "isArchived": $is_archived, "lastModified": $last_modified, "name": $name, "targetConfigurations": $target_configurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get campaign audience configuration
#
# GET /api/rnb/pvt/campaignConfiguration/{campaignId}
# operationId: Getcampaignconfiguration
export def "rnb-pvt-campaign-configuration get-campaignconfiguration" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({campaign_id: $campaign_id} | format pattern "/api/rnb/pvt/campaignConfiguration/{campaign_id}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all coupons
#
# GET /api/rnb/pvt/coupon
# operationId: Getall
export def "rnb-pvt-coupon get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update coupon
#
# POST /api/rnb/pvt/coupon
# operationId: Update
export def "rnb-pvt-coupon update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  coupon_code: string # Coupon code. (e.g. test)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  --is-archived: oneof<nothing, bool> # Defines if the coupon is archived (`true`) or not (`false`). (e.g. false)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  utm_campaign: string # UTM campaign code. (e.g. coupon3)
  utm_source: string # UTM source code. (e.g. coupon3)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon")
  let body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "isArchived": $is_archived, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create coupon
#
# POST /api/rnb/pvt/coupon/
export def "rnb-pvt-coupon post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  coupon_code: string # Coupon code. (e.g. summersale10)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  --utm-campaign: string # UTM campaign code. (e.g. summer)
  utm_source: string # UTM source code. (e.g. email)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon/")
  let body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get coupon usage
#
# GET /api/rnb/pvt/coupon/usage/{couponCode}
# operationId: Getusage
export def "rnb-pvt-coupon-usage get" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, hostName: string, profileUsages: record<profileId: record<orderUsage: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: $coupon_code} | format pattern "/api/rnb/pvt/coupon/usage/{coupon_code}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get coupon by coupon code
#
# GET /api/rnb/pvt/coupon/{couponCode}
# operationId: Getbycouponcode
export def "rnb-pvt-coupon get-bycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: $coupon_code} | format pattern "/api/rnb/pvt/coupon/{coupon_code}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Coupon Massive Generation
#
# POST /api/rnb/pvt/coupons
# operationId: MassiveGeneration
export def "rnb-pvt-coupons post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quantity: int # Quantity of coupons to generate (e.g. 10)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  coupon_code: string # Coupon code. (e.g. ctest)
  expiration_interval_per_use: string # Coupon expiration interval per use. (e.g. 00:00:00)
  max_items_per_client: int # Defines if the coupon is archived (`true`) or not (`false`). (e.g. 1)
  utm_campaign: string # UTM campaign code. (e.g. cupom3)
  utm_source: string # UTM source code. (e.g. cupom3)
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rnb/pvt/coupons" $qp)
  let body = {"couponCode": $coupon_code, "expirationIntervalPerUse": $expiration_interval_per_use, "maxItemsPerClient": $max_items_per_client, "utmCampaign": $utm_campaign, "utmSource": $utm_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Multiple SKU Promotion
#
# POST /api/rnb/pvt/import/calculatorConfiguration
export def "rnb-pvt-import-calculator-configuration post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --x-vtex-calculator-name: string # Promotion Name. (e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/import/calculatorConfiguration")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "X-VTEX-calculator-name": $x_vtex_calculator_name, "X-VTEX-cumulative": $x_vtex_cumulative, "X-VTEX-cluster-operator": $x_vtex_cluster_operator, "X-VTEX-cluster-expression": $x_vtex_cluster_expression, "X-VTEX-start-date": $x_vtex_start_date, "X-VTEX-end-date": $x_vtex_end_date, "X-VTEX-accumulate-with-manual-prices": $x_vtex_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/csv" $body
}

# Update Multiple SKU Promotion
#
# PUT /api/rnb/pvt/import/calculatorConfiguration/{promotionId}
export def "rnb-pvt-import-calculator-configuration put" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent. (e.g. text/csv)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --x-vtex-calculator-name: string # Promotion Name. (e.g. Test)
  --x-vtex-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --x-vtex-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --x-vtex-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --x-vtex-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --x-vtex-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --x-vtex-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({promotion_id: $promotion_id} | format pattern "/api/rnb/pvt/import/calculatorConfiguration/{promotion_id}"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "X-VTEX-calculator-name": $x_vtex_calculator_name, "X-VTEX-cumulative": $x_vtex_cumulative, "X-VTEX-cluster-operator": $x_vtex_cluster_operator, "X-VTEX-cluster-expression": $x_vtex_cluster_expression, "X-VTEX-start-date": $x_vtex_start_date, "X-VTEX-end-date": $x_vtex_end_date, "X-VTEX-accumulate-with-manual-prices": $x_vtex_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/csv" $body
}

# Create multiple coupons
#
# POST /api/rnb/pvt/multiple-coupons
export def "rnb-pvt-multiple-coupons post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/multiple-coupons")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get All Taxes
#
# GET /api/rnb/pvt/taxes/calculatorconfiguration
# operationId: GetAllTaxes
export def "rnb-pvt-taxes-calculatorconfiguration get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<archivedItems: list<string>, disabledItems: list<string>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/taxes/calculatorconfiguration")
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive Promotion or Tax
#
# POST /api/rnb/pvt/unarchive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: UnarchivePromotion
export def "rnb-pvt-unarchive-calculator-configuration unarchive-promotion" [
  id_calculator_configuration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id_calculator_configuration: $id_calculator_configuration} | format pattern "/api/rnb/pvt/unarchive/calculatorConfiguration/{id_calculator_configuration}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive coupon by coupon code
#
# POST /api/rnb/pvt/unarchive/coupon/{couponCode}
# operationId: Unarchivebycouponcode
export def "rnb-pvt-unarchive-coupon unarchive-bycouponcode" [
  coupon_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({coupon_code: $coupon_code} | format pattern "/api/rnb/pvt/unarchive/coupon/{coupon_code}"))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Price
#
# POST /price-sheet
# operationId: Saveprice
export def "price-sheet post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all paged prices
#
# GET /price-sheet/all/{page}/{pageSize}
# operationId: Getallpaged
export def "price-sheet-all get-allpaged" [
  page: string
  page_size: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({page: $page, page_size: $page_size} | format pattern "/price-sheet/all/{page}/{page_size}") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Price by context
#
# POST /price-sheet/context
# operationId: Pricebycontext
export def "price-sheet-context post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  id: int # format: int32
  item_id: int # format: int32
  sales_channel: int # format: int32
  seller_id: string
  valid_from: string
  valid_to: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet/context" $qp)
  let body = {"id": $id, "itemId": $item_id, "salesChannel": $sales_channel, "sellerId": $seller_id, "validFrom": $valid_from, "validTo": $valid_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Price by SKU Id
#
# DELETE /price-sheet/{skuId}
# operationId: DeletebyskuId
export def "price-sheet delete-bysku" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: $sku_id} | format pattern "/price-sheet/{sku_id}") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Price by SKU ID
#
# GET /price-sheet/{skuId}
# operationId: PricebyskuId
export def "price-sheet list" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: $sku_id} | format pattern "/price-sheet/{sku_id}") $qp)
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Price by SKU ID and Trade Policy
#
# GET /price-sheet/{skuId}/{tradePolicy}
# operationId: PricebyskuIdandtradePolicy
export def "price-sheet get" [
  sku_id: string
  trade_policy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # e.g. {{accountName}}
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: $sku_id, trade_policy: $trade_policy} | format pattern "/price-sheet/{sku_id}/{trade_policy}") $qp)
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculate discounts and taxes (Bundles)
#
# POST /pub/bundles
# operationId: Calculatediscountsandtaxes(Bundles)
# --items item shape: {id: string, index: int, isGift: bool, logisticsInfos: list, measurementUnit: string, params: list, priceSheet: list, priceTags: list, productSpecifications: list, quantity: int, sellerId: string, unitMultiplier: int}
# --params item shape: {name: string, value: string}
export def "pub-bundles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --is-shopping-cart: oneof<nothing, bool>
  items: list # item shape: {id: string, index: int, isGift: bool, logisticsInfos: list, measurementUnit: string, params: list, priceSheet: list, priceTags: list, productSpecifications: list, quantity: int, sellerId: string, unitMultiplier: int}
  origin: string
  params: list # item shape: {name: string, value: string}
  profile_id: string
  sales_channel: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br/api/rnb")
  let full_url = (build-url $base "/pub/bundles")
  let body = {"isShoppingCart": $is_shopping_cart, "items": $items, "origin": $origin, "params": $params, "profileId": $profile_id, "salesChannel": $sales_channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
