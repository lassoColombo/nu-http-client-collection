# Auto-generated client for Search Ads 360 Reporting API vv0
# Source: https://api.apis.guru/v2/specs/googleapis.com/searchads360/v0/openapi.json
# Auth: --token flag or $env.SEARCH_ADS_360_REPORTING_API_TOKEN

const BASE_URL = "https://searchads360.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_ADS_360_REPORTING_API_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://searchads360.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def summary-row-setting-completer [] { ["NO_SUMMARY_ROW" "SUMMARY_ROW_ONLY" "SUMMARY_ROW_WITH_RESULTS" "UNKNOWN" "UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customers-custom-columns list" } } | get name | first)
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
export def "customers-custom-columns list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<customColumns: table<description: string, id: string, name: string, queryable: bool, referencedSystemColumns: list, referencesAttributes: bool, referencesMetrics: bool, resourceName: string, valueType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v0/customers/{customer_id}/customColumns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}

# Returns all rows that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:search
# operationId: searchads360.customers.searchAds360.search
export def "customers-search-ads360-search list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --page-token: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --query: string # Required. The query string.
  --return-total-results-count: oneof<nothing, bool> # If true, the total number of results that match the query ignoring the LIMIT clause will be included in the response. Default is false.
  --summary-row-setting: string@summary-row-setting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
  --validate-only: oneof<nothing, bool> # If true, the request is validated but not executed.
]: any -> record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, nextPageToken: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>, totalResultsCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v0/customers/{customer_id}/searchAds360:search") $qp)
  let req_body = {"pageSize": $page_size, "pageToken": $page_token, "query": $query, "returnTotalResultsCount": $return_total_results_count, "summaryRowSetting": $summary_row_setting, "validateOnly": $validate_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns all rows that match the search stream query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/customers/{customerId}/searchAds360:searchStream
# operationId: searchads360.customers.searchAds360.searchStream
export def "customers-search-ads360-search-stream list" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --batch-size: int # The number of rows that are returned in each stream response batch. When too large batch is requested, the server may decide to further limit the number of returned rows. (format: int32)
  --query: string # Required. The query string.
  --summary-row-setting: string@summary-row-setting-completer # Determines whether a summary row will be returned. By default, summary row is not returned. If requested, the summary row will be sent in a response by itself after all other query results are returned.
]: any -> record<customColumnHeaders: table<id: string, name: string, referencesMetrics: bool>, fieldMask: string, requestId: string, results: table<adGroup: record, adGroupAd: record, adGroupAdLabel: record, adGroupAudienceView: record, adGroupBidModifier: record, adGroupCriterion: record, adGroupCriterionLabel: record, adGroupLabel: record, ageRangeView: record, biddingStrategy: record, campaign: record, campaignAudienceView: record, campaignBudget: record, campaignCriterion: record, campaignLabel: record, conversionAction: record, customColumns: list, customer: record, customerClient: record, customerManagerLink: record, dynamicSearchAdsSearchTermView: record, genderView: record, keywordView: record, label: record, locationView: record, metrics: record, productGroupView: record, segments: record, userList: record, webpageView: record>, summaryRow: record<adGroup: record<adRotationMode: string, cpcBidMicros: string, creationTime: string, endDate: string, engineId: string, engineStatus: string, id: string, labels: list, languageCode: string, lastModifiedTime: string, name: string, resourceName: string, startDate: string, status: string, targetingSetting: record, type: string>, adGroupAd: record<ad: record, creationTime: string, engineId: string, engineStatus: string, labels: list, lastModifiedTime: string, resourceName: string, status: string>, adGroupAdLabel: record<adGroupAd: string, label: string, resourceName: string>, adGroupAudienceView: record<resourceName: string>, adGroupBidModifier: record<bidModifier: float, device: record, resourceName: string>, adGroupCriterion: record<adGroup: string, ageRange: record, bidModifier: float, cpcBidMicros: string, creationTime: string, criterionId: string, effectiveCpcBidMicros: string, engineId: string, engineStatus: string, finalUrlSuffix: string, finalUrls: list, gender: record, keyword: record, labels: list, lastModifiedTime: string, listingGroup: record, location: record, negative: bool, qualityInfo: record, resourceName: string, status: string, trackingUrlTemplate: string, type: string, userList: record, webpage: record>, adGroupCriterionLabel: record<adGroupCriterion: string, label: string, resourceName: string>, adGroupLabel: record<adGroup: string, label: string, resourceName: string>, ageRangeView: record<resourceName: string>, biddingStrategy: record<campaignCount: string, currencyCode: string, effectiveCurrencyCode: string, enhancedCpc: record, id: string, maximizeConversionValue: record, maximizeConversions: record, name: string, nonRemovedCampaignCount: string, resourceName: string, status: string, targetCpa: record, targetImpressionShare: record, targetOutrankShare: record, targetRoas: record, targetSpend: record, type: string>, campaign: record<adServingOptimizationStatus: string, advertisingChannelSubType: string, advertisingChannelType: string, biddingStrategy: string, biddingStrategySystemStatus: string, biddingStrategyType: string, campaignBudget: string, createTime: string, creationTime: string, dynamicSearchAdsSetting: record, endDate: string, engineId: string, excludedParentAssetFieldTypes: list, finalUrlSuffix: string, frequencyCaps: list, geoTargetTypeSetting: record, id: string, labels: list, lastModifiedTime: string, manualCpa: record, manualCpc: record, manualCpm: record, maximizeConversionValue: record, maximizeConversions: record, name: string, networkSettings: record, optimizationGoalSetting: record, percentCpc: record, realTimeBiddingSetting: record, resourceName: string, selectiveOptimization: record, servingStatus: string, shoppingSetting: record, startDate: string, status: string, targetCpa: record, targetCpm: record, targetImpressionShare: record, targetRoas: record, targetSpend: record, trackingSetting: record, trackingUrlTemplate: string, urlCustomParameters: list, urlExpansionOptOut: bool>, campaignAudienceView: record<resourceName: string>, campaignBudget: record<amountMicros: string, deliveryMethod: string, period: string, resourceName: string>, campaignCriterion: record<ageRange: record, bidModifier: float, criterionId: string, device: record, displayName: string, gender: record, keyword: record, language: record, lastModifiedTime: string, location: record, locationGroup: record, negative: bool, resourceName: string, status: string, type: string, userList: record, webpage: record>, campaignLabel: record<campaign: string, label: string, resourceName: string>, conversionAction: record<appId: string, attributionModelSettings: record, category: string, clickThroughLookbackWindowDays: string, creationTime: string, floodlightSettings: record, id: string, includeInClientAccountConversionsMetric: bool, includeInConversionsMetric: bool, name: string, ownerCustomer: string, primaryForGoal: bool, resourceName: string, status: string, type: string, valueSettings: record>, customColumns: list<record>, customer: record<accountStatus: string, accountType: string, autoTaggingEnabled: bool, conversionTrackingSetting: record, creationTime: string, currencyCode: string, descriptiveName: string, doubleClickCampaignManagerSetting: record, engineId: string, finalUrlSuffix: string, id: string, lastModifiedTime: string, manager: bool, resourceName: string, status: string, timeZone: string, trackingUrlTemplate: string>, customerClient: record<appliedLabels: list, clientCustomer: string, currencyCode: string, descriptiveName: string, hidden: bool, id: string, level: string, manager: bool, resourceName: string, status: string, testAccount: bool, timeZone: string>, customerManagerLink: record<managerCustomer: string, managerLinkId: string, resourceName: string, status: string>, dynamicSearchAdsSearchTermView: record<landingPage: string, resourceName: string>, genderView: record<resourceName: string>, keywordView: record<resourceName: string>, label: record<id: string, name: string, resourceName: string, status: string, textLabel: record>, locationView: record<resourceName: string>, metrics: record<absoluteTopImpressionPercentage: float, allConversions: float, allConversionsByConversionDate: float, allConversionsFromClickToCall: float, allConversionsFromDirections: float, allConversionsFromInteractionsRate: float, allConversionsFromInteractionsValuePerInteraction: float, allConversionsFromMenu: float, allConversionsFromOrder: float, allConversionsFromOtherEngagement: float, allConversionsFromStoreVisit: float, allConversionsFromStoreWebsite: float, allConversionsValue: float, allConversionsValueByConversionDate: float, allConversionsValuePerCost: float, averageCost: float, averageCpc: float, averageCpm: float, clicks: string, clientAccountConversions: float, clientAccountConversionsValue: float, clientAccountViewThroughConversions: string, contentBudgetLostImpressionShare: float, contentImpressionShare: float, contentRankLostImpressionShare: float, conversions: float, conversionsByConversionDate: float, conversionsFromInteractionsRate: float, conversionsFromInteractionsValuePerInteraction: float, conversionsValue: float, conversionsValueByConversionDate: float, conversionsValuePerCost: float, costMicros: string, costPerAllConversions: float, costPerConversion: float, costPerCurrentModelAttributedConversion: float, crossDeviceConversions: float, crossDeviceConversionsValue: float, ctr: float, historicalCreativeQualityScore: string, historicalLandingPageQualityScore: string, historicalQualityScore: string, historicalSearchPredictedCtr: string, impressions: string, interactionEventTypes: list, interactionRate: float, interactions: string, invalidClickRate: float, invalidClicks: string, mobileFriendlyClicksPercentage: float, searchAbsoluteTopImpressionShare: float, searchBudgetLostAbsoluteTopImpressionShare: float, searchBudgetLostImpressionShare: float, searchBudgetLostTopImpressionShare: float, searchClickShare: float, searchExactMatchImpressionShare: float, searchImpressionShare: float, searchRankLostAbsoluteTopImpressionShare: float, searchRankLostImpressionShare: float, searchRankLostTopImpressionShare: float, searchTopImpressionShare: float, topImpressionPercentage: float, valuePerAllConversions: float, valuePerAllConversionsByConversionDate: float, valuePerConversion: float, valuePerConversionsByConversionDate: float, visits: float>, productGroupView: record<resourceName: string>, segments: record<conversionAction: string, conversionActionCategory: string, conversionActionName: string, date: string, dayOfWeek: string, device: string, month: string, quarter: string, week: string, year: int>, userList: record<id: string, name: string, resourceName: string, type: string>, webpageView: record<resourceName: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v0/customers/{customer_id}/searchAds360:searchStream") $qp)
  let req_body = {"batchSize": $batch_size, "query": $query, "summaryRowSetting": $summary_row_setting} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns all fields that match the search query. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QueryError]() [QuotaError]() [RequestError]()
