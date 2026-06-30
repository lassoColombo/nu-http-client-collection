# Auto-generated client for Item Feed Service vv1_beta.34.0
# Source: https://api.apis.guru/v2/specs/ebay.com/buy-feed/v1_beta.34.0/openapi.json
# Auth: --token flag or $env.ITEM_FEED_SERVICE_TOKEN

const BASE_URL = "https://api.ebay.com/buy/feed/v1_beta"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ITEM_FEED_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ebay.com/buy/feed/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/tab-separated-values"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "item get-feed" } } | get name | first)
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

# This method lets you download a TSV_GZIP (tab separated value gzip) Item feed file. The feed file contains all the items from all the child categories of the specified category. The first line of the file is the header, which labels the columns and indicates the order of the values on each line. Each header is described in the Response fields (/api-docs/buy/feed/resources/item/methods/getItemFeed#h3-response-fields) section. There are two types of item feed files generated: A daily Item feed file containing all the newly listed items for a specific category, date, and marketplace (feed_scope = NEWLY_LISTED) A weekly Item Bootstrap feed file containing all the items in a specific category and marketplace (feed_scope = ALL_ACTIVE) Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed_beta.html#Feed2). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future.Downloading feed files Item feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). In addition to the API, there is an open source Feed SDK (https://github.com/eBay/FeedSDK) written in Java that downloads, combines files into a single file when needed, and unzips the entire feed file. It also lets you specify field filters to curate the items in the file. Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item
# operationId: getItemFeed
export def "item get-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feed-scope: string # Specifies the type of feed file to return. Valid Values: NEWLY_LISTED - Returns the daily Item feed file containing all Good 'Til Cancelled items that were listed on the day specified by the date parameter in the category specified by the category_id parameter./item?feed_scope=NEWLY_LISTED&category_id=15032&date=20170925ALL_ACTIVE - Returns the weekly Item Bootstrap feed file containing all the Good 'Til Cancelled items in the category specified by the category_id parameter.Note: Bootstrap files are generated every Tuesday and the file is available on Wednesday. However, the exact time the file is available can vary so we recommend you download the Bootstrap file on Thursday. The items in the file are the items that were in the specified category on Sunday. /item?feed_scope=ALL_ACTIVE&category_id=15032
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplace, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field. For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level (L1) category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces.
  --date: string # The date of the daily Item feed file (feed_scope=NEWLY_LISTED) you want. The date is required only for the daily Item feed file. If you specify a date for the Item Bootstrap file (feed_scope=ALL_ACTIVE), the date is ignored and the latest file is returned. The date the Item Bootstrap feed file was generated is returned in the Last-Modified response header. The Item feed files are generated every day and there are 14 daily files available. Note: The daily Item feed files are available each day after 9AM MST (US Mountain Standard Time), which is -7 hours UTC time. There is a 48 hour latency when generating the Item feed files. This means you can download the file for July 10th on July 12 after 9AM MST. Note: For categories with a large number of items, the latency can be up to 72 hours. Format: yyyyMMdd Requirements: Required when feed_scope=NEWLY_LISTED Must be within 3-14 days in the past
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format.Default: application/json,text/tab-separated-values
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API).
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox)
]: nothing -> record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, color: string, condition: string, conditionId: string, defaultImageUrl: string, deliveryOptions: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredBrand: string, inferredEpid: string, inferredGtin: string, inferredLocalizedAspects: string, inferredMpn: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemWebUrl: string, legacyItemId: string, lengthUnitOfMeasure: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, packageHeight: string, packageLength: string, packageWeight: string, packageWidth: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, priorityListingPayload: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string, weightUnitOfMeasure: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_scope" $feed_scope "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/item" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"feed_scope": $feed_scope, "category_id": $category_id, "date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204 206]
}

