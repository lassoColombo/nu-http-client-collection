# Auto-generated client for Search Ads 360 API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/doubleclicksearch/v2/openapi.json
# Auth: --token flag or $env.SEARCH_ADS_360_API_TOKEN

const BASE_URL = "https://doubleclicksearch.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_ADS_360_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://doubleclicksearch.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "doubleclicksearch-agency-advertiser-engine-conversion get" } } | get name | first)
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

# Retrieves a list of conversions from a DoubleClick Search engine account.
#
# GET /doubleclicksearch/v2/agency/{agencyId}/advertiser/{advertiserId}/engine/{engineAccountId}/conversion
# operationId: doubleclicksearch.conversion.get
export def "doubleclicksearch-agency-advertiser-engine-conversion get" [
  agency_id: string
  advertiser_id: string
  engine_account_id: string
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
  --end-date: int # Last date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --row-count: int # The number of conversions to return per call.
  --start-date: int # First date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --start-row: int # The 0-based starting index for retrieving conversions results.
  --ad-group-id: string # Numeric ID of the ad group.
  --ad-id: string # Numeric ID of the ad.
  --campaign-id: string # Numeric ID of the campaign.
  --criterion-id: string # Numeric ID of the criterion.
  --customer-id: string # Customer ID of a client account in the new Search Ads 360 experience.
]: nothing -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "rowCount" $row_count "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "startRow" $start_row "scalar") (serialize-qp "adGroupId" $ad_group_id "scalar") (serialize-qp "adId" $ad_id "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "criterionId" $criterion_id "scalar") (serialize-qp "customerId" $customer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({agency_id: (encode-path-segment $agency_id), advertiser_id: (encode-path-segment $advertiser_id), engine_account_id: (encode-path-segment $engine_account_id)} | format pattern "/doubleclicksearch/v2/agency/{agency_id}/advertiser/{advertiser_id}/engine/{engine_account_id}/conversion") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Downloads a csv file(encoded in UTF-8) that contains ID mappings between legacy SA360 and new SA360. The file includes all children entities of the given advertiser(e.g. engine accounts, campaigns, ad groups, etc.) that exist in both legacy SA360 and new SA360.
#
# GET /doubleclicksearch/v2/agency/{agencyId}/advertiser/{advertiserId}/idmapping
# operationId: doubleclicksearch.reports.getIdMappingFile
export def "doubleclicksearch-agency-advertiser-idmapping get-mapping-file" [
  agency_id: string
  advertiser_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({agency_id: (encode-path-segment $agency_id), advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/doubleclicksearch/v2/agency/{agency_id}/advertiser/{advertiser_id}/idmapping") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve the list of saved columns for a specified advertiser.
#
# GET /doubleclicksearch/v2/agency/{agencyId}/advertiser/{advertiserId}/savedcolumns
# operationId: doubleclicksearch.savedColumns.list
export def "doubleclicksearch-agency-advertiser-savedcolumns list" [
  agency_id: string
  advertiser_id: string
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
]: nothing -> record<items: table<kind: string, savedColumnName: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({agency_id: (encode-path-segment $agency_id), advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/doubleclicksearch/v2/agency/{agency_id}/advertiser/{advertiser_id}/savedcolumns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Inserts a batch of new conversions into DoubleClick Search.
#
# POST /doubleclicksearch/v2/conversion
# operationId: doubleclicksearch.conversion.insert
# --conversion item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, ... (13 more fields)}
export def "doubleclicksearch-conversion create" [
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
  --conversion: list # The conversions being requested. — item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, ... (13 more fields)}
  --kind: string # Identifies this as a ConversionList resource. Value: the fixed string doubleclicksearch#conversionList.
]: any -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion" $qp)
  let req_body = {"conversion": $conversion, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates a batch of conversions in DoubleClick Search.
#
# PUT /doubleclicksearch/v2/conversion
# operationId: doubleclicksearch.conversion.update
# --conversion item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, ... (13 more fields)}
export def "doubleclicksearch-conversion update" [
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
  --conversion: list # The conversions being requested. — item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, ... (13 more fields)}
  --kind: string # Identifies this as a ConversionList resource. Value: the fixed string doubleclicksearch#conversionList.
]: any -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion" $qp)
  let req_body = {"conversion": $conversion, "kind": $kind} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Updates the availabilities of a batch of floodlight activities in DoubleClick Search.
#
# POST /doubleclicksearch/v2/conversion/updateAvailability
# operationId: doubleclicksearch.conversion.updateAvailability
# --availabilities item shape: {advertiserId?: string, agencyId?: string, availabilityTimestamp?: string, customerId?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string}
export def "doubleclicksearch-conversion-update-availability update" [
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
  --availabilities: list # The availabilities being requested. — item shape: {advertiserId?: string, agencyId?: string, availabilityTimestamp?: string, customerId?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string}
]: any -> record<availabilities: table<advertiserId: string, agencyId: string, availabilityTimestamp: string, customerId: string, segmentationId: string, segmentationName: string, segmentationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion/updateAvailability" $qp)
  let req_body = {"availabilities": $availabilities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a list of conversions from a DoubleClick Search engine account.
#
# GET /doubleclicksearch/v2/customer/{customerId}/conversion
# operationId: doubleclicksearch.conversion.getByCustomerId
export def "doubleclicksearch-customer-conversion get" [
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
  --end-date: int # Last date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --row-count: int # The number of conversions to return per call.
  --start-date: int # First date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --start-row: int # The 0-based starting index for retrieving conversions results.
  --ad-group-id: string # Numeric ID of the ad group.
  --ad-id: string # Numeric ID of the ad.
  --advertiser-id: string # Numeric ID of the advertiser.
  --agency-id: string # Numeric ID of the agency.
  --campaign-id: string # Numeric ID of the campaign.
  --criterion-id: string # Numeric ID of the criterion.
  --engine-account-id: string # Numeric ID of the engine account.
]: nothing -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "rowCount" $row_count "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "startRow" $start_row "scalar") (serialize-qp "adGroupId" $ad_group_id "scalar") (serialize-qp "adId" $ad_id "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "agencyId" $agency_id "scalar") (serialize-qp "campaignId" $campaign_id "scalar") (serialize-qp "criterionId" $criterion_id "scalar") (serialize-qp "engineAccountId" $engine_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/doubleclicksearch/v2/customer/{customer_id}/conversion") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Inserts a report request into the reporting system.
#
# POST /doubleclicksearch/v2/reports
# operationId: doubleclicksearch.reports.request
# --columns item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
# --filters item shape: {column?: record, operator?: string, values?: list}
# --orderBy item shape: {column?: record, sortOrder?: string}
# --reportScope shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
# --timeRange shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
export def "doubleclicksearch-reports request" [
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
  --columns: list # The columns to include in the report. This includes both DoubleClick Search columns and saved columns. For DoubleClick Search columns, only the `columnName` parameter is required. For saved columns only the `savedColumnName` parameter is required. Both `columnName` and `savedColumnName` cannot be set in the same stanza.\ The maximum number of columns per request is 300. — item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
  --download-format: string # Format that the report should be returned in. Currently `csv` or `tsv` is supported.
  --filters: list # A list of filters to be applied to the report.\ The maximum number of filters per request is 300. — item shape: {column?: record, operator?: string, values?: list}
  --include-deleted-entities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`. Deprecated, please use `includeRemovedEntities` instead.
  --include-removed-entities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`.
  --max-rows-per-file: int # Asynchronous report only. The maximum number of rows per report file. A large report is split into many files based on this field. Acceptable values are `1000000` to `100000000`, inclusive. (format: int32)
  --order-by: list # Synchronous report only. A list of columns and directions defining sorting to be performed on the report rows.\ The maximum number of orderings per request is 300. — item shape: {column?: record, sortOrder?: string}
  --report-scope: record # The reportScope is a set of IDs that are used to determine which subset of entities will be returned in the report. The full lineage of IDs from the lowest scoped level desired up through agency is required. — shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
  --report-type: string # Determines the type of rows that are returned in the report. For example, if you specify `reportType: keyword`, each row in the report will contain data about a keyword. See the [Types of Reports](/search-ads/v2/report-types/) reference for the columns that are available for each type.
  --row-count: int # Synchronous report only. The maximum number of rows to return; additional rows are dropped. Acceptable values are `0` to `10000`, inclusive. Defaults to `10000`. (format: int32)
  --start-row: int # Synchronous report only. Zero-based index of the first row to return. Acceptable values are `0` to `50000`, inclusive. Defaults to `0`. (format: int32)
  --statistics-currency: string # Specifies the currency in which monetary will be returned. Possible values are: `usd`, `agency` (valid if the report is scoped to agency or lower), `advertiser` (valid if the report is scoped to * advertiser or lower), or `account` (valid if the report is scoped to engine account or lower).
  --time-range: record # If metrics are requested in a report, this argument will be used to restrict the metrics to a specific time range. — shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
  --verify-single-time-zone: oneof<nothing, bool> # If `true`, the report would only be created if all the requested stat data are sourced from a single timezone. Defaults to `false`.
]: any -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/reports" $qp)
  let req_body = {"columns": $columns, "downloadFormat": $download_format, "filters": $filters, "includeDeletedEntities": $include_deleted_entities, "includeRemovedEntities": $include_removed_entities, "maxRowsPerFile": $max_rows_per_file, "orderBy": $order_by, "reportScope": $report_scope, "reportType": $report_type, "rowCount": $row_count, "startRow": $start_row, "statisticsCurrency": $statistics_currency, "timeRange": $time_range, "verifySingleTimeZone": $verify_single_time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Generates and returns a report immediately.
#
# POST /doubleclicksearch/v2/reports/generate
# operationId: doubleclicksearch.reports.generate
# --columns item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
# --filters item shape: {column?: record, operator?: string, values?: list}
# --orderBy item shape: {column?: record, sortOrder?: string}
# --reportScope shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
# --timeRange shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
export def "doubleclicksearch-reports-generate generate" [
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
  --columns: list # The columns to include in the report. This includes both DoubleClick Search columns and saved columns. For DoubleClick Search columns, only the `columnName` parameter is required. For saved columns only the `savedColumnName` parameter is required. Both `columnName` and `savedColumnName` cannot be set in the same stanza.\ The maximum number of columns per request is 300. — item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
  --download-format: string # Format that the report should be returned in. Currently `csv` or `tsv` is supported.
  --filters: list # A list of filters to be applied to the report.\ The maximum number of filters per request is 300. — item shape: {column?: record, operator?: string, values?: list}
  --include-deleted-entities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`. Deprecated, please use `includeRemovedEntities` instead.
  --include-removed-entities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`.
  --max-rows-per-file: int # Asynchronous report only. The maximum number of rows per report file. A large report is split into many files based on this field. Acceptable values are `1000000` to `100000000`, inclusive. (format: int32)
  --order-by: list # Synchronous report only. A list of columns and directions defining sorting to be performed on the report rows.\ The maximum number of orderings per request is 300. — item shape: {column?: record, sortOrder?: string}
  --report-scope: record # The reportScope is a set of IDs that are used to determine which subset of entities will be returned in the report. The full lineage of IDs from the lowest scoped level desired up through agency is required. — shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
  --report-type: string # Determines the type of rows that are returned in the report. For example, if you specify `reportType: keyword`, each row in the report will contain data about a keyword. See the [Types of Reports](/search-ads/v2/report-types/) reference for the columns that are available for each type.
  --row-count: int # Synchronous report only. The maximum number of rows to return; additional rows are dropped. Acceptable values are `0` to `10000`, inclusive. Defaults to `10000`. (format: int32)
  --start-row: int # Synchronous report only. Zero-based index of the first row to return. Acceptable values are `0` to `50000`, inclusive. Defaults to `0`. (format: int32)
  --statistics-currency: string # Specifies the currency in which monetary will be returned. Possible values are: `usd`, `agency` (valid if the report is scoped to agency or lower), `advertiser` (valid if the report is scoped to * advertiser or lower), or `account` (valid if the report is scoped to engine account or lower).
  --time-range: record # If metrics are requested in a report, this argument will be used to restrict the metrics to a specific time range. — shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
  --verify-single-time-zone: oneof<nothing, bool> # If `true`, the report would only be created if all the requested stat data are sourced from a single timezone. Defaults to `false`.
]: any -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/reports/generate" $qp)
  let req_body = {"columns": $columns, "downloadFormat": $download_format, "filters": $filters, "includeDeletedEntities": $include_deleted_entities, "includeRemovedEntities": $include_removed_entities, "maxRowsPerFile": $max_rows_per_file, "orderBy": $order_by, "reportScope": $report_scope, "reportType": $report_type, "rowCount": $row_count, "startRow": $start_row, "statisticsCurrency": $statistics_currency, "timeRange": $time_range, "verifySingleTimeZone": $verify_single_time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Polls for the status of a report request.
#
# GET /doubleclicksearch/v2/reports/{reportId}
# operationId: doubleclicksearch.reports.get
export def "doubleclicksearch-reports get" [
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
]: nothing -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/doubleclicksearch/v2/reports/{report_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Downloads a report file encoded in UTF-8.
#
# GET /doubleclicksearch/v2/reports/{reportId}/files/{reportFragment}
# operationId: doubleclicksearch.reports.getFile
export def "doubleclicksearch-reports-files get" [
  report_id: string
  report_fragment: int
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id), report_fragment: (encode-path-segment $report_fragment)} | format pattern "/doubleclicksearch/v2/reports/{report_id}/files/{report_fragment}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
