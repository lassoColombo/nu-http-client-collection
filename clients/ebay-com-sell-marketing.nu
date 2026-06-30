# Auto-generated client for Marketing API vv1.14.0
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-marketing/v1.14.0/openapi.json
# Auth: --token flag or $env.MARKETING_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/marketing/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MARKETING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.ebay.com/sell/marketing/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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

# This method retrieves the details for all of the seller's defined campaigns. Request parameters can be used to retrieve a specific campaign, such as the campaign's name, the start and end date, the status, and the funding model (Cost Per Sale (CPS) or Cost Per Click (CPC). You can filter the result set by a campaign name, end date range, start date range, or campaign status. You can also paginate the records returned from the result set using the limit query parameter, and control which records to return using the offset parameter.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-name: string # Specifies the campaign name. The results are filtered to include only the campaign by the specified name.Note: The results might be null if other filters exclude the campaign with this name. Maximum: 1 campaign name
  --campaign-status: string # Include this filter and input a specific campaign status to retrieve campaigns currently in that state. Note: The results might not include all the campaigns with this status if other filters exclude them. Valid values: See CampaignStatusEnum (/api-docs/sell/marketing/types/pls:CampaignStatusEnum) Maximum: 1 status
  --end-date-range: string # Specifies the range of a campaign's end date. The results are filtered to include only campaigns with an end date that is within specified range. Valid format (UTC): yyyy-MM-ddThh:mm:ssZ..yyyy-MM-ddThh:mm:ssZ (campaign ends within this range)yyyy-MM-ddThh:mm:ssZ.. (campaign ends on or after this date)..yyyy-MM-ddThh:mm:ssZ (campaign ends on or before this date)2016-09-08T00:00.00.000Z..2016-09-09T00:00:00Z (campaign ends on September 08, 2016) Note: The results might not include all the campaigns ending on this date if other filters exclude them.
  --funding-strategy: string # Specifies the funding strategy for the campaign.The results will be filtered to only include campaigns with the specified funding model. If not specified, all campaigns matching the other filter parameters will be returned. The results might not include these campaigns if other search conditions exclude them.Valid Values:COST_PER_SALECOST_PER_CLICK
  --limit: string # Specifies the maximum number of campaigns to return on a page in the paginated response. Default: 10 Maximum: 500
  --offset: string # Specifies the number of campaigns to skip in the result set before returning the first report in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --start-date-range: string # Specifies the range of a campaign's start date in which to filter the results. The results are filtered to include only campaigns with a start date that is equal to this date or is within specified range.Valid format (UTC): yyyy-MM-ddThh:mm:ssZ..yyyy-MM-ddThh:mm:ssZ (starts within this range)yyyy-MM-ddThh:mm:ssZ (campaign starts on or after this date)..yyyy-MM-ddThh:mm:ssZ (campaign starts on or before this date)2016-09-08T00:00.00.000Z..2016-09-09T00:00:00Z (campaign starts on September 08, 2016)Note: The results might not include all the campaigns with this start date if other filters exclude them.
]: nothing -> record<campaigns: table<alerts: list, budget: record, campaignCriterion: record, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record, marketplaceId: string, startDate: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_name" $campaign_name "scalar") (serialize-qp "campaign_status" $campaign_status "scalar") (serialize-qp "end_date_range" $end_date_range "scalar") (serialize-qp "funding_strategy" $funding_strategy "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start_date_range" $start_date_range "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"campaign_name": $campaign_name, "campaign_status": $campaign_status, "end_date_range": $end_date_range, "funding_strategy": $funding_strategy, "limit": $limit, "offset": $offset, "start_date_range": $start_date_range} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method creates a Promoted Listings ad campaign. A Promoted Listings campaign is the structure into which you place the ads or ad group for the listings you want to promote. Identify the items you want to place into a campaign either by "key" or by "rule" as follows: Rules-based campaigns &ndash; A rules-based campaign adds items to the campaign according to the criteria you specify in your call to createCampaign. You can set the autoSelectFutureInventory request field to true so that after your campaign launches, eBay will regularly assess your new, revised, or newly-eligible listings to determine whether any should be added or removed from your campaign according to the rules you set. If there are, eBay will add or remove them automatically on a daily basis. Key-based campaigns &ndash; Add items to an existing campaign using either listing ID values or Inventory Reference values: Add listingId values to an existing campaign by calling either createAdByListingID or bulkCreateAdsByListingId. Add inventoryReference values to an existing campaign by calling either createAdByInventoryReference or bulkCreateAdsByInventoryReference.Add an ad group to an existing campaign by calling createAdGroup.Note: No matter how you add items to a Promoted Listings campaign, each campaign can contain ads for a maximum of 50,000 items. If a rules-based campaign identifies more than 50,000 items, ads are created for only the first 50,000 items identified by the specified criteria, and ads are not created for the remaining items. Creating a campaign To create a basic campaign, supply: The user-defined campaign name The start date (and optionally the end date) of the campaign The eBay marketplace on which the campaign is hosted Details on the campaign funding model The campaign funding model specifies how the Promoted Listings fee is calculated. Currently, the supported funding models are COST_PER_SALE and COST_PER_CLICK. For complete information on how the fee is calculated and when it applies, see Promoted Listings fees (/api-docs/sell/static/marketing/pl-overview.html#pl-fees). If you populate the campaignCriterion object in your createCampaign request, campaign "ads" are created by "rule" for the listings that meet the criteria you specify, and these ads are associated with the newly created campaign. For details on creating Promoted Listings campaigns and how to select the items to be included in your campaigns, see Promoted Listings campaign creation (/api-docs/sell/static/marketing/pl-create-campaign.html). For recommendations on which listings are prime for a Promoted Listings ad campaign and to get guidance on how to set the bidPercentage field, see Using the Recommendation API to help configure campaigns (/api-docs/sell/static/marketing/pl-reco-api.html). Tip: See Promoted Listings requirements and restrictions (/api-docs/sell/marketing/static/overview.html#PL-requirements) for the details on the marketplaces that support Promoted Listings via the API. See Promoted Listings restrictions (/api-docs/sell/static/marketing/pl-restrictions) for details about campaign limitations and restrictions.
#
# POST /ad_campaign
# operationId: createCampaign
# --budget shape: {daily?: record}
# --campaignCriterion shape: {autoSelectFutureInventory?: bool, criterionType?: string, selectionRules?: list}
# --fundingStrategy shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
export def "ad-campaign create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget: record # A container for the details of a Promoted Listings campaign that uses the Cost Per Click (CPC) funding model. — shape: {daily?: record}
  --campaign-criterion: record # This type defines the fields for specifying the criterion (selection rule) settings of an ad campaign. If you populate the campaignCriterion object in your createCampaign request, ads for the campaign are created by rule for the listings that meet the criteria you specify, and these ads are associated with the newly created campaign. — shape: {autoSelectFutureInventory?: bool, criterionType?: string, selectionRules?: list}
  --campaign-name: string # A seller-defined name for the campaign. This value must be unique for the seller. You can use any alphanumeric characters in the name, except the less than (<) or greater than (>) characters.Max length: 80 characters
  --end-date: string # The date and time the campaign ends, in UTC format (yyyy-MM-ddThh:mm:ssZ). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an endCampaign (/api-docs/sell/marketing/resources/campaign/methods/endCampaign) call, or if they update the campaign at a later time with an end date.
  --funding-strategy: record # This type defines how the Promoted Listings fee is calculated for a Promoted Listings ad campaign. — shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
  --marketplace-id: string # The ID of the eBay marketplace where the campaign is hosted. See the MarketplaceIdEnum type to get the appropriate enumeration value for the listing marketplace. For implementation help, refer to eBay API documentation
  --start-date: string # The date and time the campaign starts, in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller. On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign. Call getCampaign to check the status of the campaign.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_campaign" $auth.query)
  let req_body = {"budget": $budget, "campaignCriterion": $campaign_criterion, "campaignName": $campaign_name, "endDate": $end_date, "fundingStrategy": $funding_strategy, "marketplaceId": $marketplace_id, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method retrieves the campaigns containing the listing that is specified using either a listing ID, or an inventory reference ID and inventory reference type pair. The request accepts either a listing_id, or an inventory_reference_id and inventory_reference_type pair, as used in the Inventory API.eBay listing IDs are generated by either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods) when you create a listing.An inventory reference ID can be either a seller-defined SKU or inventoryItemGroupKey, as specified in the Inventory API.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# GET /ad_campaign/find_campaign_by_ad_reference
# operationId: findCampaignByAdReference
export def "ad-campaign-find-campaign-by-ad-reference find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inventory-reference-id: string # The seller's inventory reference ID of the listing to be used to find the campaign in which it is associated. This will either be a seller-defined SKU value or inventory item group ID, depending on the reference type specified. You must always pass in both inventory_reference_id and inventory_reference_type.
  --inventory-reference-type: string # The type of the seller's inventory reference ID, which is a listing or group of items. You must always pass in both inventory_reference_id and inventory_reference_type.
  --listing-id: string # Identifier of the eBay listing associated with the ad.
]: nothing -> record<campaigns: table<alerts: list, budget: record, campaignCriterion: record, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record, marketplaceId: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inventory_reference_id" $inventory_reference_id "scalar") (serialize-qp "inventory_reference_type" $inventory_reference_type "scalar") (serialize-qp "listing_id" $listing_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign/find_campaign_by_ad_reference" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"inventory_reference_id": $inventory_reference_id, "inventory_reference_type": $inventory_reference_type, "listing_id": $listing_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method retrieves the details of a single campaign, as specified with the campaign_name query parameter. Note that the campaign name you specify must be an exact, case-sensitive match of the name of the campaign you want to retrieve.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a list of the seller's campaign names.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-name: string # The name of the campaign.
]: nothing -> record<alerts: table<alertType: string, details: list>, budget: record<daily: record<amount: record, budgetStatus: string>>, campaignCriterion: record<autoSelectFutureInventory: bool, criterionType: string, selectionRules: list<record>>, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record<adRateStrategy: string, bidPercentage: string, dynamicAdRatePreferences: list<record>, fundingModel: string>, marketplaceId: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaign_name" $campaign_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_campaign/get_campaign_by_name" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"campaign_name": $campaign_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method deletes the campaign specified by the campaign_id query parameter.Note: You can only delete campaigns that have ended.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the campaign_id and the campaign status (RUNNING, PAUSED, ENDED, and so on) for all the seller's campaigns.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# This method retrieves the details of a single campaign, as specified with the campaign_id query parameter. This method returns all the details of a campaign (including the campaign's the selection rules), except the for the listing IDs or inventory reference IDs included in the campaign. These IDs are returned by getAds (/api-docs/sell/marketing/resources/ad/methods/getAds). Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a list of the seller's campaign IDs.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alerts: table<alertType: string, details: list>, budget: record<daily: record<amount: record, budgetStatus: string>>, campaignCriterion: record<autoSelectFutureInventory: bool, criterionType: string, selectionRules: list<record>>, campaignId: string, campaignName: string, campaignStatus: string, endDate: string, fundingStrategy: record<adRateStrategy: string, bidPercentage: string, dynamicAdRatePreferences: list<record>, fundingModel: string>, marketplaceId: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method retrieves Promoted Listings ads that are associated with listings created with either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods). The method retrieves ads related to the specified campaign. Specify the Promoted Listings campaign to target with the campaign_id path parameter. Because of the large number of possible results, you can use query parameters to paginate the result set by specifying a limit, which dictates how many ads to return on each page of the response. You can also specify how many ads to skip in the result set before returning the first result using the offset path parameter. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the current campaign IDs for the seller.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-ids: string # A comma-separated list of ad group IDs. The results will be filtered to only include active ads for these ad groups. Call getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) to retrieve the ad group ID for the ad group.Note: This field only applies to the Cost Per Click (CPC) funding model; it does not apply to the Cost Per Sale (CPS) funding model.
  --ad-status: string # A comma-separated list of ad statuses. The results will be filtered to only include the given statuses of the ad. If none are provided, all ads are returned.
  --limit: string # Specifies the maximum number of ads to return on a page in the paginated response. Default: 10 Maximum: 500
  --listing-ids: string # A comma-separated list of listing IDs. The response includes only active ads (ads associated with a RUNNING campaign). The results do not include listing IDs that are excluded by other conditions.
  --offset: string # Specifies the number of ads to skip in the result set before returning the first ad in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
]: nothing -> record<ads: table<adGroupId: string, adId: string, adStatus: string, alerts: list, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "ad_status" $ad_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "listing_ids" $listing_ids "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/ad") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ad_group_ids": $ad_group_ids, "ad_status": $ad_status, "limit": $limit, "listing_ids": $listing_ids, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method adds a listing to an existing Promoted Listings campaign using a listingId value generated by the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or Inventory API (/api-docs/sell/inventory/resources/methods), or using a value generated by an ad group ID. For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, an ad may be directly created for the listing.For the listing ID specified in the request, this method: Creates an ad for the listing. Sets the bid percentage (also known as the ad rate) for the ad. Associates the ad with the specified campaign. To create an ad for a listing, specify its listingId, plus the bidPercentage for the ad in the payload of the request. Specify the campaign to associate the ad with using the campaign_id path parameter. Listing IDs are generated by eBay when a seller creates listings with the Trading API.For Promoted Listings Advanced (PLA) campaigns using the Cost Per Click (CPC) funding model, an ad group must be created first. If no ad group has been created for the campaign, an ad cannot be created.For the ad group specified in the request, this method associates the ad with the specified ad group.To create an ad for an ad group, specify the name of the ad group in the payload of the request. Specify the campaign to associate the ads with using the campaign_id path parameter. Ad groups are generated using the createAdGroup (/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup) method. You can specify one or more ad groups per campaign.Use createCampaign (/api-docs/sell/marketing/resources/campaign/methods/createCampaign) to create a new campaign and use getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get a list of existing campaigns.This call has no response payload. If the ad is successfully created, a 201 Created HTTP status code and the getAd (/api-docs/sell/marketing/resources/ad/methods/getAd) URI of the ad are returned in the location header.
#
# POST /ad_campaign/{campaign_id}/ad
# operationId: createAdByListingId
export def "ad-campaign-ad create-by-listing" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-id: string # A unique eBay-assigned ID for an ad group in a campaign that uses the Cost Per Click (CPC) funding model. Required if the campaign's funding model is Cost Per Click (CPC).Create an ad group using the createAdGroup (/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup) method.Specify the campaign to associate the ad group with using the campaign_id path parameter. Note: You can call the getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) method to retrieve the ad group IDs for a seller.
  --bid-percentage: string # The user-defined bid percentage (also known as the ad rate) sets the level that eBay increases the visibility in search results for the associated listing. The higher the bidPercentage value, the more eBay promotes the listing.Required if the campaign's funding model is Cost Per Sale (CPS). The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. The bidPercentage is a single precision value that is guided by the following rules: These values are valid: 4.1, 5.0, 5.5, ... These values are not valid: 0.01, 10.75, 99.99, and so on.This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.Minimum value: 2.0 Maximum value: 100.0
  --listing-id: string # A unique eBay-assigned ID for a listing that is generated when the listing is created. Note: This field accepts listing IDs, as generated by the Inventory API, and item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs).
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/ad") $auth.query)
  let req_body = {"adGroupId": $ad_group_id, "bidPercentage": $bid_percentage, "listingId": $listing_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method removes the specified ad from the specified campaign.Pass the ID of the ad to delete with the ID of the campaign associated with the ad as path parameters to the call.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get the current list of the seller's campaign IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.When using the CPC funding model, use the bulkUpdateAdsStatusByListingId method to change the status of ads to ARCHIVED.
#
# DELETE /ad_campaign/{campaign_id}/ad/{ad_id}
# operationId: deleteAd
export def "ad-campaign-ad delete" [
  campaign_id: string
  ad_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_id: (encode-path-segment $ad_id)} | format pattern "/ad_campaign/{campaign_id}/ad/{ad_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# This method retrieves the specified ad from the specified campaign. In the request, supply the campaign_id and ad_id as path parameters. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a list of the seller's current campaign IDs and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to retrieve their current ad IDs.
#
# GET /ad_campaign/{campaign_id}/ad/{ad_id}
# operationId: getAd
export def "ad-campaign-ad get" [
  campaign_id: string
  ad_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adGroupId: string, adId: string, adStatus: string, alerts: table<alertType: string, details: list>, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_id: (encode-path-segment $ad_id)} | format pattern "/ad_campaign/{campaign_id}/ad/{ad_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method updates the bid percentage (also known as the "ad rate") for the specified ad in the specified campaign. In the request, supply the campaign_id and ad_id as path parameters, and supply the new bidPercentage value in the payload of the call. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a seller's current campaign IDs and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to get their ad IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/ad/{ad_id}/update_bid
# operationId: updateBid
export def "ad-campaign-ad-update-bid update" [
  campaign_id: string
  ad_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bid-percentage: string # The user-defined bid percentage (also known as the ad rate) sets the level that eBay increases the visibility in search results for the associated listing. The higher the bidPercentage value, the more eBay promotes the listing. The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. The bidPercentage is a single precision value that is guided by the following rules: These values are valid: 4.1, 5.0, 5.5, ... These values are not valid: 0.01, 10.75, 99.99, and so on.This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.Minimum value: 2.0 Maximum value: 100.0
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_id: (encode-path-segment $ad_id)} | format pattern "/ad_campaign/{campaign_id}/ad/{ad_id}/update_bid") $auth.query)
  let req_body = {"bidPercentage": $bid_percentage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method retrieves ad groups for the specified campaigns.Each campaign can only have one ad group.In the request, supply the campaign_ids as path parameters.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a list of the current campaign IDs for a seller.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-status: string # A comma-separated list of ad group statuses. The results will be filtered to only include the given statuses of the ad group.The results might not include these ad groups if other search conditions exclude them.
  --limit: string # The number of results, from the current result set, to be returned in a single page.
  --offset: string # The number of results that will be skipped in the result set. This is used with the limit field to control the pagination of the output.For example, if the offset is set to 0 and the limit is set to 10, the method will retrieve items 1 through 10 from the list of items returned. If the offset is set to 10 and the limit is set to 10, the method will retrieve items 11 through 20 from the list of items returned.Default: 0
]: nothing -> record<adGroups: table<adGroupId: string, adGroupStatus: string, defaultBid: record, name: string>, href: string, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "ad_group_status" $ad_group_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ad_group_status": $ad_group_status, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method adds an ad group to an existing PLA campaign that uses the Cost Per Click (CPC) funding model.To create an ad group for a campaign, specify the defaultBid for the ad group in the payload of the request. Then specify the campaign to which the ad group should be associated using the campaign_id path parameter.Each campaign can have one or more associated ad groups.
#
# POST /ad_campaign/{campaign_id}/ad_group
# operationId: createAdGroup
# --defaultBid shape: {currency?: string, value?: string}
export def "ad-campaign-ad-group create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --name: string # The seller-defined name of the ad group.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group") $auth.query)
  let req_body = {"defaultBid": $default_bid, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method retrieves the details of a specified ad group, such as the ad group’s default bid and status.In the request, specify the campaign_id and ad_group_id as path parameters.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a list of the current campaign IDs for a seller and call getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) for the ad group ID of the ad group you wish to retrieve.