# This method lets you download a TSV_GZIP (tab separated value gzip) Item Group feed file. An item group is an item that has various aspect differences, such as color, size, storage capacity, etc. There are two types of item group feed files generated: A daily Item Group feed file containing the item group variation information associated with items returned in the Item (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file for a specific day, category, and marketplace. (feed_scope = NEWLY_LISTED) A weekly Item Group Bootstrap feed file containing all the item group variation information associated with items returned in the Item Bootstrap (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file for all the items in a specific category. (feed_scope = ALL_ACTIVE) Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future. The contents of these feed files are based on the contents of the corresponding daily Item or Item Bootstrap feed file. When a new Item or Item Bootstrap feed file is generated, the service reads the file and if an item in the file has a primaryItemGroupId value, which indicates the item is part of an item group, it uses that value to return the item group (parent item) information for that item in the corresponding Item Group or Item Group Bootstrap feed file. This information includes the name/value pair of the aspects of the items in this group returned in the variesByLocalizedAspects column. For example, if the item was a shirt some of the variation names could be Size, Color, etc. Also the images for the various aspects are returned in the additionalImageUrls column. The first line in any feed file is the header, which labels the columns and indicates the order of the values on each line. Each header is described in the Response fields (/api-docs/buy/feed/resources/item_group/methods/getItemGroupFeed#h3-response-fields) section. Combining the Item Group and Item feed files The Item Group or Item Group Bootstrap feed file contains details about the item group (parent item), including the item group ID itemGroupId. You match the value of itemGroupId from the Item Group feed file with the value of primaryItemGroupId from the corresponding daily Item or Item Bootstrap feed file.Downloading feed files Item Group feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/{swift-folder}/buy/static/api-feed_beta.html#retrv-gzip). Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/{swift-folder}/buy/feed/overview.html#API).
#
# GET /item_group
# operationId: getItemGroupFeed
export def "item-group get-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --feed-scope: string # Specifies the type of file to return. Valid Values: NEWLY_LISTED - Returns the Item Group feed file containing the item group variation information for items in the daily Item (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file that were associated with an item group. The items in this type of Item feed file are items that were listed on the day specified by the date parameter in the category specified by the category_id parameter. /item_group?feed_scope=NEWLY_LISTED&category_id=15032&date=20170925 ALL_ACTIVE - Returns the weekly Item Group Bootstrap file containing the item group variation information for items in the weekly Item Bootstrap (/api-docs/buy/feed/resources/item/methods/getItemFeed) feed file that were associated with an item group. The items are Good 'Til Cancelled items in the category specified by the category_id parameter. Note: Bootstrap files are generated every Tuesday and the file is available on Wednesday. However, the exact time the file is available can vary so we recommend you download the Bootstrap file on Thursday. The item groups in the file are for the items that were in the specified category on Sunday./item_group?feed_scope=ALL_ACTIVE&category_id=15032
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplaces, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field. For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces.
  --date: string # The date of the daily Item Group feed file (feed_scope=NEWLY_LISTED) you want. The date is required only for the daily Item Group feed file. If you specify a date for the Item Group Bootstrap file (feed_scope=ALL_ACTIVE), the date is ignored and the latest file is returned. The date the Item Group Bootstrap feed file was generated is returned in the Last-Modified response header. The Item Group feed files are generated every day and there are 14 daily files available. There is a 48 hour latency when generating the files. This means on July 10, the latest feed file you can download is July 8. Note: The generated files are stored using MST (US Mountain Standard Time), which is -7 hours UTC time. Format: yyyyMMdd Requirements: Required only when feed_scope=NEWLY_LISTED Must be within 3-14 days in the past
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API).
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox)
]: nothing -> record<itemGroups: table<additionalImageUrls: string, imageAlteringProhibited: bool, imageUrl: string, itemGroupId: string, itemGroupType: string, title: string, variesByLocalizedAspects: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed_scope" $feed_scope "scalar") (serialize-qp "category_id" $category_id "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/item_group" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"feed_scope": $feed_scope, "category_id": $category_id, "date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204 206]
}