#
# POST /v0/searchAds360Fields:search
# operationId: searchads360.searchAds360Fields.search
export def "search-ads360-fields-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Number of elements to retrieve in a single page. When too large a page is requested, the server may decide to further limit the number of returned resources. (format: int32)
  --page-token: string # Token of the page to retrieve. If not specified, the first page of results will be returned. Use the value obtained from `next_page_token` in the previous response in order to request the next page of results.
  --query: string # Required. The query string.
]: any -> record<nextPageToken: string, results: table<attributeResources: list, category: string, dataType: string, enumValues: list, filterable: bool, isRepeated: bool, metrics: list, name: string, resourceName: string, segments: list, selectable: bool, selectableWith: list, sortable: bool, typeUrl: string>, totalResultsCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v0/searchAds360Fields:search" $qp)
  let req_body = {"pageSize": $page_size, "pageToken": $page_token, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: $req_body}
}

# Returns just the requested field. List of thrown errors: [AuthenticationError]() [AuthorizationError]() [HeaderError]() [InternalError]() [QuotaError]() [RequestError]()
#
# GET /v0/{resourceName}
# operationId: searchads360.searchAds360Fields.get
export def "search-ads360-fields get" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<attributeResources: list<string>, category: string, dataType: string, enumValues: list<string>, filterable: bool, isRepeated: bool, metrics: list<string>, name: string, resourceName: string, segments: list<string>, selectable: bool, selectableWith: list<string>, sortable: bool, typeUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/v0/{resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type} | compact), body: null}
}
