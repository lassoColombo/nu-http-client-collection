# Auto-generated client for Search Ads 360 Reporting API vv0
# Source: https://api.apis.guru/v2/specs/googleapis.com/searchads360/v0/openapi.json
# Auth: --token flag or $env.SEARCH_ADS_360_REPORTING_API_TOKEN

const BASE_URL = "https://searchads360.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_ADS_360_REPORTING_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://searchads360.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def summaryRowSetting-completer [] { ["NO_SUMMARY_ROW" "SUMMARY_ROW_ONLY" "SUMMARY_ROW_WITH_RESULTS" "UNKNOWN" "UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customers-custom-columns searchads360customerscustomColumnslist" } } | get name | first)
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

# Returns all the custom columns associated with the customer in full detail.
#
# GET /v0/customers/{customerId}/customColumns
# operationId: searchads360.customers.customColumns.list
export def "customers-custom-columns searchads360customerscustomColumnslist" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<customColumns: table<description: string, id: string, name: string, queryable: bool, referencedSystemColumns: list, referencesAttributes: bool, referencesMetrics: bool, resourceName: string, valueType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v0/customers/($customerId)/customColumns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all rows that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:search
# operationId: searchads360.customers.searchAds360.search
export def "customers-search-ads360-search searchads360customerssearchAds360search" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --pageToken: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --body-query: string # Required. The query string.
  --returnTotalResultsCount: string@bool-completer # If true, the total number of results that match the query ignoring the LIMIT clause will be included in the response. Default is false.
  --summaryRowSetting: string@summaryRowSetting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
  --validateOnly: string@bool-completer # If true, the request is validated but not executed.
]: any -> record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, nextPageToken: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>, totalResultsCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v0/customers/($customerId)/searchAds360:search" $qp)
  let body = {pageSize: $pageSize, pageToken: $pageToken, query: $body_query, returnTotalResultsCount: $returnTotalResultsCount, summaryRowSetting: $summaryRowSetting, validateOnly: $validateOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all rows that match the search stream query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:searchStream
# operationId: searchads360.customers.searchAds360.searchStream
export def "customers-search-ads360-search-stream searchads360customerssearchAds360searchStream" [
  customerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --batchSize: int # The number of rows that are returned in each stream response batch. When too large batch is requested, the server may decide to further limit the number of returned rows. (format: int32)
  --body-query: string # Required. The query string.
  --summaryRowSetting: string@summaryRowSetting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
]: any -> record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, requestId: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v0/customers/($customerId)/searchAds360:searchStream" $qp)
  let body = {batchSize: $batchSize, query: $body_query, summaryRowSetting: $summaryRowSetting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all fields that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/searchAds360Fields:search
# operationId: searchads360.searchAds360Fields.search
export def "search-ads360-fields-search searchads360searchAds360Fieldssearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --pageSize: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --pageToken: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --body-query: string # Required. The query string.
]: any -> record<nextPageToken: string, results: table<attributeResources: list, category: string, dataType: string, enumValues: list, filterable: bool, isRepeated: bool, metrics: list, name: string, resourceName: string, segments: list, selectable: bool, selectableWith: list, sortable: bool, typeUrl: string>, totalResultsCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0/searchAds360Fields:search" $qp)
  let body = {pageSize: $pageSize, pageToken: $pageToken, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns just the requested field. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QuotaError]() [RequestError]()
#
# GET /v0/{resourceName}
# operationId: searchads360.searchAds360Fields.get
export def "search-ads360-fields searchads360searchAds360Fieldsget" [
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: string@bool-completer # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<attributeResources: list<string>, category: string, dataType: string, enumValues: list<string>, filterable: bool, isRepeated: bool, metrics: list<string>, name: string, resourceName: string, segments: list<string>, selectable: bool, selectableWith: list<string>, sortable: bool, typeUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v0/($resourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
