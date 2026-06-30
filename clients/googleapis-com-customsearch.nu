# Auto-generated client for Custom Search API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/customsearch/v1/openapi.json
# Auth: --token flag or $env.CUSTOM_SEARCH_API_TOKEN

const BASE_URL = "https://customsearch.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CUSTOM_SEARCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://customsearch.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def img-color-type-completer [] { ["color" "gray" "imgColorTypeUndefined" "mono" "trans"] }
def img-dominant-color-completer [] { ["black" "blue" "brown" "gray" "green" "imgDominantColorUndefined" "orange" "pink" "purple" "red" "teal" "white" "yellow"] }
def img-size-completer [] { ["HUGE" "ICON" "LARGE" "MEDIUM" "SMALL" "XLARGE" "XXLARGE" "imgSizeUndefined"] }
def img-type-completer [] { ["animated" "clipart" "face" "imgTypeUndefined" "lineart" "photo" "stock"] }
def safe-completer [] { ["active" "high" "medium" "off" "safeUndefined"] }
def search-type-completer [] { ["image" "searchTypeUndefined"] }
def site-search-filter-completer [] { ["e" "i" "siteSearchFilterUndefined"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customsearch list" } } | get name | first)
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

# Returns metadata about the search performed, metadata about the engine used for the search, and the search results.
#
# GET /customsearch/v1
# operationId: search.cse.list
export def "customsearch list" [
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
  --c2coff: string # Enables or disables [Simplified and Traditional Chinese Search](https://developers.google.com/custom-search/docs/json_api_reference#chineseSearch). The default value for this parameter is 0 (zero), meaning that the feature is enabled. Supported values are: * `1`: Disabled * `0`: Enabled (default)
  --cr: string # Restricts search results to documents originating in a particular country. You may use [Boolean operators](https://developers.google.com/custom-search/docs/json_api_reference#booleanOperators) in the cr parameter's value. Google Search determines the country of a document by analyzing: * the top-level domain (TLD) of the document's URL * the geographic location of the Web server's IP address See the [Country Parameter Values](https://developers.google.com/custom-search/docs/json_api_reference#countryCollections) page for a list of valid values for this parameter.
  --cx: string # The Programmable Search Engine ID to use for this request.
  --date-restrict: string # Restricts results to URLs based on date. Supported values include: * `d[number]`: requests results from the specified number of past days. * `w[number]`: requests results from the specified number of past weeks. * `m[number]`: requests results from the specified number of past months. * `y[number]`: requests results from the specified number of past years.
  --exact-terms: string # Identifies a phrase that all documents in the search results must contain.
  --exclude-terms: string # Identifies a word or phrase that should not appear in any documents in the search results.
  --file-type: string # Restricts results to files of a specified extension. A list of file types indexable by Google can be found in Search Console [Help Center](https://support.google.com/webmasters/answer/35287).
  --filter: string # Controls turning on or off the duplicate content filter. * See [Automatic Filtering](https://developers.google.com/custom-search/docs/json_api_reference#automaticFiltering) for more information about Google's search results filters. Note that host crowding filtering applies only to multi-site searches. * By default, Google applies filtering to all search results to improve the quality of those results. Acceptable values are: * `0`: Turns off duplicate content filter. * `1`: Turns on duplicate content filter.
  --gl: string # Geolocation of end user. * The `gl` parameter value is a two-letter country code. The `gl` parameter boosts search results whose country of origin matches the parameter value. See the [Country Codes](https://developers.google.com/custom-search/docs/json_api_reference#countryCodes) page for a list of valid values. * Specifying a `gl` parameter value should lead to more relevant results. This is particularly true for international customers and, even more specifically, for customers in English- speaking countries other than the United States.
  --googlehost: string # **Deprecated**. Use the `gl` parameter for a similar effect. The local Google domain (for example, google.com, google.de, or google.fr) to use to perform the search.
  --high-range: string # Specifies the ending value for a search range. * Use `lowRange` and `highRange` to append an inclusive search range of `lowRange...highRange` to the query.
  --hl: string # Sets the user interface language. * Explicitly setting this parameter improves the performance and the quality of your search results. * See the [Interface Languages](https://developers.google.com/custom-search/docs/json_api_reference#wsInterfaceLanguages) section of [Internationalizing Queries and Results Presentation](https://developers.google.com/custom-search/docs/json_api_reference#wsInternationalizing) for more information, and [Supported Interface Languages](https://developers.google.com/custom-search/docs/json_api_reference#interfaceLanguages) for a list of supported languages.
  --hq: string # Appends the specified query terms to the query, as if they were combined with a logical AND operator.
  --img-color-type: string@img-color-type-completer # Returns black and white, grayscale, transparent, or color images. Acceptable values are: * `"color"` * `"gray"` * `"mono"`: black and white * `"trans"`: transparent background
  --img-dominant-color: string@img-dominant-color-completer # Returns images of a specific dominant color. Acceptable values are: * `"black"` * `"blue"` * `"brown"` * `"gray"` * `"green"` * `"orange"` * `"pink"` * `"purple"` * `"red"` * `"teal"` * `"white"` * `"yellow"`
  --img-size: string@img-size-completer # Returns images of a specified size. Acceptable values are: * `"huge"` * `"icon"` * `"large"` * `"medium"` * `"small"` * `"xlarge"` * `"xxlarge"`
  --img-type: string@img-type-completer # Returns images of a type. Acceptable values are: * `"clipart"` * `"face"` * `"lineart"` * `"stock"` * `"photo"` * `"animated"`
  --link-site: string # Specifies that all search results should contain a link to a particular URL.
  --low-range: string # Specifies the starting value for a search range. Use `lowRange` and `highRange` to append an inclusive search range of `lowRange...highRange` to the query.
  --lr: string # Restricts the search to documents written in a particular language (e.g., `lr=lang_ja`). Acceptable values are: * `"lang_ar"`: Arabic * `"lang_bg"`: Bulgarian * `"lang_ca"`: Catalan * `"lang_cs"`: Czech * `"lang_da"`: Danish * `"lang_de"`: German * `"lang_el"`: Greek * `"lang_en"`: English * `"lang_es"`: Spanish * `"lang_et"`: Estonian * `"lang_fi"`: Finnish * `"lang_fr"`: French * `"lang_hr"`: Croatian * `"lang_hu"`: Hungarian * `"lang_id"`: Indonesian * `"lang_is"`: Icelandic * `"lang_it"`: Italian * `"lang_iw"`: Hebrew * `"lang_ja"`: Japanese * `"lang_ko"`: Korean * `"lang_lt"`: Lithuanian * `"lang_lv"`: Latvian * `"lang_nl"`: Dutch * `"lang_no"`: Norwegian * `"lang_pl"`: Polish * `"lang_pt"`: Portuguese * `"lang_ro"`: Romanian * `"lang_ru"`: Russian * `"lang_sk"`: Slovak * `"lang_sl"`: Slovenian * `"lang_sr"`: Serbian * `"lang_sv"`: Swedish * `"lang_tr"`: Turkish * `"lang_zh-CN"`: Chinese (Simplified) * `"lang_zh-TW"`: Chinese (Traditional)
  --num: int # Number of search results to return. * Valid values are integers between 1 and 10, inclusive.
  --or-terms: string # Provides additional search terms to check for in a document, where each document in the search results must contain at least one of the additional search terms.
  --q: string # Query
  --related-site: string # Specifies that all search results should be pages that are related to the specified URL.
  --rights: string # Filters based on licensing. Supported values include: `cc_publicdomain`, `cc_attribute`, `cc_sharealike`, `cc_noncommercial`, `cc_nonderived` and combinations of these. See [typical combinations](https://wiki.creativecommons.org/wiki/CC_Search_integration).
  --safe: string@safe-completer # Search safety level. Acceptable values are: * `"active"`: Enables SafeSearch filtering. * `"off"`: Disables SafeSearch filtering. (default)
  --search-type: string@search-type-completer # Specifies the search type: `image`. If unspecified, results are limited to webpages. Acceptable values are: * `"image"`: custom image search.
  --site-search: string # Specifies a given site which should always be included or excluded from results (see `siteSearchFilter` parameter, below).
  --site-search-filter: string@site-search-filter-completer # Controls whether to include or exclude results from the site named in the `siteSearch` parameter. Acceptable values are: * `"e"`: exclude * `"i"`: include
  --qp-sort: string # The sort expression to apply to the results. The sort parameter specifies that the results be sorted according to the specified expression i.e. sort by date. [Example: sort=date](https://developers.google.com/custom-search/docs/structured_search#sort-by-attribute).
  --start: int # The index of the first result to return. The default number of results per page is 10, so `&start=11` would start at the top of the second page of results. **Note**: The JSON API will never return more than 100 results, even if more than 100 documents match the query, so setting the sum of `start + num` to a number greater than 100 will produce an error. Also note that the maximum value for `num` is 10.
]: nothing -> record<context: record, items: table<cacheId: string, displayLink: string, fileFormat: string, formattedUrl: string, htmlFormattedUrl: string, htmlSnippet: string, htmlTitle: string, image: record, kind: string, labels: list, link: string, mime: string, pagemap: record, snippet: string, title: string>, kind: string, promotions: table<bodyLines: list, displayLink: string, htmlTitle: string, image: record, link: string, title: string>, queries: record<nextPage: list<record>, previousPage: list<record>, request: list<record>>, searchInformation: record<formattedSearchTime: string, formattedTotalResults: string, searchTime: float, totalResults: string>, spelling: record<correctedQuery: string, htmlCorrectedQuery: string>, url: record<template: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "c2coff" $c2coff "scalar") (serialize-qp "cr" $cr "scalar") (serialize-qp "cx" $cx "scalar") (serialize-qp "dateRestrict" $date_restrict "scalar") (serialize-qp "exactTerms" $exact_terms "scalar") (serialize-qp "excludeTerms" $exclude_terms "scalar") (serialize-qp "fileType" $file_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "gl" $gl "scalar") (serialize-qp "googlehost" $googlehost "scalar") (serialize-qp "highRange" $high_range "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "hq" $hq "scalar") (serialize-qp "imgColorType" $img_color_type "scalar") (serialize-qp "imgDominantColor" $img_dominant_color "scalar") (serialize-qp "imgSize" $img_size "scalar") (serialize-qp "imgType" $img_type "scalar") (serialize-qp "linkSite" $link_site "scalar") (serialize-qp "lowRange" $low_range "scalar") (serialize-qp "lr" $lr "scalar") (serialize-qp "num" $num "scalar") (serialize-qp "orTerms" $or_terms "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "relatedSite" $related_site "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "searchType" $search_type "scalar") (serialize-qp "siteSearch" $site_search "scalar") (serialize-qp "siteSearchFilter" $site_search_filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customsearch/v1" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "c2coff": $c2coff, "cr": $cr, "cx": $cx, "dateRestrict": $date_restrict, "exactTerms": $exact_terms, "excludeTerms": $exclude_terms, "fileType": $file_type, "filter": $filter, "gl": $gl, "googlehost": $googlehost, "highRange": $high_range, "hl": $hl, "hq": $hq, "imgColorType": $img_color_type, "imgDominantColor": $img_dominant_color, "imgSize": $img_size, "imgType": $img_type, "linkSite": $link_site, "lowRange": $low_range, "lr": $lr, "num": $num, "orTerms": $or_terms, "q": $q, "relatedSite": $related_site, "rights": $rights, "safe": $safe, "searchType": $search_type, "siteSearch": $site_search, "siteSearchFilter": $site_search_filter, "sort": $qp_sort, "start": $start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns metadata about the search performed, metadata about the engine used for the search, and the search results. Uses a small set of url patterns.
#
# GET /customsearch/v1/siterestrict
# operationId: search.cse.siterestrict.list
export def "customsearch-siterestrict list" [
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
  --c2coff: string # Enables or disables [Simplified and Traditional Chinese Search](https://developers.google.com/custom-search/docs/json_api_reference#chineseSearch). The default value for this parameter is 0 (zero), meaning that the feature is enabled. Supported values are: * `1`: Disabled * `0`: Enabled (default)
  --cr: string # Restricts search results to documents originating in a particular country. You may use [Boolean operators](https://developers.google.com/custom-search/docs/json_api_reference#booleanOperators) in the cr parameter's value. Google Search determines the country of a document by analyzing: * the top-level domain (TLD) of the document's URL * the geographic location of the Web server's IP address See the [Country Parameter Values](https://developers.google.com/custom-search/docs/json_api_reference#countryCollections) page for a list of valid values for this parameter.
  --cx: string # The Programmable Search Engine ID to use for this request.
  --date-restrict: string # Restricts results to URLs based on date. Supported values include: * `d[number]`: requests results from the specified number of past days. * `w[number]`: requests results from the specified number of past weeks. * `m[number]`: requests results from the specified number of past months. * `y[number]`: requests results from the specified number of past years.
  --exact-terms: string # Identifies a phrase that all documents in the search results must contain.
  --exclude-terms: string # Identifies a word or phrase that should not appear in any documents in the search results.
  --file-type: string # Restricts results to files of a specified extension. A list of file types indexable by Google can be found in Search Console [Help Center](https://support.google.com/webmasters/answer/35287).
  --filter: string # Controls turning on or off the duplicate content filter. * See [Automatic Filtering](https://developers.google.com/custom-search/docs/json_api_reference#automaticFiltering) for more information about Google's search results filters. Note that host crowding filtering applies only to multi-site searches. * By default, Google applies filtering to all search results to improve the quality of those results. Acceptable values are: * `0`: Turns off duplicate content filter. * `1`: Turns on duplicate content filter.
  --gl: string # Geolocation of end user. * The `gl` parameter value is a two-letter country code. The `gl` parameter boosts search results whose country of origin matches the parameter value. See the [Country Codes](https://developers.google.com/custom-search/docs/json_api_reference#countryCodes) page for a list of valid values. * Specifying a `gl` parameter value should lead to more relevant results. This is particularly true for international customers and, even more specifically, for customers in English- speaking countries other than the United States.
  --googlehost: string # **Deprecated**. Use the `gl` parameter for a similar effect. The local Google domain (for example, google.com, google.de, or google.fr) to use to perform the search.
  --high-range: string # Specifies the ending value for a search range. * Use `lowRange` and `highRange` to append an inclusive search range of `lowRange...highRange` to the query.
  --hl: string # Sets the user interface language. * Explicitly setting this parameter improves the performance and the quality of your search results. * See the [Interface Languages](https://developers.google.com/custom-search/docs/json_api_reference#wsInterfaceLanguages) section of [Internationalizing Queries and Results Presentation](https://developers.google.com/custom-search/docs/json_api_reference#wsInternationalizing) for more information, and [Supported Interface Languages](https://developers.google.com/custom-search/docs/json_api_reference#interfaceLanguages) for a list of supported languages.
  --hq: string # Appends the specified query terms to the query, as if they were combined with a logical AND operator.
  --img-color-type: string@img-color-type-completer # Returns black and white, grayscale, transparent, or color images. Acceptable values are: * `"color"` * `"gray"` * `"mono"`: black and white * `"trans"`: transparent background
  --img-dominant-color: string@img-dominant-color-completer # Returns images of a specific dominant color. Acceptable values are: * `"black"` * `"blue"` * `"brown"` * `"gray"` * `"green"` * `"orange"` * `"pink"` * `"purple"` * `"red"` * `"teal"` * `"white"` * `"yellow"`
  --img-size: string@img-size-completer # Returns images of a specified size. Acceptable values are: * `"huge"` * `"icon"` * `"large"` * `"medium"` * `"small"` * `"xlarge"` * `"xxlarge"`
  --img-type: string@img-type-completer # Returns images of a type. Acceptable values are: * `"clipart"` * `"face"` * `"lineart"` * `"stock"` * `"photo"` * `"animated"`
  --link-site: string # Specifies that all search results should contain a link to a particular URL.
  --low-range: string # Specifies the starting value for a search range. Use `lowRange` and `highRange` to append an inclusive search range of `lowRange...highRange` to the query.
  --lr: string # Restricts the search to documents written in a particular language (e.g., `lr=lang_ja`). Acceptable values are: * `"lang_ar"`: Arabic * `"lang_bg"`: Bulgarian * `"lang_ca"`: Catalan * `"lang_cs"`: Czech * `"lang_da"`: Danish * `"lang_de"`: German * `"lang_el"`: Greek * `"lang_en"`: English * `"lang_es"`: Spanish * `"lang_et"`: Estonian * `"lang_fi"`: Finnish * `"lang_fr"`: French * `"lang_hr"`: Croatian * `"lang_hu"`: Hungarian * `"lang_id"`: Indonesian * `"lang_is"`: Icelandic * `"lang_it"`: Italian * `"lang_iw"`: Hebrew * `"lang_ja"`: Japanese * `"lang_ko"`: Korean * `"lang_lt"`: Lithuanian * `"lang_lv"`: Latvian * `"lang_nl"`: Dutch * `"lang_no"`: Norwegian * `"lang_pl"`: Polish * `"lang_pt"`: Portuguese * `"lang_ro"`: Romanian * `"lang_ru"`: Russian * `"lang_sk"`: Slovak * `"lang_sl"`: Slovenian * `"lang_sr"`: Serbian * `"lang_sv"`: Swedish * `"lang_tr"`: Turkish * `"lang_zh-CN"`: Chinese (Simplified) * `"lang_zh-TW"`: Chinese (Traditional)
  --num: int # Number of search results to return. * Valid values are integers between 1 and 10, inclusive.
  --or-terms: string # Provides additional search terms to check for in a document, where each document in the search results must contain at least one of the additional search terms.
  --q: string # Query
  --related-site: string # Specifies that all search results should be pages that are related to the specified URL.
  --rights: string # Filters based on licensing. Supported values include: `cc_publicdomain`, `cc_attribute`, `cc_sharealike`, `cc_noncommercial`, `cc_nonderived` and combinations of these. See [typical combinations](https://wiki.creativecommons.org/wiki/CC_Search_integration).
  --safe: string@safe-completer # Search safety level. Acceptable values are: * `"active"`: Enables SafeSearch filtering. * `"off"`: Disables SafeSearch filtering. (default)
  --search-type: string@search-type-completer # Specifies the search type: `image`. If unspecified, results are limited to webpages. Acceptable values are: * `"image"`: custom image search.
  --site-search: string # Specifies a given site which should always be included or excluded from results (see `siteSearchFilter` parameter, below).
  --site-search-filter: string@site-search-filter-completer # Controls whether to include or exclude results from the site named in the `siteSearch` parameter. Acceptable values are: * `"e"`: exclude * `"i"`: include
  --qp-sort: string # The sort expression to apply to the results. The sort parameter specifies that the results be sorted according to the specified expression i.e. sort by date. [Example: sort=date](https://developers.google.com/custom-search/docs/structured_search#sort-by-attribute).
  --start: int # The index of the first result to return. The default number of results per page is 10, so `&start=11` would start at the top of the second page of results. **Note**: The JSON API will never return more than 100 results, even if more than 100 documents match the query, so setting the sum of `start + num` to a number greater than 100 will produce an error. Also note that the maximum value for `num` is 10.
]: nothing -> record<context: record, items: table<cacheId: string, displayLink: string, fileFormat: string, formattedUrl: string, htmlFormattedUrl: string, htmlSnippet: string, htmlTitle: string, image: record, kind: string, labels: list, link: string, mime: string, pagemap: record, snippet: string, title: string>, kind: string, promotions: table<bodyLines: list, displayLink: string, htmlTitle: string, image: record, link: string, title: string>, queries: record<nextPage: list<record>, previousPage: list<record>, request: list<record>>, searchInformation: record<formattedSearchTime: string, formattedTotalResults: string, searchTime: float, totalResults: string>, spelling: record<correctedQuery: string, htmlCorrectedQuery: string>, url: record<template: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "c2coff" $c2coff "scalar") (serialize-qp "cr" $cr "scalar") (serialize-qp "cx" $cx "scalar") (serialize-qp "dateRestrict" $date_restrict "scalar") (serialize-qp "exactTerms" $exact_terms "scalar") (serialize-qp "excludeTerms" $exclude_terms "scalar") (serialize-qp "fileType" $file_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "gl" $gl "scalar") (serialize-qp "googlehost" $googlehost "scalar") (serialize-qp "highRange" $high_range "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "hq" $hq "scalar") (serialize-qp "imgColorType" $img_color_type "scalar") (serialize-qp "imgDominantColor" $img_dominant_color "scalar") (serialize-qp "imgSize" $img_size "scalar") (serialize-qp "imgType" $img_type "scalar") (serialize-qp "linkSite" $link_site "scalar") (serialize-qp "lowRange" $low_range "scalar") (serialize-qp "lr" $lr "scalar") (serialize-qp "num" $num "scalar") (serialize-qp "orTerms" $or_terms "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "relatedSite" $related_site "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "searchType" $search_type "scalar") (serialize-qp "siteSearch" $site_search "scalar") (serialize-qp "siteSearchFilter" $site_search_filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customsearch/v1/siterestrict" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"$.xgafv": $xgafv, "access_token": $access_token, "alt": $alt, "callback": $callback, "fields": $fields, "key": $key, "oauth_token": $oauth_token, "prettyPrint": $pretty_print, "quotaUser": $quota_user, "upload_protocol": $upload_protocol, "uploadType": $upload_type, "c2coff": $c2coff, "cr": $cr, "cx": $cx, "dateRestrict": $date_restrict, "exactTerms": $exact_terms, "excludeTerms": $exclude_terms, "fileType": $file_type, "filter": $filter, "gl": $gl, "googlehost": $googlehost, "highRange": $high_range, "hl": $hl, "hq": $hq, "imgColorType": $img_color_type, "imgDominantColor": $img_dominant_color, "imgSize": $img_size, "imgType": $img_type, "linkSite": $link_site, "lowRange": $low_range, "lr": $lr, "num": $num, "orTerms": $or_terms, "q": $q, "relatedSite": $related_site, "rights": $rights, "safe": $safe, "searchType": $search_type, "siteSearch": $site_search, "siteSearchFilter": $site_search_filter, "sort": $qp_sort, "start": $start} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
