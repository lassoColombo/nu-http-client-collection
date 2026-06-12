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

def base-url-completer [] { ["https://doubleclicksearch.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "doubleclicksearch-agency-advertiser-engine-conversion doubleclicksearchconversionget" } } | get name | first)
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
export def "doubleclicksearch-agency-advertiser-engine-conversion doubleclicksearchconversionget" [
  agencyId: string
  advertiserId: string
  engineAccountId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --endDate: int # Last date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --rowCount: int # The number of conversions to return per call.
  --startDate: int # First date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --startRow: int # The 0-based starting index for retrieving conversions results.
  --adGroupId: string # Numeric ID of the ad group.
  --adId: string # Numeric ID of the ad.
  --campaignId: string # Numeric ID of the campaign.
  --criterionId: string # Numeric ID of the criterion.
  --customerId: string # Customer ID of a client account in the new Search Ads 360 experience.
]: nothing -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "rowCount" $rowCount "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "startRow" $startRow "scalar") (serialize-qp "adGroupId" $adGroupId "scalar") (serialize-qp "adId" $adId "scalar") (serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "criterionId" $criterionId "scalar") (serialize-qp "customerId" $customerId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/agency/($agencyId)/advertiser/($advertiserId)/engine/($engineAccountId)/conversion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Downloads a csv file(encoded in UTF-8) that contains ID mappings between legacy SA360 and new SA360. The file includes all children entities of the given advertiser(e.g. engine accounts, campaigns, ad groups, etc.) that exist in both legacy SA360 and new SA360.
#
# GET /doubleclicksearch/v2/agency/{agencyId}/advertiser/{advertiserId}/idmapping
# operationId: doubleclicksearch.reports.getIdMappingFile
export def "doubleclicksearch-agency-advertiser-idmapping doubleclicksearchreportsgetIdMappingFile" [
  agencyId: string
  advertiserId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/agency/($agencyId)/advertiser/($advertiserId)/idmapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the list of saved columns for a specified advertiser.
#
# GET /doubleclicksearch/v2/agency/{agencyId}/advertiser/{advertiserId}/savedcolumns
# operationId: doubleclicksearch.savedColumns.list
export def "doubleclicksearch-agency-advertiser-savedcolumns doubleclicksearchsavedColumnslist" [
  agencyId: string
  advertiserId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<items: table<kind: string, savedColumnName: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/agency/($agencyId)/advertiser/($advertiserId)/savedcolumns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inserts a batch of new conversions into DoubleClick Search.
#
# POST /doubleclicksearch/v2/conversion
# operationId: doubleclicksearch.conversion.insert
# --conversion item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, inventoryAccountId?: string, productCountry?: string, productGroupId?: string, productId?: string, productLanguage?: string, quantityMillis?: string, revenueMicros?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string, state?: string, storeId?: string, type?: string}
export def "doubleclicksearch-conversion doubleclicksearchconversioninsert" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --conversion: list # The conversions being requested. — item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, inventoryAccountId?: string, productCountry?: string, productGroupId?: string, productId?: string, productLanguage?: string, quantityMillis?: string, revenueMicros?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string, state?: string, storeId?: string, type?: string}
  --kind: string # Identifies this as a ConversionList resource. Value: the fixed string doubleclicksearch#conversionList.
]: any -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion" $qp)
  let body = {conversion: $conversion, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a batch of conversions in DoubleClick Search.
#
# PUT /doubleclicksearch/v2/conversion
# operationId: doubleclicksearch.conversion.update
# --conversion item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, inventoryAccountId?: string, productCountry?: string, productGroupId?: string, productId?: string, productLanguage?: string, quantityMillis?: string, revenueMicros?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string, state?: string, storeId?: string, type?: string}
export def "doubleclicksearch-conversion doubleclicksearchconversionupdate" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --conversion: list # The conversions being requested. — item shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, attributionModel?: string, campaignId?: string, channel?: string, clickId?: string, conversionId?: string, conversionModifiedTimestamp?: string, conversionTimestamp?: string, countMillis?: string, criterionId?: string, currencyCode?: string, customDimension?: list, customMetric?: list, customerId?: string, deviceType?: string, dsConversionId?: string, engineAccountId?: string, floodlightOrderId?: string, inventoryAccountId?: string, productCountry?: string, productGroupId?: string, productId?: string, productLanguage?: string, quantityMillis?: string, revenueMicros?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string, state?: string, storeId?: string, type?: string}
  --kind: string # Identifies this as a ConversionList resource. Value: the fixed string doubleclicksearch#conversionList.
]: any -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion" $qp)
  let body = {conversion: $conversion, kind: $kind} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the availabilities of a batch of floodlight activities in DoubleClick Search.
#
# POST /doubleclicksearch/v2/conversion/updateAvailability
# operationId: doubleclicksearch.conversion.updateAvailability
# --availabilities item shape: {advertiserId?: string, agencyId?: string, availabilityTimestamp?: string, customerId?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string}
export def "doubleclicksearch-conversion-update-availability doubleclicksearchconversionupdateAvailability" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --availabilities: list # The availabilities being requested. — item shape: {advertiserId?: string, agencyId?: string, availabilityTimestamp?: string, customerId?: string, segmentationId?: string, segmentationName?: string, segmentationType?: string}
]: any -> record<availabilities: table<advertiserId: string, agencyId: string, availabilityTimestamp: string, customerId: string, segmentationId: string, segmentationName: string, segmentationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/conversion/updateAvailability" $qp)
  let body = {availabilities: $availabilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a list of conversions from a DoubleClick Search engine account.
#
# GET /doubleclicksearch/v2/customer/{customerId}/conversion
# operationId: doubleclicksearch.conversion.getByCustomerId
export def "doubleclicksearch-customer-conversion doubleclicksearchconversiongetByCustomerId" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --endDate: int # Last date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --rowCount: int # The number of conversions to return per call.
  --startDate: int # First date (inclusive) on which to retrieve conversions. Format is yyyymmdd.
  --startRow: int # The 0-based starting index for retrieving conversions results.
  --adGroupId: string # Numeric ID of the ad group.
  --adId: string # Numeric ID of the ad.
  --advertiserId: string # Numeric ID of the advertiser.
  --agencyId: string # Numeric ID of the agency.
  --campaignId: string # Numeric ID of the campaign.
  --criterionId: string # Numeric ID of the criterion.
  --engineAccountId: string # Numeric ID of the engine account.
]: nothing -> record<conversion: table<adGroupId: string, adId: string, advertiserId: string, agencyId: string, attributionModel: string, campaignId: string, channel: string, clickId: string, conversionId: string, conversionModifiedTimestamp: string, conversionTimestamp: string, countMillis: string, criterionId: string, currencyCode: string, customDimension: list, customMetric: list, customerId: string, deviceType: string, dsConversionId: string, engineAccountId: string, floodlightOrderId: string, inventoryAccountId: string, productCountry: string, productGroupId: string, productId: string, productLanguage: string, quantityMillis: string, revenueMicros: string, segmentationId: string, segmentationName: string, segmentationType: string, state: string, storeId: string, type: string>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "rowCount" $rowCount "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "startRow" $startRow "scalar") (serialize-qp "adGroupId" $adGroupId "scalar") (serialize-qp "adId" $adId "scalar") (serialize-qp "advertiserId" $advertiserId "scalar") (serialize-qp "agencyId" $agencyId "scalar") (serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "criterionId" $criterionId "scalar") (serialize-qp "engineAccountId" $engineAccountId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/customer/($customerId)/conversion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
export def "doubleclicksearch-reports doubleclicksearchreportsrequest" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --columns: list # The columns to include in the report. This includes both DoubleClick Search columns and saved columns. For DoubleClick Search columns, only the `columnName` parameter is required. For saved columns only the `savedColumnName` parameter is required. Both `columnName` and `savedColumnName` cannot be set in the same stanza.\ The maximum number of columns per request is 300. — item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
  --downloadFormat: string # Format that the report should be returned in. Currently `csv` or `tsv` is supported.
  --filters: list # A list of filters to be applied to the report.\ The maximum number of filters per request is 300. — item shape: {column?: record, operator?: string, values?: list}
  --includeDeletedEntities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`. Deprecated, please use `includeRemovedEntities` instead.
  --includeRemovedEntities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`.
  --maxRowsPerFile: int # Asynchronous report only. The maximum number of rows per report file. A large report is split into many files based on this field. Acceptable values are `1000000` to `100000000`, inclusive. (format: int32)
  --orderBy: list # Synchronous report only. A list of columns and directions defining sorting to be performed on the report rows.\ The maximum number of orderings per request is 300. — item shape: {column?: record, sortOrder?: string}
  --reportScope: record # The reportScope is a set of IDs that are used to determine which subset of entities will be returned in the report. The full lineage of IDs from the lowest scoped level desired up through agency is required. — shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
  --reportType: string # Determines the type of rows that are returned in the report. For example, if you specify `reportType: keyword`, each row in the report will contain data about a keyword. See the [Types of Reports](/search-ads/v2/report-types/) reference for the columns that are available for each type.
  --rowCount: int # Synchronous report only. The maximum number of rows to return; additional rows are dropped. Acceptable values are `0` to `10000`, inclusive. Defaults to `10000`. (format: int32)
  --startRow: int # Synchronous report only. Zero-based index of the first row to return. Acceptable values are `0` to `50000`, inclusive. Defaults to `0`. (format: int32)
  --statisticsCurrency: string # Specifies the currency in which monetary will be returned. Possible values are: `usd`, `agency` (valid if the report is scoped to agency or lower), `advertiser` (valid if the report is scoped to * advertiser or lower), or `account` (valid if the report is scoped to engine account or lower).
  --timeRange: record # If metrics are requested in a report, this argument will be used to restrict the metrics to a specific time range. — shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
  --verifySingleTimeZone: oneof<nothing, bool> # If `true`, the report would only be created if all the requested stat data are sourced from a single timezone. Defaults to `false`.
]: any -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/reports" $qp)
  let body = {columns: $columns, downloadFormat: $downloadFormat, filters: $filters, includeDeletedEntities: $includeDeletedEntities, includeRemovedEntities: $includeRemovedEntities, maxRowsPerFile: $maxRowsPerFile, orderBy: $orderBy, reportScope: $reportScope, reportType: $reportType, rowCount: $rowCount, startRow: $startRow, statisticsCurrency: $statisticsCurrency, timeRange: $timeRange, verifySingleTimeZone: $verifySingleTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
export def "doubleclicksearch-reports-generate doubleclicksearchreportsgenerate" [
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --columns: list # The columns to include in the report. This includes both DoubleClick Search columns and saved columns. For DoubleClick Search columns, only the `columnName` parameter is required. For saved columns only the `savedColumnName` parameter is required. Both `columnName` and `savedColumnName` cannot be set in the same stanza.\ The maximum number of columns per request is 300. — item shape: {columnName?: string, customDimensionName?: string, customMetricName?: string, endDate?: string, groupByColumn?: bool, headerText?: string, platformSource?: string, productReportPerspective?: string, savedColumnName?: string, startDate?: string}
  --downloadFormat: string # Format that the report should be returned in. Currently `csv` or `tsv` is supported.
  --filters: list # A list of filters to be applied to the report.\ The maximum number of filters per request is 300. — item shape: {column?: record, operator?: string, values?: list}
  --includeDeletedEntities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`. Deprecated, please use `includeRemovedEntities` instead.
  --includeRemovedEntities: oneof<nothing, bool> # Determines if removed entities should be included in the report. Defaults to `false`.
  --maxRowsPerFile: int # Asynchronous report only. The maximum number of rows per report file. A large report is split into many files based on this field. Acceptable values are `1000000` to `100000000`, inclusive. (format: int32)
  --orderBy: list # Synchronous report only. A list of columns and directions defining sorting to be performed on the report rows.\ The maximum number of orderings per request is 300. — item shape: {column?: record, sortOrder?: string}
  --reportScope: record # The reportScope is a set of IDs that are used to determine which subset of entities will be returned in the report. The full lineage of IDs from the lowest scoped level desired up through agency is required. — shape: {adGroupId?: string, adId?: string, advertiserId?: string, agencyId?: string, campaignId?: string, engineAccountId?: string, keywordId?: string}
  --reportType: string # Determines the type of rows that are returned in the report. For example, if you specify `reportType: keyword`, each row in the report will contain data about a keyword. See the [Types of Reports](/search-ads/v2/report-types/) reference for the columns that are available for each type.
  --rowCount: int # Synchronous report only. The maximum number of rows to return; additional rows are dropped. Acceptable values are `0` to `10000`, inclusive. Defaults to `10000`. (format: int32)
  --startRow: int # Synchronous report only. Zero-based index of the first row to return. Acceptable values are `0` to `50000`, inclusive. Defaults to `0`. (format: int32)
  --statisticsCurrency: string # Specifies the currency in which monetary will be returned. Possible values are: `usd`, `agency` (valid if the report is scoped to agency or lower), `advertiser` (valid if the report is scoped to * advertiser or lower), or `account` (valid if the report is scoped to engine account or lower).
  --timeRange: record # If metrics are requested in a report, this argument will be used to restrict the metrics to a specific time range. — shape: {changedAttributesSinceTimestamp?: string, changedMetricsSinceTimestamp?: string, endDate?: string, startDate?: string}
  --verifySingleTimeZone: oneof<nothing, bool> # If `true`, the report would only be created if all the requested stat data are sourced from a single timezone. Defaults to `false`.
]: any -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/doubleclicksearch/v2/reports/generate" $qp)
  let body = {columns: $columns, downloadFormat: $downloadFormat, filters: $filters, includeDeletedEntities: $includeDeletedEntities, includeRemovedEntities: $includeRemovedEntities, maxRowsPerFile: $maxRowsPerFile, orderBy: $orderBy, reportScope: $reportScope, reportType: $reportType, rowCount: $rowCount, startRow: $startRow, statisticsCurrency: $statisticsCurrency, timeRange: $timeRange, verifySingleTimeZone: $verifySingleTimeZone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Polls for the status of a report request.
#
# GET /doubleclicksearch/v2/reports/{reportId}
# operationId: doubleclicksearch.reports.get
export def "doubleclicksearch-reports doubleclicksearchreportsget" [
  reportId: string
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<files: table<byteCount: string, url: string>, id: string, isReportReady: bool, kind: string, request: record<columns: list<record>, downloadFormat: string, filters: list<record>, includeDeletedEntities: bool, includeRemovedEntities: bool, maxRowsPerFile: int, orderBy: list<record>, reportScope: record<adGroupId: string, adId: string, advertiserId: string, agencyId: string, campaignId: string, engineAccountId: string, keywordId: string>, reportType: string, rowCount: int, startRow: int, statisticsCurrency: string, timeRange: record<changedAttributesSinceTimestamp: string, changedMetricsSinceTimestamp: string, endDate: string, startDate: string>, verifySingleTimeZone: bool>, rowCount: int, rows: list<record>, statisticsCurrencyCode: string, statisticsTimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/reports/($reportId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Downloads a report file encoded in UTF-8.
#
# GET /doubleclicksearch/v2/reports/{reportId}/files/{reportFragment}
# operationId: doubleclicksearch.reports.getFile
export def "doubleclicksearch-reports-files doubleclicksearchreportsgetFile" [
  reportId: string
  reportFragment: int
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
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/doubleclicksearch/v2/reports/($reportId)/files/($reportFragment)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