#
# GET /ad_campaign/{campaign_id}/ad_group/{ad_group_id}
# operationId: getAdGroup
export def "ad-campaign-ad-group get" [
  campaign_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adGroupId: string, adGroupStatus: string, defaultBid: record<currency: string, value: string>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_group_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_group_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_group_id: (encode-path-segment $ad_group_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group/{ad_group_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates the ad group associated with a campaign.With this method, you can modify the default bid for the ad group, change the state of the ad group, or change the name of the ad group. Pass the ad_group_id you want to update as a URI parameter, and configure the adGroupStatus and defaultBid in the request payload.Call getAdGroup (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroup) to retrieve the current default bid and status of the ad group that you would like to update.
#
# PUT /ad_campaign/{campaign_id}/ad_group/{ad_group_id}
# operationId: updateAdGroup
# --defaultBid shape: {currency?: string, value?: string}
export def "ad-campaign-ad-group update" [
  campaign_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-status: string # An enumeration value representing the current status of the ad group.If the status of the ad is currently ACTIVE, you can change status to PAUSED or ARCHIVED. If ad group is currently in PAUSED status, you can change the status back to ACTIVE. Ads that are currently in ARCHIVED status cannot be made ACTIVE again.Valid Values:ACTIVEPAUSEDARCHIVED For implementation help, refer to eBay API documentation
  --default-bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --name: string # The updated name for the specified ad group.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_group_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_group_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_group_id: (encode-path-segment $ad_group_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group/{ad_group_id}") $auth.query)
  let req_body = {"adGroupStatus": $ad_group_status, "defaultBid": $default_bid, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method allows sellers to retrieve the suggested bids for input keywords and match type.
#
# POST /ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_bids
# operationId: suggestBids
# --keywords item shape: {keywordText?: string, matchType?: string}
export def "ad-campaign-ad-group-suggest-bids create" [
  campaign_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keywords: list # A list of keywords in the paginated collection. Maximum number of keywords: 500 — item shape: {keywordText?: string, matchType?: string}
]: any -> record<suggestedBids: table<keywordText: string, matchType: string, proposedBid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_group_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_group_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_group_id: (encode-path-segment $ad_group_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_bids") $auth.query)
  let req_body = {"keywords": $keywords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method allows sellers to retrieve a list of keyword ideas to be targeted for Promoted Listings campaigns.
#
# POST /ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_keywords
# operationId: suggestKeywords
export def "ad-campaign-ad-group-suggest-keywords create" [
  campaign_id: string
  ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-info: list<string> # A field used to indicate whether additional information and insight data shall be provided for suggested keywords.Valid Value: KEYWORD_INSIGHTS
  --exclusions: list<string> # A field used to indicate that the keywords already selected by sellers for the specified listing IDs should be filtered out of the response, and only new and unique keyword recommendations shall be returned.Valid Value: ADOPTED_KEYWORDS
  --listing-ids: list<string> # A set of comma-separated listing IDs in the paginated collection. Maximum number of listings requested: 300
  --match-type: string # A field that defines the match type for the keyword.Valid Values:BROADEXACTPHRASE For implementation help, refer to eBay API documentation
]: any -> record<suggestedKeywords: table<additionalInfo: list, keywordText: string, matchType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($ad_group_id | is-empty) { error make --unspanned { msg: "path parameter 'ad_group_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), ad_group_id: (encode-path-segment $ad_group_id)} | format pattern "/ad_campaign/{campaign_id}/ad_group/{ad_group_id}/suggest_keywords") $auth.query)
  let req_body = {"additionalInfo": $additional_info, "exclusions": $exclusions, "listingIds": $listing_ids, "matchType": $match_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This method adds multiple listings that are managed with the Inventory API (/api-docs/sell/inventory/resources/methods) to an existing Promoted Listings campaign.For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) model, bulk ads may be directly created for the listing.For each listing specified in the request, this method:Creates an ad for the listing. Sets the bid percentage (also known as the ad rate) for the ads created. Associates the ads created with the specified campaign.To create ads for a listing, specify their inventoryReferenceId and inventoryReferenceType, plus the bidPercentage for the ad in the payload of the request. Specify the campaign to which you want to associate the ads using the campaign_id path parameter.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.Use createCampaign (/api-docs/sell/marketing/resources/campaign/methods/createCampaign) to create a new campaign and use getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get a list of existing campaigns.
#
# POST /ad_campaign/{campaign_id}/bulk_create_ads_by_inventory_reference
# operationId: bulkCreateAdsByInventoryReference
# --requests item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-create-ads-by-inventory-reference create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # A list of inventory reference ID and inventory reference type pairs, and the bid percentage, which the call uses to create ads in bulk. — item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<adGroupId: string, ads: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_create_ads_by_inventory_reference") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method adds multiple listings to an existing Promoted Listings campaign using listingId values generated by the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or Inventory API (/api-docs/sell/inventory/resources/methods), or using values generated by an ad group ID.For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, bulk ads may be directly created for the listing.For each listing ID specified in the request, this method: Creates an ad for the listing. Sets the bid percentage (also known as the ad rate) for the ad. Associates the ad with the specified campaign.To create an ad for a listing, specify its listingId, plus the bidPercentage for the ad in the payload of the request. Specify the campaign to associate the ads with using the campaign_id path parameter. Listing IDs are generated by eBay when a seller creates listings with the Trading API.You can specify a maximum of 500 listings per call and each campaign can have ads for a maximum of 50,000 items. Be aware when using this call that each variation in a multiple-variation listing creates an individual ad.For Promoted Listings Advanced (PLA) campaigns using the Cost Per Click (CPC) funding model, an ad group must be created first. If no ad group has been created for the campaign, ads cannot be created.For the ad group specified in the request, this method associates the ad with the specified ad group.To create an ad for an ad group, specify the name of the ad group plus the defaultBid for the ad in the payload of the request. Specify the campaign to associate the ads with using the campaign_id path parameter. Ad groups are generated using the createAdGroup (/api-docs/sell/marketing/resources/adgroup/methods/createAdGroup) method. You can specify one or more ad groups per campaign.Use createCampaign (/api-docs/sell/marketing/resources/campaign/methods/createCampaign) to create a new campaign and use getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get a list of existing campaigns.
#
# POST /ad_campaign/{campaign_id}/bulk_create_ads_by_listing_id
# operationId: bulkCreateAdsByListingId
# --requests item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
export def "ad-campaign-bulk-create-ads-by-listing-id create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array of listing IDs and their associated bid percentages, which the request uses to create ads in bulk. This request accepts both listing IDs, as generated by the Inventory API, and an item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs). Maximum: 500 IDs per call — item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
]: any -> record<responses: table<adGroupId: string, adId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_create_ads_by_listing_id") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method adds keywords, in bulk, to an existing PLA ad group in a campaign that uses the Cost Per Click (CPC) funding model.This method also sets the CPC rate for each keyword.In the request, supply the campaign_id as a path parameter.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /ad_campaign/{campaign_id}/bulk_create_keyword
# operationId: bulkCreateKeyword
# --requests item shape: {adGroupId?: string, bid?: record, keywordText?: string, matchType?: string}
export def "ad-campaign-bulk-create-keyword create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # This array is used to pass in multiple keywords for one or more ad groups that belong to a campaign that uses the Cost Per Click (CPC) funding model. Up to {max value} keywords can be created with one call. — item shape: {adGroupId?: string, bid?: record, keywordText?: string, matchType?: string}
]: any -> record<responses: table<adGroupId: string, errors: list, href: string, keywordId: string, keywordText: string, matchType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_create_keyword") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method works with listings created with the Inventory API (/api-docs/sell/inventory/resources/methods).The method deletes a set of ads, as specified by a list of inventory reference IDs, from the specified campaign. Inventory reference IDs are seller-defined IDs that are used with the Inventory API.Pass the campaign_id as a path parameter and populate the payload with a list of inventoryReferenceId and inventoryReferenceType pairs that you want to delete.Get the campaign IDs for a seller by calling getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to get a list of the seller's inventory reference IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/bulk_delete_ads_by_inventory_reference
# operationId: bulkDeleteAdsByInventoryReference
# --requests item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-delete-ads-by-inventory-reference delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # A list of inventory referenceID and inventory reference type pairs that specify the set of ads to remove in bulk. — item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<adIds: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_delete_ads_by_inventory_reference") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method works with listing IDs created with either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods).The method deletes a set of ads, as specified by a list of listingID values from a Promoted Listings campaign. A listing ID value is generated by eBay when a seller creates a listing with either the Trading API and Inventory API.Pass the campaign_id as a path parameter and populate the payload with the set of listing IDs that you want to delete.Get the campaign IDs for a seller by calling getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to get a list of the seller's inventory reference IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.When using the CPC funding model, use the bulkUpdateAdsStatusByListingId (/api-docs/sell/marketing/resources/ad/methods/bulkUpdateAdsStatusByListingId) method to change the status of ads to ARCHIVED.
#
# POST /ad_campaign/{campaign_id}/bulk_delete_ads_by_listing_id
# operationId: bulkDeleteAdsByListingId
# --requests item shape: {listingId?: string}
export def "ad-campaign-bulk-delete-ads-by-listing-id delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array of the listing IDs that identify the ads to remove. — item shape: {listingId?: string}
]: any -> record<responses: table<adId: string, errors: list, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_delete_ads_by_listing_id") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method works with listings created with either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods). The method updates the bidPercentage values for a set of ads associated with the specified campaign. Specify the campaign_id as a path parameter and supply a set of listing IDs with their associated updated bidPercentage values in the request body. An eBay listing ID is generated when a listing is created with the Trading API. Get the campaign IDs for a seller by calling getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to get a list of the seller's inventory reference IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_bid_by_inventory_reference
# operationId: bulkUpdateAdsBidByInventoryReference
# --requests item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-campaign-bulk-update-ads-bid-by-inventory-reference update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # A list of inventory reference ID and inventory reference type pairs, and the bid percentage, which the call uses to create ads in bulk. — item shape: {adGroupId?: string, bidPercentage?: string, inventoryReferenceId?: string, inventoryReferenceType?: string}
]: any -> record<responses: table<ads: list, errors: list, inventoryReferenceId: string, inventoryReferenceType: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_update_ads_bid_by_inventory_reference") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method works with listings created with either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods). The method updates the bidPercentage values for a set of ads associated with the specified campaign. Specify the campaign_id as a path parameter and supply a set of listing IDs with their associated updated bidPercentage values in the request body. An eBay listing ID is generated when a listing is created with the Trading API. Get the campaign IDs for a seller by calling getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to get a list of the seller's inventory reference IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_bid_by_listing_id
# operationId: bulkUpdateAdsBidByListingId
# --requests item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
export def "ad-campaign-bulk-update-ads-bid-by-listing-id update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array of listing IDs and their associated bid percentages, which the request uses to create ads in bulk. This request accepts both listing IDs, as generated by the Inventory API, and an item IDs, as used in the eBay Traditional API set (e.g., the Trading and Finding APIs). Maximum: 500 IDs per call — item shape: {adGroupId?: string, bidPercentage?: string, listingId?: string}
]: any -> record<responses: table<adId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_update_ads_bid_by_listing_id") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method works with listings created with either the Trading API or the Inventory API (/api-docs/sell/inventory/resources/methods).This method updates the status of ads in bulk.Specify the campaign_id you want to update as a URI parameter, and configure the adGroupStatus in the request payload.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_status
# operationId: bulkUpdateAdsStatus
# --requests item shape: {adId?: string, adStatus?: string}
export def "ad-campaign-bulk-update-ads-status update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array of listing IDs and bid percentages. — item shape: {adId?: string, adStatus?: string}
]: any -> record<responses: table<adId: string, errors: list, href: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_update_ads_status") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method works with listings created with either the Trading API (/Devzone/XML/docs/Reference/eBay/index.html) or the Inventory API (/api-docs/sell/inventory/resources/methods).The method updates the status of ads in bulk, based on listing ID values.Specify the campaign_id as a path parameter and supply a set of listing IDs with their updated adStatus values in the request body. An eBay listing ID is generated when a listing is created with the Trading API.Get the campaign IDs for a seller by calling getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) and call getAds (/api-docs/sell/marketing/resources/ad/methods/getAds) to retrieve a list of seller inventory reference IDs.
#
# POST /ad_campaign/{campaign_id}/bulk_update_ads_status_by_listing_id
# operationId: bulkUpdateAdsStatusByListingId
# --requests item shape: {adGroupId?: string, adStatus?: string, listingId?: string}
export def "ad-campaign-bulk-update-ads-status-by-listing-id update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array of listing IDs and bid percentages. — item shape: {adGroupId?: string, adStatus?: string, listingId?: string}
]: any -> record<responses: table<adGroupId: string, errors: list, href: string, listingId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_update_ads_status_by_listing_id") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates the bids and statuses of keywords, in bulk, for an existing PLA campaign.In the request, supply the campaign_id as a path parameter.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /ad_campaign/{campaign_id}/bulk_update_keyword
# operationId: bulkUpdateKeyword
# --requests item shape: {bid?: record, keywordId?: string, keywordStatus?: string}
export def "ad-campaign-bulk-update-keyword update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # Use this array to update the bid values and/or statuses of one or more existing keywords. — item shape: {bid?: record, keywordId?: string, keywordStatus?: string}
]: any -> record<responses: table<errors: list, keywordId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/bulk_update_keyword") $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method clones (makes a copy of) the specified campaign's campaign criterion. The campaign criterion is a container for the fields that define the criteria for a rule-based campaign.To clone a campaign, supply the campaign_id as a path parameter in your call. There is no request payload. The ID of the newly-cloned campaign is returned in the Location response header.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a seller's current campaign IDs. Requirement: In order to clone a campaign, the campaignStatus must be ENDED and the campaign must define a set of selection rules (it must be a rules-based campaign).Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/clone
# operationId: cloneCampaign
# --fundingStrategy shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
export def "ad-campaign-clone clone" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-name: string # A seller-defined name for the newly-cloned campaign. This value must be unique for the seller. You can use any alphanumeric characters in the name, except the less than (<) or greater than (>) characters.Max length: 80 characters
  --end-date: string # The date and time the campaign ends, in UTC format (yyyy-MM-ddThh:mm:ssZ). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an endCampaign (/api-docs/sell/marketing/resources/campaign/methods/endCampaign) call, or if they update the campaign at a later time with an end date.
  --funding-strategy: record # This type defines how the Promoted Listings fee is calculated for a Promoted Listings ad campaign. — shape: {adRateStrategy?: string, bidPercentage?: string, dynamicAdRatePreferences?: list, fundingModel?: string}
  --start-date: string # The date and time the cloned campaign starts, in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller. On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign. Call getCampaign to check the status of the campaign.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/clone") $auth.query)
  let req_body = {"campaignName": $campaign_name, "endDate": $end_date, "fundingStrategy": $funding_strategy, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method adds a listing that is managed with the Inventory API (/api-docs/sell/inventory/resources/methods) to an existing Promoted Listings campaign.For Promoted Listings Standard (PLS) campaigns using the Cost Per Sale (CPS) funding model, an ad may be directly created for the listing.For each listing specified in the request, this method:Creates an ad for the listing. Sets the bid percentage (also known as the ad rate) for the ads created. Associates the created ad with the specified campaign.To create an ad for a listing, specify its inventoryReferenceId and inventoryReferenceType, plus the bidPercentage for the ad in the payload of the request. Specify the campaign to associate the ad with using the campaign_id path parameter.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.Use createCampaign (/api-docs/sell/marketing/resources/campaign/methods/createCampaign) to create a new campaign and use getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get a list of existing campaigns.
#
# POST /ad_campaign/{campaign_id}/create_ads_by_inventory_reference
# operationId: createAdsByInventoryReference
export def "ad-campaign-create-ads-by-inventory-reference create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-id: string # Note: This field is not currently in use. Ad groups are only applicable to Promoted Listings Advanced (PLA) ad campaigns that use the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
  --bid-percentage: string # The user-defined bid percentage (also known as the ad rate) sets the level that eBay increases the visibility in search results for the associated listing. The higher the bidPercentage value, the more eBay promotes the listing.Required if the campaign's funding model is Cost Per Sale (CPS).The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee.The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign.The bidPercentage is a single precision value that is guided by the following rules: These values are valid: 4.1, 5.0, 5.5, ... These values are not valid: 0.01, 10.75, 99.99, and so on.This is default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.Minimum value: 2.0 Maximum value: 100.0
  --inventory-reference-id: string # An ID that identifies a single-item listing or multiple-variation listing that is managed with the Inventory API (/api-docs/sell/inventory/resources/methods). The inventory reference ID is a seller-defined value that can be either an SKU for a single-item listing or an inventoryItemGroupKey for a multiple-value listing. An inventoryItemGroupKey is a value that the seller defines to indicate a listing that's the parent of an inventory item group (a multiple-variation listing, such as a listing for a shirt that's available in multiple sizes and colors). You must always specify both an inventoryReferenceId and an inventoryReferenceType to indicate an item that's managed with the Inventory API.
  --inventory-reference-type: string # Indicates the type of item the inventoryReferenceId references. The item can be either an INVENTORY_ITEM or INVENTORY_ITEM_GROUP. You must always pair an inventoryReferenceId with and inventoryReferenceType. For implementation help, refer to eBay API documentation
]: any -> record<ads: table<adId: string, href: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/create_ads_by_inventory_reference") $auth.query)
  let req_body = {"adGroupId": $ad_group_id, "bidPercentage": $bid_percentage, "inventoryReferenceId": $inventory_reference_id, "inventoryReferenceType": $inventory_reference_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method works with listings that are managed with the Inventory API (/api-docs/sell/inventory/resources/methods). The method deletes ads using a list of seller-defined inventory reference IDs, used with the Inventory API, that are associated with the specified campaign ID. Specify the campaign ID (as a path parameter) and a list of inventoryReferenceId and inventoryReferenceType pairs to be deleted. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to get a list of the seller's current campaign IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.When using the CPC funding model, use the bulkUpdateAdsStatusByInventoryReference method to change the status of ads to ARCHIVED.
#
# POST /ad_campaign/{campaign_id}/delete_ads_by_inventory_reference
# operationId: deleteAdsByInventoryReference
export def "ad-campaign-delete-ads-by-inventory-reference delete" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inventory-reference-id: string # The inventory reference ID is a seller-defined SKU value for a single-item listing, or a seller-defined identifier for an inventory item group. Both of these values are defined when using the Inventory API, and an inventory item group is used to create a multiple-variation listing.
  --inventory-reference-type: string # The enumeration value passed into this field indicates the type of value used for the corresponding inventoryReferenceId value. The enumeration value used here will either be INVENTORY_ITEM (to delete the ad for a single SKU listing) or INVENTORY_ITEM_GROUP (to delete the ad for a multiple-variation listing). For implementation help, refer to eBay API documentation
]: any -> record<adIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/delete_ads_by_inventory_reference") $auth.query)
  let req_body = {"inventoryReferenceId": $inventory_reference_id, "inventoryReferenceType": $inventory_reference_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This method ends an active (RUNNING) or paused campaign. Specify the campaign you want to end by supplying its campaign ID in a query parameter. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the campaign_id and the campaign status (RUNNING, PAUSED, ENDED, and so on) for all the seller's campaigns.
#
# POST /ad_campaign/{campaign_id}/end
# operationId: endCampaign
export def "ad-campaign-end create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/end") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This method retrieves Promoted Listings ads associated with listings that are managed with the Inventory API (/api-docs/sell/inventory/resources/methods) from the specified campaign.Supply the campaign_id as a path parameter and use query parameters to specify the inventory_reference_id and inventory_reference_type pairs.In the Inventory API, an inventory reference ID is either a seller-defined SKU value or an inventoryItemGroupKey (a seller-defined ID for an inventory item group, which is an entity that's used in the Inventory API to create a multiple-variation listing). To indicate a listing managed by the Inventory API, you must always specify both an inventory_reference_id and the associated inventory_reference_type.Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve all of the seller's the current campaign IDs.Note: This method only applies to the Cost Per Sale (CPS) funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --inventory-reference-id: string # The inventory reference ID associated with the ad you want returned. A seller's inventory reference ID is the ID of either a listing or the ID of an inventory item group (the parent of a multi-variation listing, such as a shirt that is available in multiple sizes and colors). You must always supply in both an inventory_reference_id and an inventory_reference_type.
  --inventory-reference-type: string # The type of the inventory reference ID. Set this value to either INVENTORY_ITEM (a single listing) or INVENTORY_ITEM_GROUP (a multi-variation listing). You must always pass in both an inventory_reference_id and an inventory_reference_type.
]: nothing -> record<ads: table<adGroupId: string, adId: string, adStatus: string, alerts: list, bidPercentage: string, inventoryReferenceId: string, inventoryReferenceType: string, listingId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "inventory_reference_id" $inventory_reference_id "scalar") (serialize-qp "inventory_reference_type" $inventory_reference_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/get_ads_by_inventory_reference") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"inventory_reference_id": $inventory_reference_id, "inventory_reference_type": $inventory_reference_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method can be used to retrieve all of the keywords for ad groups in PLA campaigns that use the Cost Per Click (CPC) funding model.In the request, specify the campaign_id as a path parameter. If one or more ad_group_ids are passed in the request body, the keywords for those ad groups will be returned. If ad_group_ids are not passed in the response body, the call will return all the keywords in the campaign.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a seller.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-ids: string # A comma-separated list of ad group IDs. This query parameter is used if the seller wants to retrieve keywords from one or more specific ad groups. If this query parameter is not used, all keywords that are part of the CPC campaign are returned.Note:You can call the getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) method to retrieve the ad group IDs for a seller.
  --keyword-status: string # A comma-separated list of keyword statuses. The results will be filtered to only include the given statuses of the keyword. If none are provided, all keywords are returned.
  --limit: string # Specifies the maximum number of results to return on a page in the paginated response. Default: 10 Maximum: 500
  --offset: string # Specifies the number of results to skip in the result set before returning the first report in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
]: nothing -> record<href: string, keywords: table<adGroupId: string, bid: record, keywordId: string, keywordStatus: string, keywordText: string, matchType: string>, limit: int, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "keyword_status" $keyword_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/keyword") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ad_group_ids": $ad_group_ids, "keyword_status": $keyword_status, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method creates keywords using a specified campaign ID for an existing PLA campaign.In the request, supply the campaign_id as a path parameter.Call the suggestKeywords (/api-docs/sell/marketing/resources/campaign/methods/suggestKeywords) method to retrieve a list of keyword ideas to be targeted for PLA campaigns, and call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a seller.
#
# POST /ad_campaign/{campaign_id}/keyword
# operationId: createKeyword
# --bid shape: {currency?: string, value?: string}
export def "ad-campaign-keyword create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-id: string # This adGroupId is created when an ad group is first created and associated with a campaign. This is the ad group that the corresponding keyword will be added to. This ad group must be a part of the campaign that is specified in the call URI.Note: You can call the getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) method to retrieve the ad group IDs for a seller, and getKeywords (/api-docs/sell/marketing/resources/keywords/methods/getKeywords) to retrieve the keyword IDs for a seller's keywords.
  --bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --keyword-text: string # Input the keyword into this field.
  --match-type: string # A field that defines the match type for the keyword.Valid Values:BROADEXACTPHRASE For implementation help, refer to eBay API documentation
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/keyword") $auth.query)
  let req_body = {"adGroupId": $ad_group_id, "bid": $bid, "keywordText": $keyword_text, "matchType": $match_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method retrieves details on a specific keyword from an ad group within a PLA campaign that uses the Cost Per Click (CPC) funding model.In the request, specify the campaign_id and keyword_id as path parameters.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a seller and call the getKeywords (/api-docs/sell/marketing/resources/keyword/methods/getKeywords) method to retrieve their keyword IDs.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adGroupId: string, bid: record<currency: string, value: string>, keywordId: string, keywordStatus: string, keywordText: string, matchType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($keyword_id | is-empty) { error make --unspanned { msg: "path parameter 'keyword_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), keyword_id: (encode-path-segment $keyword_id)} | format pattern "/ad_campaign/{campaign_id}/keyword/{keyword_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates keywords using a campaign ID and keyword ID for an existing PLA campaign.In the request, specify the campaign_id and keyword_id as path parameters.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a seller and call the getKeywords (/api-docs/sell/marketing/resources/keyword/methods/getKeywords) method to retrieve their keyword IDs.
#
# PUT /ad_campaign/{campaign_id}/keyword/{keyword_id}
# operationId: updateKeyword
# --bid shape: {currency?: string, value?: string}
export def "ad-campaign-keyword update" [
  campaign_id: string
  keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bid: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --keyword-status: string # Include this field if you wish to change the status of the keyword. The status value specified here must be different than the keyword's current status. To confirm the current status of a keyword, you can use the getKeyword (/api-docs/sell/marketing/resources/keyword/methods/getKeyword) method.If the status of the ad is currently ACTIVE, you can change status to PAUSED or ARCHIVED. If ad group is currently in PAUSED status, you can change the status back to ACTIVE. Ads that are currently in ARCHIVED status cannot be made ACTIVE again. For implementation help, refer to eBay API documentation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  if ($keyword_id | is-empty) { error make --unspanned { msg: "path parameter 'keyword_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id), keyword_id: (encode-path-segment $keyword_id)} | format pattern "/ad_campaign/{campaign_id}/keyword/{keyword_id}") $auth.query)
  let req_body = {"bid": $bid, "keywordStatus": $keyword_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This method pauses an active (RUNNING) campaign. You can restart the campaign by calling resumeCampaign (/api-docs/sell/marketing/resources/campaign/methods/resumeCampaign), as long as the campaign's end date is in the future. Note: The listings associated with a paused campaign cannot be added into another campaign. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the campaign_id and the campaign status (RUNNING, PAUSED, ENDED, and so on) for all the seller's campaigns.
#
# POST /ad_campaign/{campaign_id}/pause
# operationId: pauseCampaign
export def "ad-campaign-pause pause" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/pause") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This method resumes a paused campaign, as long as its end date is in the future. Supply the campaign_id for the campaign you want to restart as a query parameter in the request. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the campaign_id and the campaign status (RUNNING, PAUSED, ENDED, and so on) for all the seller's campaigns.
#
# POST /ad_campaign/{campaign_id}/resume
# operationId: resumeCampaign
export def "ad-campaign-resume create" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/resume") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method allows sellers to obtain ideas for listings, which can be targeted for Promoted Listings campaigns.
#
# GET /ad_campaign/{campaign_id}/suggest_items
# operationId: suggestItems
export def "ad-campaign-suggest-items get" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-ids: string # Specifies the category ID that is used to limit the results. This refers to an exact leaf category (the lowest level in that category and has no children). This field can have one category ID, or a comma-separated list of IDs. To return all category IDs, set to null. Maximum: 10
  --limit: string # Specifies the maximum number of campaigns to return on a page in the paginated response. If no value is specified, the default value is used. Default: 10 Minimum: 1Maximum: 1000
  --offset: string # Specifies the number of campaigns to skip in the result set before returning the first report in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, suggestedItems: table<bases: list, listingId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let qp = [(serialize-qp "category_ids" $category_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/suggest_items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category_ids": $category_ids, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method updates the ad rate strategy for an existing Promoted Listings Standard (PLS) rules-based ad campaign that uses the Cost Per Sale (CPS) funding model.Specify the campaign_id as a path parameter. You can retrieve the campaign IDs for a seller by calling the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method.Note: This method only applies to the CPS funding model; it does not apply to the Cost Per Click (CPC) funding model. See Funding Models (/api-docs/sell/static/marketing/pl-overview.html#funding-model) in the Promoted Listings Playbook for more information.
#
# POST /ad_campaign/{campaign_id}/update_ad_rate_strategy
# operationId: updateAdRateStrategy
# --dynamicAdRatePreferences item shape: {adRateAdjustmentPercent?: string, adRateCapPercent?: string}
export def "ad-campaign-update-ad-rate-strategy update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-rate-strategy: string # The ad rate strategy that shall be applied to the campaign. For implementation help, refer to eBay API documentation
  --bid-percentage: string # The user-defined bid percentage (also known as the ad rate) sets the level that eBay increases the visibility in search results for the associated listing. The higher the bidPercentage value, the more eBay promotes the listing. The value specified here is also used to calculate the Promoted Listings fee. This percentage value is multiplied by the final sales price to determine the fee. The Promoted Listings fee is determined at the time the transaction completes and the seller is assessed the fee only when an item sells through a Promoted Listings ad campaign. The bidPercentage is a single precision value that is guided by the following rules: These values are valid: 4.1, 5.0, 5.5, ... These values are not valid: 0.01, 10.75, 99.99, and so on.This is the default bid percentage for the campaigns using the Cost Per Sale (CPS) funding model, and this value will be overridden by any ads in the campaign that have their own set bid percentages.If a bid percentage is not provided for an ad, eBay uses the default bid percentage of the associated campaign.Minimum value: 2.0 Maximum value: 100.0
  --dynamic-ad-rate-preferences: list # A field that indicates whether a single, user-defined bid percentage (also known as the ad rate) should be used, or whether eBay should automatically adjust listings to maintain the daily suggested bid percentage.Note: Dynamic adjustment is only applicable when the adRateStrategy is set to DYNAMIC.Default: FIXED — item shape: {adRateAdjustmentPercent?: string, adRateCapPercent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/update_ad_rate_strategy") $auth.query)
  let req_body = {"adRateStrategy": $ad_rate_strategy, "bidPercentage": $bid_percentage, "dynamicAdRatePreferences": $dynamic_ad_rate_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates the daily budget for a PLA campaign that uses the Cost Per Click (CPC) funding model.A click occurs when an eBay user finds and clicks on the seller’s listing (within the search results) after using a keyword that the seller has created for the campaign. For each ad in an ad group in the campaign, each click triggers a cost, which gets subtracted from the campaign’s daily budget. If the cost of the clicks exceeds the daily budget, the Promoted Listings campaign will be paused until the next day.Specify the campaign_id as a path parameter. You can retrieve the campaign IDs for a seller by calling the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method.
#
# POST /ad_campaign/{campaign_id}/update_campaign_budget
# operationId: updateCampaignBudget
# --daily shape: {amount?: record}
export def "ad-campaign-update-campaign-budget update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --daily: record # A container for the budget details of a Promoted Listings campaign that uses the Cost Per Click (CPC) funding model.Note: This container will only be returned for campaigns using the CPC funding model; it does not apply to the Cost Per Sale (CPS) funding model. — shape: {amount?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/update_campaign_budget") $auth.query)
  let req_body = {"daily": $daily} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# This method can be used to change the name of a campaign, as well as modify the start or end dates. Specify the campaign_id you want to update as a URI parameter, and configure the campaignName and startDate in the request payload. If you want to change only the end date of the campaign, specify the current campaign name and set startDate to the current date (you cannot use a start date that is in the past), and set the endDate as desired. Note that if you do not set a new end date in this call, any current endDate value will be set to null. To preserve the currently-set end date, you must specify the value again in your request. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve a seller's campaign details, including the campaign ID, campaign name, and the start and end dates of the campaign.
#
# POST /ad_campaign/{campaign_id}/update_campaign_identification
# operationId: updateCampaignIdentification
export def "ad-campaign-update-campaign-identification update" [
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaign-name: string # The new seller-defined name for the campaign. This value must be unique for the seller. If you don't want to change the name of the campaign, specify the current campaign name in this field.You can use any alphanumeric characters in the name, except the less than (<) or greater than (>) characters.Max length: 80 characters.
  --end-date: string # The date and time the campaign ends, in UTC format (yyyy-MM-ddThh:mm:ssZ). If this field is omitted, the campaign will have no defined end date, and will not end until the seller makes a decision to end the campaign with an endCampaign (/api-docs/sell/marketing/resources/campaign/methods/endCampaign) call, or if they update the campaign at a later time with an end date.If you want to change only the end date of the campaign, specify the current campaign name and set startDate to the current date (you cannot use a start date that is in the past), and set the endDate as desired. Note that if you do not set a new end date in this call, any current endDate value will be set to null. To preserve the currently-set end date, you must specify the value again in your request.
  --start-date: string # The new start date for the campaign, in UTC format (yyyy-MM-ddThh:mm:ssZ). If the campaign is currently RUNNING or PAUSED, enter the current date in this field because you cannot submit past or future date for these campaigns. On the date specified, the service derives the keywords for each listing in the campaign, creates an ad for each listing, and associates each new ad with the campaign. The campaign starts after this process is completed. The amount of time it takes the service to start the campaign depends on the number of listings in the campaign. Call getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) to retrieve the campaign_id and the campaign status (RUNNING, PAUSED, ENDED, and so on) for all the seller's campaigns.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($campaign_id | is-empty) { error make --unspanned { msg: "path parameter 'campaign_id' must be non-empty" } }
  let full_url = (build-url $base ({campaign_id: (encode-path-segment $campaign_id)} | format pattern "/ad_campaign/{campaign_id}/update_campaign_identification") $auth.query)
  let req_body = {"campaignName": $campaign_name, "endDate": $end_date, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# This call downloads the report as specified by the report_id path parameter. Call createReportTask (/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask) to schedule and generate a Promoted Listings report. All date values are returned in UTC format (yyyy-MM-ddThh:mm:ss.sssZ).Note: The reporting of some data related to sales and ad-fees may require a 72-hour (maximum) adjustment period which is often referred to as the Reconciliation Period. Such adjustment periods should, on average, be minimal. However, at any given time, the payments tab may be used to view those amounts that have actually been charged.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'report_id' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/ad_report/{report_id}") $auth.query)
  let accept_val = "text/tab-separated-values"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This call retrieves information that details the fields used in each of the Promoted Listings reports. Use the returned information to configure the different types of Promoted Listings reports.The request for this method does not use a payload or any URI parameters.Note: The reporting of some data related to sales and ad-fees may require a 72-hour (maximum) adjustment period which is often referred to as the Reconciliation Period. Such adjustment periods should, on average, be minimal. However, at any given time, the payments tab may be used to view those amounts that have actually been charged.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<reportMetadata: table<dimensionMetadata: list, maxNumberOfDimensionsToRequest: int, maxNumberOfMetricsToRequest: int, metricMetadata: list, reportType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_report_metadata" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This call retrieves metadata that details the fields used by a specific Promoted Listings report type. Use the report_type path parameter to indicate metadata to retrieve.This method does not use a request payload.Note: The reporting of some data related to sales and ad-fees may require a 72-hour (maximum) adjustment period which is often referred to as the Reconciliation Period. Such adjustment periods should, on average, be minimal. However, at any given time, the payments tab may be used to view those amounts that have actually been charged.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimensionMetadata: table<dataType: string, dimensionKey: string, dimensionKeyAnnotations: list>, maxNumberOfDimensionsToRequest: int, maxNumberOfMetricsToRequest: int, metricMetadata: table<dataType: string, metricKey: string>, reportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_type | is-empty) { error make --unspanned { msg: "path parameter 'report_type' must be non-empty" } }
  let full_url = (build-url $base ({report_type: (encode-path-segment $report_type)} | format pattern "/ad_report_metadata/{report_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method returns information on all the existing report tasks related to a seller. Use the report_task_statuses query parameter to control which reports to return. You can paginate the result set by specifying a limit, which dictates how many report tasks to return on each page of the response. Use the offset parameter to specify how many reports to skip in the result set before returning the first result.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Specifies the maximum number of report tasks to return on a page in the paginated response. Default: 10Maximum: 500
  --offset: string # Specifies the number of report tasks to skip in the result set before returning the first report in the paginated response. Combine offset with the limit query parameter to control the reports returned in the response. For example, if you supply an offset of 0 and a limit of 10, the response contains the first 10 reports from the complete list of report tasks retrieved by the call. If offset is 10 and limit is 10, the first page of the response contains reports 11-20 from the complete result set. Default: 0
  --report-task-statuses: string # This parameter filters the returned report tasks by their status. Supply a comma-separated list of the report statuses you want returned. The results are filtered to include only the report statuses you specify.Note: The results might not include some report tasks if other search conditions exclude them.Valid values: PENDING SUCCESS FAILED
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, reportTasks: table<campaignIds: list, dateFrom: string, dateTo: string, dimensions: list, fundingModels: list, inventoryReferences: list, listingIds: list, marketplaceId: string, metricKeys: list, reportExpirationDate: string, reportFormat: string, reportHref: string, reportId: string, reportName: string, reportTaskCompletionDate: string, reportTaskCreationDate: string, reportTaskExpectedCompletionDate: string, reportTaskId: string, reportTaskStatus: string, reportTaskStatusMessage: string, reportType: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "report_task_statuses" $report_task_statuses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ad_report_task" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "report_task_statuses": $report_task_statuses} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: Using multiple funding models in one report is deprecated. If multiple funding models are used, a Warning will be returned in a header. This functionality will be decommissioned on April 3, 2023. See API Deprecation Status (/develop/apis/api-deprecation-status) for details.This method creates a report task, which generates a Promoted Listings report based on the values specified in the call.The report is generated based on the criteria you specify, including the report type, the report's dimensions and metrics, the report's start and end dates, the listings to include in the report, and more. Metrics are the quantitative measurements in the report while dimensions specify the attributes of the data included in the reports.When creating a report task, you can specify the items you want included in the report. The items you specify, using either listingId or inventoryReference values, must be in a Promoted Listings campaign for them to be included in the report.For details on the required and optional fields for each report type, see Promoted Listings reporting (/api-docs/sell/static/marketing/pl-reports.html).This call returns the URL to the report task in the Location response header, and the URL includes the report-task ID.Reports often take time to generate and it's common for this call to return an HTTP status of 202, which indicates the report is being generated. Call getReportTasks (/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks) (or getReportTask (/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTask) with the report-task ID) to determine the status of a Promoted Listings report. When a report is complete, eBay sets its status to SUCCESS and you can download it using the URL returned in the reportHref field of the getReportTask call. Report files are tab-separated value gzip files with a file extension of .tsv.gz.Note: The reporting of some data related to sales and ad-fees may require a 72-hour (maximum) adjustment period which is often referred to as the Reconciliation Period. Such adjustment periods should, on average, be minimal. However, at any given time, the payments tab may be used to view those amounts that have actually been charged.Note: This call fails if you don't submit all the required fields for the specified report type. Fields not supported by the specified report type are ignored. Call getReportMetadata (/api-docs/sell/marketing/resources/ad_report_metadata/methods/getReportMetadata) to retrieve a list of the fields you need to configure for each Promoted Listings report type.
#
# POST /ad_report_task
# operationId: createReportTask
# --dimensions item shape: {annotationKeys?: list<string>, dimensionKey?: string}
# --inventoryReferences item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
export def "ad-report-task create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-records: list<string> # A list of additional records that shall be included in the report, such as non-performing data.Note: Additional records are only applicable to Promoted Listings Advanced (PLA) campaigns that use the Cost Per Click (CPC) funding model.Valid Value: NON_PERFORMING_DATA
  --campaign-ids: list<string> # A list of campaign IDs to be included in the report task. Call getCampaigns to get a list of the current campaign IDs for a seller.For Promoted Listings Standard (PLS) sellers, this field is required if the reportType is set to CAMPAIGN_PERFORMANCE_REPORT or CAMPAIGN_PERFORMANCE_SUMMARY_REPORT.For Promoted Listings Advanced (PLA) sellers, leave this request field blank to retrieve the details for all campaigns associated with your account, or specify the campaign IDs for which you would like to retrieve the campaign-specific details.Note: There is a maximum data limit that cannot be exceeded when generating reports. If this threshold is exceeded, the report will fail. Refer to Promoted Listings reporting (/api-docs/sell/static/marketing/pl-reports.html#creation) in the Selling Integration Guide for details.Maximum:25 IDs for PLS1,000 IDs for PLA
  --date-from: string # The date defining the start of the timespan covered by the report.Format the timestamp as an ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) string, which is based on the 24-hour Coordinated Universal Time (UTC) clock with local offset.Note: The date specified cannot be a future date.Format: [YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]ZExample: 2021-03-15T13:00:00-07:00
  --date-to: string # The date defining the end of the timespan covered by the report.As with the dateFrom field, format the timestamp as an ISO 8601 (https://www.iso.org/iso-8601-date-and-time-format.html) string.Note: The date specified cannot be a future date. Additionally, the time specified must be a later time than that specified in the dateFrom field.Format: [YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]ZExample: 2021-03-17T13:00:00-07:00
  --dimensions: list # The list of the dimensions applied to the report. A dimension is an attribute to which the report data applies. For example, if you set dimensionKey to campaign_id in a Campaign Performance Report, the data will apply to the entire ad campaign. For information on the dimensions and how to specify them, see Promoted Listings reporting (/api-docs/sell/static/marketing/pl-reports.html). — item shape: {annotationKeys?: list<string>, dimensionKey?: string}
  --funding-models: list<string> # The funding model for the campaign that shall be included in the report.Note: The default funding model for Promoted Listings reports is COST_PER_SALE.Note: Multiple value support for the fundingModels array has been deprecated. See API Deprecation Status for information.Valid Values:COST_PER_SALECOST_PER_CLICKRequired if the campaign funding model is Cost Per Click (CPC).
  --inventory-references: list # You can use this field to supply an array of items to include in the report if you manage your inventory with the Inventory API (/api-docs/sell/inventory/resources/methods). This field is mutually exclusive with the listingIds field; if you populate this field, do not populate the listingIds field. An inventory reference identifies an item in your inventory using a pair of values, where the inventoryReferenceId can be either a seller-defined SKU value or an inventoryItemGroupKey, where an inventoryItemGroupKey is seller-defined ID for an inventory item group (a multiple-variation listing). Couple the inventoryReferenceId with an inventoryReferenceType identifier to fully identify an item in your inventory. Maximum: 500 items Required if you do not supply an array of listingId values or if you set reportType to INVENTORY_PERFORMANCE_REPORT. — item shape: {inventoryReferenceId?: string, inventoryReferenceType?: string}
  --listing-ids: list<string> # Use this field to supply an array of listing IDs you want to include in the report.A listing ID is the eBay listing identifier that is generated when the listing is created. This field accepts listing ID values generated with both the Inventory API and the eBay Traditional APIs, such as the Trading and Finding APIs.Important: This field is mutually exclusive with the inventoryReferences field; if you populate this field, do not populate the inventoryReferences field.For Promoted Listings Standard (PLS) sellers, this field is required if you do not supply an array of inventoryReferences values or if you set the reportType to LISTING_PERFORMANCE_REPORT.For Promoted Listings Advanced (PLA) sellers, leave this field blank to retrieve the details for all listings associated with the specified campaign IDs (or all campaigns associated with your account, if no campaign IDs are specified), or specify the listing IDs for which you would like to retrieve the listing-specific details.Note: There is a maximum data limit that cannot be exceeded when generating reports. If this threshold is exceeded, the report will fail. Refer to Promoted Listings reporting (/api-docs/sell/static/marketing/pl-reports.html#creation) in the Selling Integration Guide for details.Maximum: 500 listings
  --marketplace-id: string # The ID for the eBay marketplace on which the report is based.Maximum: 1 For implementation help, refer to eBay API documentation
  --metric-keys: list<string> # The list of metrics to be included in the report. Metrics are the quantitative measurements compiled into the report and the data returned is based on the specified dimension of the report. For example, if the dimension is campaign, the metrics for number of sales would be the number of sales in the campaign. However, if the dimension is listing, the number of sales represents the number of items sold in that listing. For information on metric keys and how to set them, see Promoted Listings reporting (/api-docs/sell/static/marketing/pl-reports.html).Minimum: 1
  --report-format: string # The file format of the report. Currently, the only supported format is TSV_GZIP, which is a gzip file with tab separated values. For implementation help, refer to eBay API documentation
  --report-type: string # The type of report to be generated, such as ACCOUNT_PERFORMANCE_REPORT or CAMPAIGN_PERFORMANCE_REPORT.Note: INVENTORY_PERFORMANCE_REPORT is not currently available; availability date is pending.Maximum: 1 For implementation help, refer to eBay API documentation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ad_report_task" $auth.query)
  let req_body = {"additionalRecords": $additional_records, "campaignIds": $campaign_ids, "dateFrom": $date_from, "dateTo": $date_to, "dimensions": $dimensions, "fundingModels": $funding_models, "inventoryReferences": $inventory_references, "listingIds": $listing_ids, "marketplaceId": $marketplace_id, "metricKeys": $metric_keys, "reportFormat": $report_format, "reportType": $report_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# This call deletes the report task specified by the report_task_id path parameter. This method also deletes any reports generated by the report task. Report task IDs are generated by eBay when you call createReportTask (/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask). Get a complete list of a seller's report-task IDs by calling getReportTasks (/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks).
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_task_id | is-empty) { error make --unspanned { msg: "path parameter 'report_task_id' must be non-empty" } }
  let full_url = (build-url $base ({report_task_id: (encode-path-segment $report_task_id)} | format pattern "/ad_report_task/{report_task_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# This call returns the details of a specific Promoted Listings report task, as specified by the report_task_id path parameter. The report task includes the report criteria (such as the report dimensions, metrics, and included listing) and the report-generation rules (such as starting and ending dates for the specified report task). Report-task IDs are generated by eBay when you call createReportTask (/api-docs/sell/marketing/resources/ad_report_task/methods/createReportTask). Get a complete list of a seller's report-task IDs by calling getReportTasks (/api-docs/sell/marketing/resources/ad_report_task/methods/getReportTasks).
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<campaignIds: list<string>, dateFrom: string, dateTo: string, dimensions: table<annotationKeys: list, dimensionKey: string>, fundingModels: list<string>, inventoryReferences: table<inventoryReferenceId: string, inventoryReferenceType: string>, listingIds: list<string>, marketplaceId: string, metricKeys: list<string>, reportExpirationDate: string, reportFormat: string, reportHref: string, reportId: string, reportName: string, reportTaskCompletionDate: string, reportTaskCreationDate: string, reportTaskExpectedCompletionDate: string, reportTaskId: string, reportTaskStatus: string, reportTaskStatusMessage: string, reportType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($report_task_id | is-empty) { error make --unspanned { msg: "path parameter 'report_task_id' must be non-empty" } }
  let full_url = (build-url $base ({report_task_id: (encode-path-segment $report_task_id)} | format pattern "/ad_report_task/{report_task_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method adds negative keywords, in bulk, to an existing ad group in a PLA campaign that uses the Cost Per Click (CPC) funding model.Specify the campaignId and adGroupId in the request body, along with the negativeKeywordText and negativeKeywordMatchType.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /bulk_create_negative_keyword
# operationId: bulkCreateNegativeKeyword
# --requests item shape: {adGroupId?: string, campaignId?: string, negativeKeywordMatchType?: string, negativeKeywordText?: string}
export def "bulk-create-negative-keyword create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # This array is used to pass in multiple negative keywords for one or more ad groups that belong to a campaign that uses the Cost Per Click (CPC) funding model. — item shape: {adGroupId?: string, campaignId?: string, negativeKeywordMatchType?: string, negativeKeywordText?: string}
]: any -> record<responses: table<adGroupId: string, campaignId: string, errors: list, href: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordText: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_create_negative_keyword" $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates the statuses of existing negative keywords, in bulk.Specify the negativeKeywordId and negativeKeywordStatus in the request body.
#
# POST /bulk_update_negative_keyword
# operationId: bulkUpdateNegativeKeyword
# --requests item shape: {negativeKeywordId?: string, negativeKeywordStatus?: string}
export def "bulk-update-negative-keyword update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --requests: list # An array to update the statuses of one or more existing negative keywords. — item shape: {negativeKeywordId?: string, negativeKeywordStatus?: string}
]: any -> record<responses: table<errors: list, negativeKeywordId: string, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulk_update_negative_keyword" $auth.query)
  let req_body = {"requests": $requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200 207]
}

# This method creates an item price markdown promotion (know simply as a "markdown promotion") where a discount amount is applied directly to the items included the promotion. Discounts can be specified as either a monetary amount or a percentage off the standard sales price. eBay highlights promoted items by placing teasers for the items throughout the online sales flows. Unlike an item promotion (/api-docs/sell/marketing/resources/item_promotion/methods/createItemPromotion), a markdown promotion does not require the buyer meet a "threshold" before the offer takes effect. With markdown promotions, all the buyer needs to do is purchase the item to receive the promotion benefit. Important: There are some restrictions for which listings are available for price markdown promotions. For details, see Promotions Manager requirements and restrictions (/api-docs/sell/marketing/static/overview.html#PM-requirements). In addition, we recommend you list items at competitive prices before including them in your markdown promotions. For an extensive list of pricing recommendations, see the Growth tab in Seller Hub. There are two ways to add items to markdown promotions: Key-based promotions select items using either the listing IDs or inventory reference IDs of the items you want to promote. Note that if you use inventory reference IDs, you must specify both the inventoryReferenceId and the associated inventoryReferenceType of the item(s) you want to include the promotion. Rule-based promotions select items using a list of eBay category IDs or seller Store category IDs. Rules can further constrain items in a promotion by minimum and maximum prices, brands, and item conditions. New promotions must be created in either a DRAFT or a SCHEDULED state. Use the DRAFT state when you are initially creating a promotion and you want to be sure it's correctly configured before scheduling it to run. When you create a promotion, the promotion ID is returned in the Location response header. Use this ID to reference the promotion in subsequent requests (such as to schedule a promotion that's in a DRAFT state). Tip: Refer to Promotions Manager (/api-docs/sell/static/marketing/promotions-manager.html) in the Selling Integration Guide for details and examples showing how to create and manage seller promotions. Markdown promotions are available on all eBay marketplaces. For more information, see Promotions Manager requirements and restrictions (/api-docs/sell/marketing/static/overview.html#PM-requirements).
#
# POST /item_price_markdown
# operationId: createItemPriceMarkdownPromotion
# --selectedInventoryDiscounts item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
export def "item-price-markdown create-promotion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-free-shipping: oneof<nothing, bool> # If set to true, free shipping is applied to the first shipping service specified for the item. The first domestic shipping option is set to "free shipping," regardless if the shipping optionType for that service is set to FLAT_RATE, CALCULATED, or NOT_SPECIFIED (freight). This flag essentially adds free shipping as a promotional bonus. Default: false
  --auto-select-future-inventory: oneof<nothing, bool> # If set to true, eBay will automatically add inventory items to the markdown promotion if they meet the selectedInventoryDiscounts criteria specified for the markdown promotion. Default: false
  --block-price-increase-in-item-revision: oneof<nothing, bool> # If set to true, price increases (including removing the free shipping flag) are blocked and an error message is returned if a seller attempts to adjust the price of an item that's partaking in this markdown promotion. If set to false, an item is dropped from the markdown promotion if the seller adjusts the price. Default: false
  --description: string # This field is required if you are configuring an MARKDOWN_SALE promotion. This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." A tag line appears under the "offer-type text" that is generated for the promotion. The text is displayed on the offer tile that is shown on the seller's All Offers page and on the event page for the promotion. Note: Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. This text is not editable by the seller&mdash;it's derived from the settings in the discountRules and discountSpecification fields&mdash;and can be, for example, "20% off". Maximum length: 50
  --end-date: string # The date and time the promotion ends, in UTC format (yyyy-MM-ddThh:mm:ssZ). The value supplied for endDate must be at least 24 hours after the value supplied for the startDate of the markdown promotion.For display purposes, convert this time into the local time of the seller. Max value:14 days for the AT, CH, DE, ES, FR, IE, IT, and UK, marketplaces. 45 days for all other marketplaces.
  --marketplace-id: string # The eBay marketplace ID of the site where the markdown promotion is hosted. Markdown promotions are supported on all eBay marketplaces. For implementation help, refer to eBay API documentation
  --name: string # The seller-defined name or 'title' of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows. Maximum length: 90
  --priority: string # This field is ignored in markdown promotions. For implementation help, refer to eBay API documentation
  --promotion-image-url: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's All Offers page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotion-status: string # The current status of the promotion. When creating a new promotion, you must set this value to either DRAFT or SCHEDULED. Note that you must set this value to SCHEDULED when you update a RUNNING promotion. For implementation help, refer to eBay API documentation
  --selected-inventory-discounts: list # A list that defines the sets of selected items for the markdown promotion and the discount specified for promotion. — item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
  --start-date: string # The date and time the promotion starts in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item_price_markdown" $auth.query)
  let req_body = {"applyFreeShipping": $apply_free_shipping, "autoSelectFutureInventory": $auto_select_future_inventory, "blockPriceIncreaseInItemRevision": $block_price_increase_in_item_revision, "description": $description, "endDate": $end_date, "marketplaceId": $marketplace_id, "name": $name, "priority": $priority, "promotionImageUrl": $promotion_image_url, "promotionStatus": $promotion_status, "selectedInventoryDiscounts": $selected_inventory_discounts, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method deletes the item price markdown promotion specified by the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions. You can delete any promotion with the exception of those that are currently active (RUNNING). To end a running promotion, call updateItemPriceMarkdownPromotion (/api-docs/sell/marketing/resources/item_price_markdown/methods/updateItemPriceMarkdownPromotion) and adjust the endDate field as appropriate.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_price_markdown/{promotion_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# This method returns the complete details of the item price markdown promotion that's indicated by the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<applyFreeShipping: bool, autoSelectFutureInventory: bool, blockPriceIncreaseInItemRevision: bool, description: string, endDate: string, marketplaceId: string, name: string, priority: string, promotionImageUrl: string, promotionStatus: string, selectedInventoryDiscounts: table<discountBenefit: record, discountId: string, inventoryCriterion: record, ruleOrder: int>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_price_markdown/{promotion_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method updates the specified item price markdown promotion with the new configuration that you supply in the payload of the request. Specify the promotion you want to update using the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions. When updating a promotion, supply all the fields that you used to configure the original promotion (and not just the fields you are updating). eBay replaces the specified promotion with the values you supply in the update request and if you don't pass a field that currently has a value, the update request fails. The parameters you are allowed to update with this request depend on the status of the promotion you're updating: DRAFT or SCHEDULED promotions: You can update any of the parameters in these promotions that have not yet started to run, including the discountRules. RUNNING promotions: You can change the endDate and the item's inventory but you cannot change the promotional discount or the promotion's start date. ENDED promotions: Nothing can be changed.
#
# PUT /item_price_markdown/{promotion_id}
# operationId: updateItemPriceMarkdownPromotion
# --selectedInventoryDiscounts item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
export def "item-price-markdown update" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-free-shipping: oneof<nothing, bool> # If set to true, free shipping is applied to the first shipping service specified for the item. The first domestic shipping option is set to "free shipping," regardless if the shipping optionType for that service is set to FLAT_RATE, CALCULATED, or NOT_SPECIFIED (freight). This flag essentially adds free shipping as a promotional bonus. Default: false
  --auto-select-future-inventory: oneof<nothing, bool> # If set to true, eBay will automatically add inventory items to the markdown promotion if they meet the selectedInventoryDiscounts criteria specified for the markdown promotion. Default: false
  --block-price-increase-in-item-revision: oneof<nothing, bool> # If set to true, price increases (including removing the free shipping flag) are blocked and an error message is returned if a seller attempts to adjust the price of an item that's partaking in this markdown promotion. If set to false, an item is dropped from the markdown promotion if the seller adjusts the price. Default: false
  --description: string # This field is required if you are configuring an MARKDOWN_SALE promotion. This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." A tag line appears under the "offer-type text" that is generated for the promotion. The text is displayed on the offer tile that is shown on the seller's All Offers page and on the event page for the promotion. Note: Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. This text is not editable by the seller&mdash;it's derived from the settings in the discountRules and discountSpecification fields&mdash;and can be, for example, "20% off". Maximum length: 50
  --end-date: string # The date and time the promotion ends, in UTC format (yyyy-MM-ddThh:mm:ssZ). The value supplied for endDate must be at least 24 hours after the value supplied for the startDate of the markdown promotion.For display purposes, convert this time into the local time of the seller. Max value:14 days for the AT, CH, DE, ES, FR, IE, IT, and UK, marketplaces. 45 days for all other marketplaces.
  --marketplace-id: string # The eBay marketplace ID of the site where the markdown promotion is hosted. Markdown promotions are supported on all eBay marketplaces. For implementation help, refer to eBay API documentation
  --name: string # The seller-defined name or 'title' of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows. Maximum length: 90
  --priority: string # This field is ignored in markdown promotions. For implementation help, refer to eBay API documentation
  --promotion-image-url: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's All Offers page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotion-status: string # The current status of the promotion. When creating a new promotion, you must set this value to either DRAFT or SCHEDULED. Note that you must set this value to SCHEDULED when you update a RUNNING promotion. For implementation help, refer to eBay API documentation
  --selected-inventory-discounts: list # A list that defines the sets of selected items for the markdown promotion and the discount specified for promotion. — item shape: {discountBenefit?: record, discountId?: string, inventoryCriterion?: record, ruleOrder?: int}
  --start-date: string # The date and time the promotion starts in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_price_markdown/{promotion_id}") $auth.query)
  let req_body = {"applyFreeShipping": $apply_free_shipping, "autoSelectFutureInventory": $auto_select_future_inventory, "blockPriceIncreaseInItemRevision": $block_price_increase_in_item_revision, "description": $description, "endDate": $end_date, "marketplaceId": $marketplace_id, "name": $name, "priority": $priority, "promotionImageUrl": $promotion_image_url, "promotionStatus": $promotion_status, "selectedInventoryDiscounts": $selected_inventory_discounts, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# This method creates an item promotion, where the buyer receives a discount when they meet the buying criteria that's set for the promotion. Known here as "threshold promotions", these promotions trigger when a threshold is met. eBay highlights promoted items by placing teasers for the promoted items throughout the online buyer flows. Discounts are specified as either a monetary amount or a percentage off the standard sales price of a listing, letting you offer deals such as "Buy 1 Get 1" and "Buy $50, get 20% off". Volume pricing promotions increase the value of the discount as the buyer increases the quantity they purchase. Coded Coupons provide unique codes that a buyer can use during checkout to receive a discount. The seller can specify the number of times a buyer can use the coupon and the maximum amount across all purchases that can be discounted using the coupon. The coupon code can also be made public (appearing on the seller's Offer page, search pages, the item listing, and the checkout page) or private (only on the seller's Offer page, but the seller can include the code in email and social media). Note: Coded Coupons are currently available in the US, UK, DE, FR, IT, ES, and AU marketplaces.There are two ways to add items to a threshold promotion: Key-based promotions select items using either the listing IDs or inventory reference IDs of the items you want to promote. Note that if you use inventory reference IDs, you must specify both the inventoryReferenceId and the associated inventoryReferenceType of the item(s) you want to include the promotion. Rule-based promotions select items using a list of eBay category IDs or seller Store category IDs. Rules can further constrain items in a promotion by minimum and maximum prices, brands, and item conditions. You must create a new promotion in either a DRAFT or SCHEDULED state. Use the DRAFT state when you are initially creating a promotion and you want to be sure it's correctly configured before scheduling it to run. When you create a promotion, the promotion ID is returned in the Location response header. Use this ID to reference the promotion in subsequent requests. Tip: Refer to the Selling Integration Guide (/api-docs/sell/static/marketing/promotions-manager.html) for details and examples showing how to create and manage threshold promotions using the Promotions Manager. For information on the eBay marketplaces that support item promotions, see Promotions Manager requirements and restrictions (/api-docs/sell/marketing/static/overview.html#PM-requirements).
#
# POST /item_promotion
# operationId: createItemPromotion
# --budget shape: {currency?: string, value?: string}
# --couponConfiguration shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
# --discountRules item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
# --inventoryCriterion shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list<string>, ruleCriteria?: record}
export def "item-promotion create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-discount-to-single-item-only: oneof<nothing, bool> # This flag is relevant in only when promotionType is set to VOLUME_DISCOUNT. For details on volume pricing promotions, see Configuring volume pricing discounts (/api-docs/sell/static/marketing/pm-volume-discounts.html). If set to true, the discount is applied only when the buyer purchases multiple quantities of a single item in the promotion. Otherwise, the promotional discount applies to multiple quantities of any items in the promotion. Different variations of a multi-variation item are considered to be the same item. Note that this flag is not relevant if the inventoryCriterion container identifies a single listing ID for the promotion.
  --budget: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --coupon-configuration: record # This container defines a coded coupon promotion. It is required if the promotion type is CODED_COUPON. — shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
  --description: string # This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." The tag line appears under the "offer-type text" that is generated for the promotion and is displayed on the offer tile that's shown on the seller's All Offers page, and on the event page for the promotion. Note: Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. The offer-type text is not editable by the seller&mdash;it's derived from the settings in the discountRules and discountSpecification fields&mdash;and can be, for example, "Extra 20% off when you buy 3+". Maximum length: 50 Required if you are configuring CODED_COUPON, ORDER_DISCOUNT, or MARKDOWN_SALE promotions (and not valid for VOLUME_DISCOUNT promotions).
  --discount-rules: list # This container defines a promotion using the following two required fields: discountBenefit &ndash; Defines a discount as either a monetary amount or a percentage that is subtracted from the sales price of an item, a set of items, or an order. discountSpecification &ndash; Defines a set of rules that determine when the promotion is applied. Note: For volume pricing, you must specify at least two and not more than four discountBenefit/discountSpecification pairs. In addition, you must define each set of rules with a ruleOrder value that corresponds with the order of volume discounts you present. Tip: Refer to Specifying item promotion discounts (/api-docs/sell/static/marketing/pm-specifying-discounts.html) for information and examples on how to combine discountBenefit and discountSpecification to create different types of promotions. — item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
  --end-date: string # The date and time the promotion ends in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
  --inventory-criterion: record # This type defines either the selections rules or the list of listing IDs for the promotion. The "listing IDs" are are either the seller's item IDs or the eBay listing IDs. — shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list<string>, ruleCriteria?: record}
  --marketplace-id: string # The eBay marketplace ID of the site where the threshold promotion is hosted. Threshold promotions are currently supported on a limited number of eBay marketplaces. Valid values: EBAY_AU = Australia EBAY_DE = Germany EBAY_ES = Spain EBAY_FR = France EBAY_GB = Great Britain EBAY_IT = Italy EBAY_US = United States For implementation help, refer to eBay API documentation
  --name: string # The seller-defined name or "title" of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows. Maximum length: 90
  --priority: string # Applicable for only ORDER_DISCOUNT promotions, this field indicates the precedence of the promotion, which is used to determine the position of a promotion on the seller's All Offers page. If an item is associated with multiple promotions, the promotion with the higher priority takes precedence. For implementation help, refer to eBay API documentation
  --promotion-image-url: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, and not valid for VOLUME_DISCOUNT promotions. Populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's All Offers page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotion-status: string # The current status of the promotion. When creating a new promotion, this value must be set to either DRAFT or SCHEDULED. Note that you must set this value to SCHEDULED when you update a RUNNING promotion. For implementation help, refer to eBay API documentation
  --promotion-type: string # Use this field to specify the type of the promotion you are creating. The supported types are: CODED_COUPON &ndash; A coupon code promotion set with createItemPromotion. MARKDOWN_SALE &ndash; A markdown promotion set with createItemPriceMarkdownPromotion. ORDER_DISCOUNT &ndash; A threshold promotion set with createItemPromotion. VOLUME_DISCOUNT &ndash; A volume pricing promotion set with createItemPromotion. See the Promotions Manager (/api-docs/sell/static/marketing/promotions-manager.html) documentation for details. Required if you are creating a volume pricing promotion (VOLUME_DISCOUNT). For implementation help, refer to eBay API documentation
  --start-date: string # The date and time the promotion starts in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
]: any -> record<warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item_promotion" $auth.query)
  let req_body = {"applyDiscountToSingleItemOnly": $apply_discount_to_single_item_only, "budget": $budget, "couponConfiguration": $coupon_configuration, "description": $description, "discountRules": $discount_rules, "endDate": $end_date, "inventoryCriterion": $inventory_criterion, "marketplaceId": $marketplace_id, "name": $name, "priority": $priority, "promotionImageUrl": $promotion_image_url, "promotionStatus": $promotion_status, "promotionType": $promotion_type, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# This method deletes the threshold promotion specified by the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions. You can delete any promotion with the exception of those that are currently active (RUNNING). To end a running threshold promotion, call updateItemPromotion (/api-docs/sell/marketing/resources/item_promotion/methods/updateItemPromotion) and adjust the endDate field as appropriate.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_promotion/{promotion_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# This method returns the complete details of the threshold promotion specified by the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<applyDiscountToSingleItemOnly: bool, budget: record<currency: string, value: string>, couponConfiguration: record<couponCode: string, couponType: string, maxCouponRedemptionPerUser: int>, description: string, discountRules: table<discountBenefit: record, discountSpecification: record, maxDiscountAmount: record, ruleOrder: int>, endDate: string, inventoryCriterion: record<inventoryCriterionType: string, inventoryItems: list<record>, listingIds: list<string>, ruleCriteria: record<excludeInventoryItems: list, excludeListingIds: list, markupInventoryItems: list, markupListingIds: list, selectionRules: list>>, marketplaceId: string, name: string, priority: string, promotionId: string, promotionImageUrl: string, promotionStatus: string, promotionType: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_promotion/{promotion_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method updates the specified threshold promotion with the new configuration that you supply in the request. Indicate the promotion you want to update using the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions. When updating a promotion, supply all the fields that you used to configure the original promotion (and not just the fields you are updating). eBay replaces the specified promotion with the values you supply in the update request and if you don't pass a field that currently has a value, the update request will fail. The parameters you are allowed to update with this request depend on the status of the promotion you're updating: DRAFT or SCHEDULED promotions: You can update any of the parameters in these promotions that have not yet started to run, including the discountRules. RUNNING or PAUSED promotions: You can change the endDate and the item's inventory but you cannot change the promotional discount or the promotion's start date. ENDED promotions: Nothing can be changed. Tip: When updating a RUNNING or PAUSED promotion, set the status field to SCHEDULED for the update request. When the promotion is updated, the previous status (either RUNNING or PAUSED) is retained.
#
# PUT /item_promotion/{promotion_id}
# operationId: updateItemPromotion
# --budget shape: {currency?: string, value?: string}
# --couponConfiguration shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
# --discountRules item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
# --inventoryCriterion shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list<string>, ruleCriteria?: record}
export def "item-promotion update" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apply-discount-to-single-item-only: oneof<nothing, bool> # This flag is relevant in only when promotionType is set to VOLUME_DISCOUNT. For details on volume pricing promotions, see Configuring volume pricing discounts (/api-docs/sell/static/marketing/pm-volume-discounts.html). If set to true, the discount is applied only when the buyer purchases multiple quantities of a single item in the promotion. Otherwise, the promotional discount applies to multiple quantities of any items in the promotion. Different variations of a multi-variation item are considered to be the same item. Note that this flag is not relevant if the inventoryCriterion container identifies a single listing ID for the promotion.
  --budget: record # A complex type that describes the value of a monetary amount as represented by a global currency. — shape: {currency?: string, value?: string}
  --coupon-configuration: record # This container defines a coded coupon promotion. It is required if the promotion type is CODED_COUPON. — shape: {couponCode?: string, couponType?: string, maxCouponRedemptionPerUser?: int}
  --description: string # This is the seller-defined "tag line" for the offer, such as "Save on designer shoes." The tag line appears under the "offer-type text" that is generated for the promotion and is displayed on the offer tile that's shown on the seller's All Offers page, and on the event page for the promotion. Note: Offer-type text is a teaser that's presented throughout the buyer's journey through the sales flow and is generated by eBay. The offer-type text is not editable by the seller&mdash;it's derived from the settings in the discountRules and discountSpecification fields&mdash;and can be, for example, "Extra 20% off when you buy 3+". Maximum length: 50 Required if you are configuring CODED_COUPON, ORDER_DISCOUNT, or MARKDOWN_SALE promotions (and not valid for VOLUME_DISCOUNT promotions).
  --discount-rules: list # This container defines a promotion using the following two required fields: discountBenefit &ndash; Defines a discount as either a monetary amount or a percentage that is subtracted from the sales price of an item, a set of items, or an order. discountSpecification &ndash; Defines a set of rules that determine when the promotion is applied. Note: For volume pricing, you must specify at least two and not more than four discountBenefit/discountSpecification pairs. In addition, you must define each set of rules with a ruleOrder value that corresponds with the order of volume discounts you present. Tip: Refer to Specifying item promotion discounts (/api-docs/sell/static/marketing/pm-specifying-discounts.html) for information and examples on how to combine discountBenefit and discountSpecification to create different types of promotions. — item shape: {discountBenefit?: record, discountSpecification?: record, maxDiscountAmount?: record, ruleOrder?: int}
  --end-date: string # The date and time the promotion ends in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
  --inventory-criterion: record # This type defines either the selections rules or the list of listing IDs for the promotion. The "listing IDs" are are either the seller's item IDs or the eBay listing IDs. — shape: {inventoryCriterionType?: string, inventoryItems?: list, listingIds?: list<string>, ruleCriteria?: record}
  --marketplace-id: string # The eBay marketplace ID of the site where the threshold promotion is hosted. Threshold promotions are currently supported on a limited number of eBay marketplaces. Valid values: EBAY_AU = Australia EBAY_DE = Germany EBAY_ES = Spain EBAY_FR = France EBAY_GB = Great Britain EBAY_IT = Italy EBAY_US = United States For implementation help, refer to eBay API documentation
  --name: string # The seller-defined name or "title" of the promotion that the seller can use to identify a promotion. This label is not displayed in end-user flows. Maximum length: 90
  --priority: string # Applicable for only ORDER_DISCOUNT promotions, this field indicates the precedence of the promotion, which is used to determine the position of a promotion on the seller's All Offers page. If an item is associated with multiple promotions, the promotion with the higher priority takes precedence. For implementation help, refer to eBay API documentation
  --promotion-image-url: string # Required for CODED_COUPON, MARKDOWN_SALE, and ORDER_DISCOUNT promotions, and not valid for VOLUME_DISCOUNT promotions. Populate this field with a URL that points to an image to be used with the promotion. This image is displayed on the seller's All Offers page. The URL must point to either JPEG or PNG image and it must be a minimum of 500x500 pixels in dimension and cannot exceed 12Mb in size.
  --promotion-status: string # The current status of the promotion. When creating a new promotion, this value must be set to either DRAFT or SCHEDULED. Note that you must set this value to SCHEDULED when you update a RUNNING promotion. For implementation help, refer to eBay API documentation
  --promotion-type: string # Use this field to specify the type of the promotion you are creating. The supported types are: CODED_COUPON &ndash; A coupon code promotion set with createItemPromotion. MARKDOWN_SALE &ndash; A markdown promotion set with createItemPriceMarkdownPromotion. ORDER_DISCOUNT &ndash; A threshold promotion set with createItemPromotion. VOLUME_DISCOUNT &ndash; A volume pricing promotion set with createItemPromotion. See the Promotions Manager (/api-docs/sell/static/marketing/promotions-manager.html) documentation for details. Required if you are creating a volume pricing promotion (VOLUME_DISCOUNT). For implementation help, refer to eBay API documentation
  --start-date: string # The date and time the promotion starts in UTC format (yyyy-MM-ddThh:mm:ssZ). For display purposes, convert this time into the local time of the seller.
]: any -> record<warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/item_promotion/{promotion_id}") $auth.query)
  let req_body = {"applyDiscountToSingleItemOnly": $apply_discount_to_single_item_only, "budget": $budget, "couponConfiguration": $coupon_configuration, "description": $description, "discountRules": $discount_rules, "endDate": $end_date, "inventoryCriterion": $inventory_criterion, "marketplaceId": $marketplace_id, "name": $name, "priority": $priority, "promotionImageUrl": $promotion_image_url, "promotionStatus": $promotion_status, "promotionType": $promotion_type, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method can be used to retrieve all of the negative keywords for ad groups in PLA campaigns that use the Cost Per Click (CPC) funding model.The results can be filtered using the campaign_ids, ad_group_ids, and negative_keyword_status query parameters.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a seller.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-ids: string # A comma-separated list of ad group IDs.This query parameter is used if the seller wants to retrieve the negative keywords from one or more specific ad groups. The results might not include these ad group IDs if other search conditions exclude them.Note:You can call the getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) method to retrieve the ad group IDs for a seller.Required if the search results must be filtered to include negative keywords created at the ad group level.
  --campaign-ids: string # A unique eBay-assigned ID for an ad campaign that is generated when a campaign is created.This query parameter is used if the seller wants to retrieve the negative keywords from a specific campaign. The results might not include these campaign IDs if other search conditions exclude them.Note: Currently, only one campaign ID value is supported for each request.
  --limit: string # The number of results, from the current result set, to be returned in a single page.
  --negative-keyword-status: string # A comma-separated list of negative keyword statuses.This query parameter is used if the seller wants to filter the search results based on one or more negative keyword statuses.
  --offset: string # The number of results that will be skipped in the result set. This is used with the limit field to control the pagination of the output.For example, if the offset is set to 0 and the limit is set to 10, the method will retrieve items 1 through 10 from the list of items returned. If the offset is set to 10 and the limit is set to 10, the method will retrieve items 11 through 20 from the list of items returned.
]: nothing -> record<href: string, limit: int, negativeKeywords: table<adGroupId: string, campaignId: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordStatus: string, negativeKeywordText: string>, next: string, offset: int, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ad_group_ids" $ad_group_ids "scalar") (serialize-qp "campaign_ids" $campaign_ids "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "negative_keyword_status" $negative_keyword_status "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/negative_keyword" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ad_group_ids": $ad_group_ids, "campaign_ids": $campaign_ids, "limit": $limit, "negative_keyword_status": $negative_keyword_status, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method adds a negative keyword to an existing ad group in a PLA campaign that uses the Cost Per Click (CPC) funding model.Specify the campaignId and adGroupId in the request body, along with the negativeKeywordText and negativeKeywordMatchType.Call the getCampaigns (/api-docs/sell/marketing/resources/campaign/methods/getCampaigns) method to retrieve a list of current campaign IDs for a specified seller.
#
# POST /negative_keyword
# operationId: createNegativeKeyword
export def "negative-keyword create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ad-group-id: string # This adGroupId is created when an ad group is first created and associated with a campaign. This is the ad group to which the corresponding negative keyword will be added.Note: You can call the getAdGroups (/api-docs/sell/marketing/resources/adgroup/methods/getAdGroups) method to retrieve the ad group IDs for a seller.Required if the negative keyword is being created at the ad group level.
  --campaign-id: string # A unique eBay-assigned ID for a campaign. This ID is generated when a campaign is created.Required if the negative keyword is being created at the ad group level.
  --negative-keyword-match-type: string # A field that defines the match type for the negative keyword.Note: Broad matching of negative keywords is not currently supported.Valid Values:EXACTPHRASE For implementation help, refer to eBay API documentation
  --negative-keyword-text: string # The negative keyword text.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/negative_keyword" $auth.query)
  let req_body = {"adGroupId": $ad_group_id, "campaignId": $campaign_id, "negativeKeywordMatchType": $negative_keyword_match_type, "negativeKeywordText": $negative_keyword_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method retrieves details on a specific negative keyword.In the request, specify the negative_keyword_id as a path parameter.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adGroupId: string, campaignId: string, negativeKeywordId: string, negativeKeywordMatchType: string, negativeKeywordStatus: string, negativeKeywordText: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($negative_keyword_id | is-empty) { error make --unspanned { msg: "path parameter 'negative_keyword_id' must be non-empty" } }
  let full_url = (build-url $base ({negative_keyword_id: (encode-path-segment $negative_keyword_id)} | format pattern "/negative_keyword/{negative_keyword_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Note: This method is only available for select partners who have been approved for the eBay Promoted Listings Advanced (PLA) program. For information about how to request access to this program, refer to Promoted Listings Advanced Access Requests (/api-docs/sell/static/marketing/pl-verify-eligibility.html#access-requests ) in the Promoted Listings Playbook. To determine if a seller qualifies for PLA, use the getAdvertisingEligibility (/api-docs/sell/account/resources/advertising_eligibility/methods/getAdvertisingEligibility ) method in Account API.This method updates the status of an existing negative keyword.Specify the negative_keyword_id as a path parameter, and specify the negativeKeywordStatus in the request body.
#
# PUT /negative_keyword/{negative_keyword_id}
# operationId: updateNegativeKeyword
export def "negative-keyword update" [
  negative_keyword_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --negative-keyword-status: string # A field that defines the status of the negative keyword. For implementation help, refer to eBay API documentation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($negative_keyword_id | is-empty) { error make --unspanned { msg: "path parameter 'negative_keyword_id' must be non-empty" } }
  let full_url = (build-url $base ({negative_keyword_id: (encode-path-segment $negative_keyword_id)} | format pattern "/negative_keyword/{negative_keyword_id}") $auth.query)
  let req_body = {"negativeKeywordStatus": $negative_keyword_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# This method returns a list of a seller's undeleted promotions. The call returns up to 200 currently-available promotions on the specified marketplace. While the response body does not include the promotion's discountRules or inventoryCriterion containers, it does include the promotionHref (which you can use to retrieve the complete details of the promotion). Use query parameters to sort and filter the results by the number of promotions to return, the promotion state or type, and the eBay marketplace. You can also supply keywords to limit the response to the promotions that contain that keywords in the title of the promotion. Maximum returned: 200
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set. Default: 200 Maximum: 200
  --marketplace-id: string # The eBay marketplace ID of the site where the promotion is hosted. Valid values: EBAY_AU = Australia EBAY_DE = Germany EBAY_ES = Spain EBAY_FR = France EBAY_GB = Great Britain EBAY_IT = Italy EBAY_US = United States
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --promotion-status: string # Specifies the promotion state by which you want to filter the results. The response contains only those promotions that match the state you specify. Valid values: DRAFT SCHEDULED RUNNING PAUSED ENDEDMaximum number of input values: 1
  --promotion-type: string # Filters the returned promotions based on their campaign promotion type. Specify one of the following values to indicate the promotion type you want returned: CODED_COUPON &ndash; A coupon code promotion set with createItemPromotion. MARKDOWN_SALE &ndash; A markdown promotion set with createItemPriceMarkdownPromotion. ORDER_DISCOUNT &ndash; A threshold promotion set with createItemPromotion. VOLUME_DISCOUNT &ndash; A volume pricing promotion set with createItemPromotion.
  --q: string # A string consisting of one or more keywords. eBay filters the response by returning only the promotions that contain the supplied keywords in the promotion title. Example: "iPhone" or "Harry Potter." Commas that separate keywords are ignored. For example, a keyword string of "iPhone, iPad" equals "iPhone iPad", and each results in a response that contains promotions with both "iPhone" and "iPad" in the title.
  --qp-sort: string # Specifies the order for how to sort the response. If you precede the supplied value with a dash, the response is sorted in reverse order. Example: sort=END_DATE Sorts the promotions in the response by their end dates in ascending order sort=-PROMOTION_NAME Sorts the promotions by their promotion name in descending alphabetical order (Z-Az-a) Valid values:START_DATE END_DATE PROMOTION_NAME For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/csb:SortField
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, promotions: table<couponCode: string, description: string, endDate: string, marketplaceId: string, name: string, priority: string, promotionHref: string, promotionId: string, promotionImageUrl: string, promotionStatus: string, promotionType: string, startDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "promotion_status" $promotion_status "scalar") (serialize-qp "promotion_type" $promotion_type "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "marketplace_id": $marketplace_id, "offset": $offset, "promotion_status": $promotion_status, "promotion_type": $promotion_type, "q": $q, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method returns the set of listings associated with the promotion_id specified in the path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of a seller's promotions. The listing details are returned in a paginated set and you can control and results returned using the following query parameters: limit, offset, q, sort, and status. Maximum associated listings returned: 200 Default number of listings returned: 200
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set. Default: 200Maximum: 200
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --q: string # Reserved for future use.
  --qp-sort: string # Specifies the order in which to sort the associated listings in the response. If you precede the supplied value with a dash, the response is sorted in reverse order. Example: sort=PRICE - Sorts the associated listings by their current price in ascending order sort=-TITLE - Sorts the associated listings by their title in descending alphabetical order (Z-Az-a) Valid values:AVAILABLE PRICE TITLE For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/csb:SortField
  --status: string # This query parameter applies only to markdown promotions. It filters the response based on the indicated status of the promotion. Currently, the only supported value for this parameter is MARKED_DOWN, which indicates active markdown promotions. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/marketing/types/sme:ItemMarkdownStatusEnum
]: nothing -> record<href: string, limit: int, listings: table<currentPrice: record, freeShipping: bool, inventoryReferenceId: string, inventoryReferenceType: string, listingCategoryId: string, listingCondition: string, listingConditionId: string, listingId: string, listingPromotionStatuses: list, quantity: int, storeCategoryId: string, title: string>, next: string, offset: int, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/promotion/{promotion_id}/get_listing_set") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset, "q": $q, "sort": $qp_sort, "status": $status} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method pauses a currently-active (RUNNING) threshold promotion and changes the state of the promotion from RUNNING to PAUSED. Pausing a promotion makes the promotion temporarily unavailable to buyers and any currently-incomplete transactions will not receive the promotional offer until the promotion is resumed. Also, promotion teasers are not displayed when a promotion is paused. Pass the ID of the promotion you want to pause using the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of the seller's promotions. Note: You can only pause threshold promotions (you cannot pause markdown promotions).
#
# POST /promotion/{promotion_id}/pause
# operationId: pausePromotion
export def "promotion-pause pause" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/promotion/{promotion_id}/pause") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This method restarts a threshold promotion that was previously paused and changes the state of the promotion from PAUSED to RUNNING. Only promotions that have been previously paused can be resumed. Resuming a promotion reinstates the promotional teasers and any transactions that were in motion before the promotion was paused will again be eligible for the promotion. Pass the ID of the promotion you want to resume using the promotion_id path parameter. Call getPromotions (/api-docs/sell/marketing/resources/promotion/methods/getPromotions) to retrieve the IDs of the seller's promotions.
#
# POST /promotion/{promotion_id}/resume
# operationId: resumePromotion
export def "promotion-resume create" [
  promotion_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({promotion_id: (encode-path-segment $promotion_id)} | format pattern "/promotion/{promotion_id}/resume") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# This method generates a report that lists the seller's running, paused, and ended promotions for the specified eBay marketplace. The result set can be filtered by the promotion status and the number of results to return. You can also supply keywords to limit the report to promotions that contain the specified keywords. Specify the eBay marketplace for which you want the report run using the marketplace_id query parameter. Supply additional query parameters to control the report as needed.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Specifies the maximum number of promotions returned on a page from the result set. Default: 200 Maximum: 200
  --marketplace-id: string # The eBay marketplace ID of the site for which you want the promotions report. Valid values: EBAY_AU = Australia EBAY_DE = Germany EBAY_ES = Spain EBAY_FR = France EBAY_GB = Great Britain EBAY_IT = Italy EBAY_US = United States
  --offset: string # Specifies the number of promotions to skip in the result set before returning the first promotion in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --promotion-status: string # Limits the results to the promotions that are in the state specified by this query parameter. Valid values: DRAFT SCHEDULED RUNNING PAUSED ENDEDMaximum number of values supported: 1
  --promotion-type: string # Filters the returned promotions in the report based on their campaign promotion type. Specify one of the following values to indicate the promotion type you want returned in the report: CODED_COUPON &ndash; A coupon code promotion set with createItemPromotion. MARKDOWN_SALE &ndash; A markdown promotion set with createItemPriceMarkdownPromotion. ORDER_DISCOUNT &ndash; A threshold promotion set with createItemPromotion. VOLUME_DISCOUNT &ndash; A volume pricing promotion set with createItemPromotion.
  --q: string # A string consisting of one or more keywords. eBay filters the response by returning only the promotions that contain the supplied keywords in the promotion title. Example: "iPhone" or "Harry Potter." Commas that separate keywords are ignored. For example, a keyword string of "iPhone, iPad" equals "iPhone iPad", and each results in a response that contains promotions with both "iPhone" and "iPad" in the title.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, promotionReports: table<averageItemDiscount: record, averageItemRevenue: record, averageOrderDiscount: record, averageOrderRevenue: record, averageOrderSize: string, baseSale: record, itemsSoldQuantity: int, numberOfOrdersSold: int, percentageSalesLift: string, promotionHref: string, promotionId: string, promotionReportId: string, promotionSale: record, promotionType: string, totalDiscount: record, totalSale: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "marketplace_id" $marketplace_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "promotion_status" $promotion_status "scalar") (serialize-qp "promotion_type" $promotion_type "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion_report" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "marketplace_id": $marketplace_id, "offset": $offset, "promotion_status": $promotion_status, "promotion_type": $promotion_type, "q": $q} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# This method generates a report that summarizes the seller's promotions for the specified eBay marketplace. The report returns information on RUNNING, PAUSED, and ENDED promotions (deleted reports are not returned) and summarizes the seller's campaign performance for all promotions on a given site. For information about summary reports, see Reading the item promotion Summary report (/api-docs/sell/static/marketing/pm-summary-report.html).
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-id: string # The eBay marketplace ID of the site you for which you want a promotion summary report. Valid values: EBAY_AU = Australia EBAY_DE = Germany EBAY_ES = Spain EBAY_FR = France EBAY_GB = Great Britain EBAY_IT = Italy EBAY_US = United States
]: nothing -> record<baseSale: record<currency: string, value: string>, lastUpdated: string, percentageSalesLift: string, promotionSale: record<currency: string, value: string>, totalSale: record<currency: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplace_id" $marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/promotion_summary_report" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"marketplace_id": $marketplace_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
