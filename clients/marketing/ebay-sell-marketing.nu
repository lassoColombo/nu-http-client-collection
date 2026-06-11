# Auto-generated client for Marketing API vv1.14.0
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-marketing/v1.14.0/openapi.json
# Auth: --token flag or $env.MARKETING_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/marketing/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARKETING_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.ebay.com/sell/marketing/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ad-campaign list" } } | get name | first)
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

# This method retrieves the details for all of the seller's defined campaigns. Request parameters can be used to retrieve a specific campaign, such as the campaign's name, the start and end date, the status, and the funding model (Cost Per Sale (CPS) or Cost Per Click (CPC). <p>You can filter the result set by a campaign name, end date range, start date range, or campaign status. You can also paginate the records returned from the result set using the <b>limit</b> query parameter, and control which records to return using the  <b>offset</b> parameter.</p>
#
# GET /ad_campaign
# operationId: getCampaigns
export def "ad-campaign list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-name: string # Specifies the campaign name. The results are filtered to include only the campaign by the specified name.<br /><br /><b>Note: </b>The results might be null if other filters exclude the campaign with this name. <br /><br /><b>Maximum: </b> 1 campaign name
  --campaign-status: string # Include this filter and input a specific campaign status to retrieve campaigns currently in that state. <br /><br /><b>Note: </b>The results might not include all the campaigns with this status if other filters exclude them. <br /><br /><b>Valid values:</b> See <a href="/api-docs/sell/marketing/types/pls:CampaignStatusEnum">CampaignStatusEnum</a> <br /><br /><b>Maximum: </b> 1 status
  --end-date-range: string # Specifies the range of a campaign's end date. The results are filtered to include only campaigns with an end date that is within specified range. <br><br><b>Valid format (UTC)</b>: <ul><li><code> yyyy-MM-ddThh:mm:ssZ..yyyy-MM-ddThh:mm:ssZ </code>  (campaign ends within this range)</li><li><code>yyyy-MM-ddThh:mm:ssZ..</code> (campaign ends on or after this date)</li><li><code>..yyyy-MM-ddThh:mm:ssZ </code> (campaign ends on or before this date)</li><li><code>2016-09-08T00:00.00.000Z..2016-09-09T00:00:00Z</code> (campaign ends on September 08, 2016)</li></ul> <br /><br /><b>Note: </b>The results might not include all the campaigns ending on this date if other filters exclude them.
  --funding-strategy: string # Specifies the funding strategy for the campaign.<br /><br />The results will be filtered to only include campaigns with the specified funding model. If not specified, all campaigns matching the other filter parameters will be returned. The results might not include these campaigns if other search conditions exclude them.<br /><br /><b>Valid Values:</b><ul><li><code>COST_PER_SALE</code></li><li><code>COST_PER_CLICK</code></li></ul>
  --limit: string # <p>Specifies the maximum number of campaigns to return on a page in the paginated response.</p>  <b>Default: </b>10 <br><b>Maximum: </b> 500
  --offset: string # Specifies the number of campaigns to skip in the result set before returning the first report in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
  --start-date-range: string # Specifies the range of a campaign's start date in which to filter the results. The results are filtered to include only campaigns with a start date that is equal to this date or is within specified range.<br><br><b>Valid format (UTC): </b> <ul><li><code>yyyy-MM-ddThh:mm:ssZ..yyyy-MM-ddThh:mm:ssZ</code> (starts within this range)</li><li><code>yyyy-MM-ddThh:mm:ssZ</code> (campaign starts on or after this date)</li><li><code>..yyyy-MM-ddThh:mm:ssZ </code>(campaign starts on or before this date)</li><li><code>2016-09-08T00:00.00.000Z..2016-09-09T00:00:00Z</code> (campaign starts on September 08, 2016)</li></ul><br /><br /><b>Note: </b>The results might not include all the campaigns with this start date if other filters exclude them.
]: nothing -> record<campaigns: table<alerts: list, budget: record, campaignCriterion: record, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record, marketplaceId: string, startDate: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_name" $campaign_name "scalar") (serialize-qp "campaign_status" $campaign_status "scalar") (serialize-qp "end_date_range" $end_date_range "scalar") (serialize-qp "funding_strategy" $funding_strategy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start_date_range" $start_date_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method creates a Promoted Listings ad campaign. <p>A Promoted Listings <i>campaign</i> is the structure into which you place the ads or ad group for the listings you want to promote.</p>  <p>Identify the items you want to place into a campaign either by "key" or by "rule" as follows:</p> <ul><li><b>Rules-based campaigns</b> &ndash; A rules-based campaign adds items to the campaign according to the <i>criteria</i> you specify in your call to <b>createCampaign</b>. You can set the <b>autoSelectFutureInventory</b> request field to <code>true</code> so that after your campaign launches, eBay will regularly assess your new, revised, or newly-eligible listings to determine whether any should be added or removed from your campaign according to the rules you set. If there are, eBay will add or remove them automatically on a daily basis.</li> <li><b>Key-based campaigns</b> &ndash; Add items to an existing campaign using either listing ID values or Inventory Reference values: <ul><li>Add <b>listingId</b> values to an existing campaign by calling either <b>createAdByListingID</b> or <b>bulkCreateAdsByListingId</b>.</li>  <li>Add <b>inventoryReference</b> values to an existing campaign by calling either <b>createAdByInventoryReference</b> or <b>bulkCreateAdsByInventoryReference</b>.</li><li>Add an <b>ad group</b> to an existing campaign by calling <b>createAdGroup</b>.</li></ul><p class="tablenote"><b>Note:</b> No matter how you add items to a Promoted Listings campaign, each campaign can contain ads for a maximum of 50,000 items. <br><br>If a rules-based campaign identifies more than 50,000 items, ads are created for only the first 50,000 items identified by the specified criteria, and ads are not created for the remaining items.</p>  <p><b>Creating a campaign</b></p> <p>To create a basic campaign, supply:</p>  <ul><li>The user-defined campaign name</li> <li>The start date (and optionally the end date) of the campaign</li> <li>The eBay marketplace on which the campaign is hosted</li> <li>Details on the campaign funding model</li></ul>  <p>The campaign funding model specifies how the Promoted Listings fee is calculated. Currently, the supported funding models are <code>COST_PER_SALE</code> and <code>COST_PER_CLICK</code>. For complete information on how the fee is calculated and when it applies, see <a href="/api-docs/sell/static/marketing/pl-overview.html#pl-fees">Promoted Listings fees</a>.</p>   <p>If you populate the <b>campaignCriterion</b> object in your <b>createCampaign</b> request, campaign "ads" are created by "rule" for the listings that meet the criteria you specify, and these ads are associated with the newly created campaign.</p>  <p>For details on creating Promoted Listings campaigns and how to select the items to be included in your campaigns, see <a href="/api-docs/sell/static/marketing/pl-create-campaign.html">Promoted Listings campaign creation</a>.</p>  <p>For recommendations on which listings are prime for a Promoted Listings ad campaign and to get guidance on how to set the <b>bidPercentage</b> field, see <a href="/api-docs/sell/static/marketing/pl-reco-api.html">Using the Recommendation API to help configure campaigns</a>.</p>  <p class="tablenote"><b>Tip:</b> See <a href="/api-docs/sell/marketing/static/overview.html#PL-requirements">Promoted Listings requirements and restrictions</a> for the details on the marketplaces that support Promoted Listings via the API. See <a href="/api-docs/sell/static/marketing/pl-restrictions">Promoted Listings restrictions</a> for details about campaign limitations and restrictions.</p>
#
# POST /ad_campaign
# operationId: createCampaign
# --budget shape: {daily?: record}
# --campaignCriterion shape: {autoSelectFutureInventory?: bool, criterionType?: string, selectionRules?: list}
# --fundingStrategy shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
export def "ad-campaign createCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --budget: record # A container for the details of a Promoted Listings campaign that uses the Cost Per Click (CPC) funding model. — shape: {daily?: record}
  --campaignCriterion: record # This type defines the fields for specifying the criterion (selection rule) settings of an ad campaign. If you populate the campaignCriterion object in your <b>createCampaign</b> request, ads for the campaign are created by rule for the listings that meet the criteria you specify, and these ads are associated with the newly created campaign. — shape: {autoSelectFutureInventory?: bool, criterionType?: string, selectionRules?: list}
  --campaignName: string # A seller-defined name for the campaign. This value must be unique for the seller. <p>You can use any alphanumeric characters in the name, except the less than (&lt;) or greater than (&gt;) characters.</p><b>Max length: </b>80 characters
  --endDate: string # The date and time the campaign ends, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an <a href="/api-docs/sell/marketing/resources/campaign/methods/endCampaign">endCampaign</a> call, or if they update the campaign at a later time with an end date.
  --fundingStrategy: record # This type defines how the Promoted Listings fee is calculated for a Promoted Listings ad campaign. — shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
  --marketplaceId: string # The ID of the eBay marketplace where the campaign is hosted. See the <b>MarketplaceIdEnum</b> type to get the appropriate enumeration value for the listing marketplace. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --startDate: string # The date and time the campaign starts, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.  <p>On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign. Call <b>getCampaign</b> to check the status of the campaign.</p>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_campaign")
  let body = {budget: $budget, campaignCriterion: $campaignCriterion, campaignName: $campaignName, endDate: $endDate, fundingStrategy: $fundingStrategy, marketplaceId: $marketplaceId, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method retrieves the campaigns containing the listing that is specified using either a listing ID, or an inventory reference ID and inventory reference type pair. The request accepts either a <b>listing_id</b>, <i>or</i> an <b>inventory_reference_id</b> and <b>inventory_reference_type</b> pair, as used in the Inventory API.<br /><br />eBay <i>listing IDs</i> are generated by either the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods">Inventory API</a> when you create a listing.<br /><br />An <i>inventory reference ID</i> can be either a seller-defined <b>SKU</b> or <b>inventoryItemGroupKey</b>, as specified in the Inventory API.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# GET /ad_campaign/find_campaign_by_ad_reference
# operationId: findCampaignByAdReference
export def "ad-campaign-find-campaign-by-ad-reference findCampaignByAdReference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inventory-reference-id: string # The seller's inventory reference ID of the listing to be used to find the campaign in which it is associated.  This will either be a seller-defined <b>SKU</b> value or inventory item group ID, depending on the reference type specified. You must always pass in both  <b>inventory_reference_id</b> and <b>inventory_reference_type</b>.
  --inventory-reference-type: string # The type of the seller's inventory reference ID, which is a listing or group of items. You must always pass in both <b>inventory_reference_id</b> and <b>inventory_reference_type</b>.
  --listing-id: string # Identifier of the eBay listing associated with the ad.
]: nothing -> record<campaigns: table<alerts: list, budget: record, campaignCriterion: record, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record, marketplaceId: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inventory_reference_id" $inventory_reference_id "scalar") (serialize-qp "inventory_reference_type" $inventory_reference_type "scalar") (serialize-qp "listing_id" $listing_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign/find_campaign_by_ad_reference" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method retrieves the details of a single campaign, as specified with the <b>campaign_name</b> query parameter. Note that the campaign name you specify must be an exact, case-sensitive match of the name of the campaign you want to retrieve.</p><p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a list of the seller's campaign names.</p>
#
# GET /ad_campaign/get_campaign_by_name
# operationId: getCampaignByName
export def "ad-campaign-get-campaign-by-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaign-name: string # The name of the campaign.
]: nothing -> record<alerts: table<alertType: string, details: list>, budget: record<daily: record<amount: record, budgetStatus: string>>, campaignCriterion: record<autoSelectFutureInventory: bool, criterionType: string, selectionRules: list<record>>, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record<adRateStrategy: string, bidPercentage: string, dynamicAdRatePreferences: list<record>, fundingModel: string>, marketplaceId: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_name" $campaign_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign/get_campaign_by_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method deletes the campaign specified by the <code>campaign_id</code> query parameter.<br /><br /><span class="tablenote"><b>Note: </b> You can only delete campaigns that have ended.</span><br /><br />Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the <b>campaign_id</b> and the campaign status (<code>RUNNING</code>, <code>PAUSED</code>, <code>ENDED</code>, and so on) for all the seller's campaigns.
#
# DELETE /ad_campaign/{campaign_id}
# operationId: deleteCampaign
export def "ad-campaign delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method retrieves the details of a single campaign, as specified with the <b>campaign_id</b> query parameter.  <p>This method returns all the details of a campaign (including the campaign's the selection rules), except the for the listing IDs or inventory reference IDs included in the campaign. These IDs are returned by <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a>.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a list of the seller's campaign IDs.</p>
#
# GET /ad_campaign/{campaign_id}
# operationId: getCampaign
export def "ad-campaign get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alerts: table<alertType: string, details: list>, budget: record<daily: record<amount: record, budgetStatus: string>>, campaignCriterion: record<autoSelectFutureInventory: bool, criterionType: string, selectionRules: list<record>>, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record<adRateStrategy: string, bidPercentage: string, dynamicAdRatePreferences: list<record>, fundingModel: string>, marketplaceId: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method retrieves Promoted Listings ads that are associated with listings created with either the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>. <p>The method retrieves ads related to the specified campaign. Specify the Promoted Listings campaign to target with the <b>campaign_id</b> path parameter.</p>  <p>Because of the large number of possible results, you can use query parameters to paginate the result set by specifying a <b>limit</b>, which dictates how many ads to return on each page of the response. You can also specify how many ads to skip in the result set before returning the first result using the <b>offset</b> path parameter.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the current campaign IDs for the seller.</p>
#
# GET /ad_campaign/{campaign_id}/ad
# operationId: getAds
export def "ad-campaign-ad list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: string # A comma-separated list of ad group IDs. The results will be filtered to only include active ads for these ad groups. Call <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> to retrieve the ad group ID for the ad group.<br /><br /><span class="tablenote"><b>Note:</b> This field only applies to the Cost Per Click (CPC) funding model; it does not apply to the Cost Per Sale (CPS) funding model.</span>
  --ad-status: string # A comma-separated list of ad statuses. The results will be filtered to only include the given statuses of the ad. If none are provided, all ads are returned.
  --limit: string # Specifies the maximum number of ads to return on a page in the paginated response. <p><b>Default: </b>10 <br><b>Maximum:</b> 500</p>
  --listing-ids: string # A comma-separated list of listing IDs. The response includes only active ads (ads associated with a RUNNING campaign). The results do not include listing IDs that are excluded by other conditions.
  --offset: string # Specifies the number of ads to skip in the result set before returning the first ad in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
]: nothing -> record<ads: table<adGroupId: string, adId: string, adStatus: string, alerts: list, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "ad_status" $ad_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "listing_ids" $listing_ids "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method adds a listing to an existing Promoted Listings campaign using a <b>listingId</b> value generated by the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>, or using a value generated by an ad group ID. <p>For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, an ad may be directly created for the listing.</p><p>For the listing ID specified in the request, this method:</p>  <ul><li>Creates an ad for the listing.</li> <li>Sets the bid percentage (also known as the <i>ad rate</i>) for the ad.</li> <li>Associates the ad with the specified campaign.</li></ul>  <p>To create an ad for a listing, specify its <b>listingId</b>, plus the <b>bidPercentage</b> for the ad in the payload of the request. Specify the campaign to associate the ad with using the <b>campaign_id</b> path parameter. Listing IDs are generated by eBay when a seller creates listings with the Trading API.</p><p>For Promoted Listings Advanced (PLA) campaigns using the Cost Per Click (CPC) funding model, an ad group must be created first. If no ad group has been created for the campaign, an ad cannot be created.</p><p>For the ad group specified in the request, this method associates the ad with the specified ad group.</p><p>To create an ad for an ad group, specify the name of the ad group in the payload of the request. Specify the campaign to associate the ads with using the <b>campaign_id</b> path parameter. Ad groups are generated using the <a href="/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup">createAdGroup</a> method.</p> <p>You can specify one or more ad groups per campaign.</p><p>Use <a href="/api-docs/sell/marketing/resources/campaign/methods/createCampaign">createCampaign</a> to create a new campaign and use <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get a list of existing campaigns.</p><p>This call has no response payload. If the ad is successfully created, a <code>201 Created</code> HTTP status code and the <a href="/api-docs/sell/marketing/resources/ad/methods/getAd">getAd</a> URI of the ad are returned in the location header.</p>
#
# POST /ad_campaign/{campaign_id}/ad
# operationId: createAdByListingId
export def "ad-campaign-ad createAdByListingId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adGroupId: string # A unique eBay-assigned ID for an ad group in a campaign that uses the Cost Per Click (CPC) funding model. <p><i>Required if</i> the campaign's funding model is Cost Per Click (CPC).</p><p>Create an ad group using the <a href="/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup">createAdGroup</a> method.</p><p>Specify the campaign to associate the ad group with using the <b>campaign_id</b> path parameter. </p><span class="tablenote"><b>Note:</b> You can call the  <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> method to retrieve the ad group IDs for a seller.</span>
  --bidPercentage: string # The user-defined <b>bid percentage</b> (also known as the <i>ad rate</i>) sets the level that eBay increases the visibility in search results for the associated listing. The higher the <b>bidPercentage</b> value, the more eBay promotes the listing.<br><br><i>Required if</i> the campaign's funding model is Cost Per Sale (CPS).  <br><br>The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. <br><br>The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. <br><br>The <b>bidPercentage</b> is a single precision value that is guided by the following rules: <ul><li>These values are <b>valid</b>:<br>&nbsp;&nbsp;&nbsp;<code>4.1</code>,&nbsp;&nbsp;&nbsp;<code>5.0</code>, &nbsp;&nbsp;&nbsp;<code>5.5</code>, ...</li>  <li>These values are <b>not valid</b>:<br /> &nbsp;&nbsp;&nbsp;<code>0.01</code>, &nbsp;&nbsp;&nbsp;<code>10.75</code>, &nbsp;&nbsp;&nbsp;<code>99.99</code>,<br /> &nbsp;&nbsp;&nbsp;and so on.</li></ul>This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.<br /><br />If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.<br /><br /><b>Minimum value:</b> 2.0 <br><b>Maximum value:</b> 100.0
  --listingId: string # A unique eBay-assigned ID for a listing that is generated when the listing is created.  <p class="tablenote"><b>Note:</b> This field accepts listing IDs, as generated by the Inventory API, and item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs).</p>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad")
  let body = {adGroupId: $adGroupId, bidPercentage: $bidPercentage, listingId: $listingId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method removes the specified ad from the specified campaign.<br /><br />Pass the ID of the ad to delete with the ID of the campaign associated with the ad as path parameters to the call.<br /><br />Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get the current list of the seller's campaign IDs.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span><br /><br />When using the CPC funding model, use the <b>bulkUpdateAdsStatusByListingId</b> method to change the status of ads to ARCHIVED.
#
# DELETE /ad_campaign/{campaign_id}/ad/{ad_id}
# operationId: deleteAd
export def "ad-campaign-ad delete" [
  ad_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad/($ad_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method retrieves the specified ad from the specified campaign.  <p>In the request, supply the <b>campaign_id</b> and <b>ad_id</b> as path parameters.</p> <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a list of the seller's current campaign IDs and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to retrieve their current ad IDs.</p>
#
# GET /ad_campaign/{campaign_id}/ad/{ad_id}
# operationId: getAd
export def "ad-campaign-ad get" [
  ad_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adGroupId: string, adId: string, adStatus: string, alerts: table<alertType: string, details: list>, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad/($ad_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method updates the bid percentage (also known as the "ad rate") for the specified ad in the specified campaign. <p>In the request, supply the <b>campaign_id</b> and <b>ad_id</b> as path parameters, and supply the new <b>bidPercentage</b> value in the payload of the call.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a seller's current campaign IDs and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to get their ad IDs.</p><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/ad/{ad_id}/update_bid
# operationId: updateBid
export def "ad-campaign-ad-update-bid updateBid" [
  ad_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bidPercentage: string # The user-defined <b>bid percentage</b> (also known as the <i>ad rate</i>) sets the level that eBay increases the visibility in search results for the associated listing. The higher the <b>bidPercentage</b> value, the more eBay promotes the listing.  <br><br>The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. <br><br>The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. <br><br>The <b>bidPercentage</b> is a single precision value that is guided by the following rules: <ul><li>These values are <b>valid</b>:<br>&nbsp;&nbsp;&nbsp;<code>4.1</code>, &nbsp;&nbsp;&nbsp;<code>5.0</code>, &nbsp;&nbsp;&nbsp;<code>5.5</code>, ...</li>  <li>These values are <b>not valid</b>:<br /> &nbsp;&nbsp;&nbsp;<code>0.01</code>, &nbsp;&nbsp;&nbsp;<code>10.75</code>, &nbsp;&nbsp;&nbsp;<code>99.99</code>,<br /> &nbsp;&nbsp;&nbsp;and so on.</li></ul>This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.<br /><br />If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.<br /><br /><b>Minimum value:</b> 2.0 <br><b>Maximum value:</b> 100.0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad/($ad_id)/update_bid")
  let body = {bidPercentage: $bidPercentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method retrieves ad groups for the specified campaigns.<br /><br />Each campaign can only have <b>one</b> ad group.<br /><br />In the request, supply the <b>campaign_ids</b> as path parameters.<br /><br />Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a list of the current campaign IDs for a seller.
#
# GET /ad_campaign/{campaign_id}/ad_group
# operationId: getAdGroups
export def "ad-campaign-ad-group list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-status: string # A comma-separated list of ad group statuses. The results will be filtered to only include the given statuses of the ad group.<br /><br />The results might not include these ad groups if other search conditions exclude them.
  --limit: string # The number of results, from the current result set, to be returned in a single page.
  --offset: string # The number of results that will be skipped in the result set. This is used with the <b>limit</b> field to control the pagination of the output.<br /><br />For example, if the <b>offset</b> is set to <code>0</code> and the <b>limit</b> is set to <code>10</code>, the method will retrieve items 1 through 10 from the list of items returned. If the <b>offset</b> is set to <code>10</code> and the <b>limit</b> is set to <code>10</code>, the method will retrieve items 11 through 20 from the list of items returned.<br><br><b>Default</b>: <code>0</code>
]: nothing -> record<adGroups: table<adGroupId: string, adGroupStatus: string, defaultBid: record, name: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_status" $ad_group_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method adds an ad group to an existing PLA campaign that uses the Cost Per Click (CPC) funding model.<br /><br />To create an ad group for a campaign, specify the <b>defaultBid</b> for the ad group in the payload of the request. Then specify the campaign to which the ad group should be associated using the <b>campaign_id</b> path parameter.<br /><br />Each campaign can have one or more associated ad groups.
#
# POST /ad_campaign/{campaign_id}/ad_group
# operationId: createAdGroup
# --defaultBid shape: {currency?: string, value?: string}
export def "ad-campaign-ad-group createAdGroup" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultBid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --name: string # The seller-defined name of the ad group.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group")
  let body = {defaultBid: $defaultBid, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method retrieves the details of a specified ad group, such as the ad group’s default bid and status.<br /><br />In the request, specify the <b>campaign_id</b> and <b>ad_group_id</b> as path parameters.<br /><br />Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a list of the current campaign IDs for a seller and call <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> for the ad group ID of the ad group you wish to retrieve.
#
# GET /ad_campaign/{campaign_id}/ad_group/{ad_group_id}
# operationId: getAdGroup
export def "ad-campaign-ad-group get" [
  ad_group_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adGroupId: string, adGroupStatus: string, defaultBid: record<currency: string, value: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group/($ad_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates the ad group associated with a campaign.<br /><br />With this method, you can modify the <b>default bid</b> for the ad group, change the state of the ad group, or change the name of the ad group. Pass the <b>ad_group_id</b> you want to update as a URI parameter, and configure the <b>adGroupStatus</b> and <b>defaultBid</b> in the request payload.<br /><br />Call <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroup">getAdGroup</a> to retrieve the current default bid and status of the ad group that you would like to update.
#
# PUT /ad_campaign/{campaign_id}/ad_group/{ad_group_id}
# operationId: updateAdGroup
# --defaultBid shape: {currency?: string, value?: string}
export def "ad-campaign-ad-group updateAdGroup" [
  ad_group_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adGroupStatus: string # An enumeration value representing the current status of the ad group.<p>If the status of the ad is currently <code>ACTIVE</code>, you can change status to <code>PAUSED</code> or <code>ARCHIVED</code>. If ad group is currently in <code>PAUSED</code> status, you can change the status back to <code>ACTIVE</code>. Ads that are currently in <code>ARCHIVED</code> status cannot be made <code>ACTIVE</code> again.<br /><br /><b>Valid Values:</b><ul><li><code>ACTIVE</code></li><li><code>PAUSED</code></li><li><code>ARCHIVED</code></li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:AdGroupStatusEnum'>eBay API documentation</a>
  --defaultBid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --name: string # The updated name for the specified ad group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group/($ad_group_id)")
  let body = {adGroupStatus: $adGroupStatus, defaultBid: $defaultBid, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method allows sellers to retrieve the suggested bids for input keywords and match type.
#
# POST /ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_bids
# operationId: suggestBids
# --keywords item shape: {keywordText?: string, matchType?: string}
export def "ad-campaign-ad-group-suggest-bids suggestBids" [
  ad_group_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --keywords: list # A list of keywords in the paginated collection. <br /><br /><b>Maximum number of keywords: </b>500 — item shape: {keywordText?: string, matchType?: string}
]: any -> record<suggestedBids: table<keywordText: string, matchType: string, proposedBid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group/($ad_group_id)/suggest_bids")
  let body = {keywords: $keywords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method allows sellers to retrieve a list of keyword ideas to be targeted for Promoted Listings campaigns.
#
# POST /ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_keywords
# operationId: suggestKeywords
export def "ad-campaign-ad-group-suggest-keywords suggestKeywords" [
  ad_group_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalInfo: list # A field used to indicate whether additional information and insight data shall be provided for suggested keywords.<br /><br /><strong>Valid Value:</strong> <code>KEYWORD_INSIGHTS</code>
  --exclusions: list # A field used to indicate that the keywords already selected by sellers for the specified listing IDs should be filtered out of the response, and only new and unique keyword recommendations shall be returned.<br /><br /><strong>Valid Value:</strong> <code>ADOPTED_KEYWORDS</code>
  --listingIds: list # A set of comma-separated listing IDs in the paginated collection. <br /><br /><b>Maximum number of listings requested: </b>300
  --matchType: string # A field that defines the match type for the keyword.<br /><br /><b>Valid Values:</b><ul><li><code>BROAD</code></li><li><code>EXACT</code></li><li><code>PHRASE</code></li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:MatchTypeEnum'>eBay API documentation</a>
]: any -> record<suggestedKeywords: table<additionalInfo: list, keywordText: string, matchType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/ad_group/($ad_group_id)/suggest_keywords")
  let body = {additionalInfo: $additionalInfo, exclusions: $exclusions, listingIds: $listingIds, matchType: $matchType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method adds multiple listings that are managed with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a> to an existing Promoted Listings campaign.<br /><br />For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) model, bulk ads may be directly created for the listing.<br /><br />For each listing specified in the request, this method:<br /><ul><li>Creates an ad for the listing.</li> <li>Sets the bid percentage (also known as the <i>ad rate</i>) for the ads created.</li> <li>Associates the ads created with the specified campaign.</li></ul><br />To create ads for a listing, specify their <b>inventoryReferenceId</b> and <b>inventoryReferenceType</b>, plus the <b>bidPercentage</b> for the ad in the payload of the request. Specify the campaign to which you want to associate the ads using the <b>campaign_id</b> path parameter.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span><br /><br />Use <a href="/api-docs/sell/marketing/resources/campaign/methods/createCampaign">createCampaign</a> to create a new campaign and use <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get a list of existing campaigns.
#
# POST /ad_campaign/{campaign_id}/bulk_create_ads_by_inventory_reference
# operationId: bulkCreateAdsByInventoryReference
# --requests item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-create-ads-by-inventory-reference bulkCreateAdsByInventoryReference" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # A list of inventory reference ID and inventory reference type pairs, and the bid percentage, which the call uses to create ads in bulk. — item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<adGroupId: string, ads: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_create_ads_by_inventory_reference")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method adds multiple listings to an existing Promoted Listings campaign using <b>listingId</b> values generated by the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>, or using values generated by an ad group ID.<p>For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, bulk ads may be directly created for the listing.</p><p>For each listing ID specified in the request, this method:</p>  <ul><li>Creates an ad for the listing.</li> <li>Sets the bid percentage (also known as the <i>ad rate</i>) for the ad.</li> <li>Associates the ad with the specified campaign.</li></ul><p>To create an ad for a listing, specify its <b>listingId</b>, plus the <b>bidPercentage</b> for the ad in the payload of the request. Specify the campaign to associate the ads with using the <b>campaign_id</b> path parameter. Listing IDs are generated by eBay when a seller creates listings with the Trading API.</p><p>You can specify a maximum of <b>500 listings per call</b> and each campaign can have ads for a maximum of 50,000 items. Be aware when using this call that each variation in a multiple-variation listing creates an individual ad.</p><p>For Promoted Listings Advanced (PLA) campaigns using the Cost Per Click (CPC) funding model, an ad group must be created first. If no ad group has been created for the campaign, ads cannot be created.</p><p>For the ad group specified in the request, this method associates the ad with the specified ad group.</p><p>To create an ad for an ad group, specify the name of the ad group plus the <b>defaultBid</b> for the ad in the payload of the request. Specify the campaign to associate the ads with using the <b>campaign_id</b> path parameter. Ad groups are generated using the <a href="/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup">createAdGroup</a>  method.</p> <p>You can specify one or more ad groups per campaign.</p><p>Use <a href="/api-docs/sell/marketing/resources/campaign/methods/createCampaign">createCampaign</a> to create a new campaign and use <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get a list of existing campaigns.</p>
#
# POST /ad_campaign/{campaign_id}/bulk_create_ads_by_listing_id
# operationId: bulkCreateAdsByListingId
# --requests item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
export def "ad-campaign-bulk-create-ads-by-listing-id bulkCreateAdsByListingId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array of listing IDs and their associated bid percentages, which the request uses to create ads in bulk. This request accepts both listing IDs, as generated by the Inventory API, and an item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs).  <br><br><b>Maximum: </b> 500 IDs per call — item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
]: any -> record<responses: table<adGroupId: string, adId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_create_ads_by_listing_id")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method adds keywords, in bulk, to an existing PLA ad group in a campaign that uses the Cost Per Click (CPC) funding model.<br /><br />This method also sets the CPC rate for each keyword.<br /><br />In the request, supply the <b>campaign_id</b> as a path parameter.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /ad_campaign/{campaign_id}/bulk_create_keyword
# operationId: bulkCreateKeyword
# --requests item shape: {adGroupId?: string, bid?: record, keywordText?: string, matchType?: string}
export def "ad-campaign-bulk-create-keyword bulkCreateKeyword" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # This array is used to pass in multiple keywords for one or more ad groups that belong to a campaign that uses the Cost Per Click (CPC) funding model. Up to {max value} keywords can be created with one call. — item shape: {adGroupId?: string, bid?: record, keywordText?: string, matchType?: string}
]: any -> record<responses: table<adGroupId: string, errors: list, href: string, keywordId: string, keywordText: string, matchType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_create_keyword")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method works with listings created with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>.<br /><br />The method deletes a set of ads, as specified by a list of inventory reference IDs, from the specified campaign. <i>Inventory reference IDs</i> are seller-defined IDs that are used with the Inventory API</a>.<br /><br />Pass the <b>campaign_id</b> as a path parameter and populate the payload with a list of <b>inventoryReferenceId</b> and <b>inventoryReferenceType</b> pairs that you want to delete.<br /><br />Get the campaign IDs for a seller by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to get a list of the seller's inventory reference IDs.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/bulk_delete_ads_by_inventory_reference
# operationId: bulkDeleteAdsByInventoryReference
# --requests item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-delete-ads-by-inventory-reference bulkDeleteAdsByInventoryReference" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # A list of inventory referenceID and inventory reference type pairs that specify the set of ads to remove in bulk. — item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<adIds: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_delete_ads_by_inventory_reference")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method works with listing IDs created with either the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>.<br /><br />The method deletes a set of ads, as specified by a list of <b>listingID</b> values from a Promoted Listings campaign. A listing ID value is generated by eBay when a seller creates a listing with either the Trading API and Inventory API.<br /><br />Pass the <b>campaign_id</b> as a path parameter and populate the payload with the set of listing IDs that you want to delete.<br /><br />Get the campaign IDs for a seller by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to get a list of the seller's inventory reference IDs.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span><br /><br />When using the CPC funding model, use the <a href="/api-docs/sell/marketing/resources/ad/methods/bulkUpdateAdsStatusByListingId">bulkUpdateAdsStatusByListingId</a> method to change the status of ads to ARCHIVED.
#
# POST /ad_campaign/{campaign_id}/bulk_delete_ads_by_listing_id
# operationId: bulkDeleteAdsByListingId
# --requests item shape: {listingId?: string}
export def "ad-campaign-bulk-delete-ads-by-listing-id bulkDeleteAdsByListingId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array of the listing IDs that identify the ads to remove. — item shape: {listingId?: string}
]: any -> record<responses: table<adId: string, errors: list, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_delete_ads_by_listing_id")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method works with listings created with either the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>.  <p>The method updates the <b>bidPercentage</b> values for a set of ads associated with the specified campaign.</p>  <p>Specify the <b>campaign_id</b> as a path parameter and supply a set of listing IDs with their associated updated <b>bidPercentage</b> values in the request body. An eBay listing ID is generated when a listing is created with the Trading API.</p>  <p>Get the campaign IDs for a seller by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to get a list of the seller's inventory reference IDs.</p><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_bid_by_inventory_reference
# operationId: bulkUpdateAdsBidByInventoryReference
# --requests item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-update-ads-bid-by-inventory-reference bulkUpdateAdsBidByInventoryReference" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # A list of inventory reference ID and inventory reference type pairs, and the bid percentage, which the call uses to create ads in bulk. — item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<ads: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_update_ads_bid_by_inventory_reference")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method works with listings created with either the <a href="/Devzone/XML/docs/Reference/eBay/index.html" title="Trading API Reference">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>.  <p>The method updates the <b>bidPercentage</b> values for a set of ads associated with the specified campaign.</p>  <p>Specify the <b>campaign_id</b> as a path parameter and supply a set of listing IDs with their associated updated <b>bidPercentage</b> values in the request body. An eBay listing ID is generated when a listing is created with the Trading API.</p>  <p>Get the campaign IDs for a seller by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to get a list of the seller's inventory reference IDs.</p><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_bid_by_listing_id
# operationId: bulkUpdateAdsBidByListingId
# --requests item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
export def "ad-campaign-bulk-update-ads-bid-by-listing-id bulkUpdateAdsBidByListingId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array of listing IDs and their associated bid percentages, which the request uses to create ads in bulk. This request accepts both listing IDs, as generated by the Inventory API, and an item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs).  <br><br><b>Maximum: </b> 500 IDs per call — item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
]: any -> record<responses: table<adId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_update_ads_bid_by_listing_id")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method works with listings created with either the <a href= "/Devzone/XML/docs/Reference/eBay/index.html">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods">Inventory API</a>.<br /><br />This method updates the status of ads in bulk.<br /><br />Specify the <b>campaign_id</b> you want to update as a URI parameter, and configure the <b>adGroupStatus</b> in the request payload.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_status
# operationId: bulkUpdateAdsStatus
# --requests item shape: {adId?: string, adStatus?: string}
export def "ad-campaign-bulk-update-ads-status bulkUpdateAdsStatus" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array of listing IDs and bid percentages. — item shape: {adId?: string, adStatus?: string}
]: any -> record<responses: table<adId: string, errors: list, href: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_update_ads_status")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method works with listings created with either the <a href="/Devzone/XML/docs/Reference/eBay/index.html">Trading API</a> or the <a href="/api-docs/sell/inventory/resources/methods">Inventory API</a>.<br /><br />The method updates the status of ads in bulk, based on listing ID values.<br /><br />Specify the <b>campaign_id</b> as a path parameter and supply a set of listing IDs with their updated <b>adStatus</b> values in the request body. An eBay listing ID is generated when a listing is created with the Trading API.<br /><br />Get the campaign IDs for a seller by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> and call <a href="/api-docs/sell/marketing/resources/ad/methods/getAds">getAds</a> to retrieve a list of seller inventory reference IDs.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_status_by_listing_id
# operationId: bulkUpdateAdsStatusByListingId
# --requests item shape: {adGroupId?: string, adStatus?: string, listingId?: string}
export def "ad-campaign-bulk-update-ads-status-by-listing-id bulkUpdateAdsStatusByListingId" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array of listing IDs and bid percentages. — item shape: {adGroupId?: string, adStatus?: string, listingId?: string}
]: any -> record<responses: table<adGroupId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_update_ads_status_by_listing_id")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates the bids and statuses of keywords, in bulk, for an existing PLA campaign.<br /><br />In the request, supply the <b>campaign_id</b> as a path parameter.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /ad_campaign/{campaign_id}/bulk_update_keyword
# operationId: bulkUpdateKeyword
# --requests item shape: {bid?: record, keywordId?: string, keywordStatus?: string}
export def "ad-campaign-bulk-update-keyword bulkUpdateKeyword" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # Use this array to update the bid values and/or statuses of one or more existing keywords. — item shape: {bid?: record, keywordId?: string, keywordStatus?: string}
]: any -> record<responses: table<errors: list, keywordId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/bulk_update_keyword")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method clones (makes a copy of) the specified campaign's <b>campaign criterion</b>. The <b>campaign criterion</b> is a container for the fields that define the criteria for a rule-based campaign.<p>To clone a campaign, supply the <b>campaign_id</b> as a path parameter in your call. There is no request payload.</p>  <p>The ID of the newly-cloned campaign is returned in the <b>Location</b> response header.</p><p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a seller's current campaign IDs.</p>  <p><b>Requirement: </b>In order to clone a campaign, the <b>campaignStatus</b> must be <code>ENDED</code> and the campaign must define a set of selection rules (it must be a rules-based campaign).</p><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/clone
# operationId: cloneCampaign
# --fundingStrategy shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
export def "ad-campaign-clone cloneCampaign" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignName: string # A seller-defined name for the newly-cloned campaign. This value must be unique for the seller. <p>You can use any alphanumeric characters in the name, except the less than (&lt;) or greater than (&gt;) characters.</p><b>Max length: </b>80 characters
  --endDate: string # The date and time the campaign ends, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an <a href="/api-docs/sell/marketing/resources/campaign/methods/endCampaign">endCampaign</a> call, or if they update the campaign at a later time with an end date.
  --fundingStrategy: record # This type defines how the Promoted Listings fee is calculated for a Promoted Listings ad campaign. — shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
  --startDate: string # The date and time the cloned campaign starts, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.  <p>On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign. Call <b>getCampaign</b> to check the status of the campaign.</p>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/clone")
  let body = {campaignName: $campaignName, endDate: $endDate, fundingStrategy: $fundingStrategy, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method adds a listing that is managed with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a> to an existing Promoted Listings campaign.<br /><br />For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, an ad may be directly created for the listing.<br /><br />For each listing specified in the request, this method:<br /><ul><li>Creates an ad for the listing.</li> <li>Sets the bid percentage (also known as the <i>ad rate</i>) for the ads created.</li> <li>Associates the created ad with the specified campaign.</li></ul><br />To create an ad for a listing, specify its <b>inventoryReferenceId</b> and <b>inventoryReferenceType</b>, plus the <b>bidPercentage</b> for the ad in the payload of the request. Specify the campaign to associate the ad with using the <b>campaign_id</b> path parameter.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span><br /><br />Use <a href="/api-docs/sell/marketing/resources/campaign/methods/createCampaign">createCampaign</a> to create a new campaign and use <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get a list of existing campaigns.
#
# POST /ad_campaign/{campaign_id}/create_ads_by_inventory_reference
# operationId: createAdsByInventoryReference
export def "ad-campaign-create-ads-by-inventory-reference createAdsByInventoryReference" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adGroupId: string # <span class="tablenote"><b>Note:</b> This field is not currently in use. Ad groups are only applicable to Promoted Listings Advanced (PLA) ad campaigns that use the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
  --bidPercentage: string # The user-defined <b>bid percentage</b> (also known as the <i>ad rate</i>) sets the level that eBay increases the visibility in search results for the associated listing. The higher the <b>bidPercentage</b> value, the more eBay promotes the listing.<br /><br /><i>Required if</i> the campaign's funding model is Cost Per Sale (CPS).<br /><br />The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee.<br /><br />The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign.<br /><br />The <b>bidPercentage</b> is a single precision value that is guided by the following rules: <ul><li>These values are <b>valid</b>:<br>&nbsp;&nbsp;&nbsp;<code>4.1</code>, &nbsp;&nbsp;&nbsp;<code>5.0</code>,&nbsp;&nbsp;&nbsp;<code>5.5</code>, ...</li>  <li>These values are <b>not valid</b>:<br /> &nbsp;&nbsp;&nbsp;<code>0.01</code>, &nbsp;&nbsp;&nbsp;<code>10.75</code>, &nbsp;&nbsp;&nbsp;<code>99.99</code>,<br /> &nbsp;&nbsp;&nbsp;and so on.</li></ul>This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.<br /><br />If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.<br /><br /><b>Minimum value:</b> 2.0 <br><b>Maximum value:</b> 100.0
  --inventoryReferenceId: string # An ID that identifies a single-item listing or multiple-variation listing that is managed with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>. <p>The <i>inventory reference ID</i> is a seller-defined value that can be either an <b>SKU</b> for a single-item listing or an <b>inventoryItemGroupKey</b> for a multiple-value listing.</p>  <p>An <i>inventoryItemGroupKey</i> is a value that the seller defines to indicate a listing that's the parent of an inventory item group (a multiple-variation listing, such as a listing for a shirt that's available in multiple sizes and colors).</p>  <p>You must always specify both an <b>inventoryReferenceId</b> and an <b>inventoryReferenceType</b> to indicate an item that's managed with the Inventory API.</p>
  --inventoryReferenceType: string # Indicates the type of item the <b>inventoryReferenceId</b> references. The item can be either an <code>INVENTORY_ITEM</code> or <code>INVENTORY_ITEM_GROUP</code>. <p>You must always pair an <b>inventoryReferenceId</b> with and <b>inventoryReferenceType</b>.</p> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:InventoryReferenceTypeEnum'>eBay API documentation</a>
]: any -> record<ads: table<adId: string, href: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/create_ads_by_inventory_reference")
  let body = {adGroupId: $adGroupId, bidPercentage: $bidPercentage, inventoryReferenceId: $inventoryReferenceId, inventoryReferenceType: $inventoryReferenceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method works with listings that are managed with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a>.  <p>The method deletes ads using a list of seller-defined inventory reference IDs, used with the Inventory API, that are associated with the specified campaign ID.</p> <p>Specify the campaign ID (as a path parameter) and a list of <b>inventoryReferenceId</b> and <b>inventoryReferenceType</b> pairs to be deleted.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to get a list of the seller's current campaign IDs.</p><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span><br /><br />When using the CPC funding model, use the bulkUpdateAdsStatusByInventoryReference method to change the status of ads to ARCHIVED.
#
# POST /ad_campaign/{campaign_id}/delete_ads_by_inventory_reference
# operationId: deleteAdsByInventoryReference
export def "ad-campaign-delete-ads-by-inventory-reference post" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inventoryReferenceId: string # The inventory reference ID is a seller-defined SKU value for a single-item listing, or a seller-defined identifier for an inventory item group. Both of these values are defined when using the Inventory API, and an inventory item group is used to create a multiple-variation listing.
  --inventoryReferenceType: string # The enumeration value passed into this field indicates the type of value used for the corresponding <b>inventoryReferenceId</b> value. The enumeration value used here will either be <code>INVENTORY_ITEM</code> (to delete the ad for a single SKU listing) or <code>INVENTORY_ITEM_GROUP</code> (to delete the ad for a multiple-variation listing). For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:InventoryReferenceTypeEnum'>eBay API documentation</a>
]: any -> record<adIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/delete_ads_by_inventory_reference")
  let body = {inventoryReferenceId: $inventoryReferenceId, inventoryReferenceType: $inventoryReferenceType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method ends an active (<code>RUNNING</code>) or paused campaign. Specify the campaign you want to end by supplying its campaign ID in a query parameter.  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the <b>campaign_id</b> and the campaign status (<code>RUNNING</code>, <code>PAUSED</code>, <code>ENDED</code>, and so on) for all the seller's campaigns.</p>
#
# POST /ad_campaign/{campaign_id}/end
# operationId: endCampaign
export def "ad-campaign-end endCampaign" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/end")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method retrieves Promoted Listings ads associated with listings that are managed with the <a href="/api-docs/sell/inventory/resources/methods" title="Inventory API Reference">Inventory API</a> from the specified campaign.<br /><br />Supply the <b>campaign_id</b> as a path parameter and use query parameters to specify the <b>inventory_reference_id</b> and <b>inventory_reference_type</b> pairs.<br /><br />In the Inventory API, an <i>inventory reference ID</i> is either a seller-defined <b>SKU</b> value or an <b>inventoryItemGroupKey</b> (a seller-defined ID for an inventory item group, which is an entity that's used in the Inventory API to create a multiple-variation listing). To indicate a listing managed by the Inventory API, you must always specify both an <b>inventory_reference_id</b> and the associated <b>inventory_reference_type</b>.<br /><br />Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve all of the seller's the current campaign IDs.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# GET /ad_campaign/{campaign_id}/get_ads_by_inventory_reference
# operationId: getAdsByInventoryReference
export def "ad-campaign-get-ads-by-inventory-reference get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inventory-reference-id: string # The inventory reference ID associated with the ad you want returned. A seller's inventory reference ID is the ID of either a listing or the ID of an inventory item group (the parent of a multi-variation listing, such as a shirt that is available in multiple sizes and colors). You must always supply in both an <b>inventory_reference_id</b> and an <b>inventory_reference_type</b>.
  --inventory-reference-type: string # The type of the inventory reference ID. Set this value to either <code>INVENTORY_ITEM</CODE> (a single listing) or <code>INVENTORY_ITEM_GROUP</CODE> (a multi-variation listing). You must always pass in both an <b>inventory_reference_id</b> and an <b>inventory_reference_type</b>. 
]: nothing -> record<ads: table<adGroupId: string, adId: string, adStatus: string, alerts: list, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inventory_reference_id" $inventory_reference_id "scalar") (serialize-qp "inventory_reference_type" $inventory_reference_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/get_ads_by_inventory_reference" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method can be used to retrieve all of the keywords for ad groups in PLA campaigns that use the Cost Per Click (CPC) funding model.<br /><br />In the request, specify the <b>campaign_id</b> as a path parameter. If one or more <b>ad_group_ids</b> are passed in the request body, the keywords for those ad groups will be returned. If <b>ad_group_ids</b> are not passed in the response body, the call will return all the keywords in the campaign.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a seller.
#
# GET /ad_campaign/{campaign_id}/keyword
# operationId: getKeywords
export def "ad-campaign-keyword list" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: string # A comma-separated list of ad group IDs. This query parameter is used if the seller wants to retrieve keywords from one or more specific ad groups. If this query parameter is not used, all keywords that are part of the CPC campaign are returned.<span class="tablenote"><b>Note:</b>You can call the <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a>  method to retrieve the ad group IDs for a seller.</span>
  --keyword-status: string # A comma-separated list of keyword statuses. The results will be filtered to only include the given statuses of the keyword. If none are provided, all keywords are returned.
  --limit: string # <p>Specifies the maximum number of results to return on a page in the paginated response.</p>  <b>Default: </b>10 <br><b>Maximum: </b> 500
  --offset: string # Specifies the number of results to skip in the result set before returning the first report in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
]: nothing -> record<href: string, keywords: table<adGroupId: string, bid: record, keywordId: string, keywordStatus: string, keywordText: string, matchType: string>, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "keyword_status" $keyword_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/keyword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method creates keywords using a specified campaign ID for an existing PLA campaign.<br /><br />In the request, supply the <b>campaign_id</b> as a path parameter.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/suggestKeywords">suggestKeywords</a> method to retrieve a list of keyword ideas to be targeted for PLA campaigns, and call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a seller.
#
# POST /ad_campaign/{campaign_id}/keyword
# operationId: createKeyword
# --bid shape: {currency?: string, value?: string}
export def "ad-campaign-keyword createKeyword" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adGroupId: string # This adGroupId is created when an ad group is first created and associated with a campaign. This is the ad group that the corresponding keyword will be added to. This ad group must be a part of the campaign that is specified in the call URI.<br /><br /><span class="tablenote"><b>Note:</b> You can call the  <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> method to retrieve the ad group IDs for a seller, and <a href="/api-docs/sell/marketing/resources/keywords/methods/getKeywords">getKeywords</a> to retrieve the keyword IDs for a seller's keywords.</span>
  --bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --keywordText: string # Input the keyword into this field.
  --matchType: string # A field that defines the match type for the keyword.<br /><br /><b>Valid Values:</b><ul><li><code>BROAD</code></li><li><code>EXACT</code></li><li><code>PHRASE</code></li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:MatchTypeEnum'>eBay API documentation</a>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/keyword")
  let body = {adGroupId: $adGroupId, bid: $bid, keywordText: $keywordText, matchType: $matchType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method retrieves details on a specific keyword from an ad group within a PLA campaign that uses the Cost Per Click (CPC) funding model.<br /><br />In the request, specify the <b>campaign_id</b> and <b>keyword_id</b> as path parameters.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a seller and call the <a href="/api-docs/sell/marketing/resources/keyword/methods/getKeywords">getKeywords</a> method to retrieve their keyword IDs.
#
# GET /ad_campaign/{campaign_id}/keyword/{keyword_id}
# operationId: getKeyword
export def "ad-campaign-keyword get" [
  campaign_id: string
  keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adGroupId: string, bid: record<currency: string, value: string>, keywordId: string, keywordStatus: string, keywordText: string, matchType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/keyword/($keyword_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates keywords using a campaign ID and keyword ID for an existing PLA campaign.<br /><br />In the request, specify the <b>campaign_id</b> and <b>keyword_id</b> as path parameters.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a seller and call the <a href="/api-docs/sell/marketing/resources/keyword/methods/getKeywords">getKeywords</a> method to retrieve their keyword IDs.
#
# PUT /ad_campaign/{campaign_id}/keyword/{keyword_id}
# operationId: updateKeyword
# --bid shape: {currency?: string, value?: string}
export def "ad-campaign-keyword updateKeyword" [
  campaign_id: string
  keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --keywordStatus: string # Include this field if you wish to change the status of the keyword. The status value specified here must be different than the keyword's current status. To confirm the current status of a keyword, you can use the <a href="/api-docs/sell/marketing/resources/keyword/methods/getKeyword">getKeyword</a> method.</p><p>If the status of the ad is currently <code>ACTIVE</code>, you can change status to <code>PAUSED</code> or <code>ARCHIVED</code>. If ad group is currently in <code>PAUSED</code> status, you can change the status back to <code>ACTIVE</code>. Ads that are currently in <code>ARCHIVED</code> status cannot be made <code>ACTIVE</code> again. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:KeywordStatusEnum'>eBay API documentation</a>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/keyword/($keyword_id)")
  let body = {bid: $bid, keywordStatus: $keywordStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method pauses an active (RUNNING) campaign.  <p>You can restart the campaign by calling <a href="/api-docs/sell/marketing/resources/campaign/methods/resumeCampaign">resumeCampaign</a>, as long as the campaign's end date is in the future.</p>  <p><b>Note: </b> The listings associated with a paused campaign cannot be added into another campaign.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the <b>campaign_id</b> and the campaign status (<code>RUNNING</code>, <code>PAUSED</code>, <code>ENDED</code>, and so on) for all the seller's campaigns.</p>
#
# POST /ad_campaign/{campaign_id}/pause
# operationId: pauseCampaign
export def "ad-campaign-pause pauseCampaign" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method resumes a paused campaign, as long as its end date is in the future. Supply the <b>campaign_id</b> for the campaign you want to restart as a query parameter in the request.  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the <b>campaign_id</b> and the campaign status (<code>RUNNING</code>, <code>PAUSED</code>, <code>ENDED</code>, and so on) for all the seller's campaigns.</p>
#
# POST /ad_campaign/{campaign_id}/resume
# operationId: resumeCampaign
export def "ad-campaign-resume resumeCampaign" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method allows sellers to obtain ideas for listings, which can be targeted for Promoted Listings campaigns.
#
# GET /ad_campaign/{campaign_id}/suggest_items
# operationId: suggestItems
export def "ad-campaign-suggest-items suggestItems" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --category-ids: string # Specifies the category ID that is used to limit the results. This refers to an exact leaf category (the lowest level in that category and has no children). This field can have one category ID, or a comma-separated list of IDs. To return all category IDs, set to <code>null</code>. <br /><br /><b>Maximum: </b> 10 
  --limit: string # Specifies the maximum number of campaigns to return on a page in the paginated response. If no value is specified, the default value is used. <br /><br /><b>Default: </b>10 <br /><br /><b>Minimum: </b> 1<br /><br /><b>Maximum: </b> 1000
  --offset: string # Specifies the number of campaigns to skip in the result set before returning the first report in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, suggestedItems: table<bases: list, listingId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/suggest_items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method updates the ad rate strategy for an existing Promoted Listings Standard (PLS) rules-based ad campaign that uses the Cost Per Sale (CPS) funding model.<br /><br />Specify the <b>campaign_id</b> as a path parameter. You can retrieve the campaign IDs for a seller by calling the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method.<br /><br /><span class="tablenote"><b>Note:</b> This method only applies to the CPS funding model; it does not apply to the Cost Per Click (CPC) funding model. See <a href="/api-docs/sell/static/marketing/pl-overview.html#funding-model">Funding Models</a> in the <i>Promoted Listings Playbook</i> for more information.</span>
#
# POST /ad_campaign/{campaign_id}/update_ad_rate_strategy
# operationId: updateAdRateStrategy
# --dynamicAdRatePreferences item shape: {adRateAdjustmentPercent?: string, adRateCapPercent?: string}
export def "ad-campaign-update-ad-rate-strategy updateAdRateStrategy" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adRateStrategy: string # The ad rate strategy that shall be applied to the campaign. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:AdRateStrategyEnum'>eBay API documentation</a>
  --bidPercentage: string # The user-defined <b>bid percentage</b> (also known as the <i>ad rate</i>) sets the level that eBay increases the visibility in search results for the associated listing. The higher the <b>bidPercentage</b> value, the more eBay promotes the listing.  <br><br>The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. <br><br>The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. <br><br>The <b>bidPercentage</b> is a single precision value that is guided by the following rules: <ul><li>These values are <b>valid</b>:<br>&nbsp;&nbsp;&nbsp;<code>4.1</code>, &nbsp;&nbsp;&nbsp;<code>5.0</code>, &nbsp;&nbsp;&nbsp;<code>5.5</code>, ...</li>  <li>These values are <b>not valid</b>:<br /> &nbsp;&nbsp;&nbsp;<code>0.01</code>, &nbsp;&nbsp;&nbsp;<code>10.75</code>, &nbsp;&nbsp;&nbsp;<code>99.99</code>,<br /> &nbsp;&nbsp;&nbsp;and so on.</li></ul>This is the default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.<br /><br />If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.<br /><br /><b>Minimum value:</b> 2.0 <br><b>Maximum value:</b> 100.0
  --dynamicAdRatePreferences: list # A field that indicates whether a single, user-defined bid percentage (also known as the <i>ad rate</i>) should be used, or whether eBay should automatically adjust listings to maintain the daily suggested bid percentage.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> Dynamic adjustment is only applicable when the <b>adRateStrategy</b> is set to <code>DYNAMIC</code>.</span><br /><b>Default:</b> <code>FIXED</code> — item shape: {adRateAdjustmentPercent?: string, adRateCapPercent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/update_ad_rate_strategy")
  let body = {adRateStrategy: $adRateStrategy, bidPercentage: $bidPercentage, dynamicAdRatePreferences: $dynamicAdRatePreferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates the daily budget for a PLA campaign that uses the Cost Per Click (CPC) funding model.<br /><br />A click occurs when an eBay user finds and clicks on the seller’s listing (within the search results) after using a keyword that the seller has created for the campaign. For each ad in an ad group in the campaign, each click triggers a cost, which gets subtracted from the campaign’s daily budget. If the cost of the clicks exceeds the daily budget, the Promoted Listings campaign will be paused until the next day.<br /><br />Specify the <b>campaign_id</b> as a path parameter. You can retrieve the campaign IDs for a seller by calling the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method.
#
# POST /ad_campaign/{campaign_id}/update_campaign_budget
# operationId: updateCampaignBudget
# --daily shape: {amount?: record}
export def "ad-campaign-update-campaign-budget updateCampaignBudget" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --daily: record # A container for the budget details of a Promoted Listings campaign that uses the Cost Per Click (CPC) funding model.<br /><br /><span class="tablenote"><b>Note:</b> This container will only be returned for campaigns using the CPC funding model; it does not apply to the Cost Per Sale (CPS) funding model.</span> — shape: {amount?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/update_campaign_budget")
  let body = {daily: $daily} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method can be used to change the name of a campaign, as well as modify the start or end dates. <p>Specify the <b>campaign_id</b> you want to update as a URI parameter, and configure the <b>campaignName</b> and <b>startDate</b> in the request payload.  <p>If you want to change only the end date of the campaign, specify the current campaign name and set <b>startDate</b> to the current date (you cannot use a start date that is in the past), and set the <b>endDate</b> as desired. Note that if you do not set a new end date in this call, any current <b>endDate</b> value will be set to <code>null</code>. To preserve the currently-set end date, you must specify the value again in your request.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve a seller's campaign details, including the campaign ID, campaign name, and the start and end dates of the campaign.
#
# POST /ad_campaign/{campaign_id}/update_campaign_identification
# operationId: updateCampaignIdentification
export def "ad-campaign-update-campaign-identification updateCampaignIdentification" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignName: string # The new seller-defined name for the campaign. This value must be unique for the seller. <p>If you don't want to change the name of the campaign, specify the current campaign name in this field.<p>You can use any alphanumeric characters in the name, except the less than (&lt;) or greater than (&gt;) characters.</p><b>Max length: </b>80 characters.
  --endDate: string # The date and time the campaign ends, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an <a href="/api-docs/sell/marketing/resources/campaign/methods/endCampaign">endCampaign</a> call, or if they update the campaign at a later time with an end date.<p>If you want to change only the end date of the campaign, specify the current campaign name and set <b>startDate</b> to the current date (you cannot use a start date that is in the past), and set the <b>endDate</b> as desired. Note that if you do not set a new end date in this call, any current endDate value will be set to null. To preserve the currently-set end date, you must specify the value again in your request.</p>
  --startDate: string # The new start date for the campaign, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). <p>If the campaign is currently <code>RUNNING</code> or <code>PAUSED</code>, enter the current date in this field because you cannot submit past or future date for these campaigns.</p>  <p>On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign.</p>  <p>Call <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> to retrieve the <b>campaign_id</b> and the campaign status (<code>RUNNING</code>, <code>PAUSED</code>, <code>ENDED</code>, and so on) for all the seller's campaigns.</p>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_campaign/($campaign_id)/update_campaign_identification")
  let body = {campaignName: $campaignName, endDate: $endDate, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This call downloads the report as specified by the <b>report_id</b> path parameter.  <br><br>Call <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask" title="createReportTask API docs">createReportTask</a> to schedule and generate a Promoted Listings report. All date values are returned in UTC format (<code>yyyy-MM-ddThh:mm:ss.sssZ</code>).<br/><br/><span class="tablenote"><b>Note:</b> The reporting of some data related to sales and ad-fees may require a 72-hour (<b>maximum</b>) adjustment period which is often referred to as the <i>Reconciliation Period</i>. Such adjustment periods should, on average, be minimal. However, at any given time, the <b>payments</b> tab may be used to view those amounts that have actually been charged.</span>
#
# GET /ad_report/{report_id}
# operationId: getReport
export def "ad-report get" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_report/($report_id)")
  let accept_val = "text/tab-separated-values"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This call retrieves information that details the fields used in each of the Promoted Listings reports. Use the returned information to configure the different types of Promoted Listings reports.</br></br>The request for this method does not use a payload or any URI parameters.<br/><br/><span class="tablenote"><b>Note:</b> The reporting of some data related to sales and ad-fees may require a 72-hour (<b>maximum</b>) adjustment period which is often referred to as the <i>Reconciliation Period</i>. Such adjustment periods should, on average, be minimal. However, at any given time, the <b>payments</b> tab may be used to view those amounts that have actually been charged.</span>
#
# GET /ad_report_metadata
# operationId: getReportMetadata
export def "ad-report-metadata list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<reportMetadata: table<dimensionMetadata: list, maxNumberOfDimensionsToRequest: int, maxNumberOfMetricsToRequest: int, metricMetadata: list, reportType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_report_metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This call retrieves metadata that details the fields used by a specific Promoted Listings report type. Use the <b>report_type</b> path parameter to indicate metadata to retrieve.<br/><br/>This method does not use a request payload.<br/><br/><span class="tablenote"><b>Note:</b> The reporting of some data related to sales and ad-fees may require a 72-hour (<b>maximum</b>) adjustment period which is often referred to as the <i>Reconciliation Period</i>. Such adjustment periods should, on average, be minimal. However, at any given time, the <b>payments</b> tab may be used to view those amounts that have actually been charged.</span>
#
# GET /ad_report_metadata/{report_type}
# operationId: getReportMetadataForReportType
export def "ad-report-metadata get" [
  report_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dimensionMetadata: table<dataType: string, dimensionKey: string, dimensionKeyAnnotations: list>, maxNumberOfDimensionsToRequest: int, maxNumberOfMetricsToRequest: int, metricMetadata: table<dataType: string, metricKey: string>, reportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_report_metadata/($report_type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method returns information on all the existing report tasks related to a seller. <p>Use the <b>report_task_statuses</b> query parameter to control which reports to return. You can paginate the result set by specifying a <b>limit</b>, which dictates how many report tasks to return on each page of the response. Use the <b>offset</b> parameter to specify how many reports to skip in the result set before returning the first result.</p>
#
# GET /ad_report_task
# operationId: getReportTasks
export def "ad-report-task list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Specifies the maximum number of report tasks to return on a page in the paginated response.  <p><b>Default:</b> 10<br><b>Maximum:</b> 500</p>
  --offset: string # Specifies the number of report tasks to skip in the result set before returning the first report in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the reports returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the response contains the first 10 reports from the complete list of report tasks retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>10</code>, the first page of the response contains reports 11-20 from the complete result set.</p> <b>Default:</b> 0
  --report-task-statuses: string # This parameter filters the returned report tasks by their status. Supply a comma-separated list of the report statuses you want returned. The results are filtered to include only the report statuses you specify.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> The results might not include some report tasks if other search conditions exclude them.</span><br /><br /><b>Valid values: </b> <br>&nbsp;&nbsp;&nbsp;<code>PENDING</code> <br>&nbsp;&nbsp;&nbsp;<code>SUCCESS</code> <br>&nbsp;&nbsp;&nbsp;<code>FAILED</code>
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, reportTasks: table<campaignIds: list, dateFrom: string, dateTo: string, dimensions: list, fundingModels: list, inventoryReferences: list, listingIds: list, marketplaceId: string, metricKeys: list, reportExpirationDate: string, reportFormat: string, reportHref: string, reportId: string, reportName: string, reportTaskCompletionDate: string, reportTaskCreationDate: string, reportTaskExpectedCompletionDate: string, reportTaskId: string, reportTaskStatus: string, reportTaskStatusMessage: string, reportType: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "report_task_statuses" $report_task_statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_report_task" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> Using multiple funding models in one report is deprecated. If multiple funding models are used, a Warning will be returned in a header. This functionality will be decommissioned on April 3, 2023. See <a href="/develop/apis/api-deprecation-status">API Deprecation Status</a> for details.</span><br /><br />This method creates a <i>report task</i>, which generates a Promoted Listings report based on the values specified in the call.<br /><br />The report is generated based on the criteria you specify, including the report type, the report's dimensions and metrics, the report's start and end dates, the listings to include in the report, and more. <i>Metrics </i>are the quantitative measurements in the report while <i>dimensions</i> specify the attributes of the data included in the reports.<br /><br />When creating a report task, you can specify the items you want included in the report. The items you specify, using either <b>listingId</b> or <b>inventoryReference</b> values, must be in a Promoted Listings campaign for them to be included in the report.<br /><br />For details on the required and optional fields for each report type, see <a href="/api-docs/sell/static/marketing/pl-reports.html">Promoted Listings reporting</a>.<br /><br />This call returns the URL to the report task in the <b>Location</b> response header, and the URL includes the report-task ID.<br /><br />Reports often take time to generate and it's common for this call to return an HTTP status of <code>202</code>, which indicates the report is being generated. Call <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks">getReportTasks</a> (or <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTask">getReportTask</a> with the report-task ID) to determine the status of a Promoted Listings report. When a report is complete, eBay sets its status to <b>SUCCESS</b> and you can download it using the URL returned in the <b>reportHref</b> field of the <b>getReportTask</b> call. Report files are tab-separated value gzip files with a file extension of <code>.tsv.gz</code>.<br/><br/><span class="tablenote"><b>Note:</b> The reporting of some data related to sales and ad-fees may require a 72-hour (<b>maximum</b>) adjustment period which is often referred to as the <i>Reconciliation Period</i>. Such adjustment periods should, on average, be minimal. However, at any given time, the <b>payments</b> tab may be used to view those amounts that have actually been charged.</span><br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> This call fails if you don't submit all the required fields for the specified report type. Fields not supported by the specified report type are ignored. Call <a href="/api-docs/sell/marketing/resources/ad_report_metadata/methods/getReportMetadata">getReportMetadata</a> to retrieve a list of the fields you need to configure for each Promoted Listings report type.</span>
#
# POST /ad_report_task
# operationId: createReportTask
# --dimensions item shape: {annotationKeys?: list, dimensionKey?: string}
# --inventoryReferences item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-report-task createReportTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalRecords: list # A list of additional records that shall be included in the report, such as non-performing data.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> Additional records are only applicable to Promoted Listings Advanced (PLA) campaigns that use the Cost Per Click (CPC) funding model.</span><br /><b>Valid Value:</b> <code>NON_PERFORMING_DATA</code>
  --campaignIds: list # A list of campaign IDs to be included in the report task. Call <b>getCampaigns</b> to get a list of the current campaign IDs for a seller.<br /><br />For Promoted Listings Standard (PLS) sellers, this field is required if the <b>reportType</b> is set to <code>CAMPAIGN_PERFORMANCE_REPORT</code> or <code>CAMPAIGN_PERFORMANCE_SUMMARY_REPORT</code>.<br /><br />For Promoted Listings Advanced (PLA) sellers, leave this request field blank to retrieve the details for all campaigns associated with your account, or specify the campaign IDs for which you would like to retrieve the campaign-specific details.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> There is a maximum data limit that cannot be exceeded when generating reports. If this threshold is exceeded, the report will fail. Refer to <a href="/api-docs/sell/static/marketing/pl-reports.html#creation">Promoted Listings reporting</a> in the Selling Integration Guide for details.</span><br /><br /><b>Maximum:</b><ul><li>25 IDs for PLS</li><li>1,000 IDs for PLA</li></ul>
  --dateFrom: string # The date defining the start of the timespan covered by the report.<br /><br />Format the timestamp as an <a href="https://www.iso.org/iso-8601-date-and-time-format.html" title="https://www.iso.org" target="_blank">ISO 8601</a> string, which is based on the 24-hour Coordinated Universal Time (UTC) clock with local offset.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> The date specified cannot be a future date.</span><br /><br /><b>Format:</b> <code>[YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z</code><br /><br /><b>Example:</b> <code>2021-03-15T13:00:00-07:00</code>
  --dateTo: string # The date defining the end of the timespan covered by the report.<br /><br />As with the <b>dateFrom</b> field, format the timestamp as an <a href="https://www.iso.org/iso-8601-date-and-time-format.html" title="https://www.iso.org" target="_blank">ISO 8601</a> string.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> The date specified cannot be a future date. Additionally, the time specified must be a later time than that specified in the <b>dateFrom</b> field.</span><br /><br /><b>Format:</b> <code>[YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z</code><br /><br /><b>Example:</b> <code>2021-03-17T13:00:00-07:00</code>
  --dimensions: list # The list of the dimensions applied to the report.  <p>A dimension is an attribute to which the report data applies. For example, if you set <b>dimensionKey</b> to <code>campaign_id</code> in a Campaign Performance Report, the data will apply to the entire ad campaign. For information on the dimensions and how to specify them, see <a href="/api-docs/sell/static/marketing/pl-reports.html">Promoted Listings reporting</a>.</p> — item shape: {annotationKeys?: list, dimensionKey?: string}
  --fundingModels: list # The funding model for the campaign that shall be included in the report.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> The default funding model for Promoted Listings reports is <code>COST_PER_SALE</code>.</span><br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> Multiple value support for the <b>fundingModels</b> array has been deprecated. See <a href ="/develop/apis/api-deprecation-status ">API&nbsp;Deprecation&nbsp;Status</a> for information.</span><br /><br /><b>Valid Values:</b><ul><li><code>COST_PER_SALE</code></li><li><code>COST_PER_CLICK</code></li></ul><i>Required if</i> the campaign funding model is Cost Per Click (CPC).
  --inventoryReferences: list # You can use this field to supply an array of items to include in the report if you manage your inventory with the <a href="/api-docs/sell/inventory/resources/methods">Inventory API</a>.  <br><br>This field is mutually exclusive with the <b>listingIds</b> field; if you populate this field, <i>do not</i> populate the <b>listingIds</b> field.  <br><br>An inventory reference identifies an item in your inventory using a pair of values, where the <b>inventoryReferenceId</b> can be either a seller-defined <b>SKU</b> value or an <b>inventoryItemGroupKey</b>, where an <b>inventoryItemGroupKey</b> is seller-defined ID for an inventory item group (a multiple-variation listing). <br><br>Couple the <b>inventoryReferenceId</b> with an <b>inventoryReferenceType</b> identifier to fully identify an item in your inventory.  <br><br><b>Maximum: </b> 500 items <br><br><i>Required if </i> you do not supply an array of <b>listingId</b> values or if you set <b>reportType</b> to <code>INVENTORY_PERFORMANCE_REPORT</code>. — item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
  --listingIds: list # Use this field to supply an array of listing IDs you want to include in the report.<br><br>A listing ID is the eBay listing identifier that is generated when the listing is created. This field accepts listing ID values generated with both the Inventory API and the eBay Traditional APIs, such as the Trading and Finding APIs.<br><br><span class="tablenote"><span style="color:#FF0000"><strong>Important:</strong></span> This field is mutually exclusive with the <b>inventoryReferences</b> field; if you populate this field, <i>do not</i> populate the <b>inventoryReferences</b> field.</span><br /><br />For Promoted Listings Standard (PLS) sellers, this field is required if you do not supply an array of <b>inventoryReferences</b> values or if you set the <b>reportType</b> to <code>LISTING_PERFORMANCE_REPORT</code>.<br /><br />For Promoted Listings Advanced (PLA) sellers, leave this field blank to retrieve the details for all listings associated with the specified campaign IDs (or all campaigns associated with your account, if no campaign IDs are specified), or specify the listing IDs for which you would like to retrieve the listing-specific details.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> There is a maximum data limit that cannot be exceeded when generating reports. If this threshold is exceeded, the report will fail. Refer to <a href="/api-docs/sell/static/marketing/pl-reports.html#creation">Promoted Listings reporting</a> in the Selling Integration Guide for details.</span><br /><br /><b>Maximum:</b> 500 listings
  --marketplaceId: string # The ID for the eBay marketplace on which the report is based.<br /><br /><b>Maximum: </b> 1 For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --metricKeys: list # The list of metrics to be included in the report.  <p>Metrics are the quantitative measurements compiled into the report and the data returned is based on the specified dimension of the report. For example, if the dimension is <code>campaign</code>, the metrics for <b>number of sales</b> would be the number of sales in the campaign. However, if the dimension is <code>listing</code>, the <b>number of sales</b> represents the number of items sold in that listing.</p>  <p>For information on metric keys and how to set them, see <a href="/api-docs/sell/static/marketing/pl-reports.html">Promoted Listings reporting</a>.</p><b>Minimum: </b> 1
  --reportFormat: string # The file format of the report. Currently, the only supported format is <code>TSV_GZIP</code>, which is a gzip file with tab separated values. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/plr:ReportFormatEnum'>eBay API documentation</a>
  --reportType: string # The type of report to be generated, such as <code>ACCOUNT_PERFORMANCE_REPORT</code> or <code>CAMPAIGN_PERFORMANCE_REPORT</code>.<br/><br/><span class="tablenote"><b>Note:</b> INVENTORY_PERFORMANCE_REPORT is not currently available; availability date is pending.</span><br /><br /><b>Maximum:</b> 1 For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/plr:ReportTypeEnum'>eBay API documentation</a>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_report_task")
  let body = {additionalRecords: $additionalRecords, campaignIds: $campaignIds, dateFrom: $dateFrom, dateTo: $dateTo, dimensions: $dimensions, fundingModels: $fundingModels, inventoryReferences: $inventoryReferences, listingIds: $listingIds, marketplaceId: $marketplaceId, metricKeys: $metricKeys, reportFormat: $reportFormat, reportType: $reportType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This call deletes the report task specified by the <b>report_task_id</b> path parameter. This method also deletes any reports generated by the report task.  <p>Report task IDs are generated by eBay when you call <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask">createReportTask</a>. Get a complete list of a seller's report-task IDs by calling <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks">getReportTasks</a>.</p>
#
# DELETE /ad_report_task/{report_task_id}
# operationId: deleteReportTask
export def "ad-report-task delete" [
  report_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_report_task/($report_task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This call returns the details of a specific Promoted Listings report task, as specified by the <b>report_task_id</b> path parameter. <p>The report task includes the report criteria (such as the report dimensions, metrics, and included listing) and the report-generation rules (such as starting and ending dates for the specified report task).</p>  <p>Report-task IDs are generated by eBay when you call <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask">createReportTask</a>. Get a complete list of a seller's report-task IDs by calling <a href="/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks">getReportTasks</a>.</p>
#
# GET /ad_report_task/{report_task_id}
# operationId: getReportTask
export def "ad-report-task get" [
  report_task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<campaignIds: list<string>, dateFrom: string, dateTo: string, dimensions: table<annotationKeys: list, dimensionKey: string>, fundingModels: list<string>, inventoryReferences: table<inventoryReferenceId: string, inventoryReferenceType: string>, listingIds: list<string>, marketplaceId: string, metricKeys: list<string>, reportExpirationDate: string, reportFormat: string, reportHref: string, reportId: string, reportName: string, reportTaskCompletionDate: string, reportTaskCreationDate: string, reportTaskExpectedCompletionDate: string, reportTaskId: string, reportTaskStatus: string, reportTaskStatusMessage: string, reportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ad_report_task/($report_task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method adds negative keywords, in bulk, to an existing ad group in a PLA campaign that uses the Cost Per Click (CPC) funding model.<br /><br />Specify the <b>campaignId</b> and <b>adGroupId</b> in the request body, along with the <b>negativeKeywordText</b> and <b>negativeKeywordMatchType</b>.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /bulk_create_negative_keyword
# operationId: bulkCreateNegativeKeyword
# --requests item shape: {adGroupId?: string, campaignId?: string, negativeKeywordMatchType?: string, negativeKeywordText?: string}
export def "bulk-create-negative-keyword bulkCreateNegativeKeyword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # This array is used to pass in multiple negative keywords for one or more ad groups that belong to a campaign that uses the Cost Per Click (CPC) funding model. — item shape: {adGroupId?: string, campaignId?: string, negativeKeywordMatchType?: string, negativeKeywordText?: string}
]: any -> record<responses: table<adGroupId: string, campaignId: string, errors: list, href: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordText: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_create_negative_keyword")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates the statuses of existing negative keywords, in bulk.<br /><br />Specify the <b>negativeKeywordId</b> and <b>negativeKeywordStatus</b> in the request body.
#
# POST /bulk_update_negative_keyword
# operationId: bulkUpdateNegativeKeyword
# --requests item shape: {negativeKeywordId?: string, negativeKeywordStatus?: string}
export def "bulk-update-negative-keyword bulkUpdateNegativeKeyword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requests: list # An array to update the statuses of one or more existing negative keywords. — item shape: {negativeKeywordId?: string, negativeKeywordStatus?: string}
]: any -> record<responses: table<errors: list, negativeKeywordId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_update_negative_keyword")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method creates an <b>item price markdown promotion</b> (know simply as a "markdown promotion") where a discount amount is applied directly to the items included the promotion. Discounts can be specified as either a monetary amount or a percentage off the standard sales price. eBay highlights promoted items by placing teasers for the items throughout the online sales flows.  <p>Unlike an <a href="/api-docs/sell/marketing/resources/item_promotion/methods/createItemPromotion">item promotion</a>, a markdown promotion does not require the buyer meet a "threshold" before the offer takes effect. With markdown promotions, all the buyer needs to do is purchase the item to receive the promotion benefit.</p>  <p class="tablenote"><b>Important:</b> There are some restrictions for which listings are available for price markdown promotions. For details, see <a href="/api-docs/sell/marketing/static/overview.html#PM-requirements">Promotions Manager requirements and restrictions</a>. <br><br>In addition, we recommend you list items at competitive prices before including them in your markdown promotions. For an extensive list of pricing recommendations, see the <b>Growth</b> tab in Seller Hub.</p> <p>There are two ways to add items to markdown promotions:</p> <ul><li><b>Key-based promotions</b> select items using either the listing IDs or inventory reference IDs of the items you want to promote. Note that if you use inventory reference IDs, you must specify both the <b>inventoryReferenceId</b> and the associated <b>inventoryReferenceType</b> of the item(s) you want to include the promotion.</li>  <li><b>Rule-based promotions</b> select items using a list of eBay category IDs or seller Store category IDs. Rules can further constrain items in a promotion by minimum and maximum prices, brands, and item conditions.</li></ul>  <p>New promotions must be created in either a <code>DRAFT</code> or a <code>SCHEDULED</code> state. Use the DRAFT state when you are initially creating a promotion and you want to be sure it's correctly configured before scheduling it to run. When you create a promotion, the promotion ID is returned in the <b>Location</b> response header. Use this ID to reference the promotion in subsequent requests (such as to schedule a promotion that's in a DRAFT state).</p>  <p class="tablenote"><b>Tip:</b> Refer to <a href="/api-docs/sell/static/marketing/promotions-manager.html">Promotions Manager</a> in the <i>Selling Integration Guide</i> for details and examples showing how to create and manage seller promotions.</p>  <p>Markdown promotions are available on all eBay marketplaces. For more information, see <a href="/api-docs/sell/marketing/static/overview.html#PM-requirements">Promotions Manager requirements and restrictions</a>.</p>
#
# POST /item_price_markdown
# operationId: createItemPriceMarkdownPromotion
# --selectedInventoryDiscounts item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
export def "item-price-markdown createItemPriceMarkdownPromotion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applyFreeShipping: string@bool-completer # If set to <code>true</code>, free shipping is applied to the first shipping service specified for the item. The first domestic shipping option is set to "free shipping," regardless if the shipping <b>optionType</b> for that service is set to <code>FLAT_RATE</code>, <code>CALCULATED</code>, or <code>NOT_SPECIFIED</code> (freight). This flag essentially adds free shipping as a promotional bonus. <br><br><b>Default:</b> <code>false</code>
  --autoSelectFutureInventory: string@bool-completer # If set to <code>true</code>, eBay will automatically add inventory items to the markdown promotion if they meet the <b>selectedInventoryDiscounts</b> criteria specified for the markdown promotion.  <br><br><b>Default:</b> <code>false</code>
  --blockPriceIncreaseInItemRevision: string@bool-completer # If set to <code>true</code>, price increases (including removing the free shipping flag) are blocked and an error message is returned if a seller attempts to adjust the price of an item that's partaking in this markdown promotion. If set to <code>false</code>, an item is dropped from the markdown promotion if the seller adjusts the price.  <br><br><b>Default:</b> <code>false</code>
  --description: string # This field is required if you are configuring an MARKDOWN_SALE promotion. <br><br>This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." A tag line appears under the "offer-type text" that is generated for the promotion. The text is displayed on the offer tile that is shown on the seller's <b>All Offers</b> page and on the event page for the promotion.  <p class="tablenote"><b>Note:</b> Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. This text is not editable by the seller&mdash;it's derived from the settings in the <b>discountRules</b> and <b>discountSpecification</b> fields&mdash;and can be, for example, "20% off".</p>  <br><b>Maximum length:</b> 50
  --endDate: string # The date and time the promotion ends, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). The value supplied for <b>endDate</b> must be at least 24 hours after the value supplied for the <b>startDate</b> of the markdown promotion.<br><br>For display purposes, convert this time into the local time of the seller.  <br><br><b>Max value:</b><ul><li><code>14</code> days for the AT, CH, DE, ES, FR, IE, IT, and UK, marketplaces.</li>  <li><code>45</code> days for all other marketplaces.</li></ul>
  --marketplaceId: string # The eBay marketplace ID of the site where the markdown promotion is hosted. Markdown promotions are supported on all eBay marketplaces. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # The seller-defined name or 'title' of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows.  <br><br><b>Maximum length:</b> 90
  --priority: string # This field is ignored in markdown promotions. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionPriorityEnum'>eBay API documentation</a>
  --promotionImageUrl: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's <b>All Offers</b> page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotionStatus: string # The current status of the promotion. When creating a new promotion, you must set this value to either <code>DRAFT</code> or <code>SCHEDULED</code>.  <br><br>Note that you must set this value to <code>SCHEDULED</code> when you update a <b>RUNNING</b> promotion. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionStatusEnum'>eBay API documentation</a>
  --selectedInventoryDiscounts: list # A list that defines the sets of selected items for the markdown promotion and the discount specified for promotion. — item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
  --startDate: string # The date and time the promotion starts in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item_price_markdown")
  let body = {applyFreeShipping: $applyFreeShipping, autoSelectFutureInventory: $autoSelectFutureInventory, blockPriceIncreaseInItemRevision: $blockPriceIncreaseInItemRevision, description: $description, endDate: $endDate, marketplaceId: $marketplaceId, name: $name, priority: $priority, promotionImageUrl: $promotionImageUrl, promotionStatus: $promotionStatus, selectedInventoryDiscounts: $selectedInventoryDiscounts, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method deletes the item price markdown promotion specified by the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.  <br><br>You can delete any promotion with the exception of those that are currently active (RUNNING). To end a running promotion, call <a href="/api-docs/sell/marketing/resources/item_price_markdown/methods/updateItemPriceMarkdownPromotion">updateItemPriceMarkdownPromotion</a> and adjust the <b>endDate</b> field as appropriate.
#
# DELETE /item_price_markdown/{promotion_id}
# operationId: deleteItemPriceMarkdownPromotion
export def "item-price-markdown delete" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_price_markdown/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method returns the complete details of the item price markdown promotion that's indicated by the <b>promotion_id</b> path parameter. <br><br>Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.
#
# GET /item_price_markdown/{promotion_id}
# operationId: getItemPriceMarkdownPromotion
export def "item-price-markdown get" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applyFreeShipping: bool, autoSelectFutureInventory: bool, blockPriceIncreaseInItemRevision: bool, description: string, endDate: string, marketplaceId: string, name: string, priority: string, promotionImageUrl: string, promotionStatus: string, selectedInventoryDiscounts: table<discountBenefit: record, discountId: string, inventoryCriterion: record, ruleOrder: int>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_price_markdown/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method updates the specified item price markdown promotion with the new configuration that you supply in the payload of the request. Specify the promotion you want to update using the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.  <br><br>When updating a promotion, supply all the fields that you used to configure the original promotion (and not just the fields you are updating). eBay replaces the specified promotion with the values you supply in the update request and if you don't pass a field that currently has a value, the update request fails.  <br><br>The parameters you are allowed to update with this request depend on the status of the promotion you're updating:  <ul><li>DRAFT or SCHEDULED promotions: You can update any of the parameters in these promotions that have not yet started to run, including the <b>discountRules</b>.</li> <li>RUNNING promotions: You can change the <b>endDate</b> and the item's inventory but you cannot change the promotional discount or the promotion's start date.</li> <li>ENDED promotions: Nothing can be changed.</li></ul>
#
# PUT /item_price_markdown/{promotion_id}
# operationId: updateItemPriceMarkdownPromotion
# --selectedInventoryDiscounts item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
export def "item-price-markdown updateItemPriceMarkdownPromotion" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applyFreeShipping: string@bool-completer # If set to <code>true</code>, free shipping is applied to the first shipping service specified for the item. The first domestic shipping option is set to "free shipping," regardless if the shipping <b>optionType</b> for that service is set to <code>FLAT_RATE</code>, <code>CALCULATED</code>, or <code>NOT_SPECIFIED</code> (freight). This flag essentially adds free shipping as a promotional bonus. <br><br><b>Default:</b> <code>false</code>
  --autoSelectFutureInventory: string@bool-completer # If set to <code>true</code>, eBay will automatically add inventory items to the markdown promotion if they meet the <b>selectedInventoryDiscounts</b> criteria specified for the markdown promotion.  <br><br><b>Default:</b> <code>false</code>
  --blockPriceIncreaseInItemRevision: string@bool-completer # If set to <code>true</code>, price increases (including removing the free shipping flag) are blocked and an error message is returned if a seller attempts to adjust the price of an item that's partaking in this markdown promotion. If set to <code>false</code>, an item is dropped from the markdown promotion if the seller adjusts the price.  <br><br><b>Default:</b> <code>false</code>
  --description: string # This field is required if you are configuring an MARKDOWN_SALE promotion. <br><br>This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." A tag line appears under the "offer-type text" that is generated for the promotion. The text is displayed on the offer tile that is shown on the seller's <b>All Offers</b> page and on the event page for the promotion.  <p class="tablenote"><b>Note:</b> Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. This text is not editable by the seller&mdash;it's derived from the settings in the <b>discountRules</b> and <b>discountSpecification</b> fields&mdash;and can be, for example, "20% off".</p>  <br><b>Maximum length:</b> 50
  --endDate: string # The date and time the promotion ends, in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). The value supplied for <b>endDate</b> must be at least 24 hours after the value supplied for the <b>startDate</b> of the markdown promotion.<br><br>For display purposes, convert this time into the local time of the seller.  <br><br><b>Max value:</b><ul><li><code>14</code> days for the AT, CH, DE, ES, FR, IE, IT, and UK, marketplaces.</li>  <li><code>45</code> days for all other marketplaces.</li></ul>
  --marketplaceId: string # The eBay marketplace ID of the site where the markdown promotion is hosted. Markdown promotions are supported on all eBay marketplaces. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # The seller-defined name or 'title' of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows.  <br><br><b>Maximum length:</b> 90
  --priority: string # This field is ignored in markdown promotions. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionPriorityEnum'>eBay API documentation</a>
  --promotionImageUrl: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's <b>All Offers</b> page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotionStatus: string # The current status of the promotion. When creating a new promotion, you must set this value to either <code>DRAFT</code> or <code>SCHEDULED</code>.  <br><br>Note that you must set this value to <code>SCHEDULED</code> when you update a <b>RUNNING</b> promotion. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionStatusEnum'>eBay API documentation</a>
  --selectedInventoryDiscounts: list # A list that defines the sets of selected items for the markdown promotion and the discount specified for promotion. — item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
  --startDate: string # The date and time the promotion starts in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_price_markdown/($promotion_id)")
  let body = {applyFreeShipping: $applyFreeShipping, autoSelectFutureInventory: $autoSelectFutureInventory, blockPriceIncreaseInItemRevision: $blockPriceIncreaseInItemRevision, description: $description, endDate: $endDate, marketplaceId: $marketplaceId, name: $name, priority: $priority, promotionImageUrl: $promotionImageUrl, promotionStatus: $promotionStatus, selectedInventoryDiscounts: $selectedInventoryDiscounts, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method creates an <b>item promotion</b>, where the buyer receives a discount when they meet the buying criteria that's set for the promotion. Known here as "threshold promotions", these promotions trigger when a threshold is met.  <p>eBay highlights promoted items by placing teasers for the promoted items throughout the online buyer flows.</p>  <p><i>Discounts</i> are specified as either a monetary amount or a percentage off the standard sales price of a listing, letting you offer deals such as "Buy 1 Get 1" and "Buy $50, get 20% off".</p> <p><i>Volume pricing</i> promotions increase the value of the discount as the buyer increases the quantity they purchase.</p> <p><i>Coded Coupons</i> provide unique codes that a buyer can use during checkout to receive a discount. The seller can specify the number of times a buyer can use the coupon and the maximum amount across all purchases that can be discounted using the coupon. The coupon code can also be made public (appearing on the seller's Offer page, search pages, the item listing, and the checkout page) or private (only on the seller's Offer page, but the seller can include the code in email and social media).</p> <p class="tablenote"><b>Note</b>: Coded Coupons are currently available in the US, UK, DE, FR, IT, ES, and AU marketplaces.</p><p>There are two ways to add items to a threshold promotion:</p>  <ul><li><b>Key-based promotions</b> select items using either the listing IDs or inventory reference IDs of the items you want to promote. Note that if you use inventory reference IDs, you must specify both the <b>inventoryReferenceId</b> and the associated <b>inventoryReferenceType</b> of the item(s) you want to include the promotion.</li> <li><b>Rule-based promotions</b> select items using a list of eBay category IDs or seller Store category IDs. Rules can further constrain items in a promotion by minimum and maximum prices, brands, and item conditions.</li></ul>  <p>You must create a new promotion in either a <code>DRAFT</code> or <code>SCHEDULED</code> state. Use the DRAFT state when you are initially creating a promotion and you want to be sure it's correctly configured before scheduling it to run. When you create a promotion, the promotion ID is returned in the <b>Location</b> response header. Use this ID to reference the promotion in subsequent requests.</p>  <p class="tablenote"><b>Tip:</b> Refer to the <a href="/api-docs/sell/static/marketing/promotions-manager.html">Selling Integration Guide</a> for details and examples showing how to create and manage threshold promotions using the Promotions Manager.</p>  <p>For information on the eBay marketplaces that support item promotions, see <a href="/api-docs/sell/marketing/static/overview.html#PM-requirements">Promotions Manager requirements and restrictions</a>.</p>
#
# POST /item_promotion
# operationId: createItemPromotion
# --budget shape: {currency?: string, value?: string}
# --couponConfiguration shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
# --discountRules item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
# --inventoryCriterion shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list, ruleCriteria?: record}
export def "item-promotion createItemPromotion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applyDiscountToSingleItemOnly: string@bool-completer # This flag is relevant in only when <b>promotionType</b> is set to <code>VOLUME_DISCOUNT</code>. For details on volume pricing promotions, see <a href="/api-docs/sell/static/marketing/pm-volume-discounts.html">Configuring volume pricing discounts</a>.  <br><br>If set to <code>true</code>, the discount is applied only when the buyer purchases multiple quantities of a single item in the promotion. Otherwise, the promotional discount applies to multiple quantities of any items in the promotion. Different variations of a multi-variation item are considered to be the same item. Note that this flag is not relevant if the <b>inventoryCriterion</b> container identifies a single listing ID for the promotion.
  --budget: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --couponConfiguration: record # This container defines a coded coupon promotion. It is required if the promotion type is CODED_COUPON. — shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
  --description: string # This is the seller-defined "tag line" for the offer, such as "Save on designer shoes."  <br><br>The tag line appears under the "offer-type text" that is generated for the promotion and is displayed on the offer tile that's shown on the seller's <b>All Offers</b> page, and on the event page for the promotion.  <p class="tablenote"><b>Note:</b> Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. The offer-type text is not editable by the seller&mdash;it's derived from the settings in the <b>discountRules</b> and <b>discountSpecification</b> fields&mdash;and can be, for example, "Extra 20% off when you buy 3+".</p>  <br><b>Maximum length:</b> 50 <br><br><i>Required if</i> you are configuring CODED_COUPON, ORDER_DISCOUNT, or MARKDOWN_SALE promotions (and not valid for VOLUME_DISCOUNT promotions).
  --discountRules: list # This container defines a promotion using the following two required fields: <ul><li><b>discountBenefit</b> &ndash; Defines a discount as either a monetary amount or a percentage that is subtracted from the sales price of an item, a set of items, or an order.</li>  <li><b>discountSpecification</b> &ndash; Defines a set of rules that determine when the promotion is applied.</li></ul> <p class="tablenote"><b>Note:</b> For volume pricing, you must specify at least two and not more than four <b>discountBenefit</b>/<b>discountSpecification</b> pairs. In addition, you must define each set of rules with a <b>ruleOrder</b> value that corresponds with the order of volume discounts you present.</p>  <p><b>Tip:</b> Refer to <a href="/api-docs/sell/static/marketing/pm-specifying-discounts.html">Specifying item promotion discounts</a> for information and examples on how to combine <b>discountBenefit</b> and <b>discountSpecification</b> to create different types of promotions.</p> — item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
  --endDate: string # The date and time the promotion ends in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
  --inventoryCriterion: record # This type defines either the selections rules or the list of listing IDs for the promotion. The "listing IDs" are are either the seller's item IDs or the eBay listing IDs. — shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list, ruleCriteria?: record}
  --marketplaceId: string # The eBay marketplace ID of the site where the threshold promotion is hosted. Threshold promotions are currently supported on a limited number of eBay marketplaces.  <p><b>Valid values:</b></p>  <ul><li><code>EBAY_AU</code> = Australia</li> <li><code>EBAY_DE</code> = Germany</li> <li><code>EBAY_ES</code> = Spain</li> <li><code>EBAY_FR</code> = France</li> <li><code>EBAY_GB</code> = Great Britain</li> <li><code>EBAY_IT</code> = Italy</li> <li><code>EBAY_US</code> = United States</li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # The seller-defined name or "title" of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows.  <br><br><b>Maximum length:</b> 90
  --priority: string # Applicable for only <b>ORDER_DISCOUNT</b> promotions, this field indicates the precedence of the promotion, which is used to determine the position of a promotion on the seller's <b>All Offers</b> page. If an item is associated with multiple promotions, the promotion with the higher priority takes precedence. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionPriorityEnum'>eBay API documentation</a>
  --promotionImageUrl: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, and not valid for VOLUME_DISCOUNT promotions.  <br><br>Populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's <b>All Offers</b> page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotionStatus: string # The current status of the promotion. When creating a new promotion, this value must be set to either <code>DRAFT</code> or <code>SCHEDULED</code>.  <br><br>Note that you must set this value to <code>SCHEDULED</code> when you update a <b>RUNNING</b> promotion. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionStatusEnum'>eBay API documentation</a>
  --promotionType: string # Use this field to specify the type of the promotion you are creating. <p>The supported types are:</p> <ul><li><code>CODED_COUPON</code> &ndash; A coupon code promotion set with <b>createItemPromotion</b>.</li> <li><code>MARKDOWN_SALE</code> &ndash; A markdown promotion set with <b>createItemPriceMarkdownPromotion</b>.</li> <li><code>ORDER_DISCOUNT</code> &ndash; A threshold promotion set with <b>createItemPromotion</b>.</li> <li><code>VOLUME_DISCOUNT</code> &ndash; A volume pricing promotion set with <b>createItemPromotion</b>.</li></ul> <p>See the <a href="/api-docs/sell/static/marketing/promotions-manager.html" target="_blank">Promotions Manager</a> documentation for details.</p> <p><i>Required if </i> you are creating a volume pricing promotion (<code>VOLUME_DISCOUNT</code>).</p> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionTypeEnum'>eBay API documentation</a>
  --startDate: string # The date and time the promotion starts in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
]: any -> record<warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item_promotion")
  let body = {applyDiscountToSingleItemOnly: $applyDiscountToSingleItemOnly, budget: $budget, couponConfiguration: $couponConfiguration, description: $description, discountRules: $discountRules, endDate: $endDate, inventoryCriterion: $inventoryCriterion, marketplaceId: $marketplaceId, name: $name, priority: $priority, promotionImageUrl: $promotionImageUrl, promotionStatus: $promotionStatus, promotionType: $promotionType, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method deletes the threshold promotion specified by the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.  <br><br>You can delete any promotion with the exception of those that are currently active (RUNNING). To end a running threshold promotion, call <a href="/api-docs/sell/marketing/resources/item_promotion/methods/updateItemPromotion">updateItemPromotion</a> and adjust the <b>endDate</b> field as appropriate.
#
# DELETE /item_promotion/{promotion_id}
# operationId: deleteItemPromotion
export def "item-promotion delete" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_promotion/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method returns the complete details of the threshold promotion specified by the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.
#
# GET /item_promotion/{promotion_id}
# operationId: getItemPromotion
export def "item-promotion get" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<applyDiscountToSingleItemOnly: bool, budget: record<currency: string, value: string>, couponConfiguration: record<couponCode: string, couponType: string, maxCouponRedemptionPerUser: int>, description: string, discountRules: table<discountBenefit: record, discountSpecification: record, maxDiscountAmount: record, ruleOrder: int>, endDate: string, inventoryCriterion: record<inventoryCriterionType: string, inventoryItems: list<record>, listingIds: list<string>, ruleCriteria: record<excludeInventoryItems: list, excludeListingIds: list, markupInventoryItems: list, markupListingIds: list, selectionRules: list>>, marketplaceId: string, name: string, priority: string, promotionId: string, promotionImageUrl: string, promotionStatus: string, promotionType: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_promotion/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method updates the specified threshold promotion with the new configuration that you supply in the request. Indicate the promotion you want to update using the <b>promotion_id</b> path parameter.  <p>Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.</p>  <p>When updating a promotion, supply all the fields that you used to configure the original promotion (and not just the fields you are updating). eBay replaces the specified promotion with the values you supply in the update request and if you don't pass a field that currently has a value, the update request will fail.</p>  <p>The parameters you are allowed to update with this request depend on the status of the promotion you're updating:  <ul><li>DRAFT or SCHEDULED promotions: You can update any of the parameters in these promotions that have not yet started to run, including the <b>discountRules</b>.</li> <li>RUNNING or PAUSED promotions: You can change the <b>endDate</b> and the item's inventory but you cannot change the promotional discount or the promotion's start date.</li> <li>ENDED promotions: Nothing can be changed.</li></ul> <p class="tablenote"><b>Tip:</b> When updating a <code>RUNNING</code> or <code>PAUSED</code> promotion, set the <b>status</b> field to <code>SCHEDULED</code> for the update request. When the promotion is updated, the previous status (either <code>RUNNING</code> or <code>PAUSED</code>) is retained.</p>
#
# PUT /item_promotion/{promotion_id}
# operationId: updateItemPromotion
# --budget shape: {currency?: string, value?: string}
# --couponConfiguration shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
# --discountRules item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
# --inventoryCriterion shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list, ruleCriteria?: record}
export def "item-promotion updateItemPromotion" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applyDiscountToSingleItemOnly: string@bool-completer # This flag is relevant in only when <b>promotionType</b> is set to <code>VOLUME_DISCOUNT</code>. For details on volume pricing promotions, see <a href="/api-docs/sell/static/marketing/pm-volume-discounts.html">Configuring volume pricing discounts</a>.  <br><br>If set to <code>true</code>, the discount is applied only when the buyer purchases multiple quantities of a single item in the promotion. Otherwise, the promotional discount applies to multiple quantities of any items in the promotion. Different variations of a multi-variation item are considered to be the same item. Note that this flag is not relevant if the <b>inventoryCriterion</b> container identifies a single listing ID for the promotion.
  --budget: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --couponConfiguration: record # This container defines a coded coupon promotion. It is required if the promotion type is CODED_COUPON. — shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
  --description: string # This is the seller-defined "tag line" for the offer, such as "Save on designer shoes."  <br><br>The tag line appears under the "offer-type text" that is generated for the promotion and is displayed on the offer tile that's shown on the seller's <b>All Offers</b> page, and on the event page for the promotion.  <p class="tablenote"><b>Note:</b> Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. The offer-type text is not editable by the seller&mdash;it's derived from the settings in the <b>discountRules</b> and <b>discountSpecification</b> fields&mdash;and can be, for example, "Extra 20% off when you buy 3+".</p>  <br><b>Maximum length:</b> 50 <br><br><i>Required if</i> you are configuring CODED_COUPON, ORDER_DISCOUNT, or MARKDOWN_SALE promotions (and not valid for VOLUME_DISCOUNT promotions).
  --discountRules: list # This container defines a promotion using the following two required fields: <ul><li><b>discountBenefit</b> &ndash; Defines a discount as either a monetary amount or a percentage that is subtracted from the sales price of an item, a set of items, or an order.</li>  <li><b>discountSpecification</b> &ndash; Defines a set of rules that determine when the promotion is applied.</li></ul> <p class="tablenote"><b>Note:</b> For volume pricing, you must specify at least two and not more than four <b>discountBenefit</b>/<b>discountSpecification</b> pairs. In addition, you must define each set of rules with a <b>ruleOrder</b> value that corresponds with the order of volume discounts you present.</p>  <p><b>Tip:</b> Refer to <a href="/api-docs/sell/static/marketing/pm-specifying-discounts.html">Specifying item promotion discounts</a> for information and examples on how to combine <b>discountBenefit</b> and <b>discountSpecification</b> to create different types of promotions.</p> — item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
  --endDate: string # The date and time the promotion ends in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
  --inventoryCriterion: record # This type defines either the selections rules or the list of listing IDs for the promotion. The "listing IDs" are are either the seller's item IDs or the eBay listing IDs. — shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list, ruleCriteria?: record}
  --marketplaceId: string # The eBay marketplace ID of the site where the threshold promotion is hosted. Threshold promotions are currently supported on a limited number of eBay marketplaces.  <p><b>Valid values:</b></p>  <ul><li><code>EBAY_AU</code> = Australia</li> <li><code>EBAY_DE</code> = Germany</li> <li><code>EBAY_ES</code> = Spain</li> <li><code>EBAY_FR</code> = France</li> <li><code>EBAY_GB</code> = Great Britain</li> <li><code>EBAY_IT</code> = Italy</li> <li><code>EBAY_US</code> = United States</li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/ba:MarketplaceIdEnum'>eBay API documentation</a>
  --name: string # The seller-defined name or "title" of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows.  <br><br><b>Maximum length:</b> 90
  --priority: string # Applicable for only <b>ORDER_DISCOUNT</b> promotions, this field indicates the precedence of the promotion, which is used to determine the position of a promotion on the seller's <b>All Offers</b> page. If an item is associated with multiple promotions, the promotion with the higher priority takes precedence. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionPriorityEnum'>eBay API documentation</a>
  --promotionImageUrl: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, and not valid for VOLUME_DISCOUNT promotions.  <br><br>Populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's <b>All Offers</b> page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotionStatus: string # The current status of the promotion. When creating a new promotion, this value must be set to either <code>DRAFT</code> or <code>SCHEDULED</code>.  <br><br>Note that you must set this value to <code>SCHEDULED</code> when you update a <b>RUNNING</b> promotion. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionStatusEnum'>eBay API documentation</a>
  --promotionType: string # Use this field to specify the type of the promotion you are creating. <p>The supported types are:</p> <ul><li><code>CODED_COUPON</code> &ndash; A coupon code promotion set with <b>createItemPromotion</b>.</li> <li><code>MARKDOWN_SALE</code> &ndash; A markdown promotion set with <b>createItemPriceMarkdownPromotion</b>.</li> <li><code>ORDER_DISCOUNT</code> &ndash; A threshold promotion set with <b>createItemPromotion</b>.</li> <li><code>VOLUME_DISCOUNT</code> &ndash; A volume pricing promotion set with <b>createItemPromotion</b>.</li></ul> <p>See the <a href="/api-docs/sell/static/marketing/promotions-manager.html" target="_blank">Promotions Manager</a> documentation for details.</p> <p><i>Required if </i> you are creating a volume pricing promotion (<code>VOLUME_DISCOUNT</code>).</p> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/sme:PromotionTypeEnum'>eBay API documentation</a>
  --startDate: string # The date and time the promotion starts in UTC format (<code>yyyy-MM-ddThh:mm:ssZ</code>). For display purposes, convert this time into the local time of the seller.
]: any -> record<warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/item_promotion/($promotion_id)")
  let body = {applyDiscountToSingleItemOnly: $applyDiscountToSingleItemOnly, budget: $budget, couponConfiguration: $couponConfiguration, description: $description, discountRules: $discountRules, endDate: $endDate, inventoryCriterion: $inventoryCriterion, marketplaceId: $marketplaceId, name: $name, priority: $priority, promotionImageUrl: $promotionImageUrl, promotionStatus: $promotionStatus, promotionType: $promotionType, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method can be used to retrieve all of the negative keywords for ad groups in PLA campaigns that use the Cost Per Click (CPC) funding model.<br /><br />The results can be filtered using the <b>campaign_ids</b>, <b>ad_group_ids</b>, and <b>negative_keyword_status</b> query parameters.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a seller.
#
# GET /negative_keyword
# operationId: getNegativeKeywords
export def "negative-keyword list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ad-group-ids: string # A comma-separated list of ad group IDs.<br /><br />This query parameter is used if the seller wants to retrieve the negative keywords from one or more specific ad groups. The results might not include these ad group IDs if other search conditions exclude them.<br /><br /><span class="tablenote"><b>Note:</b>You can call the <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> method to retrieve the ad group IDs for a seller.</span><br /><br /><i>Required if</i> the search results must be filtered to include negative keywords created at the ad group level.
  --campaign-ids: string # A unique eBay-assigned ID for an ad campaign that is generated when a campaign is created.<br /><br />This query parameter is used if the seller wants to retrieve the negative keywords from a specific campaign. The results might not include these campaign IDs if other search conditions exclude them.<br /><br /><span class="tablenote"><b>Note:</b> Currently, only one campaign ID value is supported for each request.</span>
  --limit: string # The number of results, from the current result set, to be returned in a single page.
  --negative-keyword-status: string # A comma-separated list of negative keyword statuses.<br /><br />This query parameter is used if the seller wants to filter the search results based on one or more negative keyword statuses.
  --offset: string # The number of results that will be skipped in the result set. This is used with the <b>limit</b> field to control the pagination of the output.<br /><br />For example, if the <b>offset</b> is set to <code>0</code> and the <b>limit</b> is set to <code>10</code>, the method will retrieve items 1 through 10 from the list of items returned. If the <b>offset</b> is set to <code>10</code> and the <b>limit</b> is set to <code>10</code>, the method will retrieve items 11 through 20 from the list of items returned.
]: nothing -> record<href: string, limit: int, negativeKeywords: table<adGroupId: string, campaignId: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordStatus: string, negativeKeywordText: string>, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "campaign_ids" $campaign_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "negative_keyword_status" $negative_keyword_status "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/negative_keyword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method adds a negative keyword to an existing ad group in a PLA campaign that uses the Cost Per Click (CPC) funding model.<br /><br />Specify the <b>campaignId</b> and <b>adGroupId</b> in the request body, along with the <b>negativeKeywordText</b> and <b>negativeKeywordMatchType</b>.<br /><br />Call the <a href="/api-docs/sell/marketing/resources/campaign/methods/getCampaigns">getCampaigns</a> method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /negative_keyword
# operationId: createNegativeKeyword
export def "negative-keyword createNegativeKeyword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adGroupId: string # This adGroupId is created when an ad group is first created and associated with a campaign. This is the ad group to which the corresponding negative keyword will be added.<br /><br /><span class="tablenote"><b>Note:</b> You can call the  <a href="/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups">getAdGroups</a> method to retrieve the ad group IDs for a seller.</span><br /><br /><i>Required if</i> the negative keyword is being created at the ad group level.
  --campaignId: string # A unique eBay-assigned ID for a campaign. This ID is generated when a campaign is created.<br /><br /><i>Required if</i> the negative keyword is being created at the ad group level.
  --negativeKeywordMatchType: string # A field that defines the match type for the negative keyword.<br /><br /><span class="tablenote"><span style="color:#004680"><strong>Note:</strong></span> Broad matching of negative keywords is not currently supported.</span><br /><b>Valid Values:</b><ul><li><code>EXACT</code></li><li><code>PHRASE</code></li></ul> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:NegativeKeywordMatchTypeEnum'>eBay API documentation</a>
  --negativeKeywordText: string # The negative keyword text.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/negative_keyword")
  let body = {adGroupId: $adGroupId, campaignId: $campaignId, negativeKeywordMatchType: $negativeKeywordMatchType, negativeKeywordText: $negativeKeywordText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method retrieves details on a specific negative keyword.<br /><br />In the request, specify the <b>negative_keyword_id</b> as a path parameter.
#
# GET /negative_keyword/{negative_keyword_id}
# operationId: getNegativeKeyword
export def "negative-keyword get" [
  negative_keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<adGroupId: string, campaignId: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordStatus: string, negativeKeywordText: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/negative_keyword/($negative_keyword_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# <span class="tablenote"><b>Note:</b> This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to <a href="/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests " target="_blank "> Promoted Listings Advanced Access Requests</a> in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the <a href="/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility " target="_blank ">getAdvertisingEligibility</a> method in Account API.</span><br />This method updates the status of an existing negative keyword.<br /><br />Specify the <b>negative_keyword_id</b> as a path parameter, and specify the <b>negativeKeywordStatus</b> in the request body.
#
# PUT /negative_keyword/{negative_keyword_id}
# operationId: updateNegativeKeyword
export def "negative-keyword updateNegativeKeyword" [
  negative_keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --negativeKeywordStatus: string # A field that defines the status of the negative keyword. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/marketing/types/pls:NegativeKeywordStatusEnum'>eBay API documentation</a>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/negative_keyword/($negative_keyword_id)")
  let body = {negativeKeywordStatus: $negativeKeywordStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method returns a list of a seller's undeleted promotions. <p>The call returns up to 200 currently-available promotions on the specified marketplace. While the response body does not include the promotion's <b>discountRules</b> or <b>inventoryCriterion</b> containers, it does include the <b>promotionHref</b> (which you can use to retrieve the complete details of the promotion).</p>  <p>Use query parameters to sort and filter the results by the number of promotions to return, the promotion state or type, and the eBay marketplace. You can also supply keywords to limit the response to the promotions that contain that keywords in the title of the promotion.</p> <p><b>Maximum returned:</b> 200</p>
#
# GET /promotion
# operationId: getPromotions
export def "promotion get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set.  <br><br><b>Default:</b> 200 <br><b>Maximum:</b> 200
  --marketplace-id: string # The eBay marketplace ID of the site where the promotion is hosted.  <p><b>Valid values:</b></p>  <ul><li><code>EBAY_AU</code> = Australia</li> <li><code>EBAY_DE</code> = Germany</li> <li><code>EBAY_ES</code> = Spain</li> <li><code>EBAY_FR</code> = France</li> <li><code>EBAY_GB</code> = Great Britain</li> <li><code>EBAY_IT</code> = Italy</li> <li><code>EBAY_US</code> = United States</li></ul>
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
  --promotion-status: string # Specifies the promotion state by which you want to filter the results. The response contains only those promotions that match the state you specify.  <br><br><b>Valid values:</b> <ul><li><code>DRAFT</code></li> <li><code>SCHEDULED</code></li> <li><code>RUNNING</code></li> <li><code>PAUSED</code></li> <li><code>ENDED</code></li></ul><b>Maximum number of input values:</b> 1
  --promotion-type: string # Filters the returned promotions based on their campaign promotion type. Specify one of the following values to indicate the promotion type you want returned: <ul><li><code>CODED_COUPON</code> &ndash; A coupon code promotion set with <b>createItemPromotion</b>.</li> <li><code>MARKDOWN_SALE</code> &ndash; A markdown promotion set with <b>createItemPriceMarkdownPromotion</b>.</li> <li><code>ORDER_DISCOUNT</code> &ndash; A threshold promotion set with <b>createItemPromotion</b>.</li> <li><code>VOLUME_DISCOUNT</code> &ndash; A volume pricing promotion set with <b>createItemPromotion</b>.</li></ul>
  --q: string # A string consisting of one or more <i>keywords</i>. eBay filters the response by returning only the promotions that contain the supplied keywords in the promotion title.  <br><br><b>Example:</b> "iPhone" or "Harry Potter."  <br><br>Commas that separate keywords are ignored. For example, a keyword string of "iPhone, iPad" equals "iPhone iPad", and each results in a response that contains promotions with both "iPhone" and "iPad" in the title.
  --qp-sort: string # Specifies the order for how to sort the response. If you precede the supplied value with a dash, the response is sorted in reverse order.  <br><br><b>Example:</b> <br>&nbsp;&nbsp;&nbsp;<code>sort=END_DATE</code> &nbsp; Sorts the promotions in the response by their end dates in ascending order <br>&nbsp;&nbsp;&nbsp;<code>sort=-PROMOTION_NAME</code> &nbsp; Sorts the promotions by their promotion name in descending alphabetical order (Z-Az-a)  <br><br><b>Valid values</b>:<ul><li><code>START_DATE</code></li> <li><code>END_DATE</code></li> <li><code>PROMOTION_NAME</code></li></ul> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/csb:SortField
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, promotions: table<couponCode: string, description: string, endDate: string, marketplaceId: string, name: string, priority: string, promotionHref: string, promotionId: string, promotionImageUrl: string, promotionStatus: string, promotionType: string, startDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "promotion_status" $promotion_status "scalar") (serialize-qp "promotion_type" $promotion_type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method returns the set of listings associated with the <b>promotion_id</b> specified in the path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of a seller's promotions.  <p>The listing details are returned in a paginated set and you can control and results returned using the following query parameters: <b>limit</b>, <b>offset</b>, <b>q</b>, <b>sort</b>, and <b>status</b>.</p>  <ul><li><b>Maximum associated listings returned:</b> 200</li>  <li><b>Default number of listings returned:</b> 200</li></ul>
#
# GET /promotion/{promotion_id}/get_listing_set
# operationId: getListingSet
export def "promotion-get-listing-set get" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set. <br><br><b>Default:</b> 200<br><b>Maximum:</b> 200
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
  --q: string # Reserved for future use.
  --qp-sort: string # Specifies the order in which to sort the associated listings in the response. If you precede the supplied value with a dash, the response is sorted in reverse order.  <br><br><b>Example:</b> <br>&nbsp;&nbsp;&nbsp;<code>sort=PRICE</code> - Sorts the associated listings by their current price in ascending order <br>&nbsp;&nbsp;&nbsp;<code>sort=-TITLE</code> - Sorts the associated listings by their title in descending alphabetical order (Z-Az-a)  <br><br><b>Valid values</b>:<ul class="compact"><li>AVAILABLE</li> <li>PRICE</li> <li>TITLE</li></ul> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/csb:SortField
  --status: string # This query parameter applies only to markdown promotions. It filters the response based on the indicated status of the promotion. Currently, the only supported value for this parameter is <code>MARKED_DOWN</code>, which indicates active markdown promotions. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/sme:ItemMarkdownStatusEnum
]: nothing -> record<href: string, limit: int, listings: table<currentPrice: record, freeShipping: bool, inventoryReferenceId: string, inventoryReferenceType: string, listingCategoryId: string, listingCondition: string, listingConditionId: string, listingId: string, listingPromotionStatuses: list, quantity: int, storeCategoryId: string, title: string>, next: string, offset: int, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/promotion/($promotion_id)/get_listing_set" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method pauses a currently-active (RUNNING) threshold promotion and changes the state of the promotion from <code>RUNNING</code> to <code>PAUSED</code>. Pausing a promotion makes the promotion temporarily unavailable to buyers and any currently-incomplete transactions will not receive the promotional offer until the promotion is resumed. Also, promotion teasers are not displayed when a promotion is paused.  <br><br>Pass the ID of the promotion you want to pause using the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of the seller's promotions. <br><br><b>Note:</b> You can only pause threshold promotions (you cannot pause markdown promotions).
#
# POST /promotion/{promotion_id}/pause
# operationId: pausePromotion
export def "promotion-pause pausePromotion" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/promotion/($promotion_id)/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method restarts a threshold promotion that was previously paused and changes the state of the promotion from <code>PAUSED</code> to <code>RUNNING</code>. Only promotions that have been previously paused can be resumed. Resuming a promotion reinstates the promotional teasers and any transactions that were in motion before the promotion was paused will again be eligible for the promotion.  <br><br>Pass the ID of the promotion you want to resume using the <b>promotion_id</b> path parameter. Call <a href="/api-docs/sell/marketing/resources/promotion/methods/getPromotions">getPromotions</a> to retrieve the IDs of the seller's promotions.
#
# POST /promotion/{promotion_id}/resume
# operationId: resumePromotion
export def "promotion-resume resumePromotion" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/promotion/($promotion_id)/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method generates a report that lists the seller's running, paused, and ended promotions for the specified eBay marketplace. The result set can be filtered by the promotion status and the number of results to return. You can also supply <i>keywords</i> to limit the report to promotions that contain the specified keywords. <br><br>Specify the eBay marketplace for which you want the report run using the <b>marketplace_id</b> query parameter. Supply additional query parameters to control the report as needed.
#
# GET /promotion_report
# operationId: getPromotionReports
export def "promotion-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set.  <br><br><b>Default:</b> 200 <br><b>Maximum:</b> 200
  --marketplace-id: string # The eBay marketplace ID of the site for which you want the promotions report.  <p><b>Valid values:</b>  </p><ul><li><code>EBAY_AU</code> = Australia</li> <li><code>EBAY_DE</code> = Germany</li> <li><code>EBAY_ES</code> = Spain</li> <li><code>EBAY_FR</code> = France</li> <li><code>EBAY_GB</code> = Great Britain</li> <li><code>EBAY_IT</code> = Italy</li> <li><code>EBAY_US</code> = United States</li></ul>
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
  --promotion-status: string # Limits the results to the promotions that are in the state specified by this query parameter.  <br><br><b>Valid values:</b> <ul><li><code>DRAFT</code></li> <li><code>SCHEDULED</code></li> <li><code>RUNNING</code></li> <li><code>PAUSED</code></li> <li><code>ENDED</code></li></ul><b>Maximum number of values supported:</b> 1
  --promotion-type: string # Filters the returned promotions in the report based on their campaign promotion type. Specify one of the following values to indicate the promotion type you want returned in the report: <ul><li><code>CODED_COUPON</code> &ndash; A coupon code promotion set with <b>createItemPromotion</b>.</li> <li><code>MARKDOWN_SALE</code> &ndash; A markdown promotion set with <b>createItemPriceMarkdownPromotion</b>.</li> <li><code>ORDER_DISCOUNT</code> &ndash; A threshold promotion set with <b>createItemPromotion</b>.</li> <li><code>VOLUME_DISCOUNT</code> &ndash; A volume pricing promotion set with <b>createItemPromotion</b>.</li></ul>
  --q: string # A string consisting of one or more <i>keywords</i>. eBay filters the response by returning only the promotions that contain the supplied keywords in the promotion title.  <br><br><b>Example:</b> "iPhone" or "Harry Potter."  <br><br>Commas that separate keywords are ignored. For example, a keyword string of "iPhone, iPad" equals "iPhone iPad", and each results in a response that contains promotions with both "iPhone" and "iPad" in the title.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, promotionReports: table<averageItemDiscount: record, averageItemRevenue: record, averageOrderDiscount: record, averageOrderRevenue: record, averageOrderSize: string, baseSale: record, itemsSoldQuantity: int, numberOfOrdersSold: int, percentageSalesLift: string, promotionHref: string, promotionId: string, promotionReportId: string, promotionSale: record, promotionType: string, totalDiscount: record, totalSale: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "promotion_status" $promotion_status "scalar") (serialize-qp "promotion_type" $promotion_type "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion_report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method generates a report that summarizes the seller's promotions for the specified eBay marketplace. The report returns information on <code>RUNNING</code>, <code>PAUSED</code>, and <code>ENDED</code> promotions (deleted reports are not returned) and summarizes the seller's campaign performance for all promotions on a given site.  <br><br>For information about summary reports, see <a href="/api-docs/sell/static/marketing/pm-summary-report.html">Reading the item promotion Summary report</a>.
#
# GET /promotion_summary_report
# operationId: getPromotionSummaryReport
export def "promotion-summary-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --marketplace-id: string # The eBay marketplace ID of the site you for which you want a promotion summary report.  <p><b>Valid values:</b></p>  <ul><li><code>EBAY_AU</code> = Australia</li> <li><code>EBAY_DE</code> = Germany</li> <li><code>EBAY_ES</code> = Spain</li> <li><code>EBAY_FR</code> = France</li> <li><code>EBAY_GB</code> = Great Britain</li> <li><code>EBAY_IT</code> = Italy</li> <li><code>EBAY_US</code> = United States</li></ul>
]: nothing -> record<baseSale: record<currency: string, value: string>, lastUpdated: string, percentageSalesLift: string, promotionSale: record<currency: string, value: string>, totalSale: record<currency: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion_summary_report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