# Using this method, you can download a TSV_GZIP (tab separated value gzip) Item Priority feed file, which allows you to track changes (deltas) in the status of your priority items, such as when an item is added or removed from a campaign. The delta feed tracks the changes to the status of items within a category you specify in the input URI. You can also specify a specific date for the feed you want returned. Important: You must consume the daily feeds (Item, Item Group) before consuming the Item Priority feed. This ensures that your inventory is up to date.Downloading feed files Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future.Priority Item feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). In addition to the API, there is an open source Feed SDK (https://github.com/eBay/FeedSDK) written in Java that downloads, combines files into a single file when needed, and unzips the entire feed file. It also lets you specify field filters to curate the items in the file. Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file. Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item_priority
# operationId: getItemPriorityFeed
export def "item-priority get-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplaces, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field.For example: "categoryTreeNodeLevel": 1 For details see Get the eBay categories of a marketplace (/api-docs/buy/api-feed.html#Getcat).Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces.
  --date: string # The date of the feed you want returned. This can be up to 14 days in the past but cannot be set to a date in the future. Format: yyyyMMdd Note: The daily Item feed files are available each day after 9AM MST (US Mountain Standard Time), which is -7 hours UTC time. There is a 48 hour latency when generating the Item feed files. This means you can download the file for July 10th on July 12 after 9AM MST. Note: For categories with a large number of items, the latency can be up to 72 hours.
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, Buy API Support by Marketplace (/api-docs/buy/static/ref-marketplace-supported.html).
  --range: string # Header specifying content range to be retrieved. Only supported range is bytes. Example : bytes = 0-102400.
]: nothing -> record<itemDelta: table<changeMetadata: string, itemId: string, priorityListingPayload: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/item_priority" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category_id": $category_id, "date": $date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204 206]
}

