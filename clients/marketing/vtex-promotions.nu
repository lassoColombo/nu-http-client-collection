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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br" "http://example.com/.exampleParameterValue.com.br/api/rnb" "https://rnb.vtexcommercestable.com.br/api/pricing/pvt" "https://rnb.exampleParameterValue.com.br/api/pricing/pvt" "http://example.com/.vtexcommercestable.com.br/api/rnb" "http://example.com/.{environment}.com.br/api/rnb" "https://rnb.{environment}.com.br/api/pricing/pvt"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }

# Completers for enum parameters
def accept-completer [] { ["Promotion" "Tax"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rnb-pub-notifications Usagenotification" } } | get name | first)
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
export def "rnb-pub-notifications Usagenotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  accountId: string
  calculatorIds: list
  coupon: string
  itemsCount: int # format: int32
  orderId: string
  profileId: string
  --used: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br/api/rnb")
  let full_url = (build-url $base "/api/rnb/pub/notifications")
  let body = {accountId: $accountId, calculatorIds: $calculatorIds, coupon: $coupon, itemsCount: $itemsCount, orderId: $orderId, profileId: $profileId, used: $used} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Archived Promotions
#
# GET /api/rnb/pvt/archive/benefits/calculatorConfiguration
# operationId: GetArchivedPromotions
export def "rnb-pvt-archive-benefits-calculator-configuration GetArchivedPromotions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/benefits/calculatorConfiguration")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Promotion or Tax
#
# POST /api/rnb/pvt/archive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: ArchivePromotion
export def "rnb-pvt-archive-calculator-configuration ArchivePromotion" [
  idCalculatorConfiguration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/archive/calculatorConfiguration/($idCalculatorConfiguration)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get archived coupon by coupon code
#
# GET /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Getarchivedbycouponcode
export def "rnb-pvt-archive-coupon Getarchivedbycouponcode" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/archive/coupon/($couponCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive coupon by coupon code
#
# POST /api/rnb/pvt/archive/coupon/{couponCode}
# operationId: Archivebycouponcode
export def "rnb-pvt-archive-coupon Archivebycouponcode" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/archive/coupon/($couponCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Archived Taxes
#
# GET /api/rnb/pvt/archive/taxes/calculatorConfiguration
# operationId: GetArchivedTaxes
export def "rnb-pvt-archive-taxes-calculator-configuration GetArchivedTaxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/archive/taxes/calculatorConfiguration")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Promotions
#
# GET /api/rnb/pvt/benefits/calculatorconfiguration
# operationId: GetAllBenefits
export def "rnb-pvt-benefits-calculatorconfiguration GetAllBenefits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<archivedItems: list<string>, disabledItems: list<any>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>, limitConfigurationMaxPrice: record<activesCount: int, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/benefits/calculatorconfiguration")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
@deprecated --flag cardIssuers
@deprecated --flag collections2BuyTogether
@deprecated --flag coupon
@deprecated --flag disableDeal
@deprecated --flag installment
@deprecated --flag maxPricesPerItems
@deprecated --flag merchants
@deprecated --flag paymentsRules
@deprecated --flag productsSpecifications
@deprecated --flag stores
@deprecated --flag storesAreInclusive
@deprecated --flag totalValueIncludeAllItems
export def "rnb-pvt-calculatorconfiguration CreateOrUpdateCalculatorConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --absoluteShippingDiscountValue: float # Maximum shipping value. (e.g. 0)
  --accumulateWithManualPrice: oneof<nothing, bool> # Allows the promotion to apply to products whose prices have been manually added by a call-center operator. (e.g. false)
  --activateGiftsMultiplier: oneof<nothing, bool> # If set as `true`, it activates gifts Multiplier. (e.g. false)
  --activeDaysOfWeek: list # Defines which days of the week the Promotion or Tax will applied.
  --affiliates: list # Marketplace order identifier. The discount will apply to selected affiliates. — item shape: {id?: string, name?: string}
  --applyToAllShippings: oneof<nothing, bool> # Promotion or Tax will be applied to all kind of shipping. (e.g. false)
  --areSalesChannelIdsExclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any trade policies present on the `idsSalesChannel` field. If set to `true`, trade policies present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --beginDateUtc: string # Promotion or Tax Begin Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --brands: list # Object composed by the brands that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --brandsAreInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any brand present on the `brands` field. If set to `false`, brands present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --campaigns: list # Campaign Audiences that activate this Promotion or Tax. (e.g. [Campaign Audience test])
  --cardIssuers: list # DEPRECATED
  --categories: list # Object composed by the categories that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --categoriesAreInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any category present on the `categories` field. If set to `false`, categories present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --clusterExpressions: list # An expression to use with clusters.
  --collections: list # Object composed by the collections that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --collections1BuyTogether: list # Collections that will generate the Promotion, type **Buy Together**, **More for less**, **Progressive Discount**, **Buy One Get One**.
  --collections2BuyTogether: list # DEPRECATED
  --collectionsIsInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any collection present on the `collections` field. If set to `false`, collections present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --compareListPriceAndPrice: oneof<nothing, bool> # If the **List Price** and **Price** are the same. (e.g. false)
  --conditionsIds: list # Array with conditions IDs.
  --coupon: list # DEPRECATED
  --cumulative: oneof<nothing, bool> # Defines if a Promotion or Tax can accumulate with another one. (`true`) or not (`false`). (e.g. false)
  --daysAgoOfPurchases: int # Number of days that are considered to add the purchase history. (e.g. 0)
  --description: string # Internal description of the Promotion or Tax. (e.g. Description of the promotion.)
  --disableDeal: oneof<nothing, bool> # DEPRECATED
  --discountType: string # The type of discount that will apply to the promotion. (e.g. percentual)
  --enableBuyTogetherPerSku: oneof<nothing, bool> # Enable **Buy Together** per SKU. (e.g. false)
  --endDateUtc: string # Promotion or Tax End Date (UTC). (e.g. 2020-05-01T18:47:15.89Z)
  --firstBuyIsProfileOptimistic: oneof<nothing, bool> # Applies the discount even if the user is not logged. (e.g. false)
  --giftListTypes: list # Gifts List Type.
  --idCalculatorConfiguration: string # Promotion ID or Tax ID. (e.g. ba087fa9-8587-44b3-8ef1-ade8d053e9e9)
  --idSeller: string # Seller Name. (e.g. 1)
  --idSellerIsInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any seller present on the `idSeller` field. If set to `false`, sellers present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --idsSalesChannel: list # List of Trade Policies that activate this Promotion or Tax.
  --installment: int # DEPRECATED
  --isActive: oneof<nothing, bool> # If set as `true` the Promotion or Tax is activated. If set as `false` the Promotion or Tax is deactivated. (e.g. true)
  --isArchived: oneof<nothing, bool> # If set as `true` the Promotion or Tax is archived. If set as `false` the Promotion or Tax is not archived. (e.g. false)
  --isDifferentListPriceAndPrice: oneof<nothing, bool> # Applies the Promotion or Tax only if the list price and price is different. (e.g. false)
  --isFeatured: oneof<nothing, bool> # Insert a flag with the promotion name used in the product's window display and page. (e.g. true)
  --isFirstBuy: oneof<nothing, bool> # Applies the discount only if it's a first buy. (e.g. false)
  --isMinMaxInstallments: oneof<nothing, bool> # Set if the Promotion or Tax will be applied considering a minimum and maximum values for installments. (e.g. false)
  --isSlaSelected: oneof<nothing, bool> # Applies selected discount only when one of the defined shipping method is selected by the customer. (e.g. false)
  --itemMaxPrice: float # Maximum price of the item. (e.g. 0)
  --itemMinPrice: float # Minimum price of the item. (e.g. 0)
  --lastModified: string # Date when the Promotion or Tax was last modified. (e.g. 2021-02-23T20:58:38.7963862Z)
  --listSku1BuyTogether: list # SKU first list for the promotion **Buy Together**. (e.g. [SKU])
  --listSku2BuyTogether: list # SKU second list for the promotion **Buy Together**. (e.g. [SKU])
  --marketingTags: list # Promotion or Tax Marketing tags.
  --marketingTagsAreNotInclusive: oneof<nothing, bool> # If set to `false`, this Promotion or Tax will be applied to any marketing tag present on the `marketingTags` field. If set to `true`, marketing tags present on that field will make this Promotion or Tax not to be applied. (e.g. false)
  --maxInstallment: int # Maximum value for installment. (e.g. 0)
  --maxNumberOfAffectedItems: int # The maximum number of affected items for a promotion. (e.g. 0)
  --maxNumberOfAffectedItemsGroupKey: string # The maximum number of affected items by group key for a promotion. (e.g. perCart)
  --maxPricesPerItems: list # DEPRECATED
  --maxUsage: int # Defines how many times the Promotion or Tax can be used. (e.g. 0)
  --maxUsagePerClient: int # Defines if the promotion can be used multiple times per client. (e.g. 0)
  --maximumUnitPriceDiscount: float # The maximum price for each item of the purchase will be the price set up. (e.g. 0)
  --merchants: list # DEPRECATED
  --minInstallment: int # Minimum value for installment. (e.g. 0)
  --minimumQuantityBuyTogether: int # Minimum quantity for **Buy Together** promotion. (e.g. 0)
  --multipleUsePerClient: oneof<nothing, bool> # Defines if the promotion can be used multiple times per client. (e.g. false)
  --name: string # Promotion name or Tax name. (e.g. Promoção Social Seller)
  --newOffset: float # New time offset from UTC in seconds. (e.g. -3)
  --nominalDiscountValue: float # Exact discount to be applied for the total purchase value. (e.g. 0)
  --nominalRewardValue: float # Nominal value for rewards program. (e.g. 0)
  --nominalShippingDiscountValue: float # Exact discount to be applied for the shipping value. (e.g. 0)
  --nominalTax: float # Nominal Tax. (e.g. 0)
  --offset: int # Time offset from UTC in seconds. (e.g. -3)
  --orderStatusRewardValue: string # Order status reward value. (e.g. invoiced)
  --origin: string # Origin of the Promotion or Tax, `marketplace` or `Fulfillment`.  Read [Difference between orders with marketplace and fulfillment sources](https://help.vtex.com/en/tutorial/what-are-orders-with-marketplace-source-and-orders-with-fulfillment-source--6eVYrmUAwMOeKICU2KuG06) for more information. (e.g. marketplace)
  --paymentsMethods: list # Array composed by all the Payments Methods that activate this Promotion or Tax. — item shape: {id?: string, name?: string}
  --paymentsRules: list # DEPRECATED
  --percentualDiscountValue: float # Percentage discount to be applied for total purchase value. (e.g. 10)
  --percentualDiscountValueList: list # Percentual discount value list.
  --percentualDiscountValueList1: float # Valid discounts for the SKUs in `listSku1BuyTogether`, discount list used for Buy Together Promotions. (e.g. 0)
  --percentualDiscountValueList2: float # Equivalent to `percentualDiscountValueList1`. (e.g. 0)
  --percentualRewardValue: float # Percentage value for rewards program. (e.g. 0)
  --percentualShippingDiscountValue: float # Percentage discount to be applied for shipping value. (e.g. 0)
  --percentualTax: float # Percentual Tax over purchase total value. (e.g. 0)
  --products: list # Object composed by the products that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --productsAreInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any product present on the `products` field. If set to `false`, products present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --productsSpecifications: list # DEPRECATED
  --quantityToAffectBuyTogether: int # Quantity to affect **Buy Together** promotion. (e.g. 0)
  --rebatePercentualDiscountValue: float # Percentual Shipping Discount Value. (e.g. 0)
  --restrictionsBins: list # The discount will be granted if the card's BIN is given.
  --shippingPercentualTax: float # Shipping Percentual Tax over purchase total value. (e.g. 0)
  --shouldDistributeDiscountAmongMatchedItems: oneof<nothing, bool> # Should distribute discount among matched items. (e.g. false)
  --skus: list # Object composed by the SKUs that will activate or deactivate the Promotion or Tax. — item shape: {id?: string, name?: string}
  --skusAreInclusive: oneof<nothing, bool> # If set to `true`, this Promotion or Tax will be applied to any SKU present on the `skus` field. If set to `false`, SKUs present on that field will make this Promotion or Tax not to be applied. (e.g. true)
  --skusGift: record # SKU Gift Object. Total discount on the product value set as a gift. — shape: {gifts?: list, quantitySelectable?: int}
  --slasIds: list # The discount will be granted if the shipping method is the same as the one given.
  --stores: list # DEPRECATED
  --storesAreInclusive: oneof<nothing, bool> # DEPRECATED
  --totalValueCeling: float # Maximum chart value to activate the Promotion or Tax. (e.g. 0)
  --totalValueFloor: float # Minimum chart value to activate the Promotion or Tax. (e.g. 0)
  --totalValueIncludeAllItems: oneof<nothing, bool> # DEPRECATED
  --totalValueMode: string # Defines if products that already are receiving a promotion will be considered on the chart total value. There are three options available: `IncludeMatchedItems`, `ExcludeMatchedItems`, `AllItems`. (e.g. IncludeMatchedItems)
  --totalValuePurchase: float # Total value a client must have in past orders to activate the Promotion or Tax. (e.g. 0)
  --type: string # Defines what is the type of the promotion or indicates if it is a tax. Possible values: `regular` ([Regular Promotion](https://help.vtex.com/tutorial/regular-promotion--tutorials_327)), `combo` ([Buy Together](https://help.vtex.com/en/tutorial/buy-together--tutorials_323)), `forThePriceOf` ([More for Less](https://help.vtex.com/en/tutorial/creating-a-more-for-less-promotion--tutorials_325)), `progressive` ([Progressive Discount](https://help.vtex.com/en/tutorial/progressive-discount--tutorials_324)), `buyAndWin` ([Buy One Get One](https://help.vtex.com/en/tutorial/buy-one-get-one--tutorials_322)), `maxPricePerItem` (Deprecated), `campaign` ([Campaign Promotion](https://help.vtex.com/en/tutorial/campaign-promotion--1ChYXhK2AQGuS6wAqS8Ume)), `tax` (Tax), `multipleEffects` (Multiple Effects). (e.g. regular)
  --useNewProgressiveAlgorithm: oneof<nothing, bool> # Use new progressive algorithm. (e.g. false)
  --utmCampaign: string # Coupon utmCampaign code. (e.g. testSource)
  --utmSource: string # Coupon utmSource code. (e.g. testSource)
  --zipCodeRanges: list # Range of the zip code that applies the promotion. — item shape: {inclusive?: bool}
]: any -> record<absoluteShippingDiscountValue: float, accumulateWithManualPrice: bool, activateGiftsMultiplier: bool, activeDaysOfWeek: list<string>, affiliates: table<id: string, name: string>, applyToAllShippings: bool, areSalesChannelIdsExclusive: bool, beginDateUtc: string, brands: table<id: string, name: string>, brandsAreInclusive: bool, campaigns: list<any>, cardIssuers: list<any>, categories: table<id: string, name: string>, categoriesAreInclusive: bool, clusterExpressions: list<string>, collections: table<id: string, name: string>, collections1BuyTogether: list<string>, collections2BuyTogether: list<any>, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, conditionsIds: list<string>, coupon: list<any>, cumulative: bool, daysAgoOfPurchases: int, description: string, disableDeal: bool, discountType: string, enableBuyTogetherPerSku: bool, endDateUtc: string, firstBuyIsProfileOptimistic: bool, giftListTypes: list<string>, idCalculatorConfiguration: string, idSeller: string, idSellerIsInclusive: bool, idsSalesChannel: list<string>, installment: int, isActive: bool, isArchived: bool, isDifferentListPriceAndPrice: bool, isFeatured: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, lastModified: string, listSku1BuyTogether: list<any>, listSku2BuyTogether: list<any>, marketingTags: list<string>, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxNumberOfAffectedItems: int, maxNumberOfAffectedItemsGroupKey: string, maxPricesPerItems: list<any>, maxUsage: int, maxUsagePerClient: int, maximumUnitPriceDiscount: float, merchants: list<any>, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, newOffset: float, nominalDiscountValue: float, nominalRewardValue: float, nominalShippingDiscountValue: float, nominalTax: float, offset: int, orderStatusRewardValue: string, origin: string, paymentsMethods: table<id: string, name: string>, paymentsRules: list<any>, percentualDiscountValue: float, percentualDiscountValueList: list<float>, percentualDiscountValueList1: float, percentualDiscountValueList2: float, percentualRewardValue: float, percentualShippingDiscountValue: float, percentualTax: float, products: table<id: string, name: string>, productsAreInclusive: bool, productsSpecifications: list<any>, quantityToAffectBuyTogether: int, rebatePercentualDiscountValue: float, restrictionsBins: list<string>, shippingPercentualTax: float, shouldDistributeDiscountAmongMatchedItems: bool, skus: table<id: string, name: string>, skusAreInclusive: bool, skusGift: record<gifts: int, quantitySelectable: int>, slasIds: list<string>, stores: list<any>, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, type: string, useNewProgressiveAlgorithm: bool, utmCampaign: string, utmSource: string, zipCodeRanges: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/calculatorconfiguration")
  let body = {absoluteShippingDiscountValue: $absoluteShippingDiscountValue, accumulateWithManualPrice: $accumulateWithManualPrice, activateGiftsMultiplier: $activateGiftsMultiplier, activeDaysOfWeek: $activeDaysOfWeek, affiliates: $affiliates, applyToAllShippings: $applyToAllShippings, areSalesChannelIdsExclusive: $areSalesChannelIdsExclusive, beginDateUtc: $beginDateUtc, brands: $brands, brandsAreInclusive: $brandsAreInclusive, campaigns: $campaigns, cardIssuers: $cardIssuers, categories: $categories, categoriesAreInclusive: $categoriesAreInclusive, clusterExpressions: $clusterExpressions, collections: $collections, collections1BuyTogether: $collections1BuyTogether, collections2BuyTogether: $collections2BuyTogether, collectionsIsInclusive: $collectionsIsInclusive, compareListPriceAndPrice: $compareListPriceAndPrice, conditionsIds: $conditionsIds, coupon: $coupon, cumulative: $cumulative, daysAgoOfPurchases: $daysAgoOfPurchases, description: $description, disableDeal: $disableDeal, discountType: $discountType, enableBuyTogetherPerSku: $enableBuyTogetherPerSku, endDateUtc: $endDateUtc, firstBuyIsProfileOptimistic: $firstBuyIsProfileOptimistic, giftListTypes: $giftListTypes, idCalculatorConfiguration: $idCalculatorConfiguration, idSeller: $idSeller, idSellerIsInclusive: $idSellerIsInclusive, idsSalesChannel: $idsSalesChannel, installment: $installment, isActive: $isActive, isArchived: $isArchived, isDifferentListPriceAndPrice: $isDifferentListPriceAndPrice, isFeatured: $isFeatured, isFirstBuy: $isFirstBuy, isMinMaxInstallments: $isMinMaxInstallments, isSlaSelected: $isSlaSelected, itemMaxPrice: $itemMaxPrice, itemMinPrice: $itemMinPrice, lastModified: $lastModified, listSku1BuyTogether: $listSku1BuyTogether, listSku2BuyTogether: $listSku2BuyTogether, marketingTags: $marketingTags, marketingTagsAreNotInclusive: $marketingTagsAreNotInclusive, maxInstallment: $maxInstallment, maxNumberOfAffectedItems: $maxNumberOfAffectedItems, maxNumberOfAffectedItemsGroupKey: $maxNumberOfAffectedItemsGroupKey, maxPricesPerItems: $maxPricesPerItems, maxUsage: $maxUsage, maxUsagePerClient: $maxUsagePerClient, maximumUnitPriceDiscount: $maximumUnitPriceDiscount, merchants: $merchants, minInstallment: $minInstallment, minimumQuantityBuyTogether: $minimumQuantityBuyTogether, multipleUsePerClient: $multipleUsePerClient, name: $name, newOffset: $newOffset, nominalDiscountValue: $nominalDiscountValue, nominalRewardValue: $nominalRewardValue, nominalShippingDiscountValue: $nominalShippingDiscountValue, nominalTax: $nominalTax, offset: $offset, orderStatusRewardValue: $orderStatusRewardValue, origin: $origin, paymentsMethods: $paymentsMethods, paymentsRules: $paymentsRules, percentualDiscountValue: $percentualDiscountValue, percentualDiscountValueList: $percentualDiscountValueList, percentualDiscountValueList1: $percentualDiscountValueList1, percentualDiscountValueList2: $percentualDiscountValueList2, percentualRewardValue: $percentualRewardValue, percentualShippingDiscountValue: $percentualShippingDiscountValue, percentualTax: $percentualTax, products: $products, productsAreInclusive: $productsAreInclusive, productsSpecifications: $productsSpecifications, quantityToAffectBuyTogether: $quantityToAffectBuyTogether, rebatePercentualDiscountValue: $rebatePercentualDiscountValue, restrictionsBins: $restrictionsBins, shippingPercentualTax: $shippingPercentualTax, shouldDistributeDiscountAmongMatchedItems: $shouldDistributeDiscountAmongMatchedItems, skus: $skus, skusAreInclusive: $skusAreInclusive, skusGift: $skusGift, slasIds: $slasIds, stores: $stores, storesAreInclusive: $storesAreInclusive, totalValueCeling: $totalValueCeling, totalValueFloor: $totalValueFloor, totalValueIncludeAllItems: $totalValueIncludeAllItems, totalValueMode: $totalValueMode, totalValuePurchase: $totalValuePurchase, type: $type, useNewProgressiveAlgorithm: $useNewProgressiveAlgorithm, utmCampaign: $utmCampaign, utmSource: $utmSource, zipCodeRanges: $zipCodeRanges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Promotion or Tax by ID
#
# GET /api/rnb/pvt/calculatorconfiguration/{idCalculatorConfiguration}
# operationId: GetCalculatorConfigurationById
export def "rnb-pvt-calculatorconfiguration GetCalculatorConfigurationById" [
  idCalculatorConfiguration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/calculatorconfiguration/($idCalculatorConfiguration)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "Promotion")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all campaign audiences
#
# GET /api/rnb/pvt/campaignConfiguration
# operationId: Getcampaignaudiences
export def "rnb-pvt-campaign-configuration Getcampaignaudiences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> table<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create campaign audience
#
# POST /api/rnb/pvt/campaignConfiguration
# operationId: Setcampaignconfiguration
# --lastModified shape: {dateUtc?: string, user?: string}
# --targetConfigurations item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list, clusterOperator?: string, collections?: list, collections1BuyTogether?: list, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, firstBuyIsProfileOptimistic?: bool, giftListTypes?: list, id?: string, idSellerIsInclusive?: bool, idsSalesChannel?: list, installment?: int, isDifferentListPriceAndPrice?: bool, isFirstBuy?: bool, isMinMaxInstallments?: bool, isSlaSelected?: bool, itemMaxPrice?: float, itemMinPrice?: float, listBrand1BuyTogether?: list, listCategory1BuyTogether?: list, listSku1BuyTogether?: list, listSku2BuyTogether?: list, marketingTags?: list, marketingTagsAreNotInclusive?: bool, maxInstallment?: int, maxUsage?: int, maxUsagePerClient?: int, merchants?: list, minInstallment?: int, minimumQuantityBuyTogether?: int, multipleUsePerClient?: bool, name?: string, origin?: string, paymentsMethods?: list, paymentsRules?: list, percentualDiscountValueList?: list, products?: list, productsAreInclusive?: bool, productsSpecifications?: list, quantityToAffectBuyTogether?: int, restrictionsBins?: list, shouldDistributeDiscountAmongMatchedItems?: bool, skus?: list, skusAreInclusive?: bool, slasIds?: list, stores?: list, storesAreInclusive?: bool, totalValueCeling?: float, totalValueFloor?: float, totalValueIncludeAllItems?: bool, totalValueMode?: string, totalValuePurchase?: float, useNewProgressiveAlgorithm?: bool, zipCodeRanges?: list}
export def "rnb-pvt-campaign-configuration Setcampaignconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --beginDateUtc: string # Start date of the campaign audience in UTC format. (e.g. 2020-05-01T21:30:00Z)
  --endDateUtc: string # End date of the campaign audience in UTC format. (e.g. 2020-05-02T01:30:00Z)
  --id: string # Campaign audience ID. (e.g. dd270d06-1ed1-47fc-b04e-a2431121b5a4)
  --isActive: oneof<nothing, bool> # Defines if the campaign audience is active (`true`) or not (`false`). (e.g. true)
  --isAndOperator: oneof<nothing, bool> # When `true`, determines that all the `targetConfigurations` need to be valid for the campaign audience to be active. When `false`, determines that if at least one of the `targetConfigurations` is valid, the campaign audience will be active. (e.g. true)
  --isArchived: oneof<nothing, bool> # Defines if the campaign audience is archived (`true`) or not (`false`). (e.g. false)
  --lastModified: record # Object with information about the last update of the campaign audience. — shape: {dateUtc?: string, user?: string}
  --name: string # Campaign audience name. (e.g. Interna)
  --targetConfigurations: list # Array that contains all target audience that the campaign audience will be valid. — item shape: {affiliates?: list, areSalesChannelIdsExclusive?: bool, brands?: list, brandsAreInclusive?: bool, campaigns?: list, cardIssuers?: list, categories?: list, categoriesAreInclusive?: bool, clusterExpressions?: list, clusterOperator?: string, collections?: list, collections1BuyTogether?: list, collections2BuyTogether?: list, collectionsIsInclusive?: bool, compareListPriceAndPrice?: bool, coupon?: list, daysAgoOfPurchases?: int, enableBuyTogetherPerSku?: bool, featured?: bool, firstBuyIsProfileOptimistic?: bool, giftListTypes?: list, id?: string, idSellerIsInclusive?: bool, idsSalesChannel?: list, installment?: int, isDifferentListPriceAndPrice?: bool, isFirstBuy?: bool, isMinMaxInstallments?: bool, isSlaSelected?: bool, itemMaxPrice?: float, itemMinPrice?: float, listBrand1BuyTogether?: list, listCategory1BuyTogether?: list, listSku1BuyTogether?: list, listSku2BuyTogether?: list, marketingTags?: list, marketingTagsAreNotInclusive?: bool, maxInstallment?: int, maxUsage?: int, maxUsagePerClient?: int, merchants?: list, minInstallment?: int, minimumQuantityBuyTogether?: int, multipleUsePerClient?: bool, name?: string, origin?: string, paymentsMethods?: list, paymentsRules?: list, percentualDiscountValueList?: list, products?: list, productsAreInclusive?: bool, productsSpecifications?: list, quantityToAffectBuyTogether?: int, restrictionsBins?: list, shouldDistributeDiscountAmongMatchedItems?: bool, skus?: list, skusAreInclusive?: bool, slasIds?: list, stores?: list, storesAreInclusive?: bool, totalValueCeling?: float, totalValueFloor?: float, totalValueIncludeAllItems?: bool, totalValueMode?: string, totalValuePurchase?: float, useNewProgressiveAlgorithm?: bool, zipCodeRanges?: list}
]: any -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, clusterOperator: string, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/campaignConfiguration")
  let body = {beginDateUtc: $beginDateUtc, endDateUtc: $endDateUtc, id: $id, isActive: $isActive, isAndOperator: $isAndOperator, isArchived: $isArchived, lastModified: $lastModified, name: $name, targetConfigurations: $targetConfigurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get campaign audience configuration
#
# GET /api/rnb/pvt/campaignConfiguration/{campaignId}
# operationId: Getcampaignconfiguration
export def "rnb-pvt-campaign-configuration Getcampaignconfiguration" [
  campaignId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<beginDateUtc: string, endDateUtc: string, id: string, isActive: bool, isAndOperator: bool, isArchived: bool, lastModified: record<dateUtc: string, user: string>, name: string, targetConfigurations: table<affiliates: list, areSalesChannelIdsExclusive: bool, brands: list, brandsAreInclusive: bool, campaigns: list, cardIssuers: list, categories: list, categoriesAreInclusive: bool, clusterExpressions: list, collections: list, collections1BuyTogether: list, collections2BuyTogether: list, collectionsIsInclusive: bool, compareListPriceAndPrice: bool, coupon: list, daysAgoOfPurchases: int, enableBuyTogetherPerSku: bool, featured: bool, firstBuyIsProfileOptimistic: bool, giftListTypes: list, id: string, idSellerIsInclusive: bool, idsSalesChannel: list, installment: int, isDifferentListPriceAndPrice: bool, isFirstBuy: bool, isMinMaxInstallments: bool, isSlaSelected: bool, itemMaxPrice: float, itemMinPrice: float, listBrand1BuyTogether: list, listCategory1BuyTogether: list, listSku1BuyTogether: list, listSku2BuyTogether: list, marketingTags: list, marketingTagsAreNotInclusive: bool, maxInstallment: int, maxUsage: int, maxUsagePerClient: int, merchants: list, minInstallment: int, minimumQuantityBuyTogether: int, multipleUsePerClient: bool, name: string, origin: string, paymentsMethods: list, paymentsRules: list, percentualDiscountValueList: list, products: list, productsAreInclusive: bool, productsSpecifications: list, quantityToAffectBuyTogether: int, restrictionsBins: list, shouldDistributeDiscountAmongMatchedItems: bool, skus: list, skusAreInclusive: bool, slasIds: list, stores: list, storesAreInclusive: bool, totalValueCeling: float, totalValueFloor: float, totalValueIncludeAllItems: bool, totalValueMode: string, totalValuePurchase: float, useNewProgressiveAlgorithm: bool, zipCodeRanges: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/campaignConfiguration/($campaignId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all coupons
#
# GET /api/rnb/pvt/coupon
# operationId: Getall
export def "rnb-pvt-coupon Getall" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> table<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update coupon
#
# POST /api/rnb/pvt/coupon
# operationId: Update
export def "rnb-pvt-coupon Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  couponCode: string # Coupon code. (e.g. test)
  expirationIntervalPerUse: string # Coupon expiration interval per use. (e.g. 00:00:00)
  --isArchived: oneof<nothing, bool> # Defines if the coupon is archived (`true`) or not (`false`). (e.g. false)
  maxItemsPerClient: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  utmCampaign: string # UTM campaign code. (e.g. coupon3)
  utmSource: string # UTM source code. (e.g. coupon3)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon")
  let body = {couponCode: $couponCode, expirationIntervalPerUse: $expirationIntervalPerUse, isArchived: $isArchived, maxItemsPerClient: $maxItemsPerClient, utmCampaign: $utmCampaign, utmSource: $utmSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  couponCode: string # Coupon code. (e.g. summersale10)
  expirationIntervalPerUse: string # Coupon expiration interval per use. (e.g. 00:00:00)
  maxItemsPerClient: int # Maximum items per client that the coupon can be applied. (e.g. 10)
  --utmCampaign: string # UTM campaign code. (e.g. summer)
  utmSource: string # UTM source code. (e.g. email)
]: any -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/coupon/")
  let body = {couponCode: $couponCode, expirationIntervalPerUse: $expirationIntervalPerUse, maxItemsPerClient: $maxItemsPerClient, utmCampaign: $utmCampaign, utmSource: $utmSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get coupon usage
#
# GET /api/rnb/pvt/coupon/usage/{couponCode}
# operationId: Getusage
export def "rnb-pvt-coupon-usage Getusage" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, hostName: string, profileUsages: record<profileId: record<orderUsage: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/coupon/usage/($couponCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get coupon by coupon code
#
# GET /api/rnb/pvt/coupon/{couponCode}
# operationId: Getbycouponcode
export def "rnb-pvt-coupon Getbycouponcode" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<couponCode: string, expirationIntervalPerUse: string, isArchived: bool, lastModifiedUtc: string, maxItemsPerClient: int, utmCampaign: string, utmSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/coupon/($couponCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coupon Massive Generation
#
# POST /api/rnb/pvt/coupons
# operationId: MassiveGeneration
export def "rnb-pvt-coupons MassiveGeneration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quantity: int # Quantity of coupons to generate (e.g. 10)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  couponCode: string # Coupon code. (e.g. ctest)
  expirationIntervalPerUse: string # Coupon expiration interval per use. (e.g. 00:00:00)
  maxItemsPerClient: int # Defines if the coupon is archived (`true`) or not (`false`). (e.g. 1)
  utmCampaign: string # UTM campaign code. (e.g. cupom3)
  utmSource: string # UTM source code. (e.g. cupom3)
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quantity" $quantity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rnb/pvt/coupons" $qp)
  let body = {couponCode: $couponCode, expirationIntervalPerUse: $expirationIntervalPerUse, maxItemsPerClient: $maxItemsPerClient, utmCampaign: $utmCampaign, utmSource: $utmSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --Content-Type: string # Type of the content being sent. (e.g. text/csv)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --X-VTEX-calculator-name: string # Promotion Name. (e.g. Test)
  --X-VTEX-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --X-VTEX-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --X-VTEX-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --X-VTEX-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --X-VTEX-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --X-VTEX-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/import/calculatorConfiguration")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept, "X-VTEX-calculator-name": $X_VTEX_calculator_name, "X-VTEX-cumulative": $X_VTEX_cumulative, "X-VTEX-cluster-operator": $X_VTEX_cluster_operator, "X-VTEX-cluster-expression": $X_VTEX_cluster_expression, "X-VTEX-start-date": $X_VTEX_start_date, "X-VTEX-end-date": $X_VTEX_end_date, "X-VTEX-accumulate-with-manual-prices": $X_VTEX_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "text/csv" $body
}

# Update Multiple SKU Promotion
#
# PUT /api/rnb/pvt/import/calculatorConfiguration/{promotionId}
export def "rnb-pvt-import-calculator-configuration put" [
  promotionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent. (e.g. text/csv)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --X-VTEX-calculator-name: string # Promotion Name. (e.g. Test)
  --X-VTEX-cumulative: oneof<nothing, bool> # Defines if the Promotion is cumulative with other promotions. (e.g. false)
  --X-VTEX-cluster-operator: string # This header allows implementing the Promotion in multiples client clusters. You can set the value as `all` - the Promotion will be valid to all the clusters - or `any` - the Promotion will be valid to any of the clusters. (e.g. any)
  --X-VTEX-cluster-expression: string # Cluster that will be included in the Promotion. To add multiple clusters, create a header for each one of them. (e.g. cluster_name=true)
  --X-VTEX-start-date: string # Promotion start date. (e.g. 2020-08-18T16:00:00+3:00)
  --X-VTEX-end-date: string # Promotion end date. (e.g. 2020-08-18T16:30:00+3:00)
  --X-VTEX-accumulate-with-manual-prices: oneof<nothing, bool> # Condition that will accumulate the Promotion with manual prices or not. (e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/import/calculatorConfiguration/($promotionId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept, "X-VTEX-calculator-name": $X_VTEX_calculator_name, "X-VTEX-cumulative": $X_VTEX_cumulative, "X-VTEX-cluster-operator": $X_VTEX_cluster_operator, "X-VTEX-cluster-expression": $X_VTEX_cluster_expression, "X-VTEX-start-date": $X_VTEX_start_date, "X-VTEX-end-date": $X_VTEX_end_date, "X-VTEX-accumulate-with-manual-prices": $X_VTEX_accumulate_with_manual_prices} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "text/csv" $body
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
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/multiple-coupons")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Taxes
#
# GET /api/rnb/pvt/taxes/calculatorconfiguration
# operationId: GetAllTaxes
export def "rnb-pvt-taxes-calculatorconfiguration GetAllTaxes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<archivedItems: list<string>, disabledItems: list<string>, items: table<Campaigns: list, activateGiftsMultiplier: bool, areSalesChannelIdsExclusive: bool, beginDate: string, description: string, endDate: string, hasMaxPricePerItem: bool, idCalculatorConfiguration: string, idsSalesChannel: list, isActive: bool, isArchived: bool, isTax: bool, lastModifiedUtc: string, maxUsage: float, name: string, percentualTax: float, scope: record, status: string, type: string, utmCampain: string, utmSource: string, utmiCampaign: string>, limitConfiguration: record<activesCount: int, limit: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rnb/pvt/taxes/calculatorconfiguration")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive Promotion or Tax
#
# POST /api/rnb/pvt/unarchive/calculatorConfiguration/{idCalculatorConfiguration}
# operationId: UnarchivePromotion
export def "rnb-pvt-unarchive-calculator-configuration UnarchivePromotion" [
  idCalculatorConfiguration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/unarchive/calculatorConfiguration/($idCalculatorConfiguration)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive coupon by coupon code
#
# POST /api/rnb/pvt/unarchive/coupon/{couponCode}
# operationId: Unarchivebycouponcode
export def "rnb-pvt-unarchive-coupon Unarchivebycouponcode" [
  couponCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rnb/pvt/unarchive/coupon/($couponCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Save Price
#
# POST /price-sheet
# operationId: Saveprice
export def "price-sheet Saveprice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all paged prices
#
# GET /price-sheet/all/{page}/{pageSize}
# operationId: Getallpaged
export def "price-sheet-all Getallpaged" [
  page: string
  pageSize: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/price-sheet/all/($page)/($pageSize)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Price by context
#
# POST /price-sheet/context
# operationId: Pricebycontext
export def "price-sheet-context Pricebycontext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  id: int # format: int32
  itemId: int # format: int32
  salesChannel: int # format: int32
  sellerId: string
  validFrom: string
  validTo: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/price-sheet/context" $qp)
  let body = {id: $id, itemId: $itemId, salesChannel: $salesChannel, sellerId: $sellerId, validFrom: $validFrom, validTo: $validTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Price by SKU Id
#
# DELETE /price-sheet/{skuId}
# operationId: DeletebyskuId
export def "price-sheet DeletebyskuId" [
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/price-sheet/($skuId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Price by SKU ID
#
# GET /price-sheet/{skuId}
# operationId: PricebyskuId
export def "price-sheet PricebyskuId" [
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/price-sheet/($skuId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Price by SKU ID and Trade Policy
#
# GET /price-sheet/{skuId}/{tradePolicy}
# operationId: PricebyskuIdandtradePolicy
export def "price-sheet PricebyskuIdandtradePolicy" [
  skuId: string
  tradePolicy: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --an: string # e.g. {{accountName}}
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --Content-Type: string # Describes the type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "https://rnb.{environment}.com.br/api/pricing/pvt")
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/price-sheet/($skuId)/($tradePolicy)" $qp)
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Calculate discounts and taxes (Bundles)
#
# POST /pub/bundles
# operationId: Calculatediscountsandtaxes(Bundles)
# --items item shape: {id: string, index: int, isGift: bool, logisticsInfos: list, measurementUnit: string, params: list, priceSheet: list, priceTags: list, productSpecifications: list, quantity: int, sellerId: string, unitMultiplier: int}
# --params item shape: {name: string, value: string}
export def "pub-bundles CalculatediscountsandtaxesBundles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --isShoppingCart: oneof<nothing, bool>
  items: list # item shape: {id: string, index: int, isGift: bool, logisticsInfos: list, measurementUnit: string, params: list, priceSheet: list, priceTags: list, productSpecifications: list, quantity: int, sellerId: string, unitMultiplier: int}
  origin: string
  params: list # item shape: {name: string, value: string}
  profileId: string
  salesChannel: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default "http://example.com/.{environment}.com.br/api/rnb")
  let full_url = (build-url $base "/pub/bundles")
  let body = {isShoppingCart: $isShoppingCart, items: $items, origin: $origin, params: $params, profileId: $profileId, salesChannel: $salesChannel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
