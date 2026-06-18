# Auto-generated client for  Seller Service Metrics API  v1.2.0
# Source: https://api.apis.guru/v2/specs/api.ebay.com/sell-analytics/1.2.0/openapi.json
# Auth: --token flag or $env.SELLER_SERVICE_METRICS_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/analytics/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SELLER_SERVICE_METRICS_API_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.ebay.com/sell/analytics/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customer-service-metric get" } } | get name | first)
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

# Use this method to retrieve a seller's performance and rating for the customer service metric. Control the response from the getCustomerServiceMetric method using the following path and query parameters: customer_service_metric_type controls the type of customer service transactions evaluated for the metric rating. evaluation_type controls the period you want to review. evaluation_marketplace_id specifies the target marketplace for the evaluation. Currently, metric data is returned for only peer benchmarking. For more detail on the workings of peer benchmarking, see Service metrics policy.
#
# GET /customer_service_metric/{customer_service_metric_type}/{evaluation_type}
# operationId: getCustomerServiceMetric
export def "customer-service-metric get" [
  customer_service_metric_type: string
  evaluation_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --evaluation-marketplace-id: string # Use this query parameter to specify the Marketplace ID to evaluate for the customer service metrics and benchmark data. For the list of supported marketplaces, see Analytics API requirements and restrictions. For implementation help, refer to eBay API documentation at https://developer.ebay.com/devzone/rest/api-ref/analytics/types/MarketplaceIdEnum.html
]: nothing -> record<dimensionMetrics: table<dimension: record, metrics: list>, evaluationCycle: record<endDate: string, evaluationDate: string, evaluationType: string, startDate: string>, marketplaceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "evaluation_marketplace_id" $evaluation_marketplace_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_service_metric_type: (encode-path-segment $customer_service_metric_type), evaluation_type: (encode-path-segment $evaluation_type)} | format pattern "/customer_service_metric/{customer_service_metric_type}/{evaluation_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This call retrieves all the standards profiles for the associated seller. A standards profile is a set of eBay seller metrics and the seller's associated compliance values (either TOP_RATED, ABOVE_STANDARD, or BELOW_STANDARD). A seller's multiple profiles are distinguished by two criteria, a "program" and a "cycle." A profile's program is one of three regions where the seller may have done business, or PROGRAM_GLOBAL to indicate all marketplaces where the seller has done business. The cycle value specifies whether the standards compliance values were determined at the last official eBay evaluation or at the time of the request.
#
# GET /seller_standards_profile
# operationId: findSellerStandardsProfiles
export def "seller-standards-profile find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<standardsProfiles: table<cycle: record, defaultProgram: bool, evaluationReason: string, metrics: list, program: string, standardsLevel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/seller_standards_profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This call retrieves a single standards profile for the associated seller. A standards profile is a set of eBay seller metrics and the seller's associated compliance values (either TOP_RATED, ABOVE_STANDARD, or BELOW_STANDARD). A seller can have multiple profiles distinguished by two criteria, a "program" and a "cycle." A profile's program is one of three regions where the seller may have done business, or PROGRAM_GLOBAL to indicate all marketplaces where the seller has done business. The cycle value specifies whether the standards compliance values were determined at the last official eBay evaluation (CURRENT) or at the time of the request (PROJECTED). Both cycle and a program values are required URI parameters for this method.
#
# GET /seller_standards_profile/{program}/{cycle}
# operationId: getSellerStandardsProfile
export def "seller-standards-profile get" [
  program: string
  cycle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cycle: record<cycleType: string, evaluationDate: string, evaluationMonth: string>, defaultProgram: bool, evaluationReason: string, metrics: table<benchmark: record, distributions: list, metricKey: string, value: string>, program: string, standardsLevel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({program: (encode-path-segment $program), cycle: (encode-path-segment $cycle)} | format pattern "/seller_standards_profile/{program}/{cycle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method returns a report that details the user traffic received by a seller's listings. A traffic report gives sellers the ability to review how often their listings appeared on eBay, how many times their listings are viewed, and how many purchases were made. The report also returns the report's start and end dates, and the date the information was last updated. When using this call: Be sure to URL-encode the values you pass in query parameters, as described in URI parameters. See the request samples below for details. You can only specify a single metric in the sort parameter and the specified metric must be listed in the metric parameter of your request. Parameter names are case sensitive, but metric names are not. For example, the following are correct: sort=LISTING_IMPRESSION_TOTAL sort=lisitng_impression_total metric=lisitng_impression_total However, these are incorrect: SORT=LISTING_IMPRESSION_TOTAL SORT=lisitng_impression_total Metric=lisitng_impression_total For more information, see Traffic report details.
#
# GET /traffic_report
# operationId: getTrafficReport
export def "traffic-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dimension: string # This query parameter specifies the dimension, or "attribute," that is applied to the report metric. Valid values: DAY or LISTING Examples If you specify dimension=DAY and metric=CLICK_THROUGH_RATE, the traffic report contains the number of times an item displayed on a search results page and the buyer clicked through to the View Item page for each day in the date range, as in: 12-06-17: 32, 12-07-17: 54, ... If you specify dimension=LISTING and metric=LISTING_IMPRESSION_STORE, the traffic report contains the number of times that listing appeared on the seller's store during the specified date range. For example, LISTING_IMPRESSION_STORE: 157 means the item appeared 157 times in the store during the date range.
  --filter: string # This query parameter refines the information returned in the traffic report. Configure the following properties of the filter parameter to tune the traffic report to your needs: date_range Limits the report to the specified range of dates. Format the date range by enclosing the earliest date and end date for the report in brackets ("[ ]"), as follows: [YYYYMMDD..YYYYMMDD] The maximum range between the start and end dates is 90 days, and the earliest start date you can specify is two years prior to the current date, which is defined as 730 days (365 * 2), not accounting for Leap Year. The last date for which traffic data exists is a value called lastUpdatedDate. eBay returns an error if you specify a date range greater than 90 days, or the start date is after the lastUpdatedDate. If the specified end date is beyond the lastUpdatedDate, eBay returns data up to the lastUpdatedDate. Required: Always listing_ids This filter limits the results to only the supplied list of listingId values. You can specify to 200 different listingId values. Enclose the list of IDs with curly braces ("{ }"), and separate multiple values with a pipe character ("|"). This filter only returns data for listings that have been either active or sold in last 90 days, and any unsold listings in the last 30 days. All listings must be the seller's and they must be listed on the marketplace specified by the marketplace_ids filter argument. marketplace_ids This filter limits the report to seller data related to only the specified marketplace ID (currently the filter allows only a single marketplace ID). Enclose the marketplace ID in curly braces ("{ }"). Valid values: EBAY_AU EBAY_DE EBAY_GB EBAY_US EBAY_MOTORS_US Required if you set the dimension parameter to DAY. traffic_source Limits the report to either Promoted Listings items or non-Promoted Listings (organic) items. Valid values are ORGANIC and PROMOTED_LISTINGS. Enclose the list of values with curly braces ("{ }"), and separate multiple values with a pipe character ("|") The default is both values. Example filter parameter The following example shows how to configure the filter parameter with the marketplace_ids and date_range filters: filter=marketplace_ids:{EBAY_US},date_range:[20170601..20170828] Note: You must URL encode all the values you supply in the filter parameter, as described in URL parameters. For implementation help, refer to eBay API documentation at https://developer.ebay.com/devzone/rest/api-ref/analytics/types/FilterField.html
  --metric: string # This query parameter specifies the metrics you want covered in the report. Specify a comma-separated list of the metrics you want included in the report. Valid values: CLICK_THROUGH_RATE The number of times an item displays on the search results page divided by the number of times buyers clicked through to its View Item page. Localized name: Click through rate LISTING_IMPRESSION_SEARCH_RESULTS_PAGE The number of times the seller's listings displayed on the search results page. Note, the listing might not have been visible to the buyer due to its position on the page. Localized name: Listing impressions from the search results page LISTING_IMPRESSION_STORE The number of times the seller's listings displayed on the seller's store. Note, the listing might not have been visible to the buyer due to its position on the page. Localized name: Listing impressions from your Store LISTING_IMPRESSION_TOTAL The total number of times the seller's listings displayed on the search results page OR in the seller's store. The item is counted each time it displays on either page. However, the listing might not have been visible to the buyer due to its position on the page. This is a combination of: LISTING_IMPRESSION_SEARCH_RESULTS_PAGE + LISTING_IMPRESSION_STORE. Localized name: Total listing impressions LISTING_VIEWS_SOURCE_DIRECT The number of times a View Item page was directly accessed, such as when a buyer navigates to the page using a bookmark. Localized name: Direct views LISTING_VIEWS_SOURCE_OFF_EBAY The number of times a View Item page was accessed via a site other than eBay, such as when a buyer clicks on a link to the listing from a search engine page. Localized name: Off eBay views LISTING_VIEWS_SOURCE_OTHER_EBAY The number of times a View Item page was accessed from an eBay page that is not either the search results page or the seller's store. Localized name: Views from non-search and non-store pages within eBay LISTING_VIEWS_SOURCE_SEARCH_RESULTS_PAGE The number of times the item displayed on the search results page. Localized name: Views on the search results page LISTING_VIEWS_SOURCE_STORE The number of times a View Item page was accessed via the seller's store. Localized name: Views from your Store LISTING_VIEWS_TOTAL Total number of listings viewed. This number sums: LISTING_VIEWS_SOURCE_DIRECT LISTING_VIEWS_SOURCE_OFF_EBAY LISTING_VIEWS_SOURCE_OTHER_EBAY LISTING_VIEWS_SOURCE_SEARCH_RESULTS_PAGE LISTING_VIEWS_SOURCE_STORE. Localized name: Total views SALES_CONVERSION_RATE The number of completed transactions divided by the number of View Item page views. Equals: TRANSACTION / LISTING_VIEWS_TOTAL Localized name: Sales conversion rate TRANSACTION The total number of completed transactions. Localized name: Transaction count
  --qp-sort: string # This query parameter sorts the report on the specified metric. The metric you specify must be included in the configuration of the report's metric parameter. Sorting is helpful when you want to review how a specific metric is performing, such as the CLICK_THROUGH_RATE. Reports can be sorted in ascending or descending order. Precede the value of a descending-order request with a minus sign ("-"), for example: sort=-CLICK_THROUGH_RATE. For implementation help, refer to eBay API documentation at https://developer.ebay.com/devzone/rest/api-ref/analytics/types/SortField.html
]: nothing -> record<dimensionMetadata: table<metadataHeader: record, metadataRecords: list>, endDate: string, header: record<dimensionKeys: list<record>, metrics: list<record>>, lastUpdatedDate: string, records: table<dimensionValues: list, metricValues: list>, startDate: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dimension" $dimension "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "metric" $metric "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/traffic_report" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