# The Hourly Snapshot feed file is generated each hour every day for most categories. This method lets you download an Hourly Snapshot TSV_GZIP (tab-separated value gzip) feed file containing the details of all the items that have changed (/api-docs/buy/static/api-feed.html#changed-items) within the specified day and hour for a specific category. This means to generate the 8AM file of items that have changed from 8AM and 8:59AM, the service starts at 9AM. You can retrieve the 8AM snapshot file at 10AM. Snapshot feeds now include new listings. You can check itemCreationDate (/api-docs/buy/feed/resources/item_snapshot/methods/getItemSnapshotFeed#response.items.itemCreationDate) to identify listings that were newly created within the specified hour. Note: Filters are applied to the feed files. For details, see Feed File Filters (/api-docs/buy/static/api-feed.html#feed-filters). When curating the items returned, be sure to code as if these filters are not applied as they can be changed or removed in the future. You can use the response from this method to update the item details of items stored in your database. By looking at the value of itemSnapshotDate (/api-docs/buy/feed/resources/item_snapshot/methods/getItemSnapshotFeed#response.items.itemSnapshotDate) for a given item, you will be able to tell which information is the latest. Important: When the value of the availability column is UNAVAILABLE, only the itemId and availability columns are populated. Downloading feed files Hourly snapshot feed files are binary gzip files. If the file is larger than 100 MB, the download must be streamed in chunks. You specify the size of the chunks in bytes using the Range (#range-header) request header. The Content-range (#content-range) response header indicates where in the full resource this partial chunk of data belongs and the total number of bytes in the file. For more information about using these headers, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Note: A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate errors that are returned in JSON format. For documentation purposes, the successful call response is shown below as JSON fields so that the value returned in each column can be explained. The order of the response fields shows the order of the columns in the feed file.Restrictions For a list of supported sites and other restrictions, see API Restrictions (/api-docs/buy/feed/overview.html#API).
#
# GET /item_snapshot
# operationId: getItemSnapshotFeed
export def "item-snapshot get-feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --category-id: string # An eBay top-level category ID of the items to be returned in the feed file. The list of eBay category IDs changes over time and category IDs are not the same across all the eBay marketplaces. To get a list of the top-level categories for a marketplace, you can use the Taxonomy API getCategoryTree (/api-docs/commerce/taxonomy/resources/category_tree/methods/getCategoryTree) method. This method retrieves the complete category tree for the marketplace. The top-level categories are identified by the categoryTreeNodeLevel field.For example: "categoryTreeNodeLevel": 1 For details see Get Categories for Buy APIs (/api-docs/buy/buy-categories.html). Restriction: Must be a top-level category other than Real Estate. Items listed under Real Estate L1 categories are excluded from all feeds in all marketplaces.
  --snapshot-date: string # The date and hour of the snapshot feed file you want. Each file contains the items that changed within the hour in the specified category. So, the 9AM file contains the items that changed between 9AM and 9:59AM on the day specified. It takes 2 hours to generate a snapshot file, which means to get the file for 9AM the earliest you could submit the call is at 11AM.There are 7 days of Hourly Snapshot feed files available.Note: The Feed API uses GMT, so you must convert your local time to GMT. For example, if you lived in California and wanted the September 15th 7pm file, you would submit the following call: item_snapshot?category_id=625&snapshot_date=2017-09-16T02:00:00.000Z Format: UTC yyyy-MM-ddThh:00:00.000Z Files are generated on the hour, so minutes and seconds are always zeros.
  --hdr-accept: string # The formats that the client accepts for the response.A successful call will always return a TSV.GZIP file; however, unsuccessful calls generate error codes that are returned in JSON format.Default: application/json,text/tab-separated-values
  --x-ebay-c-marketplace-id: string # The ID of the eBay marketplace where the item is hosted. Note: This value is case sensitive.For example: X-EBAY-C-MARKETPLACE-ID = EBAY_US For a list of supported sites see, API Restrictions (/api-docs/buy/feed/overview.html#API).
  --range: string # This header specifies the range in bytes of the chunks of the gzip file being returned. Format: bytes=startpos-endpos For example, the following retrieves the first 10 MBs of the feed file. Range bytes=0-10485760 For more information about using this header, see Retrieving a gzip feed file (/api-docs/buy/static/api-feed_beta.html#retrv-gzip). Maximum: 100 MB (10MB in the Sandbox)
]: nothing -> record<items: table<acceptedPaymentMethods: string, additionalImageUrls: string, additionalShippingCostPerUnit: string, ageGroup: string, alerts: string, authenticityGuaranteeFeeCurrency: string, authenticityGuaranteeFeeValue: string, authenticityGuaranteeSelection: string, authenticityGuaranteeServiceId: string, availability: string, availabilityThreshold: int, availabilityThresholdType: string, brand: string, buyingOptions: string, category: string, categoryId: string, changeMetadata: string, color: string, condition: string, conditionId: string, couponDiscountCurrency: string, couponDiscountType: string, couponDiscountValue: string, couponExpirationDate: string, couponMessage: string, couponRedemptionCode: string, couponTermsWebUrl: string, defaultImageUrl: string, deliveryOptions: string, description: string, discountAmount: string, discountPercentage: string, ecoParticipationFeeCurrency: string, ecoParticipationFeeValue: string, energyEfficiencyClass: string, epid: string, estimatedAvailableQuantity: int, gender: string, gtin: string, hazmatAdditionalInformation: string, hazmatPictogramDescriptions: string, hazmatPictogramIds: string, hazmatPictogramImageUrls: string, hazmatSignalWord: string, hazmatSignalWordId: string, hazmatStatementDescriptions: string, hazmatStatementIds: string, imageAlteringProhibited: bool, imageUrl: string, inferredEpid: string, itemAffiliateWebUrl: string, itemCreationDate: string, itemEndDate: string, itemId: string, itemLocationCountry: string, itemSnapshotDate: string, itemWebUrl: string, legacyItemId: string, localizedAspects: string, lotSize: int, material: string, mpn: string, originalPriceCurrency: string, originalPriceValue: string, pattern: string, priceCurrency: string, priceValue: string, primaryItemGroupId: string, primaryItemGroupType: string, qualifiedPrograms: string, quantityUsedForEstimate: int, refundMethod: string, repairScore: string, returnMethod: string, returnPeriodUnit: string, returnPeriodValue: int, returnShippingCostPayer: string, returnsAccepted: bool, sellerAccountType: string, sellerFeedbackPercentage: string, sellerFeedbackScore: string, sellerItemRevision: string, sellerTrustLevel: string, sellerUsername: string, shipToExcludedRegions: string, shipToIncludedRegions: string, shippingCarrierCode: string, shippingCost: string, shippingCostType: string, shippingServiceCode: string, shippingType: string, size: string, takeBackPolicyDescription: string, takeBackPolicyLabel: string, title: string, totalUnits: string, tyreLabelImageUrl: string, unitPrice: string, unitPricingMeasure: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "category_id" $category_id "scalar") (serialize-qp "snapshot_date" $snapshot_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/item_snapshot" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "X-EBAY-C-MARKETPLACE-ID": $x_ebay_c_marketplace_id, "Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"category_id": $category_id, "snapshot_date": $snapshot_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204 206]
}
