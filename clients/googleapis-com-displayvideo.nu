# Auto-generated client for Display & Video 360 API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/displayvideo/v2/openapi.json
# Auth: --token flag or $env.DISPLAY_VIDEO_360_API_TOKEN

const BASE_URL = "https://displayvideo.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISPLAY_VIDEO_360_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://displayvideo.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def entity-status-completer [] { ["ENTITY_STATUS_ACTIVE" "ENTITY_STATUS_ARCHIVED" "ENTITY_STATUS_DRAFT" "ENTITY_STATUS_PAUSED" "ENTITY_STATUS_SCHEDULED_FOR_DELETION" "ENTITY_STATUS_UNSPECIFIED"] }
def creative-type-completer [] { ["CREATIVE_TYPE_AUDIO" "CREATIVE_TYPE_EXPANDABLE" "CREATIVE_TYPE_LIGHTBOX" "CREATIVE_TYPE_NATIVE" "CREATIVE_TYPE_NATIVE_APP_INSTALL" "CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE" "CREATIVE_TYPE_NATIVE_SITE_SQUARE" "CREATIVE_TYPE_NATIVE_VIDEO" "CREATIVE_TYPE_PUBLISHER_HOSTED" "CREATIVE_TYPE_STANDARD" "CREATIVE_TYPE_TEMPLATED_APP_INSTALL" "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL" "CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO" "CREATIVE_TYPE_UNSPECIFIED" "CREATIVE_TYPE_VIDEO"] }
def expanding-direction-completer [] { ["EXPANDING_DIRECTION_ANY_DIAGONAL" "EXPANDING_DIRECTION_DOWN" "EXPANDING_DIRECTION_DOWN_AND_LEFT" "EXPANDING_DIRECTION_DOWN_AND_RIGHT" "EXPANDING_DIRECTION_LEFT" "EXPANDING_DIRECTION_LEFT_OR_RIGHT" "EXPANDING_DIRECTION_NONE" "EXPANDING_DIRECTION_RIGHT" "EXPANDING_DIRECTION_UNSPECIFIED" "EXPANDING_DIRECTION_UP" "EXPANDING_DIRECTION_UP_AND_LEFT" "EXPANDING_DIRECTION_UP_AND_RIGHT" "EXPANDING_DIRECTION_UP_OR_DOWN"] }
def hosting-source-completer [] { ["HOSTING_SOURCE_CM" "HOSTING_SOURCE_HOSTED" "HOSTING_SOURCE_RICH_MEDIA" "HOSTING_SOURCE_THIRD_PARTY" "HOSTING_SOURCE_UNSPECIFIED"] }
def billable-outcome-completer [] { ["BILLABLE_OUTCOME_PAY_PER_CLICK" "BILLABLE_OUTCOME_PAY_PER_IMPRESSION" "BILLABLE_OUTCOME_PAY_PER_VIEWABLE_IMPRESSION" "BILLABLE_OUTCOME_UNSPECIFIED"] }
def insertion-order-type-completer [] { ["INSERTION_ORDER_TYPE_UNSPECIFIED" "OVER_THE_TOP" "RTB"] }
def loi-sapin-invoice-type-completer [] { ["LOI_SAPIN_INVOICE_TYPE_MEDIA" "LOI_SAPIN_INVOICE_TYPE_PLATFORM" "LOI_SAPIN_INVOICE_TYPE_UNSPECIFIED"] }
def line-item-type-completer [] { ["LINE_ITEM_TYPE_AUDIO_DEFAULT" "LINE_ITEM_TYPE_DISPLAY_DEFAULT" "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INSTALL" "LINE_ITEM_TYPE_DISPLAY_MOBILE_APP_INVENTORY" "LINE_ITEM_TYPE_UNSPECIFIED" "LINE_ITEM_TYPE_VIDEO_DEFAULT" "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INSTALL" "LINE_ITEM_TYPE_VIDEO_MOBILE_APP_INVENTORY" "LINE_ITEM_TYPE_VIDEO_OVER_THE_TOP" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_ACTION" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_AUDIO" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_NON_SKIPPABLE" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_NON_SKIPPABLE_OVER_THE_TOP" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_REACH" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_REACH_OVER_THE_TOP" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_SIMPLE" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_SIMPLE_OVER_THE_TOP" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_TARGET_FREQUENCY" "LINE_ITEM_TYPE_YOUTUBE_AND_PARTNERS_VIDEO_SEQUENCE"] }
def location-type-completer [] { ["TARGETING_LOCATION_TYPE_PROXIMITY" "TARGETING_LOCATION_TYPE_REGIONAL" "TARGETING_LOCATION_TYPE_UNSPECIFIED"] }
def custom-bidding-algorithm-type-completer [] { ["ADS_DATA_HUB_BASED" "CUSTOM_BIDDING_ALGORITHM_TYPE_UNSPECIFIED" "GOAL_BUILDER_BASED" "SCRIPT_BASED"] }
def audience-type-completer [] { ["ACTIVITY_BASED" "AUDIENCE_TYPE_UNSPECIFIED" "CUSTOMER_MATCH_CONTACT_INFO" "CUSTOMER_MATCH_DEVICE_ID" "CUSTOMER_MATCH_USER_ID" "FREQUENCY_CAP" "LICENSED" "TAG_BASED" "YOUTUBE_USERS"] }
def first-and-third-party-audience-type-completer [] { ["FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_FIRST_PARTY" "FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_THIRD_PARTY" "FIRST_AND_THIRD_PARTY_AUDIENCE_TYPE_UNSPECIFIED"] }
def exchange-completer [] { ["EXCHANGE_ADFORM" "EXCHANGE_ADMETA" "EXCHANGE_ADMIXER" "EXCHANGE_ADSMOGO" "EXCHANGE_ADSWIZZ" "EXCHANGE_AJA" "EXCHANGE_APPLOVIN" "EXCHANGE_APPNEXUS" "EXCHANGE_BIDSWITCH" "EXCHANGE_BRIGHTROLL" "EXCHANGE_BRIGHTROLL_DISPLAY" "EXCHANGE_CADREON" "EXCHANGE_CONNATIX" "EXCHANGE_DAILYMOTION" "EXCHANGE_DAX" "EXCHANGE_FIVE" "EXCHANGE_FLUCT" "EXCHANGE_FREEWHEEL" "EXCHANGE_FYBER" "EXCHANGE_GENIEE" "EXCHANGE_GOOGLE_AD_MANAGER" "EXCHANGE_GUMGUM" "EXCHANGE_HIVESTACK" "EXCHANGE_IBILLBOARD" "EXCHANGE_IMOBILE" "EXCHANGE_IMPROVE_DIGITAL" "EXCHANGE_INDEX" "EXCHANGE_INMOBI" "EXCHANGE_JCD" "EXCHANGE_KARGO" "EXCHANGE_MEDIANET" "EXCHANGE_MICROAD" "EXCHANGE_MOPUB" "EXCHANGE_NEND" "EXCHANGE_NEXSTAR_DIGITAL" "EXCHANGE_ONE_BY_AOL_DISPLAY" "EXCHANGE_ONE_BY_AOL_MOBILE" "EXCHANGE_ONE_BY_AOL_VIDEO" "EXCHANGE_OOYALA" "EXCHANGE_OPEN8" "EXCHANGE_OPENX" "EXCHANGE_PERMODO" "EXCHANGE_PLACE_EXCHANGE" "EXCHANGE_PLATFORMID" "EXCHANGE_PLATFORMONE" "EXCHANGE_PUBMATIC" "EXCHANGE_PULSEPOINT" "EXCHANGE_RED_FOR_PUBLISHERS" "EXCHANGE_RESET_DIGITAL" "EXCHANGE_REVENUEMAX" "EXCHANGE_RUBICON" "EXCHANGE_SHARETHROUGH" "EXCHANGE_SMAATO" "EXCHANGE_SMARTCLIP" "EXCHANGE_SMARTRTB" "EXCHANGE_SMARTSTREAMTV" "EXCHANGE_SOUNDCAST" "EXCHANGE_SOVRN" "EXCHANGE_SPOTXCHANGE" "EXCHANGE_STROER" "EXCHANGE_SUPERSHIP" "EXCHANGE_TABOOLA" "EXCHANGE_TAPJOY" "EXCHANGE_TEADSTV" "EXCHANGE_TELARIA" "EXCHANGE_TRIPLELIFT" "EXCHANGE_TRITON" "EXCHANGE_TVN" "EXCHANGE_UNITED" "EXCHANGE_UNRULYX" "EXCHANGE_UNSPECIFIED" "EXCHANGE_VISTAR" "EXCHANGE_WAZE" "EXCHANGE_YIELDLAB" "EXCHANGE_YIELDMO"] }
def commitment-completer [] { ["INVENTORY_SOURCE_COMMITMENT_GUARANTEED" "INVENTORY_SOURCE_COMMITMENT_NON_GUARANTEED" "INVENTORY_SOURCE_COMMITMENT_UNSPECIFIED"] }
def delivery-method-completer [] { ["INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC" "INVENTORY_SOURCE_DELIVERY_METHOD_TAG" "INVENTORY_SOURCE_DELIVERY_METHOD_UNSPECIFIED"] }
def inventory-source-type-completer [] { ["INVENTORY_SOURCE_TYPE_AUCTION_PACKAGE" "INVENTORY_SOURCE_TYPE_PRIVATE" "INVENTORY_SOURCE_TYPE_UNSPECIFIED"] }
def version-completer [] { ["SDF_VERSION_3_1" "SDF_VERSION_4" "SDF_VERSION_4_1" "SDF_VERSION_4_2" "SDF_VERSION_5" "SDF_VERSION_5_1" "SDF_VERSION_5_2" "SDF_VERSION_5_3" "SDF_VERSION_5_4" "SDF_VERSION_5_5" "SDF_VERSION_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "download get" } } | get name | first)
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

# Downloads media. Download is supported on the URI `/download/{resource_name=**}?alt=media.` **Note**: Download requests will not be successful without including `alt=media` query string.
#
# GET /download/{resourceName}
# operationId: displayvideo.media.download
export def "download get" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<resourceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/download/{resource_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads media. Upload is supported on the URI `/upload/media/{resource_name=**}?upload_type=media.` **Note**: Upload requests will not be successful without including `upload_type=media` query string.
#
# POST /media/{resourceName}
# operationId: displayvideo.media.upload
export def "media upload" [
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> record<resourceName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource_name: (encode-path-segment $resource_name)} | format pattern "/media/{resource_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $req_body
}

# Lists advertisers that are accessible to the current user. The order is defined by the order_by parameter. A single partner_id is required. Cross-partner listing is not supported.
#
# GET /v2/advertisers
# operationId: displayvideo.advertisers.list
export def "advertisers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by advertiser properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator used on `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The operator must be `EQUALS (=)`. * Supported fields: - `advertiserId` - `displayName` - `entityStatus` - `updateTime` (input in ISO 8601 format, or YYYY-MM-DDTHH:MM:SSZ) Examples: * All active advertisers under a partner: `entityStatus="ENTITY_STATUS_ACTIVE"` * All advertisers with an update time less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All advertisers with an update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `entityStatus` * `updateTime` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListAdvertisers` method. If not specified, the first page of results will be returned.
  --partner-id: string # Required. The ID of the partner that the fetched advertisers should all belong to. The system only supports listing advertisers for one partner at a time.
]: nothing -> record<advertisers: table<adServerConfig: record, advertiserId: string, billingConfig: record, creativeConfig: record, dataAccessConfig: record, displayName: string, entityStatus: string, generalConfig: record, integrationDetails: record, name: string, partnerId: string, prismaEnabled: bool, servingConfig: record, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/advertisers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new advertiser. Returns the newly created advertiser if successful. This method can take up to 180 seconds to complete.
#
# POST /v2/advertisers
# operationId: displayvideo.advertisers.create
# --adServerConfig shape: {cmHybridConfig?: record, thirdPartyOnlyConfig?: record}
# --billingConfig shape: {billingProfileId?: string}
# --creativeConfig shape: {dynamicCreativeEnabled?: bool, iasClientId?: string, obaComplianceDisabled?: bool, videoCreativeDataSharingAuthorized?: bool}
# --dataAccessConfig shape: {sdfConfig?: record}
# --generalConfig shape: {currencyCode?: string, domainUrl?: string}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --servingConfig shape: {exemptTvFromViewabilityTargeting?: bool}
export def "advertisers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --ad-server-config: record # Ad server related settings of an advertiser. — shape: {cmHybridConfig?: record, thirdPartyOnlyConfig?: record}
  --billing-config: record # Billing related settings of an advertiser. — shape: {billingProfileId?: string}
  --creative-config: record # Creatives related settings of an advertiser. — shape: {dynamicCreativeEnabled?: bool, iasClientId?: string, obaComplianceDisabled?: bool, videoCreativeDataSharingAuthorized?: bool}
  --data-access-config: record # Settings that control how advertiser related data may be accessed. — shape: {sdfConfig?: record}
  --display-name: string # Required. The display name of the advertiser. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not insertion orders and line items of the advertiser can spend their budgets and bid on inventory. * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_PAUSED` and `ENTITY_STATUS_SCHEDULED_FOR_DELETION`. * If set to `ENTITY_STATUS_SCHEDULED_FOR_DELETION`, the advertiser will be deleted 30 days from when it was first scheduled for deletion.
  --general-config: record # General settings of an advertiser. — shape: {currencyCode?: string, domainUrl?: string}
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --partner-id: string # Required. Immutable. The unique ID of the partner that the advertiser belongs to. (format: int64)
  --prisma-enabled: oneof<nothing, bool> # Whether integration with Mediaocean (Prisma) is enabled. By enabling this, you agree to the following: On behalf of my company, I authorize Mediaocean (Prisma) to send budget segment plans to Google, and I authorize Google to send corresponding reporting and invoices from DV360 to Mediaocean for the purposes of budget planning, billing, and reconciliation for this advertiser.
  --serving-config: record # Targeting settings related to ad serving of an advertiser. — shape: {exemptTvFromViewabilityTargeting?: bool}
]: any -> record<adServerConfig: record<cmHybridConfig: record<cmAccountId: string, cmFloodlightConfigId: string, cmFloodlightLinkingAuthorized: bool, cmSyncableSiteIds: list, dv360ToCmCostReportingEnabled: bool, dv360ToCmDataSharingEnabled: bool>, thirdPartyOnlyConfig: record<pixelOrderIdReportingEnabled: bool>>, advertiserId: string, billingConfig: record<billingProfileId: string>, creativeConfig: record<dynamicCreativeEnabled: bool, iasClientId: string, obaComplianceDisabled: bool, videoCreativeDataSharingAuthorized: bool>, dataAccessConfig: record<sdfConfig: record<overridePartnerSdfConfig: bool, sdfConfig: record>>, displayName: string, entityStatus: string, generalConfig: record<currencyCode: string, domainUrl: string, timeZone: string>, integrationDetails: record<details: string, integrationCode: string>, name: string, partnerId: string, prismaEnabled: bool, servingConfig: record<exemptTvFromViewabilityTargeting: bool>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/advertisers" $qp)
  let req_body = {"adServerConfig": $ad_server_config, "billingConfig": $billing_config, "creativeConfig": $creative_config, "dataAccessConfig": $data_access_config, "displayName": $display_name, "entityStatus": $entity_status, "generalConfig": $general_config, "integrationDetails": $integration_details, "partnerId": $partner_id, "prismaEnabled": $prisma_enabled, "servingConfig": $serving_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an advertiser. Deleting an advertiser will delete all of its child resources, for example, campaigns, insertion orders and line items. A deleted advertiser cannot be recovered.
#
# DELETE /v2/advertisers/{advertiserId}
# operationId: displayvideo.advertisers.delete
export def "advertisers delete" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an advertiser.
#
# GET /v2/advertisers/{advertiserId}
# operationId: displayvideo.advertisers.get
export def "advertisers get" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<adServerConfig: record<cmHybridConfig: record<cmAccountId: string, cmFloodlightConfigId: string, cmFloodlightLinkingAuthorized: bool, cmSyncableSiteIds: list, dv360ToCmCostReportingEnabled: bool, dv360ToCmDataSharingEnabled: bool>, thirdPartyOnlyConfig: record<pixelOrderIdReportingEnabled: bool>>, advertiserId: string, billingConfig: record<billingProfileId: string>, creativeConfig: record<dynamicCreativeEnabled: bool, iasClientId: string, obaComplianceDisabled: bool, videoCreativeDataSharingAuthorized: bool>, dataAccessConfig: record<sdfConfig: record<overridePartnerSdfConfig: bool, sdfConfig: record>>, displayName: string, entityStatus: string, generalConfig: record<currencyCode: string, domainUrl: string, timeZone: string>, integrationDetails: record<details: string, integrationCode: string>, name: string, partnerId: string, prismaEnabled: bool, servingConfig: record<exemptTvFromViewabilityTargeting: bool>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing advertiser. Returns the updated advertiser if successful.
#
# PATCH /v2/advertisers/{advertiserId}
# operationId: displayvideo.advertisers.patch
# --adServerConfig shape: {cmHybridConfig?: record, thirdPartyOnlyConfig?: record}
# --billingConfig shape: {billingProfileId?: string}
# --creativeConfig shape: {dynamicCreativeEnabled?: bool, iasClientId?: string, obaComplianceDisabled?: bool, videoCreativeDataSharingAuthorized?: bool}
# --dataAccessConfig shape: {sdfConfig?: record}
# --generalConfig shape: {currencyCode?: string, domainUrl?: string}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --servingConfig shape: {exemptTvFromViewabilityTargeting?: bool}
export def "advertisers update" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --ad-server-config: record # Ad server related settings of an advertiser. — shape: {cmHybridConfig?: record, thirdPartyOnlyConfig?: record}
  --billing-config: record # Billing related settings of an advertiser. — shape: {billingProfileId?: string}
  --creative-config: record # Creatives related settings of an advertiser. — shape: {dynamicCreativeEnabled?: bool, iasClientId?: string, obaComplianceDisabled?: bool, videoCreativeDataSharingAuthorized?: bool}
  --data-access-config: record # Settings that control how advertiser related data may be accessed. — shape: {sdfConfig?: record}
  --display-name: string # Required. The display name of the advertiser. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not insertion orders and line items of the advertiser can spend their budgets and bid on inventory. * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_PAUSED` and `ENTITY_STATUS_SCHEDULED_FOR_DELETION`. * If set to `ENTITY_STATUS_SCHEDULED_FOR_DELETION`, the advertiser will be deleted 30 days from when it was first scheduled for deletion.
  --general-config: record # General settings of an advertiser. — shape: {currencyCode?: string, domainUrl?: string}
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --partner-id: string # Required. Immutable. The unique ID of the partner that the advertiser belongs to. (format: int64)
  --prisma-enabled: oneof<nothing, bool> # Whether integration with Mediaocean (Prisma) is enabled. By enabling this, you agree to the following: On behalf of my company, I authorize Mediaocean (Prisma) to send budget segment plans to Google, and I authorize Google to send corresponding reporting and invoices from DV360 to Mediaocean for the purposes of budget planning, billing, and reconciliation for this advertiser.
  --serving-config: record # Targeting settings related to ad serving of an advertiser. — shape: {exemptTvFromViewabilityTargeting?: bool}
]: any -> record<adServerConfig: record<cmHybridConfig: record<cmAccountId: string, cmFloodlightConfigId: string, cmFloodlightLinkingAuthorized: bool, cmSyncableSiteIds: list, dv360ToCmCostReportingEnabled: bool, dv360ToCmDataSharingEnabled: bool>, thirdPartyOnlyConfig: record<pixelOrderIdReportingEnabled: bool>>, advertiserId: string, billingConfig: record<billingProfileId: string>, creativeConfig: record<dynamicCreativeEnabled: bool, iasClientId: string, obaComplianceDisabled: bool, videoCreativeDataSharingAuthorized: bool>, dataAccessConfig: record<sdfConfig: record<overridePartnerSdfConfig: bool, sdfConfig: record>>, displayName: string, entityStatus: string, generalConfig: record<currencyCode: string, domainUrl: string, timeZone: string>, integrationDetails: record<details: string, integrationCode: string>, name: string, partnerId: string, prismaEnabled: bool, servingConfig: record<exemptTvFromViewabilityTargeting: bool>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}") $qp)
  let req_body = {"adServerConfig": $ad_server_config, "billingConfig": $billing_config, "creativeConfig": $creative_config, "dataAccessConfig": $data_access_config, "displayName": $display_name, "entityStatus": $entity_status, "generalConfig": $general_config, "integrationDetails": $integration_details, "partnerId": $partner_id, "prismaEnabled": $prisma_enabled, "servingConfig": $serving_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Uploads an asset. Returns the ID of the newly uploaded asset if successful. The asset file size should be no more than 10 MB for images, 200 MB for ZIP files, and 1 GB for videos. Must be used within the [multipart media upload process](/display-video/api/guides/how-tos/upload#multipart). Examples using provided client libraries can be found in our [Creating Creatives guide](/display-video/api/guides/creating-creatives/overview#upload_an_asset).
#
# POST /v2/advertisers/{advertiserId}/assets
# operationId: displayvideo.advertisers.assets.upload
export def "advertisers-assets upload" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> record<asset: record<content: string, mediaId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/assets") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $req_body
}

# Lists campaigns in an advertiser. The order is defined by the order_by parameter. If a filter by entity_status is not specified, campaigns with `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/advertisers/{advertiserId}/campaigns
# operationId: displayvideo.advertisers.campaigns.list
export def "advertisers-campaigns list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by campaign properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator used on `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The operator must be `EQUALS (=)`. * Supported fields: - `campaignId` - `displayName` - `entityStatus` - `updateTime` (input in ISO 8601 format, or YYYY-MM-DDTHH:MM:SSZ) Examples: * All `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED` campaigns under an advertiser: `(entityStatus="ENTITY_STATUS_ACTIVE" OR entityStatus="ENTITY_STATUS_PAUSED")` * All campaigns with an update time less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All campaigns with an update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `entityStatus` * `updateTime` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCampaigns` method. If not specified, the first page of results will be returned.
]: nothing -> record<campaigns: table<advertiserId: string, campaignBudgets: list, campaignFlight: record, campaignGoal: record, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record, name: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new campaign. Returns the newly created campaign if successful.
#
# POST /v2/advertisers/{advertiserId}/campaigns
# operationId: displayvideo.advertisers.campaigns.create
# --campaignBudgets item shape: {budgetAmountMicros?: string, budgetId?: string, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS", dateRange?: record, displayName?: string, externalBudgetId?: string, externalBudgetSource?: "EXTERNAL_BUDGET_SOURCE_UNSPECIFIED"|"EXTERNAL_BUDGET_SOURCE_NONE"|"EXTERNAL_BUDGET_SOURCE_MEDIA_OCEAN", invoiceGroupingId?: string, prismaConfig?: record}
# --campaignFlight shape: {plannedDates?: record, plannedSpendAmountMicros?: string}
# --campaignGoal shape: {campaignGoalType?: "CAMPAIGN_GOAL_TYPE_UNSPECIFIED"|"CAMPAIGN_GOAL_TYPE_APP_INSTALL"|"CAMPAIGN_GOAL_TYPE_BRAND_AWARENESS"|"CAMPAIGN_GOAL_TYPE_OFFLINE_ACTION"|"CAMPAIGN_GOAL_TYPE_ONLINE_ACTION", performanceGoal?: record}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
export def "advertisers-campaigns create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --campaign-budgets: list # The list of budgets available to this campaign. If this field is not set, the campaign uses an unlimited budget. — item shape: {budgetAmountMicros?: string, budgetId?: string, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS", dateRange?: record, displayName?: string, externalBudgetId?: string, externalBudgetSource?: "EXTERNAL_BUDGET_SOURCE_UNSPECIFIED"|"EXTERNAL_BUDGET_SOURCE_NONE"|"EXTERNAL_BUDGET_SOURCE_MEDIA_OCEAN", invoiceGroupingId?: string, prismaConfig?: record}
  --campaign-flight: record # Settings that track the planned spend and duration of a campaign. — shape: {plannedDates?: record, plannedSpendAmountMicros?: string}
  --campaign-goal: record # Settings that control the goal of a campaign. — shape: {campaignGoalType?: "CAMPAIGN_GOAL_TYPE_UNSPECIFIED"|"CAMPAIGN_GOAL_TYPE_APP_INSTALL"|"CAMPAIGN_GOAL_TYPE_BRAND_AWARENESS"|"CAMPAIGN_GOAL_TYPE_OFFLINE_ACTION"|"CAMPAIGN_GOAL_TYPE_ONLINE_ACTION", performanceGoal?: record}
  --display-name: string # Required. The display name of the campaign. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the insertion orders under this campaign can spend their budgets and bid on inventory. * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_ARCHIVED`, and `ENTITY_STATUS_PAUSED`. * For CreateCampaign method, `ENTITY_STATUS_ARCHIVED` is not allowed.
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
]: any -> record<advertiserId: string, campaignBudgets: table<budgetAmountMicros: string, budgetId: string, budgetUnit: string, dateRange: record, displayName: string, externalBudgetId: string, externalBudgetSource: string, invoiceGroupingId: string, prismaConfig: record>, campaignFlight: record<plannedDates: record<endDate: record, startDate: record>, plannedSpendAmountMicros: string>, campaignGoal: record<campaignGoalType: string, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, name: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns") $qp)
  let req_body = {"campaignBudgets": $campaign_budgets, "campaignFlight": $campaign_flight, "campaignGoal": $campaign_goal, "displayName": $display_name, "entityStatus": $entity_status, "frequencyCap": $frequency_cap} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Permanently deletes a campaign. A deleted campaign cannot be recovered. The campaign should be archived first, i.e. set entity_status to `ENTITY_STATUS_ARCHIVED`, to be able to delete it.
#
# DELETE /v2/advertisers/{advertiserId}/campaigns/{campaignId}
# operationId: displayvideo.advertisers.campaigns.delete
export def "advertisers-campaigns delete" [
  advertiser_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a campaign.
#
# GET /v2/advertisers/{advertiserId}/campaigns/{campaignId}
# operationId: displayvideo.advertisers.campaigns.get
export def "advertisers-campaigns get" [
  advertiser_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<advertiserId: string, campaignBudgets: table<budgetAmountMicros: string, budgetId: string, budgetUnit: string, dateRange: record, displayName: string, externalBudgetId: string, externalBudgetSource: string, invoiceGroupingId: string, prismaConfig: record>, campaignFlight: record<plannedDates: record<endDate: record, startDate: record>, plannedSpendAmountMicros: string>, campaignGoal: record<campaignGoalType: string, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, name: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing campaign. Returns the updated campaign if successful.
#
# PATCH /v2/advertisers/{advertiserId}/campaigns/{campaignId}
# operationId: displayvideo.advertisers.campaigns.patch
# --campaignBudgets item shape: {budgetAmountMicros?: string, budgetId?: string, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS", dateRange?: record, displayName?: string, externalBudgetId?: string, externalBudgetSource?: "EXTERNAL_BUDGET_SOURCE_UNSPECIFIED"|"EXTERNAL_BUDGET_SOURCE_NONE"|"EXTERNAL_BUDGET_SOURCE_MEDIA_OCEAN", invoiceGroupingId?: string, prismaConfig?: record}
# --campaignFlight shape: {plannedDates?: record, plannedSpendAmountMicros?: string}
# --campaignGoal shape: {campaignGoalType?: "CAMPAIGN_GOAL_TYPE_UNSPECIFIED"|"CAMPAIGN_GOAL_TYPE_APP_INSTALL"|"CAMPAIGN_GOAL_TYPE_BRAND_AWARENESS"|"CAMPAIGN_GOAL_TYPE_OFFLINE_ACTION"|"CAMPAIGN_GOAL_TYPE_ONLINE_ACTION", performanceGoal?: record}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
export def "advertisers-campaigns update" [
  advertiser_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --campaign-budgets: list # The list of budgets available to this campaign. If this field is not set, the campaign uses an unlimited budget. — item shape: {budgetAmountMicros?: string, budgetId?: string, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS", dateRange?: record, displayName?: string, externalBudgetId?: string, externalBudgetSource?: "EXTERNAL_BUDGET_SOURCE_UNSPECIFIED"|"EXTERNAL_BUDGET_SOURCE_NONE"|"EXTERNAL_BUDGET_SOURCE_MEDIA_OCEAN", invoiceGroupingId?: string, prismaConfig?: record}
  --campaign-flight: record # Settings that track the planned spend and duration of a campaign. — shape: {plannedDates?: record, plannedSpendAmountMicros?: string}
  --campaign-goal: record # Settings that control the goal of a campaign. — shape: {campaignGoalType?: "CAMPAIGN_GOAL_TYPE_UNSPECIFIED"|"CAMPAIGN_GOAL_TYPE_APP_INSTALL"|"CAMPAIGN_GOAL_TYPE_BRAND_AWARENESS"|"CAMPAIGN_GOAL_TYPE_OFFLINE_ACTION"|"CAMPAIGN_GOAL_TYPE_ONLINE_ACTION", performanceGoal?: record}
  --display-name: string # Required. The display name of the campaign. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the insertion orders under this campaign can spend their budgets and bid on inventory. * Accepted values are `ENTITY_STATUS_ACTIVE`, `ENTITY_STATUS_ARCHIVED`, and `ENTITY_STATUS_PAUSED`. * For CreateCampaign method, `ENTITY_STATUS_ARCHIVED` is not allowed.
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
]: any -> record<advertiserId: string, campaignBudgets: table<budgetAmountMicros: string, budgetId: string, budgetUnit: string, dateRange: record, displayName: string, externalBudgetId: string, externalBudgetSource: string, invoiceGroupingId: string, prismaConfig: record>, campaignFlight: record<plannedDates: record<endDate: record, startDate: record>, plannedSpendAmountMicros: string>, campaignGoal: record<campaignGoalType: string, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, name: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}") $qp)
  let req_body = {"campaignBudgets": $campaign_budgets, "campaignFlight": $campaign_flight, "campaignGoal": $campaign_goal, "displayName": $display_name, "entityStatus": $entity_status, "frequencyCap": $frequency_cap} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the targeting options assigned to a campaign for a specified targeting type.
#
# GET /v2/advertisers/{advertiserId}/campaigns/{campaignId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.campaigns.targetingTypes.assignedTargetingOptions.list
export def "advertisers-campaigns-targeting-types-assigned-targeting-options list" [
  advertiser_id: string
  campaign_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` - `inheritance` Examples: * AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `5000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCampaignAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to a campaign.
#
# GET /v2/advertisers/{advertiserId}/campaigns/{campaignId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.campaigns.targetingTypes.assignedTargetingOptions.get
export def "advertisers-campaigns-targeting-types-assigned-targeting-options get" [
  advertiser_id: string
  campaign_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists assigned targeting options of a campaign across targeting types.
#
# GET /v2/advertisers/{advertiserId}/campaigns/{campaignId}:listAssignedTargetingOptions
# operationId: displayvideo.advertisers.campaigns.listAssignedTargetingOptions
export def "advertisers-campaigns list-assigned-targeting-options" [
  advertiser_id: string
  campaign_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR` on the same field. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of targeting type TARGETING_TYPE_LANGUAGE or TARGETING_TYPE_GENDER `targetingType="TARGETING_TYPE_LANGUAGE" OR targetingType="TARGETING_TYPE_GENDER"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `targetingType` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingType desc`.
  --page-size: int # Requested page size. The size must be an integer between `1` and `5000`. If unspecified, the default is `5000`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token that lets the client fetch the next page of results. Typically, this is the value of next_page_token returned from the previous call to `BulkListCampaignAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), campaign_id: (encode-path-segment $campaign_id)} | format pattern "/v2/advertisers/{advertiser_id}/campaigns/{campaign_id}:listAssignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists channels for a partner or advertiser.
#
# GET /v2/advertisers/{advertiserId}/channels
# operationId: displayvideo.advertisers.channels.list
export def "advertisers-channels list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by channel fields. Supported syntax: * Filter expressions for channel currently can only contain at most one * restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All channels for which the display name contains "google": `displayName : "google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `channelId` The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListChannels` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that owns the channels.
]: nothing -> record<channels: table<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new channel. Returns the newly created channel if successful.
#
# POST /v2/advertisers/{advertiserId}/channels
# operationId: displayvideo.advertisers.channels.create
export def "advertisers-channels create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --partner-id: string # The ID of the partner that owns the created channel.
  --body-advertiser-id: string # The ID of the advertiser that owns the channel. (format: int64)
  --display-name: string # Required. The display name of the channel. Must be UTF-8 encoded with a maximum length of 240 bytes.
  --partner-id: string # The ID of the partner that owns the channel. (format: int64)
]: any -> record<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "displayName": $display_name, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a channel. Returns the updated channel if successful.
#
# PATCH /v2/advertisers/{advertiserId}/channels/{channelId}
# operationId: displayvideo.advertisers.channels.patch
export def "advertisers-channels update" [
  advertiser_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --partner-id: string # The ID of the partner that owns the created channel.
  --update-mask: string # Required. The mask to control which fields to update.
  --body-advertiser-id: string # The ID of the advertiser that owns the channel. (format: int64)
  --display-name: string # Required. The display name of the channel. Must be UTF-8 encoded with a maximum length of 240 bytes.
  --partner-id: string # The ID of the partner that owns the channel. (format: int64)
]: any -> record<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "partnerId" $partner_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels/{channel_id}") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "displayName": $display_name, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists sites in a channel.
#
# GET /v2/advertisers/{advertiserId}/channels/{channelId}/sites
# operationId: displayvideo.advertisers.channels.sites.list
export def "advertisers-channels-sites list" [
  advertiser_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by site fields. Supported syntax: * Filter expressions for site currently can only contain at most one * restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `urlOrAppId` Examples: * All sites for which the URL or app ID contains "google": `urlOrAppId : "google"`
  --order-by: string # Field by which to sort the list. Acceptable values are: * `urlOrAppId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `urlOrAppId desc`.
  --page-size: int # Requested page size. Must be between `1` and `10000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListSites` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that owns the parent channel.
]: nothing -> record<nextPageToken: string, sites: table<name: string, urlOrAppId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels/{channel_id}/sites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a site from a channel.
#
# DELETE /v2/advertisers/{advertiserId}/channels/{channelId}/sites/{urlOrAppId}
# operationId: displayvideo.advertisers.channels.sites.delete
export def "advertisers-channels-sites delete" [
  advertiser_id: string
  channel_id: string
  url_or_app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --partner-id: string # The ID of the partner that owns the parent channel.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), channel_id: (encode-path-segment $channel_id), url_or_app_id: (encode-path-segment $url_or_app_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels/{channel_id}/sites/{url_or_app_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk edits sites under a single channel. The operation will delete the sites provided in BulkEditSitesRequest.deleted_sites and then create the sites provided in BulkEditSitesRequest.created_sites.
#
# POST /v2/advertisers/{advertiserId}/channels/{channelId}/sites:bulkEdit
# operationId: displayvideo.advertisers.channels.sites.bulkEdit
# --createdSites item shape: {urlOrAppId?: string}
export def "advertisers-channels-sites-bulk-edit create" [
  advertiser_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body-advertiser-id: string # The ID of the advertiser that owns the parent channel. (format: int64)
  --created-sites: list # The sites to create in batch, specified as a list of Sites. — item shape: {urlOrAppId?: string}
  --deleted-sites: list<string> # The sites to delete in batch, specified as a list of site url_or_app_ids.
  --partner-id: string # The ID of the partner that owns the parent channel. (format: int64)
]: any -> record<sites: table<name: string, urlOrAppId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels/{channel_id}/sites:bulkEdit") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "createdSites": $created_sites, "deletedSites": $deleted_sites, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replaces all of the sites under a single channel. The operation will replace the sites under a channel with the sites provided in ReplaceSitesRequest.new_sites.
#
# POST /v2/advertisers/{advertiserId}/channels/{channelId}/sites:replace
# operationId: displayvideo.advertisers.channels.sites.replace
# --newSites item shape: {urlOrAppId?: string}
export def "advertisers-channels-sites-replace update" [
  advertiser_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body-advertiser-id: string # The ID of the advertiser that owns the parent channel. (format: int64)
  --new-sites: list # The sites that will replace the existing sites assigned to the channel, specified as a list of Sites. — item shape: {urlOrAppId?: string}
  --partner-id: string # The ID of the partner that owns the parent channel. (format: int64)
]: any -> record<sites: table<name: string, urlOrAppId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/advertisers/{advertiser_id}/channels/{channel_id}/sites:replace") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "newSites": $new_sites, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists creatives in an advertiser. The order is defined by the order_by parameter. If a filter by entity_status is not specified, creatives with `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/advertisers/{advertiserId}/creatives
# operationId: displayvideo.advertisers.creatives.list
export def "advertisers-creatives list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by creative properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restriction for the same field must be combined by `OR`. * Restriction for different fields must be combined by `AND`. * Between `(` and `)` there can only be restrictions combined by `OR` for the same field. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)` for the following fields: - `entityStatus` - `creativeType`. - `dimensions` - `minDuration` - `maxDuration` - `approvalStatus` - `exchangeReviewStatus` - `dynamic` - `creativeId` * The operator must be `HAS (:)` for the following fields: - `lineItemIds` * The operator must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)` for the following fields: - `updateTime` (input in ISO 8601 format, or YYYY-MM-DDTHH:MM:SSZ) * For `entityStatus`, `minDuration`, `maxDuration`, `updateTime`, and `dynamic`, there may be at most one restriction. * For `dimensions`, the value is in the form of `"{width}x{height}"`. * For `exchangeReviewStatus`, the value is in the form of `{exchange}-{reviewStatus}`. * For `minDuration` and `maxDuration`, the value is in the form of `"{duration}s"`. Only seconds are supported with millisecond granularity. * For `updateTime`, a creative resource's field value reflects the last time that a creative has been updated, which includes updates made by the system (e.g. creative review updates). * There may be multiple `lineItemIds` restrictions in order to search against multiple possible line item IDs. * There may be multiple `creativeId` restrictions in order to search against multiple possible creative IDs. Examples: * All native creatives: `creativeType="CREATIVE_TYPE_NATIVE"` * All active creatives with 300x400 or 50x100 dimensions: `entityStatus="ENTITY_STATUS_ACTIVE" AND (dimensions="300x400" OR dimensions="50x100")` * All dynamic creatives that are approved by AdX or AppNexus, with a minimum duration of 5 seconds and 200ms. `dynamic="true" AND minDuration="5.2s" AND (exchangeReviewStatus="EXCHANGE_GOOGLE_AD_MANAGER-REVIEW_STATUS_APPROVED" OR exchangeReviewStatus="EXCHANGE_APPNEXUS-REVIEW_STATUS_APPROVED")` * All video creatives that are associated with line item ID 1 or 2: `creativeType="CREATIVE_TYPE_VIDEO" AND (lineItemIds:1 OR lineItemIds:2)` * Find creatives by multiple creative IDs: `creativeId=1 OR creativeId=2` * All creatives with an update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `creativeId` (default) * `createTime` * `mediaDuration` * `dimensions` (sorts by width first, then by height) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `createTime desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCreatives` method. If not specified, the first page of results will be returned.
]: nothing -> record<creatives: table<additionalDimensions: list, advertiserId: string, appendedTag: string, assets: list, cmPlacementId: string, cmTrackingAd: record, companionCreativeIds: list, counterEvents: list, createTime: string, creativeAttributes: list, creativeId: string, creativeType: string, dimensions: record, displayName: string, dynamic: bool, entityStatus: string, exitEvents: list, expandOnHover: bool, expandingDirection: string, hostingSource: string, html5Video: bool, iasCampaignMonitoring: bool, integrationCode: string, jsTrackerUrl: string, lineItemIds: list, mediaDuration: string, mp3Audio: bool, name: string, notes: string, obaIcon: record, oggAudio: bool, progressOffset: record, requireHtml5: bool, requireMraid: bool, requirePingForAttribution: bool, reviewStatus: record, skipOffset: record, skippable: bool, thirdPartyTag: string, thirdPartyUrls: list, timerEvents: list, trackerUrls: list, transcodes: list, universalAdId: record, updateTime: string, vastTagUrl: string, vpaid: bool>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/creatives") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new creative. Returns the newly created creative if successful.
#
# POST /v2/advertisers/{advertiserId}/creatives
# operationId: displayvideo.advertisers.creatives.create
# --additionalDimensions item shape: {heightPixels?: int, widthPixels?: int}
# --assets item shape: {asset?: record, role?: "ASSET_ROLE_UNSPECIFIED"|"ASSET_ROLE_MAIN"|"ASSET_ROLE_BACKUP"|"ASSET_ROLE_POLITE_LOAD"|"ASSET_ROLE_HEADLINE"|"ASSET_ROLE_LONG_HEADLINE"|"ASSET_ROLE_BODY"|"ASSET_ROLE_LONG_BODY"|"ASSET_ROLE_CAPTION_URL"|"ASSET_ROLE_CALL_TO_ACTION"|"ASSET_ROLE_ADVERTISER_NAME"|"ASSET_ROLE_PRICE"|"ASSET_ROLE_ANDROID_APP_ID"|"ASSET_ROLE_IOS_APP_ID"|"ASSET_ROLE_RATING"|"ASSET_ROLE_ICON"|"ASSET_ROLE_COVER_IMAGE"}
# --cmTrackingAd shape: {cmAdId?: string, cmCreativeId?: string, cmPlacementId?: string}
# --counterEvents item shape: {name?: string, reportingName?: string}
# --dimensions shape: {heightPixels?: int, widthPixels?: int}
# --exitEvents item shape: {name?: string, reportingName?: string, type?: "EXIT_EVENT_TYPE_UNSPECIFIED"|"EXIT_EVENT_TYPE_DEFAULT"|"EXIT_EVENT_TYPE_BACKUP", url?: string}
# --obaIcon shape: {clickTrackingUrl?: string, dimensions?: record, landingPageUrl?: string, position?: "OBA_ICON_POSITION_UNSPECIFIED"|"OBA_ICON_POSITION_UPPER_RIGHT"|"OBA_ICON_POSITION_UPPER_LEFT"|"OBA_ICON_POSITION_LOWER_RIGHT"|"OBA_ICON_POSITION_LOWER_LEFT", program?: string, resourceMimeType?: string, resourceUrl?: string, viewTrackingUrl?: string}
# --progressOffset shape: {percentage?: string, seconds?: string}
# --reviewStatus shape: {approvalStatus?: "APPROVAL_STATUS_UNSPECIFIED"|"APPROVAL_STATUS_PENDING_NOT_SERVABLE"|"APPROVAL_STATUS_PENDING_SERVABLE"|"APPROVAL_STATUS_APPROVED_SERVABLE"|"APPROVAL_STATUS_REJECTED_NOT_SERVABLE", contentAndPolicyReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", creativeAndLandingPageReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", ... (2 more fields)}
# --skipOffset shape: {percentage?: string, seconds?: string}
# --thirdPartyUrls item shape: {type?: "THIRD_PARTY_URL_TYPE_UNSPECIFIED"|"THIRD_PARTY_URL_TYPE_IMPRESSION"|"THIRD_PARTY_URL_TYPE_CLICK_TRACKING"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_START"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FIRST_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MIDPOINT"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_THIRD_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_COMPLETE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MUTE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PAUSE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_REWIND"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FULLSCREEN"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_STOP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_CUSTOM"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_SKIP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PROGRESS", ... (1 more fields)}
# --timerEvents item shape: {name?: string, reportingName?: string}
# --transcodes item shape: {audioBitRateKbps?: string, audioSampleRateHz?: string, bitRateKbps?: string, dimensions?: record, fileSizeBytes?: string, frameRate?: float, mimeType?: string, name?: string, transcoded?: bool}
# --universalAdId shape: {id?: string, registry?: "UNIVERSAL_AD_REGISTRY_UNSPECIFIED"|"UNIVERSAL_AD_REGISTRY_OTHER"|"UNIVERSAL_AD_REGISTRY_AD_ID"|"UNIVERSAL_AD_REGISTRY_CLEARCAST"|"UNIVERSAL_AD_REGISTRY_DV360"|"UNIVERSAL_AD_REGISTRY_CM"}
export def "advertisers-creatives create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --additional-dimensions: list # Additional dimensions. Applicable when creative_type is one of: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE` * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_LIGHTBOX` * `CREATIVE_TYPE_PUBLISHER_HOSTED` If this field is specified, width_pixels and height_pixels are both required and must be greater than or equal to 0. — item shape: {heightPixels?: int, widthPixels?: int}
  --appended-tag: string # Third-party HTML tracking tag to be appended to the creative tag.
  --assets: list # Required. Assets associated to this creative. — item shape: {asset?: record, role?: "ASSET_ROLE_UNSPECIFIED"|"ASSET_ROLE_MAIN"|"ASSET_ROLE_BACKUP"|"ASSET_ROLE_POLITE_LOAD"|"ASSET_ROLE_HEADLINE"|"ASSET_ROLE_LONG_HEADLINE"|"ASSET_ROLE_BODY"|"ASSET_ROLE_LONG_BODY"|"ASSET_ROLE_CAPTION_URL"|"ASSET_ROLE_CALL_TO_ACTION"|"ASSET_ROLE_ADVERTISER_NAME"|"ASSET_ROLE_PRICE"|"ASSET_ROLE_ANDROID_APP_ID"|"ASSET_ROLE_IOS_APP_ID"|"ASSET_ROLE_RATING"|"ASSET_ROLE_ICON"|"ASSET_ROLE_COVER_IMAGE"}
  --cm-tracking-ad: record # A Campaign Manager 360 tracking ad. — shape: {cmAdId?: string, cmCreativeId?: string, cmPlacementId?: string}
  --companion-creative-ids: list<string> # The IDs of companion creatives for a video creative. You can assign existing display creatives (with image or HTML5 assets) to serve surrounding the publisher's video player. Companions display around the video player while the video is playing and remain after the video has completed. Creatives contain additional dimensions can not be companion creatives. This field is only supported for following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  --counter-events: list # Counter events for a rich media creative. Counters track the number of times that a user interacts with any part of a rich media creative in a specified way (mouse-overs, mouse-outs, clicks, taps, data loading, keyboard entries, etc.). Any event that can be captured in the creative can be recorded as a counter. Leave it empty or unset for creatives containing image assets only. — item shape: {name?: string, reportingName?: string}
  --creative-type: string@creative-type-completer # Required. Immutable. The type of the creative.
  --dimensions: record # Dimensions. — shape: {heightPixels?: int, widthPixels?: int}
  --display-name: string # Required. The display name of the creative. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the creative can serve. Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED` * `ENTITY_STATUS_PAUSED`
  --exit-events: list # Required. Exit events for this creative. An exit (also known as a click tag) is any area in your creative that someone can click or tap to open an advertiser's landing page. Every creative must include at least one exit. You can add an exit to your creative in any of the following ways: * Use Google Web Designer's tap area. * Define a JavaScript variable called "clickTag". * Use the Enabler (Enabler.exit()) to track exits in rich media formats. — item shape: {name?: string, reportingName?: string, type?: "EXIT_EVENT_TYPE_UNSPECIFIED"|"EXIT_EVENT_TYPE_DEFAULT"|"EXIT_EVENT_TYPE_BACKUP", url?: string}
  --expand-on-hover: oneof<nothing, bool> # Optional. Indicates the creative will automatically expand on hover. Optional and only valid for third-party expandable creatives. Third-party expandable creatives are creatives with following hosting source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_EXPANDABLE`
  --expanding-direction: string@expanding-direction-completer # Optional. Specifies the expanding direction of the creative. Required and only valid for third-party expandable creatives. Third-party expandable creatives are creatives with following hosting source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_EXPANDABLE`
  --hosting-source: string@hosting-source-completer # Required. Indicates where the creative is hosted.
  --ias-campaign-monitoring: oneof<nothing, bool> # Indicates whether Integral Ad Science (IAS) campaign monitoring is enabled. To enable this for the creative, make sure the Advertiser.creative_config.ias_client_id has been set to your IAS client ID.
  --integration-code: string # ID information used to link this creative to an external system. Must be UTF-8 encoded with a length of no more than 10,000 characters.
  --js-tracker-url: string # JavaScript measurement URL from supported third-party verification providers (ComScore, DoubleVerify, IAS, Moat). HTML script tags are not supported. This field is only writeable in following creative_type: * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  --notes: string # User notes for this creative. Must be UTF-8 encoded with a length of no more than 20,000 characters.
  --oba-icon: record # OBA Icon for a Creative — shape: {clickTrackingUrl?: string, dimensions?: record, landingPageUrl?: string, position?: "OBA_ICON_POSITION_UNSPECIFIED"|"OBA_ICON_POSITION_UPPER_RIGHT"|"OBA_ICON_POSITION_UPPER_LEFT"|"OBA_ICON_POSITION_LOWER_RIGHT"|"OBA_ICON_POSITION_LOWER_LEFT", program?: string, resourceMimeType?: string, resourceUrl?: string, viewTrackingUrl?: string}
  --progress-offset: record # The length an audio or a video has been played. — shape: {percentage?: string, seconds?: string}
  --require-html5: oneof<nothing, bool> # Optional. Indicates that the creative relies on HTML5 to render properly. Optional and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --require-mraid: oneof<nothing, bool> # Optional. Indicates that the creative requires MRAID (Mobile Rich Media Ad Interface Definitions system). Set this if the creative relies on mobile gestures for interactivity, such as swiping or tapping. Optional and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --require-ping-for-attribution: oneof<nothing, bool> # Optional. Indicates that the creative will wait for a return ping for attribution. Only valid when using a Campaign Manager 360 tracking ad with a third-party ad server parameter and the ${DC_DBM_TOKEN} macro. Optional and only valid for third-party tag creatives or third-party VAST tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE` Third-party VAST tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  --review-status: record # Review statuses for the creative. — shape: {approvalStatus?: "APPROVAL_STATUS_UNSPECIFIED"|"APPROVAL_STATUS_PENDING_NOT_SERVABLE"|"APPROVAL_STATUS_PENDING_SERVABLE"|"APPROVAL_STATUS_APPROVED_SERVABLE"|"APPROVAL_STATUS_REJECTED_NOT_SERVABLE", contentAndPolicyReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", creativeAndLandingPageReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", ... (2 more fields)}
  --skip-offset: record # The length an audio or a video has been played. — shape: {percentage?: string, seconds?: string}
  --skippable: oneof<nothing, bool> # Whether the user can choose to skip a video creative. This field is only supported for the following creative_type: * `CREATIVE_TYPE_VIDEO`
  --third-party-tag: string # Optional. The original third-party tag used for the creative. Required and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --third-party-urls: list # Tracking URLs from third parties to track interactions with a video creative. This field is only supported for the following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO` * `CREATIVE_TYPE_NATIVE_VIDEO` — item shape: {type?: "THIRD_PARTY_URL_TYPE_UNSPECIFIED"|"THIRD_PARTY_URL_TYPE_IMPRESSION"|"THIRD_PARTY_URL_TYPE_CLICK_TRACKING"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_START"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FIRST_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MIDPOINT"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_THIRD_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_COMPLETE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MUTE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PAUSE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_REWIND"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FULLSCREEN"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_STOP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_CUSTOM"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_SKIP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PROGRESS", ... (1 more fields)}
  --timer-events: list # Timer custom events for a rich media creative. Timers track the time during which a user views and interacts with a specified part of a rich media creative. A creative can have multiple timer events, each timed independently. Leave it empty or unset for creatives containing image assets only. — item shape: {name?: string, reportingName?: string}
  --tracker-urls: list<string> # Tracking URLs for analytics providers or third-party ad technology vendors. The URLs must start with https (except on inventory that doesn't require SSL compliance). If using macros in your URL, use only macros supported by Display & Video 360. Standard URLs only, no IMG or SCRIPT tags. This field is only writeable in following creative_type: * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  --universal-ad-id: record # A creative identifier provided by a registry that is unique across all platforms. This is part of the VAST 4.0 standard. — shape: {id?: string, registry?: "UNIVERSAL_AD_REGISTRY_UNSPECIFIED"|"UNIVERSAL_AD_REGISTRY_OTHER"|"UNIVERSAL_AD_REGISTRY_AD_ID"|"UNIVERSAL_AD_REGISTRY_CLEARCAST"|"UNIVERSAL_AD_REGISTRY_DV360"|"UNIVERSAL_AD_REGISTRY_CM"}
  --vast-tag-url: string # Optional. The URL of the VAST tag for a third-party VAST tag creative. Required and only valid for third-party VAST tag creatives. Third-party VAST tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
]: any -> record<additionalDimensions: table<heightPixels: int, widthPixels: int>, advertiserId: string, appendedTag: string, assets: table<asset: record, role: string>, cmPlacementId: string, cmTrackingAd: record<cmAdId: string, cmCreativeId: string, cmPlacementId: string>, companionCreativeIds: list<string>, counterEvents: table<name: string, reportingName: string>, createTime: string, creativeAttributes: list<string>, creativeId: string, creativeType: string, dimensions: record<heightPixels: int, widthPixels: int>, displayName: string, dynamic: bool, entityStatus: string, exitEvents: table<name: string, reportingName: string, type: string, url: string>, expandOnHover: bool, expandingDirection: string, hostingSource: string, html5Video: bool, iasCampaignMonitoring: bool, integrationCode: string, jsTrackerUrl: string, lineItemIds: list<string>, mediaDuration: string, mp3Audio: bool, name: string, notes: string, obaIcon: record<clickTrackingUrl: string, dimensions: record<heightPixels: int, widthPixels: int>, landingPageUrl: string, position: string, program: string, resourceMimeType: string, resourceUrl: string, viewTrackingUrl: string>, oggAudio: bool, progressOffset: record<percentage: string, seconds: string>, requireHtml5: bool, requireMraid: bool, requirePingForAttribution: bool, reviewStatus: record<approvalStatus: string, contentAndPolicyReviewStatus: string, creativeAndLandingPageReviewStatus: string, exchangeReviewStatuses: list<record>, publisherReviewStatuses: list<record>>, skipOffset: record<percentage: string, seconds: string>, skippable: bool, thirdPartyTag: string, thirdPartyUrls: table<type: string, url: string>, timerEvents: table<name: string, reportingName: string>, trackerUrls: list<string>, transcodes: table<audioBitRateKbps: string, audioSampleRateHz: string, bitRateKbps: string, dimensions: record, fileSizeBytes: string, frameRate: float, mimeType: string, name: string, transcoded: bool>, universalAdId: record<id: string, registry: string>, updateTime: string, vastTagUrl: string, vpaid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/creatives") $qp)
  let req_body = {"additionalDimensions": $additional_dimensions, "appendedTag": $appended_tag, "assets": $assets, "cmTrackingAd": $cm_tracking_ad, "companionCreativeIds": $companion_creative_ids, "counterEvents": $counter_events, "creativeType": $creative_type, "dimensions": $dimensions, "displayName": $display_name, "entityStatus": $entity_status, "exitEvents": $exit_events, "expandOnHover": $expand_on_hover, "expandingDirection": $expanding_direction, "hostingSource": $hosting_source, "iasCampaignMonitoring": $ias_campaign_monitoring, "integrationCode": $integration_code, "jsTrackerUrl": $js_tracker_url, "notes": $notes, "obaIcon": $oba_icon, "progressOffset": $progress_offset, "requireHtml5": $require_html5, "requireMraid": $require_mraid, "requirePingForAttribution": $require_ping_for_attribution, "reviewStatus": $review_status, "skipOffset": $skip_offset, "skippable": $skippable, "thirdPartyTag": $third_party_tag, "thirdPartyUrls": $third_party_urls, "timerEvents": $timer_events, "trackerUrls": $tracker_urls, "universalAdId": $universal_ad_id, "vastTagUrl": $vast_tag_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a creative. Returns error code `NOT_FOUND` if the creative does not exist. The creative should be archived first, i.e. set entity_status to `ENTITY_STATUS_ARCHIVED`, before it can be deleted.
#
# DELETE /v2/advertisers/{advertiserId}/creatives/{creativeId}
# operationId: displayvideo.advertisers.creatives.delete
export def "advertisers-creatives delete" [
  advertiser_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2/advertisers/{advertiser_id}/creatives/{creative_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a creative.
#
# GET /v2/advertisers/{advertiserId}/creatives/{creativeId}
# operationId: displayvideo.advertisers.creatives.get
export def "advertisers-creatives get" [
  advertiser_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<additionalDimensions: table<heightPixels: int, widthPixels: int>, advertiserId: string, appendedTag: string, assets: table<asset: record, role: string>, cmPlacementId: string, cmTrackingAd: record<cmAdId: string, cmCreativeId: string, cmPlacementId: string>, companionCreativeIds: list<string>, counterEvents: table<name: string, reportingName: string>, createTime: string, creativeAttributes: list<string>, creativeId: string, creativeType: string, dimensions: record<heightPixels: int, widthPixels: int>, displayName: string, dynamic: bool, entityStatus: string, exitEvents: table<name: string, reportingName: string, type: string, url: string>, expandOnHover: bool, expandingDirection: string, hostingSource: string, html5Video: bool, iasCampaignMonitoring: bool, integrationCode: string, jsTrackerUrl: string, lineItemIds: list<string>, mediaDuration: string, mp3Audio: bool, name: string, notes: string, obaIcon: record<clickTrackingUrl: string, dimensions: record<heightPixels: int, widthPixels: int>, landingPageUrl: string, position: string, program: string, resourceMimeType: string, resourceUrl: string, viewTrackingUrl: string>, oggAudio: bool, progressOffset: record<percentage: string, seconds: string>, requireHtml5: bool, requireMraid: bool, requirePingForAttribution: bool, reviewStatus: record<approvalStatus: string, contentAndPolicyReviewStatus: string, creativeAndLandingPageReviewStatus: string, exchangeReviewStatuses: list<record>, publisherReviewStatuses: list<record>>, skipOffset: record<percentage: string, seconds: string>, skippable: bool, thirdPartyTag: string, thirdPartyUrls: table<type: string, url: string>, timerEvents: table<name: string, reportingName: string>, trackerUrls: list<string>, transcodes: table<audioBitRateKbps: string, audioSampleRateHz: string, bitRateKbps: string, dimensions: record, fileSizeBytes: string, frameRate: float, mimeType: string, name: string, transcoded: bool>, universalAdId: record<id: string, registry: string>, updateTime: string, vastTagUrl: string, vpaid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2/advertisers/{advertiser_id}/creatives/{creative_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing creative. Returns the updated creative if successful.
#
# PATCH /v2/advertisers/{advertiserId}/creatives/{creativeId}
# operationId: displayvideo.advertisers.creatives.patch
# --additionalDimensions item shape: {heightPixels?: int, widthPixels?: int}
# --assets item shape: {asset?: record, role?: "ASSET_ROLE_UNSPECIFIED"|"ASSET_ROLE_MAIN"|"ASSET_ROLE_BACKUP"|"ASSET_ROLE_POLITE_LOAD"|"ASSET_ROLE_HEADLINE"|"ASSET_ROLE_LONG_HEADLINE"|"ASSET_ROLE_BODY"|"ASSET_ROLE_LONG_BODY"|"ASSET_ROLE_CAPTION_URL"|"ASSET_ROLE_CALL_TO_ACTION"|"ASSET_ROLE_ADVERTISER_NAME"|"ASSET_ROLE_PRICE"|"ASSET_ROLE_ANDROID_APP_ID"|"ASSET_ROLE_IOS_APP_ID"|"ASSET_ROLE_RATING"|"ASSET_ROLE_ICON"|"ASSET_ROLE_COVER_IMAGE"}
# --cmTrackingAd shape: {cmAdId?: string, cmCreativeId?: string, cmPlacementId?: string}
# --counterEvents item shape: {name?: string, reportingName?: string}
# --dimensions shape: {heightPixels?: int, widthPixels?: int}
# --exitEvents item shape: {name?: string, reportingName?: string, type?: "EXIT_EVENT_TYPE_UNSPECIFIED"|"EXIT_EVENT_TYPE_DEFAULT"|"EXIT_EVENT_TYPE_BACKUP", url?: string}
# --obaIcon shape: {clickTrackingUrl?: string, dimensions?: record, landingPageUrl?: string, position?: "OBA_ICON_POSITION_UNSPECIFIED"|"OBA_ICON_POSITION_UPPER_RIGHT"|"OBA_ICON_POSITION_UPPER_LEFT"|"OBA_ICON_POSITION_LOWER_RIGHT"|"OBA_ICON_POSITION_LOWER_LEFT", program?: string, resourceMimeType?: string, resourceUrl?: string, viewTrackingUrl?: string}
# --progressOffset shape: {percentage?: string, seconds?: string}
# --reviewStatus shape: {approvalStatus?: "APPROVAL_STATUS_UNSPECIFIED"|"APPROVAL_STATUS_PENDING_NOT_SERVABLE"|"APPROVAL_STATUS_PENDING_SERVABLE"|"APPROVAL_STATUS_APPROVED_SERVABLE"|"APPROVAL_STATUS_REJECTED_NOT_SERVABLE", contentAndPolicyReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", creativeAndLandingPageReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", ... (2 more fields)}
# --skipOffset shape: {percentage?: string, seconds?: string}
# --thirdPartyUrls item shape: {type?: "THIRD_PARTY_URL_TYPE_UNSPECIFIED"|"THIRD_PARTY_URL_TYPE_IMPRESSION"|"THIRD_PARTY_URL_TYPE_CLICK_TRACKING"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_START"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FIRST_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MIDPOINT"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_THIRD_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_COMPLETE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MUTE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PAUSE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_REWIND"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FULLSCREEN"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_STOP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_CUSTOM"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_SKIP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PROGRESS", ... (1 more fields)}
# --timerEvents item shape: {name?: string, reportingName?: string}
# --transcodes item shape: {audioBitRateKbps?: string, audioSampleRateHz?: string, bitRateKbps?: string, dimensions?: record, fileSizeBytes?: string, frameRate?: float, mimeType?: string, name?: string, transcoded?: bool}
# --universalAdId shape: {id?: string, registry?: "UNIVERSAL_AD_REGISTRY_UNSPECIFIED"|"UNIVERSAL_AD_REGISTRY_OTHER"|"UNIVERSAL_AD_REGISTRY_AD_ID"|"UNIVERSAL_AD_REGISTRY_CLEARCAST"|"UNIVERSAL_AD_REGISTRY_DV360"|"UNIVERSAL_AD_REGISTRY_CM"}
export def "advertisers-creatives update" [
  advertiser_id: string
  creative_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --additional-dimensions: list # Additional dimensions. Applicable when creative_type is one of: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE` * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_LIGHTBOX` * `CREATIVE_TYPE_PUBLISHER_HOSTED` If this field is specified, width_pixels and height_pixels are both required and must be greater than or equal to 0. — item shape: {heightPixels?: int, widthPixels?: int}
  --appended-tag: string # Third-party HTML tracking tag to be appended to the creative tag.
  --assets: list # Required. Assets associated to this creative. — item shape: {asset?: record, role?: "ASSET_ROLE_UNSPECIFIED"|"ASSET_ROLE_MAIN"|"ASSET_ROLE_BACKUP"|"ASSET_ROLE_POLITE_LOAD"|"ASSET_ROLE_HEADLINE"|"ASSET_ROLE_LONG_HEADLINE"|"ASSET_ROLE_BODY"|"ASSET_ROLE_LONG_BODY"|"ASSET_ROLE_CAPTION_URL"|"ASSET_ROLE_CALL_TO_ACTION"|"ASSET_ROLE_ADVERTISER_NAME"|"ASSET_ROLE_PRICE"|"ASSET_ROLE_ANDROID_APP_ID"|"ASSET_ROLE_IOS_APP_ID"|"ASSET_ROLE_RATING"|"ASSET_ROLE_ICON"|"ASSET_ROLE_COVER_IMAGE"}
  --cm-tracking-ad: record # A Campaign Manager 360 tracking ad. — shape: {cmAdId?: string, cmCreativeId?: string, cmPlacementId?: string}
  --companion-creative-ids: list<string> # The IDs of companion creatives for a video creative. You can assign existing display creatives (with image or HTML5 assets) to serve surrounding the publisher's video player. Companions display around the video player while the video is playing and remain after the video has completed. Creatives contain additional dimensions can not be companion creatives. This field is only supported for following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  --counter-events: list # Counter events for a rich media creative. Counters track the number of times that a user interacts with any part of a rich media creative in a specified way (mouse-overs, mouse-outs, clicks, taps, data loading, keyboard entries, etc.). Any event that can be captured in the creative can be recorded as a counter. Leave it empty or unset for creatives containing image assets only. — item shape: {name?: string, reportingName?: string}
  --creative-type: string@creative-type-completer # Required. Immutable. The type of the creative.
  --dimensions: record # Dimensions. — shape: {heightPixels?: int, widthPixels?: int}
  --display-name: string # Required. The display name of the creative. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the creative can serve. Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED` * `ENTITY_STATUS_PAUSED`
  --exit-events: list # Required. Exit events for this creative. An exit (also known as a click tag) is any area in your creative that someone can click or tap to open an advertiser's landing page. Every creative must include at least one exit. You can add an exit to your creative in any of the following ways: * Use Google Web Designer's tap area. * Define a JavaScript variable called "clickTag". * Use the Enabler (Enabler.exit()) to track exits in rich media formats. — item shape: {name?: string, reportingName?: string, type?: "EXIT_EVENT_TYPE_UNSPECIFIED"|"EXIT_EVENT_TYPE_DEFAULT"|"EXIT_EVENT_TYPE_BACKUP", url?: string}
  --expand-on-hover: oneof<nothing, bool> # Optional. Indicates the creative will automatically expand on hover. Optional and only valid for third-party expandable creatives. Third-party expandable creatives are creatives with following hosting source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_EXPANDABLE`
  --expanding-direction: string@expanding-direction-completer # Optional. Specifies the expanding direction of the creative. Required and only valid for third-party expandable creatives. Third-party expandable creatives are creatives with following hosting source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_EXPANDABLE`
  --hosting-source: string@hosting-source-completer # Required. Indicates where the creative is hosted.
  --ias-campaign-monitoring: oneof<nothing, bool> # Indicates whether Integral Ad Science (IAS) campaign monitoring is enabled. To enable this for the creative, make sure the Advertiser.creative_config.ias_client_id has been set to your IAS client ID.
  --integration-code: string # ID information used to link this creative to an external system. Must be UTF-8 encoded with a length of no more than 10,000 characters.
  --js-tracker-url: string # JavaScript measurement URL from supported third-party verification providers (ComScore, DoubleVerify, IAS, Moat). HTML script tags are not supported. This field is only writeable in following creative_type: * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  --notes: string # User notes for this creative. Must be UTF-8 encoded with a length of no more than 20,000 characters.
  --oba-icon: record # OBA Icon for a Creative — shape: {clickTrackingUrl?: string, dimensions?: record, landingPageUrl?: string, position?: "OBA_ICON_POSITION_UNSPECIFIED"|"OBA_ICON_POSITION_UPPER_RIGHT"|"OBA_ICON_POSITION_UPPER_LEFT"|"OBA_ICON_POSITION_LOWER_RIGHT"|"OBA_ICON_POSITION_LOWER_LEFT", program?: string, resourceMimeType?: string, resourceUrl?: string, viewTrackingUrl?: string}
  --progress-offset: record # The length an audio or a video has been played. — shape: {percentage?: string, seconds?: string}
  --require-html5: oneof<nothing, bool> # Optional. Indicates that the creative relies on HTML5 to render properly. Optional and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --require-mraid: oneof<nothing, bool> # Optional. Indicates that the creative requires MRAID (Mobile Rich Media Ad Interface Definitions system). Set this if the creative relies on mobile gestures for interactivity, such as swiping or tapping. Optional and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --require-ping-for-attribution: oneof<nothing, bool> # Optional. Indicates that the creative will wait for a return ping for attribution. Only valid when using a Campaign Manager 360 tracking ad with a third-party ad server parameter and the ${DC_DBM_TOKEN} macro. Optional and only valid for third-party tag creatives or third-party VAST tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE` Third-party VAST tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
  --review-status: record # Review statuses for the creative. — shape: {approvalStatus?: "APPROVAL_STATUS_UNSPECIFIED"|"APPROVAL_STATUS_PENDING_NOT_SERVABLE"|"APPROVAL_STATUS_PENDING_SERVABLE"|"APPROVAL_STATUS_APPROVED_SERVABLE"|"APPROVAL_STATUS_REJECTED_NOT_SERVABLE", contentAndPolicyReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", creativeAndLandingPageReviewStatus?: "REVIEW_STATUS_UNSPECIFIED"|"REVIEW_STATUS_APPROVED"|"REVIEW_STATUS_REJECTED"|"REVIEW_STATUS_PENDING", ... (2 more fields)}
  --skip-offset: record # The length an audio or a video has been played. — shape: {percentage?: string, seconds?: string}
  --skippable: oneof<nothing, bool> # Whether the user can choose to skip a video creative. This field is only supported for the following creative_type: * `CREATIVE_TYPE_VIDEO`
  --third-party-tag: string # Optional. The original third-party tag used for the creative. Required and only valid for third-party tag creatives. Third-party tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_STANDARD` * `CREATIVE_TYPE_EXPANDABLE`
  --third-party-urls: list # Tracking URLs from third parties to track interactions with a video creative. This field is only supported for the following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO` * `CREATIVE_TYPE_NATIVE_VIDEO` — item shape: {type?: "THIRD_PARTY_URL_TYPE_UNSPECIFIED"|"THIRD_PARTY_URL_TYPE_IMPRESSION"|"THIRD_PARTY_URL_TYPE_CLICK_TRACKING"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_START"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FIRST_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MIDPOINT"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_THIRD_QUARTILE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_COMPLETE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_MUTE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PAUSE"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_REWIND"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_FULLSCREEN"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_STOP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_CUSTOM"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_SKIP"|"THIRD_PARTY_URL_TYPE_AUDIO_VIDEO_PROGRESS", ... (1 more fields)}
  --timer-events: list # Timer custom events for a rich media creative. Timers track the time during which a user views and interacts with a specified part of a rich media creative. A creative can have multiple timer events, each timed independently. Leave it empty or unset for creatives containing image assets only. — item shape: {name?: string, reportingName?: string}
  --tracker-urls: list<string> # Tracking URLs for analytics providers or third-party ad technology vendors. The URLs must start with https (except on inventory that doesn't require SSL compliance). If using macros in your URL, use only macros supported by Display & Video 360. Standard URLs only, no IMG or SCRIPT tags. This field is only writeable in following creative_type: * `CREATIVE_TYPE_NATIVE` * `CREATIVE_TYPE_NATIVE_SITE_SQUARE` * `CREATIVE_TYPE_NATIVE_VIDEO`
  --universal-ad-id: record # A creative identifier provided by a registry that is unique across all platforms. This is part of the VAST 4.0 standard. — shape: {id?: string, registry?: "UNIVERSAL_AD_REGISTRY_UNSPECIFIED"|"UNIVERSAL_AD_REGISTRY_OTHER"|"UNIVERSAL_AD_REGISTRY_AD_ID"|"UNIVERSAL_AD_REGISTRY_CLEARCAST"|"UNIVERSAL_AD_REGISTRY_DV360"|"UNIVERSAL_AD_REGISTRY_CM"}
  --vast-tag-url: string # Optional. The URL of the VAST tag for a third-party VAST tag creative. Required and only valid for third-party VAST tag creatives. Third-party VAST tag creatives are creatives with following hosting_source: * `HOSTING_SOURCE_THIRD_PARTY` combined with following creative_type: * `CREATIVE_TYPE_AUDIO` * `CREATIVE_TYPE_VIDEO`
]: any -> record<additionalDimensions: table<heightPixels: int, widthPixels: int>, advertiserId: string, appendedTag: string, assets: table<asset: record, role: string>, cmPlacementId: string, cmTrackingAd: record<cmAdId: string, cmCreativeId: string, cmPlacementId: string>, companionCreativeIds: list<string>, counterEvents: table<name: string, reportingName: string>, createTime: string, creativeAttributes: list<string>, creativeId: string, creativeType: string, dimensions: record<heightPixels: int, widthPixels: int>, displayName: string, dynamic: bool, entityStatus: string, exitEvents: table<name: string, reportingName: string, type: string, url: string>, expandOnHover: bool, expandingDirection: string, hostingSource: string, html5Video: bool, iasCampaignMonitoring: bool, integrationCode: string, jsTrackerUrl: string, lineItemIds: list<string>, mediaDuration: string, mp3Audio: bool, name: string, notes: string, obaIcon: record<clickTrackingUrl: string, dimensions: record<heightPixels: int, widthPixels: int>, landingPageUrl: string, position: string, program: string, resourceMimeType: string, resourceUrl: string, viewTrackingUrl: string>, oggAudio: bool, progressOffset: record<percentage: string, seconds: string>, requireHtml5: bool, requireMraid: bool, requirePingForAttribution: bool, reviewStatus: record<approvalStatus: string, contentAndPolicyReviewStatus: string, creativeAndLandingPageReviewStatus: string, exchangeReviewStatuses: list<record>, publisherReviewStatuses: list<record>>, skipOffset: record<percentage: string, seconds: string>, skippable: bool, thirdPartyTag: string, thirdPartyUrls: table<type: string, url: string>, timerEvents: table<name: string, reportingName: string>, trackerUrls: list<string>, transcodes: table<audioBitRateKbps: string, audioSampleRateHz: string, bitRateKbps: string, dimensions: record, fileSizeBytes: string, frameRate: float, mimeType: string, name: string, transcoded: bool>, universalAdId: record<id: string, registry: string>, updateTime: string, vastTagUrl: string, vpaid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), creative_id: (encode-path-segment $creative_id)} | format pattern "/v2/advertisers/{advertiser_id}/creatives/{creative_id}") $qp)
  let req_body = {"additionalDimensions": $additional_dimensions, "appendedTag": $appended_tag, "assets": $assets, "cmTrackingAd": $cm_tracking_ad, "companionCreativeIds": $companion_creative_ids, "counterEvents": $counter_events, "creativeType": $creative_type, "dimensions": $dimensions, "displayName": $display_name, "entityStatus": $entity_status, "exitEvents": $exit_events, "expandOnHover": $expand_on_hover, "expandingDirection": $expanding_direction, "hostingSource": $hosting_source, "iasCampaignMonitoring": $ias_campaign_monitoring, "integrationCode": $integration_code, "jsTrackerUrl": $js_tracker_url, "notes": $notes, "obaIcon": $oba_icon, "progressOffset": $progress_offset, "requireHtml5": $require_html5, "requireMraid": $require_mraid, "requirePingForAttribution": $require_ping_for_attribution, "reviewStatus": $review_status, "skipOffset": $skip_offset, "skippable": $skippable, "thirdPartyTag": $third_party_tag, "thirdPartyUrls": $third_party_urls, "timerEvents": $timer_events, "trackerUrls": $tracker_urls, "universalAdId": $universal_ad_id, "vastTagUrl": $vast_tag_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists insertion orders in an advertiser. The order is defined by the order_by parameter. If a filter by entity_status is not specified, insertion orders with `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/advertisers/{advertiserId}/insertionOrders
# operationId: displayvideo.advertisers.insertionOrders.list
export def "advertisers-insertion-orders list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by insertion order properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator used on `budget.budget_segments.date_range.end_date` must be LESS THAN (<). * The operator used on `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The operators used on all other fields must be `EQUALS (=)`. * Supported fields: - `campaignId` - `displayName` - `entityStatus` - `budget.budget_segments.date_range.end_date` (input as YYYY-MM-DD) - `updateTime` (input in ISO 8601 format, or YYYY-MM-DDTHH:MM:SSZ) Examples: * All insertion orders under a campaign: `campaignId="1234"` * All `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED` insertion orders under an advertiser: `(entityStatus="ENTITY_STATUS_ACTIVE" OR entityStatus="ENTITY_STATUS_PAUSED")` * All insertion orders whose budget segments' dates end before March 28, 2019: `budget.budget_segments.date_range.end_date<"2019-03-28"` * All insertion orders with an update time less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All insertion orders with an update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime>="2020-11-04T18:54:47Z"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * "displayName" (default) * "entityStatus" * "updateTime" The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `100`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListInsertionOrders` method. If not specified, the first page of results will be returned.
]: nothing -> record<insertionOrders: table<advertiserId: string, bidStrategy: record, billableOutcome: string, budget: record, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record, insertionOrderId: string, insertionOrderType: string, integrationDetails: record, name: string, pacing: record, partnerCosts: list, performanceGoal: record, reservationType: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new insertion order. Returns the newly created insertion order if successful.
#
# POST /v2/advertisers/{advertiserId}/insertionOrders
# operationId: displayvideo.advertisers.insertionOrders.create
# --bidStrategy shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
# --budget shape: {automationType?: "INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED"|"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"|"INSERTION_ORDER_AUTOMATION_TYPE_NONE"|"INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET", budgetSegments?: list, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS"}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --pacing shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
# --partnerCosts item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
# --performanceGoal shape: {performanceGoalAmountMicros?: string, performanceGoalPercentageMicros?: string, performanceGoalString?: string, ... (1 more fields)}
export def "advertisers-insertion-orders create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --bid-strategy: record # Settings that control the bid strategy. Bid strategy determines the bid price. — shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
  --billable-outcome: string@billable-outcome-completer # Immutable. The billable outcome of the insertion order.
  --budget: record # Settings that control how insertion order budget is allocated. — shape: {automationType?: "INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED"|"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"|"INSERTION_ORDER_AUTOMATION_TYPE_NONE"|"INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET", budgetSegments?: list, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS"}
  --campaign-id: string # Required. Immutable. The unique ID of the campaign that the insertion order belongs to. (format: int64)
  --display-name: string # Required. The display name of the insertion order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the insertion order can spend its budget and bid on inventory. * For CreateInsertionOrder method, only `ENTITY_STATUS_DRAFT` is allowed. To activate an insertion order, use UpdateInsertionOrder method and update the status to `ENTITY_STATUS_ACTIVE` after creation. * An insertion order cannot be changed back to `ENTITY_STATUS_DRAFT` status from any other status. * An insertion order cannot be set to `ENTITY_STATUS_ACTIVE` if its parent campaign is not active.
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
  --insertion-order-type: string@insertion-order-type-completer # The type of insertion order. If this field is unspecified in creation, the value defaults to `RTB`.
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --pacing: record # Settings that control the rate at which a budget is spent. — shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
  --partner-costs: list # The partner costs associated with the insertion order. If absent or empty in CreateInsertionOrder method, the newly created insertion order will inherit partner costs from the partner settings. — item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
  --performance-goal: record # Settings that control the performance goal of a campaign or insertion order. — shape: {performanceGoalAmountMicros?: string, performanceGoalPercentageMicros?: string, performanceGoalString?: string, ... (1 more fields)}
]: any -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, billableOutcome: string, budget: record<automationType: string, budgetSegments: list<record>, budgetUnit: string>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, insertionOrderType: string, integrationDetails: record<details: string, integrationCode: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>, reservationType: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders") $qp)
  let req_body = {"bidStrategy": $bid_strategy, "billableOutcome": $billable_outcome, "budget": $budget, "campaignId": $campaign_id, "displayName": $display_name, "entityStatus": $entity_status, "frequencyCap": $frequency_cap, "insertionOrderType": $insertion_order_type, "integrationDetails": $integration_details, "pacing": $pacing, "partnerCosts": $partner_costs, "performanceGoal": $performance_goal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an insertion order. Returns error code `NOT_FOUND` if the insertion order does not exist. The insertion order should be archived first, i.e. set entity_status to `ENTITY_STATUS_ARCHIVED`, to be able to delete it.
#
# DELETE /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}
# operationId: displayvideo.advertisers.insertionOrders.delete
export def "advertisers-insertion-orders delete" [
  advertiser_id: string
  insertion_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an insertion order. Returns error code `NOT_FOUND` if the insertion order does not exist.
#
# GET /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}
# operationId: displayvideo.advertisers.insertionOrders.get
export def "advertisers-insertion-orders get" [
  advertiser_id: string
  insertion_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, billableOutcome: string, budget: record<automationType: string, budgetSegments: list<record>, budgetUnit: string>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, insertionOrderType: string, integrationDetails: record<details: string, integrationCode: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>, reservationType: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing insertion order. Returns the updated insertion order if successful.
#
# PATCH /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}
# operationId: displayvideo.advertisers.insertionOrders.patch
# --bidStrategy shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
# --budget shape: {automationType?: "INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED"|"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"|"INSERTION_ORDER_AUTOMATION_TYPE_NONE"|"INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET", budgetSegments?: list, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS"}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --pacing shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
# --partnerCosts item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
# --performanceGoal shape: {performanceGoalAmountMicros?: string, performanceGoalPercentageMicros?: string, performanceGoalString?: string, ... (1 more fields)}
export def "advertisers-insertion-orders update" [
  advertiser_id: string
  insertion_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --bid-strategy: record # Settings that control the bid strategy. Bid strategy determines the bid price. — shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
  --billable-outcome: string@billable-outcome-completer # Immutable. The billable outcome of the insertion order.
  --budget: record # Settings that control how insertion order budget is allocated. — shape: {automationType?: "INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED"|"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"|"INSERTION_ORDER_AUTOMATION_TYPE_NONE"|"INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET", budgetSegments?: list, budgetUnit?: "BUDGET_UNIT_UNSPECIFIED"|"BUDGET_UNIT_CURRENCY"|"BUDGET_UNIT_IMPRESSIONS"}
  --campaign-id: string # Required. Immutable. The unique ID of the campaign that the insertion order belongs to. (format: int64)
  --display-name: string # Required. The display name of the insertion order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the insertion order can spend its budget and bid on inventory. * For CreateInsertionOrder method, only `ENTITY_STATUS_DRAFT` is allowed. To activate an insertion order, use UpdateInsertionOrder method and update the status to `ENTITY_STATUS_ACTIVE` after creation. * An insertion order cannot be changed back to `ENTITY_STATUS_DRAFT` status from any other status. * An insertion order cannot be set to `ENTITY_STATUS_ACTIVE` if its parent campaign is not active.
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
  --insertion-order-type: string@insertion-order-type-completer # The type of insertion order. If this field is unspecified in creation, the value defaults to `RTB`.
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --pacing: record # Settings that control the rate at which a budget is spent. — shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
  --partner-costs: list # The partner costs associated with the insertion order. If absent or empty in CreateInsertionOrder method, the newly created insertion order will inherit partner costs from the partner settings. — item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
  --performance-goal: record # Settings that control the performance goal of a campaign or insertion order. — shape: {performanceGoalAmountMicros?: string, performanceGoalPercentageMicros?: string, performanceGoalString?: string, ... (1 more fields)}
]: any -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, billableOutcome: string, budget: record<automationType: string, budgetSegments: list<record>, budgetUnit: string>, campaignId: string, displayName: string, entityStatus: string, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, insertionOrderType: string, integrationDetails: record<details: string, integrationCode: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, performanceGoal: record<performanceGoalAmountMicros: string, performanceGoalPercentageMicros: string, performanceGoalString: string, performanceGoalType: string>, reservationType: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}") $qp)
  let req_body = {"bidStrategy": $bid_strategy, "billableOutcome": $billable_outcome, "budget": $budget, "campaignId": $campaign_id, "displayName": $display_name, "entityStatus": $entity_status, "frequencyCap": $frequency_cap, "insertionOrderType": $insertion_order_type, "integrationDetails": $integration_details, "pacing": $pacing, "partnerCosts": $partner_costs, "performanceGoal": $performance_goal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the targeting options assigned to an insertion order.
#
# GET /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.insertionOrders.targetingTypes.assignedTargetingOptions.list
export def "advertisers-insertion-orders-targeting-types-assigned-targeting-options list" [
  advertiser_id: string
  insertion_order_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` - `inheritance` Examples: * AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `5000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListInsertionOrderAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns a targeting option to an insertion order. Returns the assigned targeting option if successful. Supported targeting types: * `TARGETING_TYPE_AGE_RANGE` * `TARGETING_TYPE_BROWSER` * `TARGETING_TYPE_CATEGORY` * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_DEVICE_MAKE_MODEL` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_KEYWORD` * `TARGETING_TYPE_LANGUAGE` * `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST` * `TARGETING_TYPE_OPERATING_SYSTEM` * `TARGETING_TYPE_PARENTAL_STATUS` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` * `TARGETING_TYPE_VIEWABILITY`
#
# POST /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.insertionOrders.targetingTypes.assignedTargetingOptions.create
# --ageRangeDetails shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
# --appCategoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --appDetails shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
# --audienceGroupDetails shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
# --audioContentTypeDetails shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
# --authorizedSellerStatusDetails shape: {targetingOptionId?: string}
# --browserDetails shape: {negative?: bool, targetingOptionId?: string}
# --businessChainDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --carrierAndIspDetails shape: {negative?: bool, targetingOptionId?: string}
# --categoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --channelDetails shape: {channelId?: string, negative?: bool}
# --contentDurationDetails shape: {targetingOptionId?: string}
# --contentGenreDetails shape: {negative?: bool, targetingOptionId?: string}
# --contentInstreamPositionDetails shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
# --contentOutstreamPositionDetails shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
# --contentStreamTypeDetails shape: {targetingOptionId?: string}
# --dayAndTimeDetails shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
# --deviceMakeModelDetails shape: {negative?: bool, targetingOptionId?: string}
# --deviceTypeDetails shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
# --digitalContentLabelExclusionDetails shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
# --environmentDetails shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
# --exchangeDetails shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
# --genderDetails shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
# --geoRegionDetails shape: {negative?: bool, targetingOptionId?: string}
# --householdIncomeDetails shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
# --inventorySourceDetails shape: {inventorySourceId?: string}
# --inventorySourceGroupDetails shape: {inventorySourceGroupId?: string}
# --keywordDetails shape: {keyword?: string, negative?: bool}
# --languageDetails shape: {negative?: bool, targetingOptionId?: string}
# --nativeContentPositionDetails shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
# --negativeKeywordListDetails shape: {negativeKeywordListId?: string}
# --omidDetails shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
# --onScreenPositionDetails shape: {targetingOptionId?: string}
# --operatingSystemDetails shape: {negative?: bool, targetingOptionId?: string}
# --parentalStatusDetails shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
# --poiDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --proximityLocationListDetails shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
# --regionalLocationListDetails shape: {negative?: bool, regionalLocationListId?: string}
# --sensitiveCategoryExclusionDetails shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
# --sessionPositionDetails shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
# --subExchangeDetails shape: {targetingOptionId?: string}
# --thirdPartyVerifierDetails shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
# --urlDetails shape: {negative?: bool, url?: string}
# --userRewardedContentDetails shape: {targetingOptionId?: string}
# --videoPlayerSizeDetails shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
# --viewabilityDetails shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
# --youtubeChannelDetails shape: {channelId?: string, negative?: bool}
# --youtubeVideoDetails shape: {negative?: bool, videoId?: string}
export def "advertisers-insertion-orders-targeting-types-assigned-targeting-options create" [
  advertiser_id: string
  insertion_order_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --age-range-details: record # Represents a targetable age range. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AGE_RANGE`. — shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
  --app-category-details: record # Details for assigned app category targeting option. This will be populated in the app_category_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --app-details: record # Details for assigned app targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP`. — shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
  --audience-group-details: record # Assigned audience group targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUDIENCE_GROUP`. The relation between each group is UNION, except for excluded_first_and_third_party_audience_group and excluded_google_audience_group, of which COMPLEMENT is used as an INTERSECTION with other groups. — shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
  --audio-content-type-details: record # Details for audio content type assigned targeting option. This will be populated in the audio_content_type_details field when targeting_type is `TARGETING_TYPE_AUDIO_CONTENT_TYPE`. Explicitly targeting all options is not supported. Remove all audio content type targeting options to achieve this effect. — shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
  --authorized-seller-status-details: record # Represents an assigned authorized seller status. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`. — shape: {targetingOptionId?: string}
  --browser-details: record # Details for assigned browser targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BROWSER`. — shape: {negative?: bool, targetingOptionId?: string}
  --business-chain-details: record # Details for assigned Business chain targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BUSINESS_CHAIN`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --carrier-and-isp-details: record # Details for assigned carrier and ISP targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`. — shape: {negative?: bool, targetingOptionId?: string}
  --category-details: record # Assigned category targeting option details. This will be populated in the category_details field when targeting_type is `TARGETING_TYPE_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --channel-details: record # Details for assigned channel targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --content-duration-details: record # Details for content duration assigned targeting option. This will be populated in the content_duration_details field when targeting_type is `TARGETING_TYPE_CONTENT_DURATION`. Explicitly targeting all options is not supported. Remove all content duration targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --content-genre-details: record # Details for content genre assigned targeting option. This will be populated in the content_genre_details field when targeting_type is `TARGETING_TYPE_CONTENT_GENRE`. Explicitly targeting all options is not supported. Remove all content genre targeting options to achieve this effect. — shape: {negative?: bool, targetingOptionId?: string}
  --content-instream-position-details: record # Assigned content instream position targeting option details. This will be populated in the content_instream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`. — shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
  --content-outstream-position-details: record # Assigned content outstream position targeting option details. This will be populated in the content_outstream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`. — shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
  --content-stream-type-details: record # Details for content stream type assigned targeting option. This will be populated in the content_stream_type_details field when targeting_type is `TARGETING_TYPE_CONTENT_STREAM_TYPE`. Explicitly targeting all options is not supported. Remove all content stream type targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --day-and-time-details: record # Representation of a segment of time defined on a specific day of the week and with a start and end time. The time represented by `start_hour` must be before the time represented by `end_hour`. — shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
  --device-make-model-details: record # Assigned device make and model targeting option details. This will be populated in the device_make_model_details field when targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`. — shape: {negative?: bool, targetingOptionId?: string}
  --device-type-details: record # Targeting details for device type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`. — shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
  --digital-content-label-exclusion-details: record # Targeting details for digital content label. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`. — shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
  --environment-details: record # Assigned environment targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_ENVIRONMENT`. — shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
  --exchange-details: record # Details for assigned exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_EXCHANGE`. — shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
  --gender-details: record # Details for assigned gender targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GENDER`. — shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
  --geo-region-details: record # Details for assigned geographic region targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GEO_REGION`. — shape: {negative?: bool, targetingOptionId?: string}
  --household-income-details: record # Details for assigned household income targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`. — shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
  --inventory-source-details: record # Targeting details for inventory source. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE`. — shape: {inventorySourceId?: string}
  --inventory-source-group-details: record # Targeting details for inventory source group. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`. — shape: {inventorySourceGroupId?: string}
  --keyword-details: record # Details for assigned keyword targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_KEYWORD`. — shape: {keyword?: string, negative?: bool}
  --language-details: record # Details for assigned language targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_LANGUAGE`. — shape: {negative?: bool, targetingOptionId?: string}
  --native-content-position-details: record # Details for native content position assigned targeting option. This will be populated in the native_content_position_details field when targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`. Explicitly targeting all options is not supported. Remove all native content position targeting options to achieve this effect. — shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
  --negative-keyword-list-details: record # Targeting details for negative keyword list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`. — shape: {negativeKeywordListId?: string}
  --omid-details: record # Represents a targetable Open Measurement enabled inventory type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_OMID`. — shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
  --on-screen-position-details: record # On screen position targeting option details. This will be populated in the on_screen_position_details field when targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`. — shape: {targetingOptionId?: string}
  --operating-system-details: record # Assigned operating system targeting option details. This will be populated in the operating_system_details field when targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`. — shape: {negative?: bool, targetingOptionId?: string}
  --parental-status-details: record # Details for assigned parental status targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PARENTAL_STATUS`. — shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
  --poi-details: record # Details for assigned POI targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_POI`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --proximity-location-list-details: record # Targeting details for proximity location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`. — shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
  --regional-location-list-details: record # Targeting details for regional location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_REGIONAL_LOCATION_LIST`. — shape: {negative?: bool, regionalLocationListId?: string}
  --sensitive-category-exclusion-details: record # Targeting details for sensitive category. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`. — shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
  --session-position-details: record # Details for session position assigned targeting option. This will be populated in the session_position_details field when targeting_type is `TARGETING_TYPE_SESSION_POSITION`. — shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
  --sub-exchange-details: record # Details for assigned sub-exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`. — shape: {targetingOptionId?: string}
  --third-party-verifier-details: record # Assigned third party verifier targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_THIRD_PARTY_VERIFIER`. — shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
  --url-details: record # Details for assigned URL targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_URL`. — shape: {negative?: bool, url?: string}
  --user-rewarded-content-details: record # User rewarded content targeting option details. This will be populated in the user_rewarded_content_details field when targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`. — shape: {targetingOptionId?: string}
  --video-player-size-details: record # Video player size targeting option details. This will be populated in the video_player_size_details field when targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`. Explicitly targeting all options is not supported. Remove all video player size targeting options to achieve this effect. — shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
  --viewability-details: record # Assigned viewability targeting option details. This will be populated in the viewability_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_VIEWABILITY`. — shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
  --youtube-channel-details: record # Details for YouTube channel assigned targeting option. This will be populated in the youtube_channel_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --youtube-video-details: record # Details for YouTube video assigned targeting option. This will be populated in the youtube_video_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_VIDEO`. — shape: {negative?: bool, videoId?: string}
]: any -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let req_body = {"ageRangeDetails": $age_range_details, "appCategoryDetails": $app_category_details, "appDetails": $app_details, "audienceGroupDetails": $audience_group_details, "audioContentTypeDetails": $audio_content_type_details, "authorizedSellerStatusDetails": $authorized_seller_status_details, "browserDetails": $browser_details, "businessChainDetails": $business_chain_details, "carrierAndIspDetails": $carrier_and_isp_details, "categoryDetails": $category_details, "channelDetails": $channel_details, "contentDurationDetails": $content_duration_details, "contentGenreDetails": $content_genre_details, "contentInstreamPositionDetails": $content_instream_position_details, "contentOutstreamPositionDetails": $content_outstream_position_details, "contentStreamTypeDetails": $content_stream_type_details, "dayAndTimeDetails": $day_and_time_details, "deviceMakeModelDetails": $device_make_model_details, "deviceTypeDetails": $device_type_details, "digitalContentLabelExclusionDetails": $digital_content_label_exclusion_details, "environmentDetails": $environment_details, "exchangeDetails": $exchange_details, "genderDetails": $gender_details, "geoRegionDetails": $geo_region_details, "householdIncomeDetails": $household_income_details, "inventorySourceDetails": $inventory_source_details, "inventorySourceGroupDetails": $inventory_source_group_details, "keywordDetails": $keyword_details, "languageDetails": $language_details, "nativeContentPositionDetails": $native_content_position_details, "negativeKeywordListDetails": $negative_keyword_list_details, "omidDetails": $omid_details, "onScreenPositionDetails": $on_screen_position_details, "operatingSystemDetails": $operating_system_details, "parentalStatusDetails": $parental_status_details, "poiDetails": $poi_details, "proximityLocationListDetails": $proximity_location_list_details, "regionalLocationListDetails": $regional_location_list_details, "sensitiveCategoryExclusionDetails": $sensitive_category_exclusion_details, "sessionPositionDetails": $session_position_details, "subExchangeDetails": $sub_exchange_details, "thirdPartyVerifierDetails": $third_party_verifier_details, "urlDetails": $url_details, "userRewardedContentDetails": $user_rewarded_content_details, "videoPlayerSizeDetails": $video_player_size_details, "viewabilityDetails": $viewability_details, "youtubeChannelDetails": $youtube_channel_details, "youtubeVideoDetails": $youtube_video_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an assigned targeting option from an insertion order. Supported targeting types: * `TARGETING_TYPE_AGE_RANGE` * `TARGETING_TYPE_BROWSER` * `TARGETING_TYPE_CATEGORY` * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_DEVICE_MAKE_MODEL` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_KEYWORD` * `TARGETING_TYPE_LANGUAGE` * `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST` * `TARGETING_TYPE_OPERATING_SYSTEM` * `TARGETING_TYPE_PARENTAL_STATUS` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` * `TARGETING_TYPE_VIEWABILITY`
#
# DELETE /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.insertionOrders.targetingTypes.assignedTargetingOptions.delete
export def "advertisers-insertion-orders-targeting-types-assigned-targeting-options delete" [
  advertiser_id: string
  insertion_order_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to an insertion order.
#
# GET /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.insertionOrders.targetingTypes.assignedTargetingOptions.get
export def "advertisers-insertion-orders-targeting-types-assigned-targeting-options get" [
  advertiser_id: string
  insertion_order_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists assigned targeting options of an insertion order across targeting types.
#
# GET /v2/advertisers/{advertiserId}/insertionOrders/{insertionOrderId}:listAssignedTargetingOptions
# operationId: displayvideo.advertisers.insertionOrders.listAssignedTargetingOptions
export def "advertisers-insertion-orders list-assigned-targeting-options" [
  advertiser_id: string
  insertion_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR` on the same field. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of targeting type TARGETING_TYPE_PROXIMITY_LOCATION_LIST or TARGETING_TYPE_CHANNEL `targetingType="TARGETING_TYPE_PROXIMITY_LOCATION_LIST" OR targetingType="TARGETING_TYPE_CHANNEL"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `targetingType` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingType desc`.
  --page-size: int # Requested page size. The size must be an integer between `1` and `5000`. If unspecified, the default is `5000`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token that lets the client fetch the next page of results. Typically, this is the value of next_page_token returned from the previous call to `BulkListInsertionOrderAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), insertion_order_id: (encode-path-segment $insertion_order_id)} | format pattern "/v2/advertisers/{advertiser_id}/insertionOrders/{insertion_order_id}:listAssignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists invoices posted for an advertiser in a given month. Invoices generated by billing profiles with a "Partner" invoice level are not retrievable through this method.
#
# GET /v2/advertisers/{advertiserId}/invoices
# operationId: displayvideo.advertisers.invoices.list
export def "advertisers-invoices list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --issue-month: string # The month to list the invoices for. If not set, the request will retrieve invoices for the previous month. Must be in the format YYYYMM.
  --loi-sapin-invoice-type: string@loi-sapin-invoice-type-completer # Select type of invoice to retrieve for Loi Sapin advertisers. Only applicable to Loi Sapin advertisers. Will be ignored otherwise.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListInvoices` method. If not specified, the first page of results will be returned.
]: nothing -> record<invoices: table<budgetInvoiceGroupingId: string, budgetSummaries: list, correctedInvoiceId: string, currencyCode: string, displayName: string, dueDate: record, invoiceId: string, invoiceType: string, issueDate: record, name: string, nonBudgetMicros: string, paymentsAccountId: string, paymentsProfileId: string, pdfUrl: string, purchaseOrderNumber: string, replacedInvoiceIds: list, serviceDateRange: record, subtotalAmountMicros: string, totalAmountMicros: string, totalTaxAmountMicros: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "issueMonth" $issue_month "scalar") (serialize-qp "loiSapinInvoiceType" $loi_sapin_invoice_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the invoice currency used by an advertiser in a given month.
#
# GET /v2/advertisers/{advertiserId}/invoices:lookupInvoiceCurrency
# operationId: displayvideo.advertisers.invoices.lookupInvoiceCurrency
export def "advertisers-invoices-lookup-invoice-currency get" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --invoice-month: string # Month for which the currency is needed. If not set, the request will return existing currency settings for the advertiser. Must be in the format YYYYMM.
]: nothing -> record<currencyCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "invoiceMonth" $invoice_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/invoices:lookupInvoiceCurrency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists line items in an advertiser. The order is defined by the order_by parameter. If a filter by entity_status is not specified, line items with `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/advertisers/{advertiserId}/lineItems
# operationId: displayvideo.advertisers.lineItems.list
export def "advertisers-line-items list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by line item properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator used on `flight.dateRange.endDate` must be LESS THAN (<). * The operator used on `updateTime` must be `GREATER THAN OR EQUAL TO (>=)` or `LESS THAN OR EQUAL TO (<=)`. * The operator used on `warningMessages` must be `HAS (:)`. * The operators used on all other fields must be `EQUALS (=)`. * Supported properties: - `campaignId` - `displayName` - `insertionOrderId` - `entityStatus` - `lineItemId` - `lineItemType` - `flight.dateRange.endDate` (input formatted as YYYY-MM-DD) - `warningMessages` - `flight.triggerId` - `updateTime` (input in ISO 8601 format, or YYYY-MM-DDTHH:MM:SSZ) - `targetedChannelId` - `targetedNegativeKeywordListId` Examples: * All line items under an insertion order: `insertionOrderId="1234"` * All `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED` and `LINE_ITEM_TYPE_DISPLAY_DEFAULT` line items under an advertiser: `(entityStatus="ENTITY_STATUS_ACTIVE" OR entityStatus="ENTITY_STATUS_PAUSED") AND lineItemType="LINE_ITEM_TYPE_DISPLAY_DEFAULT"` * All line items whose flight dates end before March 28, 2019: `flight.dateRange.endDate<"2019-03-28"` * All line items that have `NO_VALID_CREATIVE` in `warningMessages`: `warningMessages:"NO_VALID_CREATIVE"` * All line items with an update time less than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime<="2020-11-04T18:54:47Z"` * All line items with an update time greater than or equal to `2020-11-04T18:54:47Z (format of ISO 8601)`: `updateTime>="2020-11-04T18:54:47Z"` * All line items that are using both the specified channel and specified negative keyword list in their targeting: `targetedNegativeKeywordListId=789 AND targetedChannelId=12345` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `entityStatus` * `flight.dateRange.endDate` * `updateTime` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListLineItems` method. If not specified, the first page of results will be returned.
]: nothing -> record<lineItems: table<advertiserId: string, bidStrategy: record, budget: record, campaignId: string, conversionCounting: record, creativeIds: list, displayName: string, entityStatus: string, excludeNewExchanges: bool, flight: record, frequencyCap: record, insertionOrderId: string, integrationDetails: record, lineItemId: string, lineItemType: string, mobileApp: record, name: string, pacing: record, partnerCosts: list, partnerRevenueModel: record, reservationType: string, targetingExpansion: record, updateTime: string, warningMessages: list, youtubeAndPartnersSettings: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new line item. Returns the newly created line item if successful.
#
# POST /v2/advertisers/{advertiserId}/lineItems
# operationId: displayvideo.advertisers.lineItems.create
# --bidStrategy shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
# --budget shape: {budgetAllocationType?: "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNSPECIFIED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED", maxAmount?: string}
# --conversionCounting shape: {floodlightActivityConfigs?: list, postViewCountPercentageMillis?: string}
# --flight shape: {dateRange?: record, flightDateType?: "LINE_ITEM_FLIGHT_DATE_TYPE_UNSPECIFIED"|"LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED"|"LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM"}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --mobileApp shape: {appId?: string}
# --pacing shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
# --partnerCosts item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
# --partnerRevenueModel shape: {markupAmount?: string, markupType?: "PARTNER_REVENUE_MODEL_MARKUP_TYPE_UNSPECIFIED"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP"}
# --targetingExpansion shape: {excludeFirstPartyAudience?: bool, targetingExpansionLevel?: "TARGETING_EXPANSION_LEVEL_UNSPECIFIED"|"NO_EXPANSION"|"LEAST_EXPANSION"|"SOME_EXPANSION"|"BALANCED_EXPANSION"|"MORE_EXPANSION"|"MOST_EXPANSION"}
# --youtubeAndPartnersSettings shape: {biddingStrategy?: record, contentCategory?: "YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_UNSPECIFIED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_STANDARD"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_EXPANDED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_LIMITED", inventorySourceSettings?: record, leadFormId?: string, linkedMerchantId?: string, relatedVideoIds?: list<string>, targetFrequency?: record, thirdPartyMeasurementSettings?: record, videoAdSequenceSettings?: record, viewFrequencyCap?: record}
export def "advertisers-line-items create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --bid-strategy: record # Settings that control the bid strategy. Bid strategy determines the bid price. — shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
  --budget: record # Settings that control how budget is allocated. — shape: {budgetAllocationType?: "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNSPECIFIED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED", maxAmount?: string}
  --conversion-counting: record # Settings that control how conversions are counted. All post-click conversions will be counted. A percentage value can be set for post-view conversions counting. — shape: {floodlightActivityConfigs?: list, postViewCountPercentageMillis?: string}
  --creative-ids: list<string> # The IDs of the creatives associated with the line item.
  --display-name: string # Required. The display name of the line item. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the line item can spend its budget and bid on inventory. * For CreateLineItem method, only `ENTITY_STATUS_DRAFT` is allowed. To activate a line item, use UpdateLineItem method and update the status to `ENTITY_STATUS_ACTIVE` after creation. * A line item cannot be changed back to `ENTITY_STATUS_DRAFT` status from any other status. * If the line item's parent insertion order is not active, the line item can't spend its budget even if its own status is `ENTITY_STATUS_ACTIVE`.
  --exclude-new-exchanges: oneof<nothing, bool> # Whether to exclude new exchanges from automatically being targeted by the line item. This field is false by default.
  --flight: record # Settings that control the active duration of a line item. — shape: {dateRange?: record, flightDateType?: "LINE_ITEM_FLIGHT_DATE_TYPE_UNSPECIFIED"|"LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED"|"LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM"}
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
  --insertion-order-id: string # Required. Immutable. The unique ID of the insertion order that the line item belongs to. (format: int64)
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --line-item-type: string@line-item-type-completer # Required. Immutable. The type of the line item.
  --mobile-app: record # A mobile app promoted by a mobile app install line item. — shape: {appId?: string}
  --pacing: record # Settings that control the rate at which a budget is spent. — shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
  --partner-costs: list # The partner costs associated with the line item. If absent or empty in CreateLineItem method, the newly created line item will inherit partner costs from its parent insertion order. — item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
  --partner-revenue-model: record # Settings that control how partner revenue is calculated. — shape: {markupAmount?: string, markupType?: "PARTNER_REVENUE_MODEL_MARKUP_TYPE_UNSPECIFIED"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP"}
  --targeting-expansion: record # Settings that control the targeting expansion of the line item. Targeting expansion allows the line item to reach a larger audience based on the original audience list and the targeting expansion level. Beginning **March 25, 2023**, these settings may represent the [optimized targeting feature](//support.google.com/displayvideo/answer/12060859) in place of targeting expansion. This feature will be rolled out to all partners by early May 2023. — shape: {excludeFirstPartyAudience?: bool, targetingExpansionLevel?: "TARGETING_EXPANSION_LEVEL_UNSPECIFIED"|"NO_EXPANSION"|"LEAST_EXPANSION"|"SOME_EXPANSION"|"BALANCED_EXPANSION"|"MORE_EXPANSION"|"MOST_EXPANSION"}
  --youtube-and-partners-settings: record # Settings for YouTube and Partners line items. — shape: {biddingStrategy?: record, contentCategory?: "YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_UNSPECIFIED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_STANDARD"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_EXPANDED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_LIMITED", inventorySourceSettings?: record, leadFormId?: string, linkedMerchantId?: string, relatedVideoIds?: list<string>, targetFrequency?: record, thirdPartyMeasurementSettings?: record, videoAdSequenceSettings?: record, viewFrequencyCap?: record}
]: any -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, budget: record<budgetAllocationType: string, budgetUnit: string, maxAmount: string>, campaignId: string, conversionCounting: record<floodlightActivityConfigs: list<record>, postViewCountPercentageMillis: string>, creativeIds: list<string>, displayName: string, entityStatus: string, excludeNewExchanges: bool, flight: record<dateRange: record<endDate: record, startDate: record>, flightDateType: string>, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, integrationDetails: record<details: string, integrationCode: string>, lineItemId: string, lineItemType: string, mobileApp: record<appId: string, displayName: string, platform: string, publisher: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, partnerRevenueModel: record<markupAmount: string, markupType: string>, reservationType: string, targetingExpansion: record<excludeFirstPartyAudience: bool, targetingExpansionLevel: string>, updateTime: string, warningMessages: list<string>, youtubeAndPartnersSettings: record<biddingStrategy: record<adGroupEffectiveTargetCpaSource: string, adGroupEffectiveTargetCpaValue: string, type: string, value: string>, contentCategory: string, inventorySourceSettings: record<includeYoutubeSearch: bool, includeYoutubeVideoPartners: bool, includeYoutubeVideos: bool>, leadFormId: string, linkedMerchantId: string, relatedVideoIds: list<string>, targetFrequency: record<targetCount: string, timeUnit: string, timeUnitCount: int>, thirdPartyMeasurementSettings: record<brandLiftVendorConfigs: list, brandSafetyVendorConfigs: list, reachVendorConfigs: list, viewabilityVendorConfigs: list>, videoAdSequenceSettings: record<minimumDuration: string, steps: list>, viewFrequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems") $qp)
  let req_body = {"bidStrategy": $bid_strategy, "budget": $budget, "conversionCounting": $conversion_counting, "creativeIds": $creative_ids, "displayName": $display_name, "entityStatus": $entity_status, "excludeNewExchanges": $exclude_new_exchanges, "flight": $flight, "frequencyCap": $frequency_cap, "insertionOrderId": $insertion_order_id, "integrationDetails": $integration_details, "lineItemType": $line_item_type, "mobileApp": $mobile_app, "pacing": $pacing, "partnerCosts": $partner_costs, "partnerRevenueModel": $partner_revenue_model, "targetingExpansion": $targeting_expansion, "youtubeAndPartnersSettings": $youtube_and_partners_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a line item. Returns error code `NOT_FOUND` if the line item does not exist. The line item should be archived first, i.e. set entity_status to `ENTITY_STATUS_ARCHIVED`, to be able to delete it.
#
# DELETE /v2/advertisers/{advertiserId}/lineItems/{lineItemId}
# operationId: displayvideo.advertisers.lineItems.delete
export def "advertisers-line-items delete" [
  advertiser_id: string
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a line item.
#
# GET /v2/advertisers/{advertiserId}/lineItems/{lineItemId}
# operationId: displayvideo.advertisers.lineItems.get
export def "advertisers-line-items get" [
  advertiser_id: string
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, budget: record<budgetAllocationType: string, budgetUnit: string, maxAmount: string>, campaignId: string, conversionCounting: record<floodlightActivityConfigs: list<record>, postViewCountPercentageMillis: string>, creativeIds: list<string>, displayName: string, entityStatus: string, excludeNewExchanges: bool, flight: record<dateRange: record<endDate: record, startDate: record>, flightDateType: string>, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, integrationDetails: record<details: string, integrationCode: string>, lineItemId: string, lineItemType: string, mobileApp: record<appId: string, displayName: string, platform: string, publisher: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, partnerRevenueModel: record<markupAmount: string, markupType: string>, reservationType: string, targetingExpansion: record<excludeFirstPartyAudience: bool, targetingExpansionLevel: string>, updateTime: string, warningMessages: list<string>, youtubeAndPartnersSettings: record<biddingStrategy: record<adGroupEffectiveTargetCpaSource: string, adGroupEffectiveTargetCpaValue: string, type: string, value: string>, contentCategory: string, inventorySourceSettings: record<includeYoutubeSearch: bool, includeYoutubeVideoPartners: bool, includeYoutubeVideos: bool>, leadFormId: string, linkedMerchantId: string, relatedVideoIds: list<string>, targetFrequency: record<targetCount: string, timeUnit: string, timeUnitCount: int>, thirdPartyMeasurementSettings: record<brandLiftVendorConfigs: list, brandSafetyVendorConfigs: list, reachVendorConfigs: list, viewabilityVendorConfigs: list>, videoAdSequenceSettings: record<minimumDuration: string, steps: list>, viewFrequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing line item. Returns the updated line item if successful. Requests to this endpoint cannot be made concurrently with the following requests updating the same line item: * BulkEditAssignedTargetingOptions * BulkUpdateLineItems * CreateLineItemAssignedTargetingOption * DeleteLineItemAssignedTargetingOption
#
# PATCH /v2/advertisers/{advertiserId}/lineItems/{lineItemId}
# operationId: displayvideo.advertisers.lineItems.patch
# --bidStrategy shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
# --budget shape: {budgetAllocationType?: "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNSPECIFIED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED", maxAmount?: string}
# --conversionCounting shape: {floodlightActivityConfigs?: list, postViewCountPercentageMillis?: string}
# --flight shape: {dateRange?: record, flightDateType?: "LINE_ITEM_FLIGHT_DATE_TYPE_UNSPECIFIED"|"LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED"|"LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM"}
# --frequencyCap shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
# --integrationDetails shape: {details?: string, integrationCode?: string}
# --mobileApp shape: {appId?: string}
# --pacing shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
# --partnerCosts item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
# --partnerRevenueModel shape: {markupAmount?: string, markupType?: "PARTNER_REVENUE_MODEL_MARKUP_TYPE_UNSPECIFIED"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP"}
# --targetingExpansion shape: {excludeFirstPartyAudience?: bool, targetingExpansionLevel?: "TARGETING_EXPANSION_LEVEL_UNSPECIFIED"|"NO_EXPANSION"|"LEAST_EXPANSION"|"SOME_EXPANSION"|"BALANCED_EXPANSION"|"MORE_EXPANSION"|"MOST_EXPANSION"}
# --youtubeAndPartnersSettings shape: {biddingStrategy?: record, contentCategory?: "YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_UNSPECIFIED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_STANDARD"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_EXPANDED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_LIMITED", inventorySourceSettings?: record, leadFormId?: string, linkedMerchantId?: string, relatedVideoIds?: list<string>, targetFrequency?: record, thirdPartyMeasurementSettings?: record, videoAdSequenceSettings?: record, viewFrequencyCap?: record}
export def "advertisers-line-items update" [
  advertiser_id: string
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --bid-strategy: record # Settings that control the bid strategy. Bid strategy determines the bid price. — shape: {fixedBid?: record, maximizeSpendAutoBid?: record, performanceGoalAutoBid?: record}
  --budget: record # Settings that control how budget is allocated. — shape: {budgetAllocationType?: "LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNSPECIFIED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_AUTOMATIC"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_FIXED"|"LINE_ITEM_BUDGET_ALLOCATION_TYPE_UNLIMITED", maxAmount?: string}
  --conversion-counting: record # Settings that control how conversions are counted. All post-click conversions will be counted. A percentage value can be set for post-view conversions counting. — shape: {floodlightActivityConfigs?: list, postViewCountPercentageMillis?: string}
  --creative-ids: list<string> # The IDs of the creatives associated with the line item.
  --display-name: string # Required. The display name of the line item. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Required. Controls whether or not the line item can spend its budget and bid on inventory. * For CreateLineItem method, only `ENTITY_STATUS_DRAFT` is allowed. To activate a line item, use UpdateLineItem method and update the status to `ENTITY_STATUS_ACTIVE` after creation. * A line item cannot be changed back to `ENTITY_STATUS_DRAFT` status from any other status. * If the line item's parent insertion order is not active, the line item can't spend its budget even if its own status is `ENTITY_STATUS_ACTIVE`.
  --exclude-new-exchanges: oneof<nothing, bool> # Whether to exclude new exchanges from automatically being targeted by the line item. This field is false by default.
  --flight: record # Settings that control the active duration of a line item. — shape: {dateRange?: record, flightDateType?: "LINE_ITEM_FLIGHT_DATE_TYPE_UNSPECIFIED"|"LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED"|"LINE_ITEM_FLIGHT_DATE_TYPE_CUSTOM"}
  --frequency-cap: record # Settings that control the number of times a user may be shown with the same ad during a given time period. — shape: {maxImpressions?: int, maxViews?: int, timeUnit?: "TIME_UNIT_UNSPECIFIED"|"TIME_UNIT_LIFETIME"|"TIME_UNIT_MONTHS"|"TIME_UNIT_WEEKS"|"TIME_UNIT_DAYS"|"TIME_UNIT_HOURS"|"TIME_UNIT_MINUTES", timeUnitCount?: int, unlimited?: bool}
  --insertion-order-id: string # Required. Immutable. The unique ID of the insertion order that the line item belongs to. (format: int64)
  --integration-details: record # Integration details of an entry. — shape: {details?: string, integrationCode?: string}
  --line-item-type: string@line-item-type-completer # Required. Immutable. The type of the line item.
  --mobile-app: record # A mobile app promoted by a mobile app install line item. — shape: {appId?: string}
  --pacing: record # Settings that control the rate at which a budget is spent. — shape: {dailyMaxImpressions?: string, dailyMaxMicros?: string, pacingPeriod?: "PACING_PERIOD_UNSPECIFIED"|"PACING_PERIOD_DAILY"|"PACING_PERIOD_FLIGHT", pacingType?: "PACING_TYPE_UNSPECIFIED"|"PACING_TYPE_AHEAD"|"PACING_TYPE_ASAP"|"PACING_TYPE_EVEN"}
  --partner-costs: list # The partner costs associated with the line item. If absent or empty in CreateLineItem method, the newly created line item will inherit partner costs from its parent insertion order. — item shape: {costType?: "PARTNER_COST_TYPE_UNSPECIFIED"|"PARTNER_COST_TYPE_ADLOOX"|"PARTNER_COST_TYPE_ADLOOX_PREBID"|"PARTNER_COST_TYPE_ADSAFE"|"PARTNER_COST_TYPE_ADXPOSE"|"PARTNER_COST_TYPE_AGGREGATE_KNOWLEDGE"|"PARTNER_COST_TYPE_AGENCY_TRADING_DESK"|"PARTNER_COST_TYPE_DV360_FEE"|"PARTNER_COST_TYPE_COMSCORE_VCE"|"PARTNER_COST_TYPE_DATA_MANAGEMENT_PLATFORM"|"PARTNER_COST_TYPE_DEFAULT"|"PARTNER_COST_TYPE_DOUBLE_VERIFY"|"PARTNER_COST_TYPE_DOUBLE_VERIFY_PREBID"|"PARTNER_COST_TYPE_EVIDON"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_VIDEO"|"PARTNER_COST_TYPE_INTEGRAL_AD_SCIENCE_PREBID"|"PARTNER_COST_TYPE_MEDIA_COST_DATA"|"PARTNER_COST_TYPE_MOAT_VIDEO"|"PARTNER_COST_TYPE_NIELSEN_DAR"|"PARTNER_COST_TYPE_SHOP_LOCAL"|"PARTNER_COST_TYPE_TERACENT"|"PARTNER_COST_TYPE_THIRD_PARTY_AD_SERVER"|"PARTNER_COST_TYPE_TRUST_METRICS"|"PARTNER_COST_TYPE_VIZU"|"PARTNER_COST_TYPE_ADLINGO_FEE"|"PARTNER_COST_TYPE_CUSTOM_FEE_1"|"PARTNER_COST_TYPE_CUSTOM_FEE_2"|"PARTNER_COST_TYPE_CUSTOM_FEE_3"|"PARTNER_COST_TYPE_CUSTOM_FEE_4"|"PARTNER_COST_TYPE_CUSTOM_FEE_5", ... (4 more fields)}
  --partner-revenue-model: record # Settings that control how partner revenue is calculated. — shape: {markupAmount?: string, markupType?: "PARTNER_REVENUE_MODEL_MARKUP_TYPE_UNSPECIFIED"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_CPM"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_MEDIA_COST_MARKUP"|"PARTNER_REVENUE_MODEL_MARKUP_TYPE_TOTAL_MEDIA_COST_MARKUP"}
  --targeting-expansion: record # Settings that control the targeting expansion of the line item. Targeting expansion allows the line item to reach a larger audience based on the original audience list and the targeting expansion level. Beginning **March 25, 2023**, these settings may represent the [optimized targeting feature](//support.google.com/displayvideo/answer/12060859) in place of targeting expansion. This feature will be rolled out to all partners by early May 2023. — shape: {excludeFirstPartyAudience?: bool, targetingExpansionLevel?: "TARGETING_EXPANSION_LEVEL_UNSPECIFIED"|"NO_EXPANSION"|"LEAST_EXPANSION"|"SOME_EXPANSION"|"BALANCED_EXPANSION"|"MORE_EXPANSION"|"MOST_EXPANSION"}
  --youtube-and-partners-settings: record # Settings for YouTube and Partners line items. — shape: {biddingStrategy?: record, contentCategory?: "YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_UNSPECIFIED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_STANDARD"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_EXPANDED"|"YOUTUBE_AND_PARTNERS_CONTENT_CATEGORY_LIMITED", inventorySourceSettings?: record, leadFormId?: string, linkedMerchantId?: string, relatedVideoIds?: list<string>, targetFrequency?: record, thirdPartyMeasurementSettings?: record, videoAdSequenceSettings?: record, viewFrequencyCap?: record}
]: any -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, budget: record<budgetAllocationType: string, budgetUnit: string, maxAmount: string>, campaignId: string, conversionCounting: record<floodlightActivityConfigs: list<record>, postViewCountPercentageMillis: string>, creativeIds: list<string>, displayName: string, entityStatus: string, excludeNewExchanges: bool, flight: record<dateRange: record<endDate: record, startDate: record>, flightDateType: string>, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, integrationDetails: record<details: string, integrationCode: string>, lineItemId: string, lineItemType: string, mobileApp: record<appId: string, displayName: string, platform: string, publisher: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, partnerRevenueModel: record<markupAmount: string, markupType: string>, reservationType: string, targetingExpansion: record<excludeFirstPartyAudience: bool, targetingExpansionLevel: string>, updateTime: string, warningMessages: list<string>, youtubeAndPartnersSettings: record<biddingStrategy: record<adGroupEffectiveTargetCpaSource: string, adGroupEffectiveTargetCpaValue: string, type: string, value: string>, contentCategory: string, inventorySourceSettings: record<includeYoutubeSearch: bool, includeYoutubeVideoPartners: bool, includeYoutubeVideos: bool>, leadFormId: string, linkedMerchantId: string, relatedVideoIds: list<string>, targetFrequency: record<targetCount: string, timeUnit: string, timeUnitCount: int>, thirdPartyMeasurementSettings: record<brandLiftVendorConfigs: list, brandSafetyVendorConfigs: list, reachVendorConfigs: list, viewabilityVendorConfigs: list>, videoAdSequenceSettings: record<minimumDuration: string, steps: list>, viewFrequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}") $qp)
  let req_body = {"bidStrategy": $bid_strategy, "budget": $budget, "conversionCounting": $conversion_counting, "creativeIds": $creative_ids, "displayName": $display_name, "entityStatus": $entity_status, "excludeNewExchanges": $exclude_new_exchanges, "flight": $flight, "frequencyCap": $frequency_cap, "insertionOrderId": $insertion_order_id, "integrationDetails": $integration_details, "lineItemType": $line_item_type, "mobileApp": $mobile_app, "pacing": $pacing, "partnerCosts": $partner_costs, "partnerRevenueModel": $partner_revenue_model, "targetingExpansion": $targeting_expansion, "youtubeAndPartnersSettings": $youtube_and_partners_settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the targeting options assigned to a line item.
#
# GET /v2/advertisers/{advertiserId}/lineItems/{lineItemId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.lineItems.targetingTypes.assignedTargetingOptions.list
export def "advertisers-line-items-targeting-types-assigned-targeting-options list" [
  advertiser_id: string
  line_item_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` - `inheritance` Examples: * AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR assignedTargetingOptionId="2"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `5000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListLineItemAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns a targeting option to a line item. Returns the assigned targeting option if successful. Requests to this endpoint cannot be made concurrently with the following requests updating the same line item: * BulkEditAssignedTargetingOptions * BulkUpdate * UpdateLineItem * DeleteLineItemAssignedTargetingOption
#
# POST /v2/advertisers/{advertiserId}/lineItems/{lineItemId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.lineItems.targetingTypes.assignedTargetingOptions.create
# --ageRangeDetails shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
# --appCategoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --appDetails shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
# --audienceGroupDetails shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
# --audioContentTypeDetails shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
# --authorizedSellerStatusDetails shape: {targetingOptionId?: string}
# --browserDetails shape: {negative?: bool, targetingOptionId?: string}
# --businessChainDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --carrierAndIspDetails shape: {negative?: bool, targetingOptionId?: string}
# --categoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --channelDetails shape: {channelId?: string, negative?: bool}
# --contentDurationDetails shape: {targetingOptionId?: string}
# --contentGenreDetails shape: {negative?: bool, targetingOptionId?: string}
# --contentInstreamPositionDetails shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
# --contentOutstreamPositionDetails shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
# --contentStreamTypeDetails shape: {targetingOptionId?: string}
# --dayAndTimeDetails shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
# --deviceMakeModelDetails shape: {negative?: bool, targetingOptionId?: string}
# --deviceTypeDetails shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
# --digitalContentLabelExclusionDetails shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
# --environmentDetails shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
# --exchangeDetails shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
# --genderDetails shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
# --geoRegionDetails shape: {negative?: bool, targetingOptionId?: string}
# --householdIncomeDetails shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
# --inventorySourceDetails shape: {inventorySourceId?: string}
# --inventorySourceGroupDetails shape: {inventorySourceGroupId?: string}
# --keywordDetails shape: {keyword?: string, negative?: bool}
# --languageDetails shape: {negative?: bool, targetingOptionId?: string}
# --nativeContentPositionDetails shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
# --negativeKeywordListDetails shape: {negativeKeywordListId?: string}
# --omidDetails shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
# --onScreenPositionDetails shape: {targetingOptionId?: string}
# --operatingSystemDetails shape: {negative?: bool, targetingOptionId?: string}
# --parentalStatusDetails shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
# --poiDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --proximityLocationListDetails shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
# --regionalLocationListDetails shape: {negative?: bool, regionalLocationListId?: string}
# --sensitiveCategoryExclusionDetails shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
# --sessionPositionDetails shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
# --subExchangeDetails shape: {targetingOptionId?: string}
# --thirdPartyVerifierDetails shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
# --urlDetails shape: {negative?: bool, url?: string}
# --userRewardedContentDetails shape: {targetingOptionId?: string}
# --videoPlayerSizeDetails shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
# --viewabilityDetails shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
# --youtubeChannelDetails shape: {channelId?: string, negative?: bool}
# --youtubeVideoDetails shape: {negative?: bool, videoId?: string}
export def "advertisers-line-items-targeting-types-assigned-targeting-options create" [
  advertiser_id: string
  line_item_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --age-range-details: record # Represents a targetable age range. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AGE_RANGE`. — shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
  --app-category-details: record # Details for assigned app category targeting option. This will be populated in the app_category_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --app-details: record # Details for assigned app targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP`. — shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
  --audience-group-details: record # Assigned audience group targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUDIENCE_GROUP`. The relation between each group is UNION, except for excluded_first_and_third_party_audience_group and excluded_google_audience_group, of which COMPLEMENT is used as an INTERSECTION with other groups. — shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
  --audio-content-type-details: record # Details for audio content type assigned targeting option. This will be populated in the audio_content_type_details field when targeting_type is `TARGETING_TYPE_AUDIO_CONTENT_TYPE`. Explicitly targeting all options is not supported. Remove all audio content type targeting options to achieve this effect. — shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
  --authorized-seller-status-details: record # Represents an assigned authorized seller status. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`. — shape: {targetingOptionId?: string}
  --browser-details: record # Details for assigned browser targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BROWSER`. — shape: {negative?: bool, targetingOptionId?: string}
  --business-chain-details: record # Details for assigned Business chain targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BUSINESS_CHAIN`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --carrier-and-isp-details: record # Details for assigned carrier and ISP targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`. — shape: {negative?: bool, targetingOptionId?: string}
  --category-details: record # Assigned category targeting option details. This will be populated in the category_details field when targeting_type is `TARGETING_TYPE_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --channel-details: record # Details for assigned channel targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --content-duration-details: record # Details for content duration assigned targeting option. This will be populated in the content_duration_details field when targeting_type is `TARGETING_TYPE_CONTENT_DURATION`. Explicitly targeting all options is not supported. Remove all content duration targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --content-genre-details: record # Details for content genre assigned targeting option. This will be populated in the content_genre_details field when targeting_type is `TARGETING_TYPE_CONTENT_GENRE`. Explicitly targeting all options is not supported. Remove all content genre targeting options to achieve this effect. — shape: {negative?: bool, targetingOptionId?: string}
  --content-instream-position-details: record # Assigned content instream position targeting option details. This will be populated in the content_instream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`. — shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
  --content-outstream-position-details: record # Assigned content outstream position targeting option details. This will be populated in the content_outstream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`. — shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
  --content-stream-type-details: record # Details for content stream type assigned targeting option. This will be populated in the content_stream_type_details field when targeting_type is `TARGETING_TYPE_CONTENT_STREAM_TYPE`. Explicitly targeting all options is not supported. Remove all content stream type targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --day-and-time-details: record # Representation of a segment of time defined on a specific day of the week and with a start and end time. The time represented by `start_hour` must be before the time represented by `end_hour`. — shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
  --device-make-model-details: record # Assigned device make and model targeting option details. This will be populated in the device_make_model_details field when targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`. — shape: {negative?: bool, targetingOptionId?: string}
  --device-type-details: record # Targeting details for device type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`. — shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
  --digital-content-label-exclusion-details: record # Targeting details for digital content label. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`. — shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
  --environment-details: record # Assigned environment targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_ENVIRONMENT`. — shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
  --exchange-details: record # Details for assigned exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_EXCHANGE`. — shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
  --gender-details: record # Details for assigned gender targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GENDER`. — shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
  --geo-region-details: record # Details for assigned geographic region targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GEO_REGION`. — shape: {negative?: bool, targetingOptionId?: string}
  --household-income-details: record # Details for assigned household income targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`. — shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
  --inventory-source-details: record # Targeting details for inventory source. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE`. — shape: {inventorySourceId?: string}
  --inventory-source-group-details: record # Targeting details for inventory source group. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`. — shape: {inventorySourceGroupId?: string}
  --keyword-details: record # Details for assigned keyword targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_KEYWORD`. — shape: {keyword?: string, negative?: bool}
  --language-details: record # Details for assigned language targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_LANGUAGE`. — shape: {negative?: bool, targetingOptionId?: string}
  --native-content-position-details: record # Details for native content position assigned targeting option. This will be populated in the native_content_position_details field when targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`. Explicitly targeting all options is not supported. Remove all native content position targeting options to achieve this effect. — shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
  --negative-keyword-list-details: record # Targeting details for negative keyword list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`. — shape: {negativeKeywordListId?: string}
  --omid-details: record # Represents a targetable Open Measurement enabled inventory type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_OMID`. — shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
  --on-screen-position-details: record # On screen position targeting option details. This will be populated in the on_screen_position_details field when targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`. — shape: {targetingOptionId?: string}
  --operating-system-details: record # Assigned operating system targeting option details. This will be populated in the operating_system_details field when targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`. — shape: {negative?: bool, targetingOptionId?: string}
  --parental-status-details: record # Details for assigned parental status targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PARENTAL_STATUS`. — shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
  --poi-details: record # Details for assigned POI targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_POI`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --proximity-location-list-details: record # Targeting details for proximity location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`. — shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
  --regional-location-list-details: record # Targeting details for regional location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_REGIONAL_LOCATION_LIST`. — shape: {negative?: bool, regionalLocationListId?: string}
  --sensitive-category-exclusion-details: record # Targeting details for sensitive category. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`. — shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
  --session-position-details: record # Details for session position assigned targeting option. This will be populated in the session_position_details field when targeting_type is `TARGETING_TYPE_SESSION_POSITION`. — shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
  --sub-exchange-details: record # Details for assigned sub-exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`. — shape: {targetingOptionId?: string}
  --third-party-verifier-details: record # Assigned third party verifier targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_THIRD_PARTY_VERIFIER`. — shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
  --url-details: record # Details for assigned URL targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_URL`. — shape: {negative?: bool, url?: string}
  --user-rewarded-content-details: record # User rewarded content targeting option details. This will be populated in the user_rewarded_content_details field when targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`. — shape: {targetingOptionId?: string}
  --video-player-size-details: record # Video player size targeting option details. This will be populated in the video_player_size_details field when targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`. Explicitly targeting all options is not supported. Remove all video player size targeting options to achieve this effect. — shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
  --viewability-details: record # Assigned viewability targeting option details. This will be populated in the viewability_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_VIEWABILITY`. — shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
  --youtube-channel-details: record # Details for YouTube channel assigned targeting option. This will be populated in the youtube_channel_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --youtube-video-details: record # Details for YouTube video assigned targeting option. This will be populated in the youtube_video_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_VIDEO`. — shape: {negative?: bool, videoId?: string}
]: any -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let req_body = {"ageRangeDetails": $age_range_details, "appCategoryDetails": $app_category_details, "appDetails": $app_details, "audienceGroupDetails": $audience_group_details, "audioContentTypeDetails": $audio_content_type_details, "authorizedSellerStatusDetails": $authorized_seller_status_details, "browserDetails": $browser_details, "businessChainDetails": $business_chain_details, "carrierAndIspDetails": $carrier_and_isp_details, "categoryDetails": $category_details, "channelDetails": $channel_details, "contentDurationDetails": $content_duration_details, "contentGenreDetails": $content_genre_details, "contentInstreamPositionDetails": $content_instream_position_details, "contentOutstreamPositionDetails": $content_outstream_position_details, "contentStreamTypeDetails": $content_stream_type_details, "dayAndTimeDetails": $day_and_time_details, "deviceMakeModelDetails": $device_make_model_details, "deviceTypeDetails": $device_type_details, "digitalContentLabelExclusionDetails": $digital_content_label_exclusion_details, "environmentDetails": $environment_details, "exchangeDetails": $exchange_details, "genderDetails": $gender_details, "geoRegionDetails": $geo_region_details, "householdIncomeDetails": $household_income_details, "inventorySourceDetails": $inventory_source_details, "inventorySourceGroupDetails": $inventory_source_group_details, "keywordDetails": $keyword_details, "languageDetails": $language_details, "nativeContentPositionDetails": $native_content_position_details, "negativeKeywordListDetails": $negative_keyword_list_details, "omidDetails": $omid_details, "onScreenPositionDetails": $on_screen_position_details, "operatingSystemDetails": $operating_system_details, "parentalStatusDetails": $parental_status_details, "poiDetails": $poi_details, "proximityLocationListDetails": $proximity_location_list_details, "regionalLocationListDetails": $regional_location_list_details, "sensitiveCategoryExclusionDetails": $sensitive_category_exclusion_details, "sessionPositionDetails": $session_position_details, "subExchangeDetails": $sub_exchange_details, "thirdPartyVerifierDetails": $third_party_verifier_details, "urlDetails": $url_details, "userRewardedContentDetails": $user_rewarded_content_details, "videoPlayerSizeDetails": $video_player_size_details, "viewabilityDetails": $viewability_details, "youtubeChannelDetails": $youtube_channel_details, "youtubeVideoDetails": $youtube_video_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an assigned targeting option from a line item. Requests to this endpoint cannot be made concurrently with the following requests updating the same line item: * BulkEditAssignedTargetingOptions * BulkUpdate * UpdateLineItem * CreateLineItemAssignedTargetingOption
#
# DELETE /v2/advertisers/{advertiserId}/lineItems/{lineItemId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.lineItems.targetingTypes.assignedTargetingOptions.delete
export def "advertisers-line-items-targeting-types-assigned-targeting-options delete" [
  advertiser_id: string
  line_item_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to a line item.
#
# GET /v2/advertisers/{advertiserId}/lineItems/{lineItemId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.lineItems.targetingTypes.assignedTargetingOptions.get
export def "advertisers-line-items-targeting-types-assigned-targeting-options get" [
  advertiser_id: string
  line_item_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicates a line item. Returns the ID of the created line item if successful.
#
# POST /v2/advertisers/{advertiserId}/lineItems/{lineItemId}:duplicate
# operationId: displayvideo.advertisers.lineItems.duplicate
export def "advertisers-line-items create-duplicate" [
  advertiser_id: string
  line_item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --target-display-name: string # The display name of the new line item. Must be UTF-8 encoded with a maximum size of 240 bytes.
]: any -> record<duplicateLineItemId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), line_item_id: (encode-path-segment $line_item_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems/{line_item_id}:duplicate") $qp)
  let req_body = {"targetDisplayName": $target_display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk edits targeting options under multiple line items. The operation will delete the assigned targeting options provided in BulkEditAssignedTargetingOptionsRequest.delete_requests and then create the assigned targeting options provided in BulkEditAssignedTargetingOptionsRequest.create_requests. Requests to this endpoint cannot be made concurrently with the following requests updating the same line item: * BulkUpdate * UpdateLineItem * CreateLineItemAssignedTargetingOption * DeleteLineItemAssignedTargetingOption
#
# POST /v2/advertisers/{advertiserId}/lineItems:bulkEditAssignedTargetingOptions
# operationId: displayvideo.advertisers.lineItems.bulkEditAssignedTargetingOptions
# --createRequests item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
# --deleteRequests item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
export def "advertisers-line-items-bulk-edit-assigned-targeting-options create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --create-requests: list # The assigned targeting options to create in batch, specified as a list of CreateAssignedTargetingOptionsRequest. Supported targeting types include: * `TARGETING_TYPE_AGE_RANGE` * `TARGETING_TYPE_APP` * `TARGETING_TYPE_APP_CATEGORY` * `TARGETING_TYPE_AUDIENCE_GROUP` * `TARGETING_TYPE_AUDIO_CONTENT_TYPE` * `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS` * `TARGETING_TYPE_BROWSER` * `TARGETING_TYPE_BUSINESS_CHAIN` * `TARGETING_TYPE_CARRIER_AND_ISP` * `TARGETING_TYPE_CATEGORY` * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_CONTENT_DURATION` * `TARGETING_TYPE_CONTENT_GENRE` * `TARGETING_TYPE_CONTENT_INSTREAM_POSITION` * `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION` * `TARGETING_TYPE_CONTENT_STREAM_TYPE` * `TARGETING_TYPE_DAY_AND_TIME` * `TARGETING_TYPE_DEVICE_MAKE_MODEL` * `TARGETING_TYPE_DEVICE_TYPE` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_EXCHANGE` * `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_GEO_REGION` * `TARGETING_TYPE_HOUSEHOLD_INCOME` * `TARGETING_TYPE_INVENTORY_SOURCE` * `TARGETING_TYPE_INVENTORY_SOURCE_GROUP` * `TARGETING_TYPE_KEYWORD` * `TARGETING_TYPE_LANGUAGE` * `TARGETING_TYPE_NATIVE_CONTENT_POSITION` * `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST` * `TARGETING_TYPE_OMID` * `TARGETING_TYPE_ON_SCREEN_POSITION` * `TARGETING_TYPE_OPERATING_SYSTEM` * `TARGETING_TYPE_PARENTAL_STATUS` * `TARGETING_TYPE_POI` * `TARGETING_TYPE_PROXIMITY_LOCATION_LIST` * `TARGETING_TYPE_REGIONAL_LOCATION_LIST` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` * `TARGETING_TYPE_SUB_EXCHANGE` * `TARGETING_TYPE_THIRD_PARTY_VERIFIER` * `TARGETING_TYPE_URL` * `TARGETING_TYPE_USER_REWARDED_CONTENT` * `TARGETING_TYPE_VIDEO_PLAYER_SIZE` * `TARGETING_TYPE_VIEWABILITY` — item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
  --delete-requests: list # The assigned targeting options to delete in batch, specified as a list of DeleteAssignedTargetingOptionsRequest. Supported targeting types include: * `TARGETING_TYPE_AGE_RANGE` * `TARGETING_TYPE_APP` * `TARGETING_TYPE_APP_CATEGORY` * `TARGETING_TYPE_AUDIENCE_GROUP` * `TARGETING_TYPE_AUDIO_CONTENT_TYPE` * `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS` * `TARGETING_TYPE_BROWSER` * `TARGETING_TYPE_BUSINESS_CHAIN` * `TARGETING_TYPE_CARRIER_AND_ISP` * `TARGETING_TYPE_CATEGORY` * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_CONTENT_DURATION` * `TARGETING_TYPE_CONTENT_GENRE` * `TARGETING_TYPE_CONTENT_INSTREAM_POSITION` * `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION` * `TARGETING_TYPE_CONTENT_STREAM_TYPE` * `TARGETING_TYPE_DAY_AND_TIME` * `TARGETING_TYPE_DEVICE_MAKE_MODEL` * `TARGETING_TYPE_DEVICE_TYPE` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_ENVIRONMENT` * `TARGETING_TYPE_EXCHANGE` * `TARGETING_TYPE_GENDER` * `TARGETING_TYPE_GEO_REGION` * `TARGETING_TYPE_HOUSEHOLD_INCOME` * `TARGETING_TYPE_INVENTORY_SOURCE` * `TARGETING_TYPE_INVENTORY_SOURCE_GROUP` * `TARGETING_TYPE_KEYWORD` * `TARGETING_TYPE_LANGUAGE` * `TARGETING_TYPE_NATIVE_CONTENT_POSITION` * `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST` * `TARGETING_TYPE_OMID` * `TARGETING_TYPE_ON_SCREEN_POSITION` * `TARGETING_TYPE_OPERATING_SYSTEM` * `TARGETING_TYPE_PARENTAL_STATUS` * `TARGETING_TYPE_POI` * `TARGETING_TYPE_PROXIMITY_LOCATION_LIST` * `TARGETING_TYPE_REGIONAL_LOCATION_LIST` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` * `TARGETING_TYPE_SUB_EXCHANGE` * `TARGETING_TYPE_THIRD_PARTY_VERIFIER` * `TARGETING_TYPE_URL` * `TARGETING_TYPE_USER_REWARDED_CONTENT` * `TARGETING_TYPE_VIDEO_PLAYER_SIZE` * `TARGETING_TYPE_VIEWABILITY` — item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
  --line-item-ids: list<string> # Required. The ID of the line items whose targeting is being updated.
]: any -> record<errors: table<code: int, details: list, message: string>, failedLineItemIds: list<string>, updatedLineItemIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems:bulkEditAssignedTargetingOptions") $qp)
  let req_body = {"createRequests": $create_requests, "deleteRequests": $delete_requests, "lineItemIds": $line_item_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists assigned targeting options for multiple line items across targeting types.
#
# GET /v2/advertisers/{advertiserId}/lineItems:bulkListAssignedTargetingOptions
# operationId: displayvideo.advertisers.lineItems.bulkListAssignedTargetingOptions
export def "advertisers-line-items-bulk-list-assigned-targeting-options list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR` on the same field. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `targetingType` - `inheritance` Examples: * AssignedTargetingOptions of targeting type TARGETING_TYPE_PROXIMITY_LOCATION_LIST or TARGETING_TYPE_CHANNEL `targetingType="TARGETING_TYPE_PROXIMITY_LOCATION_LIST" OR targetingType="TARGETING_TYPE_CHANNEL"` * AssignedTargetingOptions with inheritance status of NOT_INHERITED or INHERITED_FROM_PARTNER `inheritance="NOT_INHERITED" OR inheritance="INHERITED_FROM_PARTNER"` The length of this field should be no more than 500 characters.
  --line-item-ids: list<string> # Required. The IDs of the line items to list assigned targeting options for.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `lineItemId` (default) * `assignedTargetingOption.targetingType` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingType desc`.
  --page-size: int # Requested page size. The size must be an integer between `1` and `5000`. If unspecified, the default is `5000`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token that lets the client fetch the next page of results. Typically, this is the value of next_page_token returned from the previous call to the `BulkListAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<lineItemAssignedTargetingOptions: table<assignedTargetingOption: record, lineItemId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "lineItemIds" $line_item_ids "multi") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems:bulkListAssignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates multiple line items. Requests to this endpoint cannot be made concurrently with the following requests updating the same line item: * BulkEditAssignedTargetingOptions * UpdateLineItem * CreateLineItemAssignedTargetingOption * DeleteLineItemAssignedTargetingOption
#
# POST /v2/advertisers/{advertiserId}/lineItems:bulkUpdate
# operationId: displayvideo.advertisers.lineItems.bulkUpdate
# --targetLineItem shape: {bidStrategy?: record, budget?: record, conversionCounting?: record, creativeIds?: list<string>, displayName?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION", excludeNewExchanges?: bool, flight?: record, frequencyCap?: record, insertionOrderId?: string, integrationDetails?: record, ... (7 more fields)}
export def "advertisers-line-items-bulk-update update" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --line-item-ids: list<string> # Required. IDs of line items to update.
  --target-line-item: record # A single line item. — shape: {bidStrategy?: record, budget?: record, conversionCounting?: record, creativeIds?: list<string>, displayName?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION", excludeNewExchanges?: bool, flight?: record, frequencyCap?: record, insertionOrderId?: string, integrationDetails?: record, ... (7 more fields)}
  --update-mask: string # Required. A field mask identifying which fields to update. Only the following fields are currently supported: * entityStatus (format: google-fieldmask)
]: any -> record<errors: table<code: int, details: list, message: string>, failedLineItemIds: list<string>, skippedLineItemIds: list<string>, updatedLineItemIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems:bulkUpdate") $qp)
  let req_body = {"lineItemIds": $line_item_ids, "targetLineItem": $target_line_item, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new line item with settings (including targeting) inherited from the insertion order and an `ENTITY_STATUS_DRAFT` entity_status. Returns the newly created line item if successful. There are default values based on the three fields: * The insertion order's insertion_order_type * The insertion order's automation_type * The given line_item_type
#
# POST /v2/advertisers/{advertiserId}/lineItems:generateDefault
# operationId: displayvideo.advertisers.lineItems.generateDefault
# --mobileApp shape: {appId?: string}
export def "advertisers-line-items-generate-default generate" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --display-name: string # Required. The display name of the line item. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --insertion-order-id: string # Required. The unique ID of the insertion order that the line item belongs to. (format: int64)
  --line-item-type: string@line-item-type-completer # Required. The type of the line item.
  --mobile-app: record # A mobile app promoted by a mobile app install line item. — shape: {appId?: string}
]: any -> record<advertiserId: string, bidStrategy: record<fixedBid: record<bidAmountMicros: string>, maximizeSpendAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalType: string, raiseBidForDeals: bool>, performanceGoalAutoBid: record<customBiddingAlgorithmId: string, maxAverageCpmBidAmountMicros: string, performanceGoalAmountMicros: string, performanceGoalType: string>>, budget: record<budgetAllocationType: string, budgetUnit: string, maxAmount: string>, campaignId: string, conversionCounting: record<floodlightActivityConfigs: list<record>, postViewCountPercentageMillis: string>, creativeIds: list<string>, displayName: string, entityStatus: string, excludeNewExchanges: bool, flight: record<dateRange: record<endDate: record, startDate: record>, flightDateType: string>, frequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>, insertionOrderId: string, integrationDetails: record<details: string, integrationCode: string>, lineItemId: string, lineItemType: string, mobileApp: record<appId: string, displayName: string, platform: string, publisher: string>, name: string, pacing: record<dailyMaxImpressions: string, dailyMaxMicros: string, pacingPeriod: string, pacingType: string>, partnerCosts: table<costType: string, feeAmount: string, feePercentageMillis: string, feeType: string, invoiceType: string>, partnerRevenueModel: record<markupAmount: string, markupType: string>, reservationType: string, targetingExpansion: record<excludeFirstPartyAudience: bool, targetingExpansionLevel: string>, updateTime: string, warningMessages: list<string>, youtubeAndPartnersSettings: record<biddingStrategy: record<adGroupEffectiveTargetCpaSource: string, adGroupEffectiveTargetCpaValue: string, type: string, value: string>, contentCategory: string, inventorySourceSettings: record<includeYoutubeSearch: bool, includeYoutubeVideoPartners: bool, includeYoutubeVideos: bool>, leadFormId: string, linkedMerchantId: string, relatedVideoIds: list<string>, targetFrequency: record<targetCount: string, timeUnit: string, timeUnitCount: int>, thirdPartyMeasurementSettings: record<brandLiftVendorConfigs: list, brandSafetyVendorConfigs: list, reachVendorConfigs: list, viewabilityVendorConfigs: list>, videoAdSequenceSettings: record<minimumDuration: string, steps: list>, viewFrequencyCap: record<maxImpressions: int, maxViews: int, timeUnit: string, timeUnitCount: int, unlimited: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/lineItems:generateDefault") $qp)
  let req_body = {"displayName": $display_name, "insertionOrderId": $insertion_order_id, "lineItemType": $line_item_type, "mobileApp": $mobile_app} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists location lists based on a given advertiser id.
#
# GET /v2/advertisers/{advertiserId}/locationLists
# operationId: displayvideo.advertisers.locationLists.list
export def "advertisers-location-lists list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by location list fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `locationType` Examples: * All regional location list: `locationType="TARGETING_LOCATION_TYPE_REGIONAL"` * All proximity location list: `locationType="TARGETING_LOCATION_TYPE_PROXIMITY"`
  --order-by: string # Field by which to sort the list. Acceptable values are: * `locationListId` (default) * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. Defaults to `100` if not set. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListLocationLists` method. If not specified, the first page of results will be returned.
]: nothing -> record<locationLists: table<advertiserId: string, displayName: string, locationListId: string, locationType: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new location list. Returns the newly created location list if successful.
#
# POST /v2/advertisers/{advertiserId}/locationLists
# operationId: displayvideo.advertisers.locationLists.create
export def "advertisers-location-lists create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body-advertiser-id: string # Required. Immutable. The unique ID of the advertiser the location list belongs to. (format: int64)
  --display-name: string # Required. The display name of the location list. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --location-type: string@location-type-completer # Required. Immutable. The type of location. All locations in the list will share this type.
]: any -> record<advertiserId: string, displayName: string, locationListId: string, locationType: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "displayName": $display_name, "locationType": $location_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a location list. Returns the updated location list if successful.
#
# PATCH /v2/advertisers/{advertiserId}/locationLists/{locationListId}
# operationId: displayvideo.advertisers.locationLists.patch
export def "advertisers-location-lists update" [
  advertiser_id: string
  location_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --body-advertiser-id: string # Required. Immutable. The unique ID of the advertiser the location list belongs to. (format: int64)
  --display-name: string # Required. The display name of the location list. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --location-type: string@location-type-completer # Required. Immutable. The type of location. All locations in the list will share this type.
]: any -> record<advertiserId: string, displayName: string, locationListId: string, locationType: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), location_list_id: (encode-path-segment $location_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists/{location_list_id}") $qp)
  let req_body = {"advertiserId": $body_advertiser_id, "displayName": $display_name, "locationType": $location_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists locations assigned to a location list.
#
# GET /v2/advertisers/{advertiserId}/locationLists/{locationListId}/assignedLocations
# operationId: displayvideo.advertisers.locationLists.assignedLocations.list
export def "advertisers-location-lists-assigned-locations list" [
  advertiser_id: string
  location_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by location list assignment fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedLocationId` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedLocationId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `assignedLocationId desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListAssignedLocations` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedLocations: table<assignedLocationId: string, name: string, targetingOptionId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), location_list_id: (encode-path-segment $location_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists/{location_list_id}/assignedLocations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an assignment between a location and a location list.
#
# POST /v2/advertisers/{advertiserId}/locationLists/{locationListId}/assignedLocations
# operationId: displayvideo.advertisers.locationLists.assignedLocations.create
export def "advertisers-location-lists-assigned-locations create" [
  advertiser_id: string
  location_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --targeting-option-id: string # Required. The ID of the targeting option assigned to the location list. Must be of type TARGETING_TYPE_GEO_REGION.
]: any -> record<assignedLocationId: string, name: string, targetingOptionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), location_list_id: (encode-path-segment $location_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists/{location_list_id}/assignedLocations") $qp)
  let req_body = {"targetingOptionId": $targeting_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the assignment between a location and a location list.
#
# DELETE /v2/advertisers/{advertiserId}/locationLists/{locationListId}/assignedLocations/{assignedLocationId}
# operationId: displayvideo.advertisers.locationLists.assignedLocations.delete
export def "advertisers-location-lists-assigned-locations delete" [
  advertiser_id: string
  location_list_id: string
  assigned_location_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), location_list_id: (encode-path-segment $location_list_id), assigned_location_id: (encode-path-segment $assigned_location_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists/{location_list_id}/assignedLocations/{assigned_location_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk edits multiple assignments between locations and a single location list. The operation will delete the assigned locations provided in BulkEditAssignedLocationsRequest.deleted_assigned_locations and then create the assigned locations provided in BulkEditAssignedLocationsRequest.created_assigned_locations.
#
# POST /v2/advertisers/{advertiserId}/locationLists/{locationListId}/assignedLocations:bulkEdit
# operationId: displayvideo.advertisers.locationLists.assignedLocations.bulkEdit
# --createdAssignedLocations item shape: {targetingOptionId?: string}
export def "advertisers-location-lists-assigned-locations-bulk-edit create" [
  advertiser_id: string
  location_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --created-assigned-locations: list # The assigned locations to create in bulk, specified as a list of AssignedLocations. — item shape: {targetingOptionId?: string}
  --deleted-assigned-locations: list<string> # The IDs of the assigned locations to delete in bulk, specified as a list of assigned_location_ids.
]: any -> record<assignedLocations: table<assignedLocationId: string, name: string, targetingOptionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), location_list_id: (encode-path-segment $location_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/locationLists/{location_list_id}/assignedLocations:bulkEdit") $qp)
  let req_body = {"createdAssignedLocations": $created_assigned_locations, "deletedAssignedLocations": $deleted_assigned_locations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists manual triggers that are accessible to the current user for a given advertiser ID. The order is defined by the order_by parameter. A single advertiser_id is required.
#
# GET /v2/advertisers/{advertiserId}/manualTriggers
# operationId: displayvideo.advertisers.manualTriggers.list
export def "advertisers-manual-triggers list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by manual trigger properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `displayName` - `state` Examples: * All active manual triggers under an advertiser: `state="ACTIVE"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `state` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListManualTriggers` method. If not specified, the first page of results will be returned.
]: nothing -> record<manualTriggers: table<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new manual trigger. Returns the newly created manual trigger if successful.
#
# POST /v2/advertisers/{advertiserId}/manualTriggers
# operationId: displayvideo.advertisers.manualTriggers.create
export def "advertisers-manual-triggers create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --activation-duration-minutes: string # Required. The maximum duration of each activation in minutes. Must be between 1 and 360 inclusive. After this duration, the trigger will be automatically deactivated. (format: int64)
  --body-advertiser-id: string # Required. Immutable. The unique ID of the advertiser that the manual trigger belongs to. (format: int64)
  --display-name: string # Required. The display name of the manual trigger. Must be UTF-8 encoded with a maximum size of 240 bytes.
]: any -> record<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers") $qp)
  let req_body = {"activationDurationMinutes": $activation_duration_minutes, "advertiserId": $body_advertiser_id, "displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a manual trigger.
#
# GET /v2/advertisers/{advertiserId}/manualTriggers/{triggerId}
# operationId: displayvideo.advertisers.manualTriggers.get
export def "advertisers-manual-triggers get" [
  advertiser_id: string
  trigger_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), trigger_id: (encode-path-segment $trigger_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers/{trigger_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a manual trigger. Returns the updated manual trigger if successful.
#
# PATCH /v2/advertisers/{advertiserId}/manualTriggers/{triggerId}
# operationId: displayvideo.advertisers.manualTriggers.patch
export def "advertisers-manual-triggers update" [
  advertiser_id: string
  trigger_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --activation-duration-minutes: string # Required. The maximum duration of each activation in minutes. Must be between 1 and 360 inclusive. After this duration, the trigger will be automatically deactivated. (format: int64)
  --body-advertiser-id: string # Required. Immutable. The unique ID of the advertiser that the manual trigger belongs to. (format: int64)
  --display-name: string # Required. The display name of the manual trigger. Must be UTF-8 encoded with a maximum size of 240 bytes.
]: any -> record<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), trigger_id: (encode-path-segment $trigger_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers/{trigger_id}") $qp)
  let req_body = {"activationDurationMinutes": $activation_duration_minutes, "advertiserId": $body_advertiser_id, "displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Activates a manual trigger. Each activation of the manual trigger must be at least 5 minutes apart, otherwise an error will be returned.
#
# POST /v2/advertisers/{advertiserId}/manualTriggers/{triggerId}:activate
# operationId: displayvideo.advertisers.manualTriggers.activate
export def "advertisers-manual-triggers create-activate" [
  advertiser_id: string
  trigger_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> record<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), trigger_id: (encode-path-segment $trigger_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers/{trigger_id}:activate") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deactivates a manual trigger.
#
# POST /v2/advertisers/{advertiserId}/manualTriggers/{triggerId}:deactivate
# operationId: displayvideo.advertisers.manualTriggers.deactivate
export def "advertisers-manual-triggers create-deactivate" [
  advertiser_id: string
  trigger_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> record<activationDurationMinutes: string, advertiserId: string, displayName: string, latestActivationTime: string, name: string, state: string, triggerId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), trigger_id: (encode-path-segment $trigger_id)} | format pattern "/v2/advertisers/{advertiser_id}/manualTriggers/{trigger_id}:deactivate") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists negative keyword lists based on a given advertiser id.
#
# GET /v2/advertisers/{advertiserId}/negativeKeywordLists
# operationId: displayvideo.advertisers.negativeKeywordLists.list
export def "advertisers-negative-keyword-lists list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --page-size: int # Requested page size. Must be between `1` and `200`. Defaults to `100` if not set. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListNegativeKeywordLists` method. If not specified, the first page of results will be returned.
]: nothing -> record<negativeKeywordLists: table<advertiserId: string, displayName: string, name: string, negativeKeywordListId: string, targetedLineItemCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new negative keyword list. Returns the newly created negative keyword list if successful.
#
# POST /v2/advertisers/{advertiserId}/negativeKeywordLists
# operationId: displayvideo.advertisers.negativeKeywordLists.create
export def "advertisers-negative-keyword-lists create" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --display-name: string # Required. The display name of the negative keyword list. Must be UTF-8 encoded with a maximum size of 255 bytes.
]: any -> record<advertiserId: string, displayName: string, name: string, negativeKeywordListId: string, targetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists") $qp)
  let req_body = {"displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a negative keyword list. Returns the updated negative keyword list if successful.
#
# PATCH /v2/advertisers/{advertiserId}/negativeKeywordLists/{negativeKeywordListId}
# operationId: displayvideo.advertisers.negativeKeywordLists.patch
export def "advertisers-negative-keyword-lists update" [
  advertiser_id: string
  negative_keyword_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --display-name: string # Required. The display name of the negative keyword list. Must be UTF-8 encoded with a maximum size of 255 bytes.
]: any -> record<advertiserId: string, displayName: string, name: string, negativeKeywordListId: string, targetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), negative_keyword_list_id: (encode-path-segment $negative_keyword_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists/{negative_keyword_list_id}") $qp)
  let req_body = {"displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists negative keywords in a negative keyword list.
#
# GET /v2/advertisers/{advertiserId}/negativeKeywordLists/{negativeKeywordListId}/negativeKeywords
# operationId: displayvideo.advertisers.negativeKeywordLists.negativeKeywords.list
export def "advertisers-negative-keyword-lists-negative-keywords list" [
  advertiser_id: string
  negative_keyword_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by negative keyword fields. Supported syntax: * Filter expressions for negative keyword currently can only contain at most one * restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `keywordValue` Examples: * All negative keywords for which the keyword value contains "google": `keywordValue : "google"`
  --order-by: string # Field by which to sort the list. Acceptable values are: * `keywordValue` (default) The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `keywordValue desc`.
  --page-size: int # Requested page size. Must be between `1` and `1000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListNegativeKeywords` method. If not specified, the first page of results will be returned.
]: nothing -> record<negativeKeywords: table<keywordValue: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), negative_keyword_list_id: (encode-path-segment $negative_keyword_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists/{negative_keyword_list_id}/negativeKeywords") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a negative keyword from a negative keyword list.
#
# DELETE /v2/advertisers/{advertiserId}/negativeKeywordLists/{negativeKeywordListId}/negativeKeywords/{keywordValue}
# operationId: displayvideo.advertisers.negativeKeywordLists.negativeKeywords.delete
export def "advertisers-negative-keyword-lists-negative-keywords delete" [
  advertiser_id: string
  negative_keyword_list_id: string
  keyword_value: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), negative_keyword_list_id: (encode-path-segment $negative_keyword_list_id), keyword_value: (encode-path-segment $keyword_value)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists/{negative_keyword_list_id}/negativeKeywords/{keyword_value}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk edits negative keywords in a single negative keyword list. The operation will delete the negative keywords provided in BulkEditNegativeKeywordsRequest.deleted_negative_keywords and then create the negative keywords provided in BulkEditNegativeKeywordsRequest.created_negative_keywords. This operation is guaranteed to be atomic and will never result in a partial success or partial failure.
#
# POST /v2/advertisers/{advertiserId}/negativeKeywordLists/{negativeKeywordListId}/negativeKeywords:bulkEdit
# operationId: displayvideo.advertisers.negativeKeywordLists.negativeKeywords.bulkEdit
# --createdNegativeKeywords item shape: {keywordValue?: string}
export def "advertisers-negative-keyword-lists-negative-keywords-bulk-edit create" [
  advertiser_id: string
  negative_keyword_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --created-negative-keywords: list # The negative keywords to create in batch, specified as a list of NegativeKeywords. — item shape: {keywordValue?: string}
  --deleted-negative-keywords: list<string> # The negative keywords to delete in batch, specified as a list of keyword_values.
]: any -> record<negativeKeywords: table<keywordValue: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), negative_keyword_list_id: (encode-path-segment $negative_keyword_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists/{negative_keyword_list_id}/negativeKeywords:bulkEdit") $qp)
  let req_body = {"createdNegativeKeywords": $created_negative_keywords, "deletedNegativeKeywords": $deleted_negative_keywords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replaces all negative keywords in a single negative keyword list. The operation will replace the keywords in a negative keyword list with keywords provided in ReplaceNegativeKeywordsRequest.new_negative_keywords.
#
# POST /v2/advertisers/{advertiserId}/negativeKeywordLists/{negativeKeywordListId}/negativeKeywords:replace
# operationId: displayvideo.advertisers.negativeKeywordLists.negativeKeywords.replace
# --newNegativeKeywords item shape: {keywordValue?: string}
export def "advertisers-negative-keyword-lists-negative-keywords-replace update" [
  advertiser_id: string
  negative_keyword_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --new-negative-keywords: list # The negative keywords that will replace the existing keywords in the negative keyword list, specified as a list of NegativeKeywords. — item shape: {keywordValue?: string}
]: any -> record<negativeKeywords: table<keywordValue: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), negative_keyword_list_id: (encode-path-segment $negative_keyword_list_id)} | format pattern "/v2/advertisers/{advertiser_id}/negativeKeywordLists/{negative_keyword_list_id}/negativeKeywords:replace") $qp)
  let req_body = {"newNegativeKeywords": $new_negative_keywords} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the targeting options assigned to an advertiser.
#
# GET /v2/advertisers/{advertiserId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.targetingTypes.assignedTargetingOptions.list
export def "advertisers-targeting-types-assigned-targeting-options list" [
  advertiser_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` Examples: * AssignedTargetingOption with ID 123456 `assignedTargetingOptionId="123456"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `5000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListAdvertiserAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns a targeting option to an advertiser. Returns the assigned targeting option if successful.
#
# POST /v2/advertisers/{advertiserId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.targetingTypes.assignedTargetingOptions.create
# --ageRangeDetails shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
# --appCategoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --appDetails shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
# --audienceGroupDetails shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
# --audioContentTypeDetails shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
# --authorizedSellerStatusDetails shape: {targetingOptionId?: string}
# --browserDetails shape: {negative?: bool, targetingOptionId?: string}
# --businessChainDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --carrierAndIspDetails shape: {negative?: bool, targetingOptionId?: string}
# --categoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --channelDetails shape: {channelId?: string, negative?: bool}
# --contentDurationDetails shape: {targetingOptionId?: string}
# --contentGenreDetails shape: {negative?: bool, targetingOptionId?: string}
# --contentInstreamPositionDetails shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
# --contentOutstreamPositionDetails shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
# --contentStreamTypeDetails shape: {targetingOptionId?: string}
# --dayAndTimeDetails shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
# --deviceMakeModelDetails shape: {negative?: bool, targetingOptionId?: string}
# --deviceTypeDetails shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
# --digitalContentLabelExclusionDetails shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
# --environmentDetails shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
# --exchangeDetails shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
# --genderDetails shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
# --geoRegionDetails shape: {negative?: bool, targetingOptionId?: string}
# --householdIncomeDetails shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
# --inventorySourceDetails shape: {inventorySourceId?: string}
# --inventorySourceGroupDetails shape: {inventorySourceGroupId?: string}
# --keywordDetails shape: {keyword?: string, negative?: bool}
# --languageDetails shape: {negative?: bool, targetingOptionId?: string}
# --nativeContentPositionDetails shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
# --negativeKeywordListDetails shape: {negativeKeywordListId?: string}
# --omidDetails shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
# --onScreenPositionDetails shape: {targetingOptionId?: string}
# --operatingSystemDetails shape: {negative?: bool, targetingOptionId?: string}
# --parentalStatusDetails shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
# --poiDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --proximityLocationListDetails shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
# --regionalLocationListDetails shape: {negative?: bool, regionalLocationListId?: string}
# --sensitiveCategoryExclusionDetails shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
# --sessionPositionDetails shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
# --subExchangeDetails shape: {targetingOptionId?: string}
# --thirdPartyVerifierDetails shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
# --urlDetails shape: {negative?: bool, url?: string}
# --userRewardedContentDetails shape: {targetingOptionId?: string}
# --videoPlayerSizeDetails shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
# --viewabilityDetails shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
# --youtubeChannelDetails shape: {channelId?: string, negative?: bool}
# --youtubeVideoDetails shape: {negative?: bool, videoId?: string}
export def "advertisers-targeting-types-assigned-targeting-options create" [
  advertiser_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --age-range-details: record # Represents a targetable age range. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AGE_RANGE`. — shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
  --app-category-details: record # Details for assigned app category targeting option. This will be populated in the app_category_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --app-details: record # Details for assigned app targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP`. — shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
  --audience-group-details: record # Assigned audience group targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUDIENCE_GROUP`. The relation between each group is UNION, except for excluded_first_and_third_party_audience_group and excluded_google_audience_group, of which COMPLEMENT is used as an INTERSECTION with other groups. — shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
  --audio-content-type-details: record # Details for audio content type assigned targeting option. This will be populated in the audio_content_type_details field when targeting_type is `TARGETING_TYPE_AUDIO_CONTENT_TYPE`. Explicitly targeting all options is not supported. Remove all audio content type targeting options to achieve this effect. — shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
  --authorized-seller-status-details: record # Represents an assigned authorized seller status. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`. — shape: {targetingOptionId?: string}
  --browser-details: record # Details for assigned browser targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BROWSER`. — shape: {negative?: bool, targetingOptionId?: string}
  --business-chain-details: record # Details for assigned Business chain targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BUSINESS_CHAIN`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --carrier-and-isp-details: record # Details for assigned carrier and ISP targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`. — shape: {negative?: bool, targetingOptionId?: string}
  --category-details: record # Assigned category targeting option details. This will be populated in the category_details field when targeting_type is `TARGETING_TYPE_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --channel-details: record # Details for assigned channel targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --content-duration-details: record # Details for content duration assigned targeting option. This will be populated in the content_duration_details field when targeting_type is `TARGETING_TYPE_CONTENT_DURATION`. Explicitly targeting all options is not supported. Remove all content duration targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --content-genre-details: record # Details for content genre assigned targeting option. This will be populated in the content_genre_details field when targeting_type is `TARGETING_TYPE_CONTENT_GENRE`. Explicitly targeting all options is not supported. Remove all content genre targeting options to achieve this effect. — shape: {negative?: bool, targetingOptionId?: string}
  --content-instream-position-details: record # Assigned content instream position targeting option details. This will be populated in the content_instream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`. — shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
  --content-outstream-position-details: record # Assigned content outstream position targeting option details. This will be populated in the content_outstream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`. — shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
  --content-stream-type-details: record # Details for content stream type assigned targeting option. This will be populated in the content_stream_type_details field when targeting_type is `TARGETING_TYPE_CONTENT_STREAM_TYPE`. Explicitly targeting all options is not supported. Remove all content stream type targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --day-and-time-details: record # Representation of a segment of time defined on a specific day of the week and with a start and end time. The time represented by `start_hour` must be before the time represented by `end_hour`. — shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
  --device-make-model-details: record # Assigned device make and model targeting option details. This will be populated in the device_make_model_details field when targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`. — shape: {negative?: bool, targetingOptionId?: string}
  --device-type-details: record # Targeting details for device type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`. — shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
  --digital-content-label-exclusion-details: record # Targeting details for digital content label. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`. — shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
  --environment-details: record # Assigned environment targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_ENVIRONMENT`. — shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
  --exchange-details: record # Details for assigned exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_EXCHANGE`. — shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
  --gender-details: record # Details for assigned gender targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GENDER`. — shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
  --geo-region-details: record # Details for assigned geographic region targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GEO_REGION`. — shape: {negative?: bool, targetingOptionId?: string}
  --household-income-details: record # Details for assigned household income targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`. — shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
  --inventory-source-details: record # Targeting details for inventory source. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE`. — shape: {inventorySourceId?: string}
  --inventory-source-group-details: record # Targeting details for inventory source group. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`. — shape: {inventorySourceGroupId?: string}
  --keyword-details: record # Details for assigned keyword targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_KEYWORD`. — shape: {keyword?: string, negative?: bool}
  --language-details: record # Details for assigned language targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_LANGUAGE`. — shape: {negative?: bool, targetingOptionId?: string}
  --native-content-position-details: record # Details for native content position assigned targeting option. This will be populated in the native_content_position_details field when targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`. Explicitly targeting all options is not supported. Remove all native content position targeting options to achieve this effect. — shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
  --negative-keyword-list-details: record # Targeting details for negative keyword list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`. — shape: {negativeKeywordListId?: string}
  --omid-details: record # Represents a targetable Open Measurement enabled inventory type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_OMID`. — shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
  --on-screen-position-details: record # On screen position targeting option details. This will be populated in the on_screen_position_details field when targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`. — shape: {targetingOptionId?: string}
  --operating-system-details: record # Assigned operating system targeting option details. This will be populated in the operating_system_details field when targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`. — shape: {negative?: bool, targetingOptionId?: string}
  --parental-status-details: record # Details for assigned parental status targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PARENTAL_STATUS`. — shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
  --poi-details: record # Details for assigned POI targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_POI`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --proximity-location-list-details: record # Targeting details for proximity location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`. — shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
  --regional-location-list-details: record # Targeting details for regional location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_REGIONAL_LOCATION_LIST`. — shape: {negative?: bool, regionalLocationListId?: string}
  --sensitive-category-exclusion-details: record # Targeting details for sensitive category. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`. — shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
  --session-position-details: record # Details for session position assigned targeting option. This will be populated in the session_position_details field when targeting_type is `TARGETING_TYPE_SESSION_POSITION`. — shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
  --sub-exchange-details: record # Details for assigned sub-exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`. — shape: {targetingOptionId?: string}
  --third-party-verifier-details: record # Assigned third party verifier targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_THIRD_PARTY_VERIFIER`. — shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
  --url-details: record # Details for assigned URL targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_URL`. — shape: {negative?: bool, url?: string}
  --user-rewarded-content-details: record # User rewarded content targeting option details. This will be populated in the user_rewarded_content_details field when targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`. — shape: {targetingOptionId?: string}
  --video-player-size-details: record # Video player size targeting option details. This will be populated in the video_player_size_details field when targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`. Explicitly targeting all options is not supported. Remove all video player size targeting options to achieve this effect. — shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
  --viewability-details: record # Assigned viewability targeting option details. This will be populated in the viewability_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_VIEWABILITY`. — shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
  --youtube-channel-details: record # Details for YouTube channel assigned targeting option. This will be populated in the youtube_channel_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --youtube-video-details: record # Details for YouTube video assigned targeting option. This will be populated in the youtube_video_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_VIDEO`. — shape: {negative?: bool, videoId?: string}
]: any -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let req_body = {"ageRangeDetails": $age_range_details, "appCategoryDetails": $app_category_details, "appDetails": $app_details, "audienceGroupDetails": $audience_group_details, "audioContentTypeDetails": $audio_content_type_details, "authorizedSellerStatusDetails": $authorized_seller_status_details, "browserDetails": $browser_details, "businessChainDetails": $business_chain_details, "carrierAndIspDetails": $carrier_and_isp_details, "categoryDetails": $category_details, "channelDetails": $channel_details, "contentDurationDetails": $content_duration_details, "contentGenreDetails": $content_genre_details, "contentInstreamPositionDetails": $content_instream_position_details, "contentOutstreamPositionDetails": $content_outstream_position_details, "contentStreamTypeDetails": $content_stream_type_details, "dayAndTimeDetails": $day_and_time_details, "deviceMakeModelDetails": $device_make_model_details, "deviceTypeDetails": $device_type_details, "digitalContentLabelExclusionDetails": $digital_content_label_exclusion_details, "environmentDetails": $environment_details, "exchangeDetails": $exchange_details, "genderDetails": $gender_details, "geoRegionDetails": $geo_region_details, "householdIncomeDetails": $household_income_details, "inventorySourceDetails": $inventory_source_details, "inventorySourceGroupDetails": $inventory_source_group_details, "keywordDetails": $keyword_details, "languageDetails": $language_details, "nativeContentPositionDetails": $native_content_position_details, "negativeKeywordListDetails": $negative_keyword_list_details, "omidDetails": $omid_details, "onScreenPositionDetails": $on_screen_position_details, "operatingSystemDetails": $operating_system_details, "parentalStatusDetails": $parental_status_details, "poiDetails": $poi_details, "proximityLocationListDetails": $proximity_location_list_details, "regionalLocationListDetails": $regional_location_list_details, "sensitiveCategoryExclusionDetails": $sensitive_category_exclusion_details, "sessionPositionDetails": $session_position_details, "subExchangeDetails": $sub_exchange_details, "thirdPartyVerifierDetails": $third_party_verifier_details, "urlDetails": $url_details, "userRewardedContentDetails": $user_rewarded_content_details, "videoPlayerSizeDetails": $video_player_size_details, "viewabilityDetails": $viewability_details, "youtubeChannelDetails": $youtube_channel_details, "youtubeVideoDetails": $youtube_video_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an assigned targeting option from an advertiser.
#
# DELETE /v2/advertisers/{advertiserId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.targetingTypes.assignedTargetingOptions.delete
export def "advertisers-targeting-types-assigned-targeting-options delete" [
  advertiser_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to an advertiser.
#
# GET /v2/advertisers/{advertiserId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.targetingTypes.assignedTargetingOptions.get
export def "advertisers-targeting-types-assigned-targeting-options get" [
  advertiser_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists YouTube ad group ads.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroupAds
# operationId: displayvideo.advertisers.youtubeAdGroupAds.list
export def "advertisers-youtube-ad-group-ads list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by custom YouTube ad group ad fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` and `OR`. Only the restrictions for * the same field can be combined by `OR`. A sequence of restrictions * implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported properties: - `adGroupId` - `displayName` - `entityStatus` - `adGroupAdId` Examples: * All ad group ads under an ad group: `adGroupId="1234"` and its * entityStatus is `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED`: `(entityStatus="ENTITY_STATUS_ACTIVE" OR entityStatus="ENTITY_STATUS_PAUSED") AND adGroupId="12345"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `entityStatus` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `100`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListYoutubeAdGroupAds` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, youtubeAdGroupAds: table<adGroupAdId: string, adGroupId: string, adUrls: list, advertiserId: string, audioAd: record, bumperAd: record, displayName: string, displayVideoSourceAd: record, entityStatus: string, inStreamAd: record, mastheadAd: record, name: string, nonSkippableAd: record, videoDiscoverAd: record, videoPerformanceAd: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroupAds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a YouTube ad group ad.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroupAds/{youtubeAdGroupAdId}
# operationId: displayvideo.advertisers.youtubeAdGroupAds.get
export def "advertisers-youtube-ad-group-ads get" [
  advertiser_id: string
  youtube_ad_group_ad_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<adGroupAdId: string, adGroupId: string, adUrls: table<type: string, url: string>, advertiserId: string, audioAd: record<displayUrl: string, finalUrl: string, trackingUrl: string, video: record<id: string, unavailableReason: string>>, bumperAd: record<commonInStreamAttribute: record<actionButtonLabel: string, actionHeadline: string, companionBanner: record, displayUrl: string, finalUrl: string, trackingUrl: string, video: record>>, displayName: string, displayVideoSourceAd: record<creativeId: string>, entityStatus: string, inStreamAd: record<commonInStreamAttribute: record<actionButtonLabel: string, actionHeadline: string, companionBanner: record, displayUrl: string, finalUrl: string, trackingUrl: string, video: record>, customParameters: record>, mastheadAd: record<autoplayVideoDuration: string, autoplayVideoStartMillisecond: string, callToActionButtonLabel: string, callToActionFinalUrl: string, callToActionTrackingUrl: string, companionYoutubeVideos: list<record>, description: string, headline: string, showChannelArt: bool, video: record<id: string, unavailableReason: string>, videoAspectRatio: string>, name: string, nonSkippableAd: record<commonInStreamAttribute: record<actionButtonLabel: string, actionHeadline: string, companionBanner: record, displayUrl: string, finalUrl: string, trackingUrl: string, video: record>, customParameters: record>, videoDiscoverAd: record<description1: string, description2: string, headline: string, thumbnail: string, video: record<id: string, unavailableReason: string>>, videoPerformanceAd: record<actionButtonLabels: list<string>, companionBanners: list<record>, customParameters: record, descriptions: list<string>, displayUrlBreadcrumb1: string, displayUrlBreadcrumb2: string, domain: string, finalUrl: string, headlines: list<string>, longHeadlines: list<string>, trackingUrl: string, videos: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), youtube_ad_group_ad_id: (encode-path-segment $youtube_ad_group_ad_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroupAds/{youtube_ad_group_ad_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists YouTube ad groups.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroups
# operationId: displayvideo.advertisers.youtubeAdGroups.list
export def "advertisers-youtube-ad-groups list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by custom YouTube ad group fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` and `OR`. Only the restrictions for * the same field can be combined by `OR`. A sequence of restrictions * implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported properties: - `adGroupId` - `displayName` - `entityStatus` - `lineItemId` - `adGroupFormat` Examples: * All ad groups under an line item: `lineItemId="1234"` * All `ENTITY_STATUS_ACTIVE` or `ENTITY_STATUS_PAUSED` and `YOUTUBE_AND_PARTNERS_AD_GROUP_FORMAT_IN_STREAM` ad groups under an advertiser: `(entityStatus="ENTITY_STATUS_ACTIVE" OR entityStatus="ENTITY_STATUS_PAUSED") AND adGroupFormat="YOUTUBE_AND_PARTNERS_AD_GROUP_FORMAT_IN_STREAM"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `entityStatus` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListYoutubeAdGroups` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, youtubeAdGroups: table<adGroupFormat: string, adGroupId: string, advertiserId: string, biddingStrategy: record, displayName: string, entityStatus: string, lineItemId: string, name: string, productFeedData: record, targetingExpansion: record, youtubeAdIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a YouTube ad group.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroups/{youtubeAdGroupId}
# operationId: displayvideo.advertisers.youtubeAdGroups.get
export def "advertisers-youtube-ad-groups get" [
  advertiser_id: string
  youtube_ad_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<adGroupFormat: string, adGroupId: string, advertiserId: string, biddingStrategy: record<adGroupEffectiveTargetCpaSource: string, adGroupEffectiveTargetCpaValue: string, type: string, value: string>, displayName: string, entityStatus: string, lineItemId: string, name: string, productFeedData: record<isFeedDisabled: bool, productMatchDimensions: list<record>, productMatchType: string>, targetingExpansion: record<excludeFirstPartyAudience: bool, targetingExpansionLevel: string>, youtubeAdIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), youtube_ad_group_id: (encode-path-segment $youtube_ad_group_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroups/{youtube_ad_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the targeting options assigned to a YouTube ad group. Inherited assigned targeting options are not included.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroups/{youtubeAdGroupId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.advertisers.youtubeAdGroups.targetingTypes.assignedTargetingOptions.list
export def "advertisers-youtube-ad-groups-targeting-types-assigned-targeting-options list" [
  advertiser_id: string
  youtube_ad_group_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` Examples: * AssignedTargetingOptions with ID 1 or 2 `assignedTargetingOptionId="1" OR assignedTargetingOptionId="2"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `5000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListYoutubeAdGroupAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), youtube_ad_group_id: (encode-path-segment $youtube_ad_group_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroups/{youtube_ad_group_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to a YouTube ad group. Inherited assigned targeting options are not included.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroups/{youtubeAdGroupId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.advertisers.youtubeAdGroups.targetingTypes.assignedTargetingOptions.get
export def "advertisers-youtube-ad-groups-targeting-types-assigned-targeting-options get" [
  advertiser_id: string
  youtube_ad_group_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id), youtube_ad_group_id: (encode-path-segment $youtube_ad_group_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroups/{youtube_ad_group_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists assigned targeting options for multiple YouTube ad groups across targeting types. Inherieted assigned targeting options are not included.
#
# GET /v2/advertisers/{advertiserId}/youtubeAdGroups:bulkListAdGroupAssignedTargetingOptions
# operationId: displayvideo.advertisers.youtubeAdGroups.bulkListAdGroupAssignedTargetingOptions
export def "advertisers-youtube-ad-groups-bulk-list-ad-group-assigned-targeting-options list" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR` on the same field. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `targetingType` Examples: * AssignedTargetingOptions of targeting type TARGETING_TYPE_YOUTUBE_VIDEO or TARGETING_TYPE_YOUTUBE_CHANNEL `targetingType="TARGETING_TYPE_YOUTUBE_VIDEO" OR targetingType="TARGETING_TYPE_YOUTUBE_CHANNEL"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `youtubeAdGroupId` (default) * `assignedTargetingOption.targetingType` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingType desc`.
  --page-size: int # Requested page size. The size must be an integer between `1` and `5000`. If unspecified, the default is `5000`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token that lets the client fetch the next page of results. Typically, this is the value of next_page_token returned from the previous call to the `BulkListAdGroupAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
  --youtube-ad-group-ids: list<string> # Required. The IDs of the youtube ad groups to list assigned targeting options for.
]: nothing -> record<nextPageToken: string, youtubeAdGroupAssignedTargetingOptions: table<assignedTargetingOption: record, youtubeAdGroupId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "youtubeAdGroupIds" $youtube_ad_group_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}/youtubeAdGroups:bulkListAdGroupAssignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Audits an advertiser. Returns the counts of used entities per resource type under the advertiser provided. Used entities count towards their respective resource limit. See https://support.google.com/displayvideo/answer/6071450.
#
# GET /v2/advertisers/{advertiserId}:audit
# operationId: displayvideo.advertisers.audit
export def "advertisers get-audit" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --read-mask: string # Optional. The specific fields to return. If no mask is specified, all fields in the response proto will be filled. Valid values are: * usedLineItemsCount * usedInsertionOrdersCount * usedCampaignsCount * channelsCount * negativelyTargetedChannelsCount * negativeKeywordListsCount * adGroupCriteriaCount * campaignCriteriaCount
]: nothing -> record<adGroupCriteriaCount: string, campaignCriteriaCount: string, channelsCount: string, negativeKeywordListsCount: string, negativelyTargetedChannelsCount: string, usedCampaignsCount: string, usedInsertionOrdersCount: string, usedLineItemsCount: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "readMask" $read_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}:audit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edits targeting options under a single advertiser. The operation will delete the assigned targeting options provided in BulkEditAdvertiserAssignedTargetingOptionsRequest.delete_requests and then create the assigned targeting options provided in BulkEditAdvertiserAssignedTargetingOptionsRequest.create_requests .
#
# POST /v2/advertisers/{advertiserId}:editAssignedTargetingOptions
# operationId: displayvideo.advertisers.editAssignedTargetingOptions
# --createRequests item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
# --deleteRequests item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
export def "advertisers create-edit-assigned-targeting-options" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --create-requests: list # The assigned targeting options to create in batch, specified as a list of `CreateAssignedTargetingOptionsRequest`. Supported targeting types: * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_OMID` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` — item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
  --delete-requests: list # The assigned targeting options to delete in batch, specified as a list of `DeleteAssignedTargetingOptionsRequest`. Supported targeting types: * `TARGETING_TYPE_CHANNEL` * `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION` * `TARGETING_TYPE_OMID` * `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION` — item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
]: any -> record<createdAssignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}:editAssignedTargetingOptions") $qp)
  let req_body = {"createRequests": $create_requests, "deleteRequests": $delete_requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists assigned targeting options of an advertiser across targeting types.
#
# GET /v2/advertisers/{advertiserId}:listAssignedTargetingOptions
# operationId: displayvideo.advertisers.listAssignedTargetingOptions
export def "advertisers list-assigned-targeting-options" [
  advertiser_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`.. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `targetingType` Examples: * targetingType with value TARGETING_TYPE_CHANNEL `targetingType="TARGETING_TYPE_CHANNEL"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `targetingType` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingType desc`.
  --page-size: int # Requested page size. The size must be an integer between `1` and `5000`. If unspecified, the default is '5000'. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token that lets the client fetch the next page of results. Typically, this is the value of next_page_token returned from the previous call to `BulkListAdvertiserAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({advertiser_id: (encode-path-segment $advertiser_id)} | format pattern "/v2/advertisers/{advertiser_id}:listAssignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists combined audiences. The order is defined by the order_by parameter.
#
# GET /v2/combinedAudiences
# operationId: displayvideo.combinedAudiences.list
export def "combined-audiences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched combined audiences.
  --filter: string # Allows filtering by combined audience fields. Supported syntax: * Filter expressions for combined audiences currently can only contain at most one restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All combined audiences for which the display name contains "Google": `displayName : "Google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `combinedAudienceId` (default) * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCombinedAudiences` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the fetched combined audiences.
]: nothing -> record<combinedAudiences: table<combinedAudienceId: string, displayName: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/combinedAudiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a combined audience.
#
# GET /v2/combinedAudiences/{combinedAudienceId}
# operationId: displayvideo.combinedAudiences.get
export def "combined-audiences get" [
  combined_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched combined audience.
  --partner-id: string # The ID of the partner that has access to the fetched combined audience.
]: nothing -> record<combinedAudienceId: string, displayName: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({combined_audience_id: (encode-path-segment $combined_audience_id)} | format pattern "/v2/combinedAudiences/{combined_audience_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists custom bidding algorithms that are accessible to the current user and can be used in bidding stratgies. The order is defined by the order_by parameter.
#
# GET /v2/customBiddingAlgorithms
# operationId: displayvideo.customBiddingAlgorithms.list
export def "custom-bidding-algorithms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the DV360 advertiser that has access to the custom bidding algorithm.
  --filter: string # Allows filtering by custom bidding algorithm fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND`. A sequence of restrictions * implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)` or `EQUALS (=)`. * The operator must be `CONTAINS (:)` for the following field: - `displayName` * The operator must be `EQUALS (=)` for the following field: - `customBiddingAlgorithmType` * For `displayName`, the value is a string. We return all custom bidding algorithms whose display_name contains such string. * For `customBiddingAlgorithmType`, the value is a string. We return all algorithms whose custom_bidding_algorithm_type is equal to the given type. Examples: * All custom bidding algorithms for which the display name contains "politics": `displayName:politics`. * All custom bidding algorithms for which the type is "SCRIPT_BASED": `customBiddingAlgorithmType=SCRIPT_BASED` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCustomBiddingAlgorithms` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the DV360 partner that has access to the custom bidding algorithm.
]: nothing -> record<customBiddingAlgorithms: table<advertiserId: string, customBiddingAlgorithmId: string, customBiddingAlgorithmType: string, displayName: string, entityStatus: string, modelDetails: list, name: string, partnerId: string, sharedAdvertiserIds: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customBiddingAlgorithms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new custom bidding algorithm. Returns the newly created custom bidding algorithm if successful.
#
# POST /v2/customBiddingAlgorithms
# operationId: displayvideo.customBiddingAlgorithms.create
# --modelDetails item shape: {advertiserId?: string, readinessState?: "READINESS_STATE_UNSPECIFIED"|"READINESS_STATE_ACTIVE"|"READINESS_STATE_INSUFFICIENT_DATA"|"READINESS_STATE_TRAINING"|"READINESS_STATE_NO_VALID_SCRIPT"}
export def "custom-bidding-algorithms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Immutable. The unique ID of the advertiser that owns the custom bidding algorithm. (format: int64)
  --custom-bidding-algorithm-type: string@custom-bidding-algorithm-type-completer # Required. Immutable. The type of custom bidding algorithm.
  --display-name: string # Required. The display name of the custom bidding algorithm. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Controls whether or not the custom bidding algorithm can be used as a bidding strategy. Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED`
  --partner-id: string # Immutable. The unique ID of the partner that owns the custom bidding algorithm. (format: int64)
  --shared-advertiser-ids: list<string> # The IDs of the advertisers who have access to this algorithm. If advertiser_id is set, this field will only consist of that value. This field will not be set if the algorithm [`owner`](/display-video/api/reference/rest/v1/customBiddingAlgorithms#CustomBiddingAlgorithm.FIELDS.oneof_owner) is a partner and is being retrieved using an advertiser [`accessor`](/display-video/api/reference/rest/v1/customBiddingAlgorithms/list#body.QUERY_PARAMETERS.oneof_accessor).
]: any -> record<advertiserId: string, customBiddingAlgorithmId: string, customBiddingAlgorithmType: string, displayName: string, entityStatus: string, modelDetails: table<advertiserId: string, readinessState: string, suspensionState: string>, name: string, partnerId: string, sharedAdvertiserIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customBiddingAlgorithms" $qp)
  let req_body = {"advertiserId": $advertiser_id, "customBiddingAlgorithmType": $custom_bidding_algorithm_type, "displayName": $display_name, "entityStatus": $entity_status, "partnerId": $partner_id, "sharedAdvertiserIds": $shared_advertiser_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a custom bidding algorithm.
#
# GET /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}
# operationId: displayvideo.customBiddingAlgorithms.get
export def "custom-bidding-algorithms get" [
  custom_bidding_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the DV360 partner that has access to the custom bidding algorithm.
  --partner-id: string # The ID of the DV360 partner that has access to the custom bidding algorithm.
]: nothing -> record<advertiserId: string, customBiddingAlgorithmId: string, customBiddingAlgorithmType: string, displayName: string, entityStatus: string, modelDetails: table<advertiserId: string, readinessState: string, suspensionState: string>, name: string, partnerId: string, sharedAdvertiserIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing custom bidding algorithm. Returns the updated custom bidding algorithm if successful.
#
# PATCH /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}
# operationId: displayvideo.customBiddingAlgorithms.patch
# --modelDetails item shape: {advertiserId?: string, readinessState?: "READINESS_STATE_UNSPECIFIED"|"READINESS_STATE_ACTIVE"|"READINESS_STATE_INSUFFICIENT_DATA"|"READINESS_STATE_TRAINING"|"READINESS_STATE_NO_VALID_SCRIPT"}
export def "custom-bidding-algorithms update" [
  custom_bidding_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --advertiser-id: string # Immutable. The unique ID of the advertiser that owns the custom bidding algorithm. (format: int64)
  --custom-bidding-algorithm-type: string@custom-bidding-algorithm-type-completer # Required. Immutable. The type of custom bidding algorithm.
  --display-name: string # Required. The display name of the custom bidding algorithm. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --entity-status: string@entity-status-completer # Controls whether or not the custom bidding algorithm can be used as a bidding strategy. Accepted values are: * `ENTITY_STATUS_ACTIVE` * `ENTITY_STATUS_ARCHIVED`
  --partner-id: string # Immutable. The unique ID of the partner that owns the custom bidding algorithm. (format: int64)
  --shared-advertiser-ids: list<string> # The IDs of the advertisers who have access to this algorithm. If advertiser_id is set, this field will only consist of that value. This field will not be set if the algorithm [`owner`](/display-video/api/reference/rest/v1/customBiddingAlgorithms#CustomBiddingAlgorithm.FIELDS.oneof_owner) is a partner and is being retrieved using an advertiser [`accessor`](/display-video/api/reference/rest/v1/customBiddingAlgorithms/list#body.QUERY_PARAMETERS.oneof_accessor).
]: any -> record<advertiserId: string, customBiddingAlgorithmId: string, customBiddingAlgorithmType: string, displayName: string, entityStatus: string, modelDetails: table<advertiserId: string, readinessState: string, suspensionState: string>, name: string, partnerId: string, sharedAdvertiserIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}") $qp)
  let req_body = {"advertiserId": $advertiser_id, "customBiddingAlgorithmType": $custom_bidding_algorithm_type, "displayName": $display_name, "entityStatus": $entity_status, "partnerId": $partner_id, "sharedAdvertiserIds": $shared_advertiser_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists custom bidding scripts that belong to the given algorithm. The order is defined by the order_by parameter.
#
# GET /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}/scripts
# operationId: displayvideo.customBiddingAlgorithms.scripts.list
export def "custom-bidding-algorithms-scripts list" [
  custom_bidding_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent custom bidding algorithm.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `createTime desc` (default) The default sorting order is descending. To specify ascending order for a field, the suffix "desc" should be removed. Example: `createTime`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCustomBiddingScripts` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that owns the parent custom bidding algorithm. Only this partner will have write access to this custom bidding script.
]: nothing -> record<customBiddingScripts: table<active: bool, createTime: string, customBiddingAlgorithmId: string, customBiddingScriptId: string, errors: list, name: string, script: record, state: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}/scripts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new custom bidding script. Returns the newly created script if successful.
#
# POST /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}/scripts
# operationId: displayvideo.customBiddingAlgorithms.scripts.create
# --errors item shape: {column?: string, errorCode?: "ERROR_CODE_UNSPECIFIED"|"SYNTAX_ERROR"|"DEPRECATED_SYNTAX"|"INTERNAL_ERROR", errorMessage?: string, line?: string}
# --script shape: {resourceName?: string}
export def "custom-bidding-algorithms-scripts create" [
  custom_bidding_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent custom bidding algorithm.
  --partner-id: string # The ID of the partner that owns the parent custom bidding algorithm. Only this partner will have write access to this custom bidding script.
  --script: record # The reference to the uploaded custom bidding script file. — shape: {resourceName?: string}
]: any -> record<active: bool, createTime: string, customBiddingAlgorithmId: string, customBiddingScriptId: string, errors: table<column: string, errorCode: string, errorMessage: string, line: string>, name: string, script: record<resourceName: string>, state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}/scripts") $qp)
  let req_body = {"script": $script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a custom bidding script.
#
# GET /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}/scripts/{customBiddingScriptId}
# operationId: displayvideo.customBiddingAlgorithms.scripts.get
export def "custom-bidding-algorithms-scripts get" [
  custom_bidding_algorithm_id: string
  custom_bidding_script_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent custom bidding algorithm.
  --partner-id: string # The ID of the partner that owns the parent custom bidding algorithm. Only this partner will have write access to this custom bidding script.
]: nothing -> record<active: bool, createTime: string, customBiddingAlgorithmId: string, customBiddingScriptId: string, errors: table<column: string, errorCode: string, errorMessage: string, line: string>, name: string, script: record<resourceName: string>, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id), custom_bidding_script_id: (encode-path-segment $custom_bidding_script_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}/scripts/{custom_bidding_script_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a custom bidding script reference object for a script file. The resulting reference object provides a resource path to which the script file should be uploaded. This reference object should be included in when creating a new custom bidding script object.
#
# GET /v2/customBiddingAlgorithms/{customBiddingAlgorithmId}:uploadScript
# operationId: displayvideo.customBiddingAlgorithms.uploadScript
export def "custom-bidding-algorithms upload-script" [
  custom_bidding_algorithm_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent custom bidding algorithm.
  --partner-id: string # The ID of the partner that owns the parent custom bidding algorithm. Only this partner will have write access to this custom bidding script.
]: nothing -> record<resourceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_bidding_algorithm_id: (encode-path-segment $custom_bidding_algorithm_id)} | format pattern "/v2/customBiddingAlgorithms/{custom_bidding_algorithm_id}:uploadScript") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists custom lists. The order is defined by the order_by parameter.
#
# GET /v2/customLists
# operationId: displayvideo.customLists.list
export def "custom-lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the DV360 advertiser that has access to the fetched custom lists.
  --filter: string # Allows filtering by custom list fields. Supported syntax: * Filter expressions for custom lists currently can only contain at most one restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All custom lists for which the display name contains "Google": `displayName : "Google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `customListId` (default) * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListCustomLists` method. If not specified, the first page of results will be returned.
]: nothing -> record<customLists: table<customListId: string, displayName: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/customLists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a custom list.
#
# GET /v2/customLists/{customListId}
# operationId: displayvideo.customLists.get
export def "custom-lists get" [
  custom_list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the DV360 advertiser that has access to the fetched custom lists.
]: nothing -> record<customListId: string, displayName: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({custom_list_id: (encode-path-segment $custom_list_id)} | format pattern "/v2/customLists/{custom_list_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists first and third party audiences. The order is defined by the order_by parameter.
#
# GET /v2/firstAndThirdPartyAudiences
# operationId: displayvideo.firstAndThirdPartyAudiences.list
export def "first-and-third-party-audiences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched first and third party audiences.
  --filter: string # Allows filtering by first and third party audience fields. Supported syntax: * Filter expressions for first and third party audiences currently can only contain at most one restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All first and third party audiences for which the display name contains "Google": `displayName : "Google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `firstAndThirdPartyAudienceId` (default) * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListFirstAndThirdPartyAudiences` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the fetched first and third party audiences.
]: nothing -> record<firstAndThirdPartyAudiences: table<activeDisplayAudienceSize: string, appId: string, audienceSource: string, audienceType: string, contactInfoList: record, description: string, displayAudienceSize: string, displayDesktopAudienceSize: string, displayMobileAppAudienceSize: string, displayMobileWebAudienceSize: string, displayName: string, firstAndThirdPartyAudienceId: string, firstAndThirdPartyAudienceType: string, gmailAudienceSize: string, membershipDurationDays: string, mobileDeviceIdList: record, name: string, youtubeAudienceSize: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/firstAndThirdPartyAudiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a FirstAndThirdPartyAudience. Only supported for the following audience_type: * `CUSTOMER_MATCH_CONTACT_INFO` * `CUSTOMER_MATCH_DEVICE_ID`
#
# POST /v2/firstAndThirdPartyAudiences
# operationId: displayvideo.firstAndThirdPartyAudiences.create
# --contactInfoList shape: {contactInfos?: list}
# --mobileDeviceIdList shape: {mobileDeviceIds?: list<string>}
export def "first-and-third-party-audiences create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Required. The ID of the advertiser under whom the FirstAndThirdPartyAudience will be created.
  --app-id: string # The app_id matches with the type of the mobile_device_ids being uploaded. Only applicable to audience_type `CUSTOMER_MATCH_DEVICE_ID`
  --audience-type: string@audience-type-completer # The type of the audience.
  --contact-info-list: record # Wrapper message for a list of contact information defining Customer Match audience members. — shape: {contactInfos?: list}
  --description: string # The user-provided description of the audience. Only applicable to first party audiences.
  --display-name: string # The display name of the first and third party audience.
  --first-and-third-party-audience-type: string@first-and-third-party-audience-type-completer # Whether the audience is a first or third party audience.
  --membership-duration-days: string # The duration in days that an entry remains in the audience after the qualifying event. If the audience has no expiration, set the value of this field to 10000. Otherwise, the set value must be greater than 0 and less than or equal to 540. Only applicable to first party audiences. This field is required if one of the following audience_type is used: * `CUSTOMER_MATCH_CONTACT_INFO` * `CUSTOMER_MATCH_DEVICE_ID` (format: int64)
  --mobile-device-id-list: record # Wrapper message for a list of mobile device IDs defining Customer Match audience members. — shape: {mobileDeviceIds?: list<string>}
]: any -> record<activeDisplayAudienceSize: string, appId: string, audienceSource: string, audienceType: string, contactInfoList: record<contactInfos: list<record>>, description: string, displayAudienceSize: string, displayDesktopAudienceSize: string, displayMobileAppAudienceSize: string, displayMobileWebAudienceSize: string, displayName: string, firstAndThirdPartyAudienceId: string, firstAndThirdPartyAudienceType: string, gmailAudienceSize: string, membershipDurationDays: string, mobileDeviceIdList: record<mobileDeviceIds: list<string>>, name: string, youtubeAudienceSize: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/firstAndThirdPartyAudiences" $qp)
  let req_body = {"appId": $app_id, "audienceType": $audience_type, "contactInfoList": $contact_info_list, "description": $description, "displayName": $display_name, "firstAndThirdPartyAudienceType": $first_and_third_party_audience_type, "membershipDurationDays": $membership_duration_days, "mobileDeviceIdList": $mobile_device_id_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a first and third party audience.
#
# GET /v2/firstAndThirdPartyAudiences/{firstAndThirdPartyAudienceId}
# operationId: displayvideo.firstAndThirdPartyAudiences.get
export def "first-and-third-party-audiences get" [
  first_and_third_party_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched first and third party audience.
  --partner-id: string # The ID of the partner that has access to the fetched first and third party audience.
]: nothing -> record<activeDisplayAudienceSize: string, appId: string, audienceSource: string, audienceType: string, contactInfoList: record<contactInfos: list<record>>, description: string, displayAudienceSize: string, displayDesktopAudienceSize: string, displayMobileAppAudienceSize: string, displayMobileWebAudienceSize: string, displayName: string, firstAndThirdPartyAudienceId: string, firstAndThirdPartyAudienceType: string, gmailAudienceSize: string, membershipDurationDays: string, mobileDeviceIdList: record<mobileDeviceIds: list<string>>, name: string, youtubeAudienceSize: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({first_and_third_party_audience_id: (encode-path-segment $first_and_third_party_audience_id)} | format pattern "/v2/firstAndThirdPartyAudiences/{first_and_third_party_audience_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing FirstAndThirdPartyAudience. Only supported for the following audience_type: * `CUSTOMER_MATCH_CONTACT_INFO` * `CUSTOMER_MATCH_DEVICE_ID`
#
# PATCH /v2/firstAndThirdPartyAudiences/{firstAndThirdPartyAudienceId}
# operationId: displayvideo.firstAndThirdPartyAudiences.patch
# --contactInfoList shape: {contactInfos?: list}
# --mobileDeviceIdList shape: {mobileDeviceIds?: list<string>}
export def "first-and-third-party-audiences update" [
  first_and_third_party_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Required. The ID of the owner advertiser of the updated FirstAndThirdPartyAudience.
  --update-mask: string # Required. The mask to control which fields to update. Updates are only supported for the following fields: * `displayName` * `description` * `membershipDurationDays`
  --app-id: string # The app_id matches with the type of the mobile_device_ids being uploaded. Only applicable to audience_type `CUSTOMER_MATCH_DEVICE_ID`
  --audience-type: string@audience-type-completer # The type of the audience.
  --contact-info-list: record # Wrapper message for a list of contact information defining Customer Match audience members. — shape: {contactInfos?: list}
  --description: string # The user-provided description of the audience. Only applicable to first party audiences.
  --display-name: string # The display name of the first and third party audience.
  --first-and-third-party-audience-type: string@first-and-third-party-audience-type-completer # Whether the audience is a first or third party audience.
  --membership-duration-days: string # The duration in days that an entry remains in the audience after the qualifying event. If the audience has no expiration, set the value of this field to 10000. Otherwise, the set value must be greater than 0 and less than or equal to 540. Only applicable to first party audiences. This field is required if one of the following audience_type is used: * `CUSTOMER_MATCH_CONTACT_INFO` * `CUSTOMER_MATCH_DEVICE_ID` (format: int64)
  --mobile-device-id-list: record # Wrapper message for a list of mobile device IDs defining Customer Match audience members. — shape: {mobileDeviceIds?: list<string>}
]: any -> record<activeDisplayAudienceSize: string, appId: string, audienceSource: string, audienceType: string, contactInfoList: record<contactInfos: list<record>>, description: string, displayAudienceSize: string, displayDesktopAudienceSize: string, displayMobileAppAudienceSize: string, displayMobileWebAudienceSize: string, displayName: string, firstAndThirdPartyAudienceId: string, firstAndThirdPartyAudienceType: string, gmailAudienceSize: string, membershipDurationDays: string, mobileDeviceIdList: record<mobileDeviceIds: list<string>>, name: string, youtubeAudienceSize: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({first_and_third_party_audience_id: (encode-path-segment $first_and_third_party_audience_id)} | format pattern "/v2/firstAndThirdPartyAudiences/{first_and_third_party_audience_id}") $qp)
  let req_body = {"appId": $app_id, "audienceType": $audience_type, "contactInfoList": $contact_info_list, "description": $description, "displayName": $display_name, "firstAndThirdPartyAudienceType": $first_and_third_party_audience_type, "membershipDurationDays": $membership_duration_days, "mobileDeviceIdList": $mobile_device_id_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates the member list of a Customer Match audience. Only supported for the following audience_type: * `CUSTOMER_MATCH_CONTACT_INFO` * `CUSTOMER_MATCH_DEVICE_ID`
#
# POST /v2/firstAndThirdPartyAudiences/{firstAndThirdPartyAudienceId}:editCustomerMatchMembers
# operationId: displayvideo.firstAndThirdPartyAudiences.editCustomerMatchMembers
# --addedContactInfoList shape: {contactInfos?: list}
# --addedMobileDeviceIdList shape: {mobileDeviceIds?: list<string>}
export def "first-and-third-party-audiences create-edit-customer-match-members" [
  first_and_third_party_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --added-contact-info-list: record # Wrapper message for a list of contact information defining Customer Match audience members. — shape: {contactInfos?: list}
  --added-mobile-device-id-list: record # Wrapper message for a list of mobile device IDs defining Customer Match audience members. — shape: {mobileDeviceIds?: list<string>}
  --advertiser-id: string # Required. The ID of the owner advertiser of the updated Customer Match FirstAndThirdPartyAudience. (format: int64)
]: any -> record<firstAndThirdPartyAudienceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({first_and_third_party_audience_id: (encode-path-segment $first_and_third_party_audience_id)} | format pattern "/v2/firstAndThirdPartyAudiences/{first_and_third_party_audience_id}:editCustomerMatchMembers") $qp)
  let req_body = {"addedContactInfoList": $added_contact_info_list, "addedMobileDeviceIdList": $added_mobile_device_id_list, "advertiserId": $advertiser_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a Floodlight group.
#
# GET /v2/floodlightGroups/{floodlightGroupId}
# operationId: displayvideo.floodlightGroups.get
export def "floodlight-groups get" [
  floodlight_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --partner-id: string # Required. The partner context by which the Floodlight group is being accessed.
]: nothing -> record<activeViewConfig: record<displayName: string, minimumDuration: string, minimumQuartile: string, minimumViewability: string, minimumVolume: string>, customVariables: record, displayName: string, floodlightGroupId: string, lookbackWindow: record<clickDays: int, impressionDays: int>, name: string, webTagType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({floodlight_group_id: (encode-path-segment $floodlight_group_id)} | format pattern "/v2/floodlightGroups/{floodlight_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Google audiences. The order is defined by the order_by parameter.
#
# GET /v2/googleAudiences
# operationId: displayvideo.googleAudiences.list
export def "google-audiences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched Google audiences.
  --filter: string # Allows filtering by Google audience fields. Supported syntax: * Filter expressions for Google audiences currently can only contain at most one restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All Google audiences for which the display name contains "Google": `displayName : "Google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `googleAudienceId` (default) * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListGoogleAudiences` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the fetched Google audiences.
]: nothing -> record<googleAudiences: table<displayName: string, googleAudienceId: string, googleAudienceType: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/googleAudiences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a Google audience.
#
# GET /v2/googleAudiences/{googleAudienceId}
# operationId: displayvideo.googleAudiences.get
export def "google-audiences get" [
  google_audience_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the fetched Google audience.
  --partner-id: string # The ID of the partner that has access to the fetched Google audience.
]: nothing -> record<displayName: string, googleAudienceId: string, googleAudienceType: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({google_audience_id: (encode-path-segment $google_audience_id)} | format pattern "/v2/googleAudiences/{google_audience_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists guaranteed orders that are accessible to the current user. The order is defined by the order_by parameter. If a filter by entity_status is not specified, guaranteed orders with entity status `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/guaranteedOrders
# operationId: displayvideo.guaranteedOrders.list
export def "guaranteed-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the guaranteed order.
  --filter: string # Allows filtering by guaranteed order properties. * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `guaranteed_order_id` - `exchange` - `display_name` - `status.entityStatus` Examples: * All active guaranteed orders: `status.entityStatus="ENTITY_STATUS_ACTIVE"` * Guaranteed orders belonging to Google Ad Manager or Rubicon exchanges: `exchange="EXCHANGE_GOOGLE_AD_MANAGER" OR exchange="EXCHANGE_RUBICON"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListGuaranteedOrders` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the guaranteed order.
]: nothing -> record<guaranteedOrders: table<defaultAdvertiserId: string, defaultCampaignId: string, displayName: string, exchange: string, guaranteedOrderId: string, legacyGuaranteedOrderId: string, name: string, publisherName: string, readAccessInherited: bool, readAdvertiserIds: list, readWriteAdvertiserId: string, readWritePartnerId: string, status: record, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/guaranteedOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new guaranteed order. Returns the newly created guaranteed order if successful.
#
# POST /v2/guaranteedOrders
# operationId: displayvideo.guaranteedOrders.create
# --status shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
export def "guaranteed-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that the request is being made within.
  --partner-id: string # The ID of the partner that the request is being made within.
  --default-campaign-id: string # The ID of the default campaign that is assigned to the guaranteed order. The default campaign must belong to the default advertiser. (format: int64)
  --display-name: string # Required. The display name of the guaranteed order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --exchange: string@exchange-completer # Required. Immutable. The exchange where the guaranteed order originated.
  --publisher-name: string # Required. The publisher name of the guaranteed order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --read-access-inherited: oneof<nothing, bool> # Whether all advertisers of read_write_partner_id have read access to the guaranteed order. Only applicable if read_write_partner_id is set. If True, overrides read_advertiser_ids.
  --read-advertiser-ids: list<string> # The IDs of advertisers with read access to the guaranteed order. This field must not include the advertiser assigned to read_write_advertiser_id if it is set. All advertisers in this field must belong to read_write_partner_id or the same partner as read_write_advertiser_id.
  --read-write-advertiser-id: string # The advertiser with read/write access to the guaranteed order. This is also the default advertiser of the guaranteed order. (format: int64)
  --read-write-partner-id: string # The partner with read/write access to the guaranteed order. (format: int64)
  --status: record # The status settings of the guaranteed order. — shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
]: any -> record<defaultAdvertiserId: string, defaultCampaignId: string, displayName: string, exchange: string, guaranteedOrderId: string, legacyGuaranteedOrderId: string, name: string, publisherName: string, readAccessInherited: bool, readAdvertiserIds: list<string>, readWriteAdvertiserId: string, readWritePartnerId: string, status: record<configStatus: string, entityPauseReason: string, entityStatus: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/guaranteedOrders" $qp)
  let req_body = {"defaultCampaignId": $default_campaign_id, "displayName": $display_name, "exchange": $exchange, "publisherName": $publisher_name, "readAccessInherited": $read_access_inherited, "readAdvertiserIds": $read_advertiser_ids, "readWriteAdvertiserId": $read_write_advertiser_id, "readWritePartnerId": $read_write_partner_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a guaranteed order.
#
# GET /v2/guaranteedOrders/{guaranteedOrderId}
# operationId: displayvideo.guaranteedOrders.get
export def "guaranteed-orders get" [
  guaranteed_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the guaranteed order.
  --partner-id: string # The ID of the partner that has access to the guaranteed order.
]: nothing -> record<defaultAdvertiserId: string, defaultCampaignId: string, displayName: string, exchange: string, guaranteedOrderId: string, legacyGuaranteedOrderId: string, name: string, publisherName: string, readAccessInherited: bool, readAdvertiserIds: list<string>, readWriteAdvertiserId: string, readWritePartnerId: string, status: record<configStatus: string, entityPauseReason: string, entityStatus: string>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guaranteed_order_id: (encode-path-segment $guaranteed_order_id)} | format pattern "/v2/guaranteedOrders/{guaranteed_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing guaranteed order. Returns the updated guaranteed order if successful.
#
# PATCH /v2/guaranteedOrders/{guaranteedOrderId}
# operationId: displayvideo.guaranteedOrders.patch
# --status shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
export def "guaranteed-orders update" [
  guaranteed_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that the request is being made within.
  --partner-id: string # The ID of the partner that the request is being made within.
  --update-mask: string # Required. The mask to control which fields to update.
  --default-campaign-id: string # The ID of the default campaign that is assigned to the guaranteed order. The default campaign must belong to the default advertiser. (format: int64)
  --display-name: string # Required. The display name of the guaranteed order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --exchange: string@exchange-completer # Required. Immutable. The exchange where the guaranteed order originated.
  --publisher-name: string # Required. The publisher name of the guaranteed order. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --read-access-inherited: oneof<nothing, bool> # Whether all advertisers of read_write_partner_id have read access to the guaranteed order. Only applicable if read_write_partner_id is set. If True, overrides read_advertiser_ids.
  --read-advertiser-ids: list<string> # The IDs of advertisers with read access to the guaranteed order. This field must not include the advertiser assigned to read_write_advertiser_id if it is set. All advertisers in this field must belong to read_write_partner_id or the same partner as read_write_advertiser_id.
  --read-write-advertiser-id: string # The advertiser with read/write access to the guaranteed order. This is also the default advertiser of the guaranteed order. (format: int64)
  --read-write-partner-id: string # The partner with read/write access to the guaranteed order. (format: int64)
  --status: record # The status settings of the guaranteed order. — shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
]: any -> record<defaultAdvertiserId: string, defaultCampaignId: string, displayName: string, exchange: string, guaranteedOrderId: string, legacyGuaranteedOrderId: string, name: string, publisherName: string, readAccessInherited: bool, readAdvertiserIds: list<string>, readWriteAdvertiserId: string, readWritePartnerId: string, status: record<configStatus: string, entityPauseReason: string, entityStatus: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guaranteed_order_id: (encode-path-segment $guaranteed_order_id)} | format pattern "/v2/guaranteedOrders/{guaranteed_order_id}") $qp)
  let req_body = {"defaultCampaignId": $default_campaign_id, "displayName": $display_name, "exchange": $exchange, "publisherName": $publisher_name, "readAccessInherited": $read_access_inherited, "readAdvertiserIds": $read_advertiser_ids, "readWriteAdvertiserId": $read_write_advertiser_id, "readWritePartnerId": $read_write_partner_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Edits read advertisers of a guaranteed order.
#
# POST /v2/guaranteedOrders/{guaranteedOrderId}:editGuaranteedOrderReadAccessors
# operationId: displayvideo.guaranteedOrders.editGuaranteedOrderReadAccessors
export def "guaranteed-orders get-edit-accessors" [
  guaranteed_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --added-advertisers: list<string> # The advertisers to add as read accessors to the guaranteed order.
  --partner-id: string # Required. The partner context in which the change is being made. (format: int64)
  --read-access-inherited: oneof<nothing, bool> # Whether to give all advertisers of the read/write accessor partner read access to the guaranteed order. Only applicable if read_write_partner_id is set in the guaranteed order.
  --removed-advertisers: list<string> # The advertisers to remove as read accessors to the guaranteed order.
]: any -> record<readAccessInherited: bool, readAdvertiserIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guaranteed_order_id: (encode-path-segment $guaranteed_order_id)} | format pattern "/v2/guaranteedOrders/{guaranteed_order_id}:editGuaranteedOrderReadAccessors") $qp)
  let req_body = {"addedAdvertisers": $added_advertisers, "partnerId": $partner_id, "readAccessInherited": $read_access_inherited, "removedAdvertisers": $removed_advertisers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists inventory source groups that are accessible to the current user. The order is defined by the order_by parameter.
#
# GET /v2/inventorySourceGroups
# operationId: displayvideo.inventorySourceGroups.list
export def "inventory-source-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the inventory source group. If an inventory source group is partner-owned, only advertisers to which the group is explicitly shared can access the group.
  --filter: string # Allows filtering by inventory source group properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `inventorySourceGroupId` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `inventorySourceGroupId` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListInventorySources` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the inventory source group. A partner cannot access advertiser-owned inventory source groups.
]: nothing -> record<inventorySourceGroups: table<displayName: string, inventorySourceGroupId: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/inventorySourceGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new inventory source group. Returns the newly created inventory source group if successful.
#
# POST /v2/inventorySourceGroups
# operationId: displayvideo.inventorySourceGroups.create
export def "inventory-source-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the inventory source group. The parent partner will not have access to this group.
  --partner-id: string # The ID of the partner that owns the inventory source group. Only this partner will have write access to this group. Only advertisers to which this group is explicitly shared will have read access to this group.
  --display-name: string # Required. The display name of the inventory source group. Must be UTF-8 encoded with a maximum size of 240 bytes.
]: any -> record<displayName: string, inventorySourceGroupId: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/inventorySourceGroups" $qp)
  let req_body = {"displayName": $display_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an inventory source group.
#
# DELETE /v2/inventorySourceGroups/{inventorySourceGroupId}
# operationId: displayvideo.inventorySourceGroups.delete
export def "inventory-source-groups delete" [
  inventory_source_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the inventory source group. The parent partner does not have access to this group.
  --partner-id: string # The ID of the partner that owns the inventory source group. Only this partner has write access to this group.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an inventory source group.
#
# GET /v2/inventorySourceGroups/{inventorySourceGroupId}
# operationId: displayvideo.inventorySourceGroups.get
export def "inventory-source-groups get" [
  inventory_source_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the inventory source group. If an inventory source group is partner-owned, only advertisers to which the group is explicitly shared can access the group.
  --partner-id: string # The ID of the partner that has access to the inventory source group. A partner cannot access an advertiser-owned inventory source group.
]: nothing -> record<displayName: string, inventorySourceGroupId: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists inventory sources assigned to an inventory source group.
#
# GET /v2/inventorySourceGroups/{inventorySourceGroupId}/assignedInventorySources
# operationId: displayvideo.inventorySourceGroups.assignedInventorySources.list
export def "inventory-source-groups-assigned-inventory-sources list" [
  inventory_source_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the assignment. If the parent inventory source group is partner-owned, only advertisers to which the parent group is explicitly shared can access the assigned inventory source.
  --filter: string # Allows filtering by assigned inventory source fields. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedInventorySourceId` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedInventorySourceId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `assignedInventorySourceId desc`.
  --page-size: int # Requested page size. Must be between `1` and `100`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListAssignedInventorySources` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the assignment. If the parent inventory source group is advertiser-owned, the assignment cannot be accessed via a partner.
]: nothing -> record<assignedInventorySources: table<assignedInventorySourceId: string, inventorySourceId: string, name: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}/assignedInventorySources") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an assignment between an inventory source and an inventory source group.
#
# POST /v2/inventorySourceGroups/{inventorySourceGroupId}/assignedInventorySources
# operationId: displayvideo.inventorySourceGroups.assignedInventorySources.create
export def "inventory-source-groups-assigned-inventory-sources create" [
  inventory_source_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent inventory source group. The parent partner will not have access to this assigned inventory source.
  --partner-id: string # The ID of the partner that owns the parent inventory source group. Only this partner will have write access to this assigned inventory source.
  --inventory-source-id: string # Required. The ID of the inventory source entity being targeted.
]: any -> record<assignedInventorySourceId: string, inventorySourceId: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}/assignedInventorySources") $qp)
  let req_body = {"inventorySourceId": $inventory_source_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes the assignment between an inventory source and an inventory source group.
#
# DELETE /v2/inventorySourceGroups/{inventorySourceGroupId}/assignedInventorySources/{assignedInventorySourceId}
# operationId: displayvideo.inventorySourceGroups.assignedInventorySources.delete
export def "inventory-source-groups-assigned-inventory-sources delete" [
  inventory_source_group_id: string
  assigned_inventory_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent inventory source group. The parent partner does not have access to this assigned inventory source.
  --partner-id: string # The ID of the partner that owns the parent inventory source group. Only this partner has write access to this assigned inventory source.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id), assigned_inventory_source_id: (encode-path-segment $assigned_inventory_source_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}/assignedInventorySources/{assigned_inventory_source_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk edits multiple assignments between inventory sources and a single inventory source group. The operation will delete the assigned inventory sources provided in BulkEditAssignedInventorySourcesRequest.deleted_assigned_inventory_sources and then create the assigned inventory sources provided in BulkEditAssignedInventorySourcesRequest.created_assigned_inventory_sources.
#
# POST /v2/inventorySourceGroups/{inventorySourceGroupId}/assignedInventorySources:bulkEdit
# operationId: displayvideo.inventorySourceGroups.assignedInventorySources.bulkEdit
# --createdAssignedInventorySources item shape: {inventorySourceId?: string}
export def "inventory-source-groups-assigned-inventory-sources-bulk-edit create" [
  inventory_source_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent inventory source group. The parent partner does not have access to these assigned inventory sources. (format: int64)
  --created-assigned-inventory-sources: list # The assigned inventory sources to create in bulk, specified as a list of AssignedInventorySources. — item shape: {inventorySourceId?: string}
  --deleted-assigned-inventory-sources: list<string> # The IDs of the assigned inventory sources to delete in bulk, specified as a list of assigned_inventory_source_ids.
  --partner-id: string # The ID of the partner that owns the inventory source group. Only this partner has write access to these assigned inventory sources. (format: int64)
]: any -> record<assignedInventorySources: table<assignedInventorySourceId: string, inventorySourceId: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_group_id: (encode-path-segment $inventory_source_group_id)} | format pattern "/v2/inventorySourceGroups/{inventory_source_group_id}/assignedInventorySources:bulkEdit") $qp)
  let req_body = {"advertiserId": $advertiser_id, "createdAssignedInventorySources": $created_assigned_inventory_sources, "deletedAssignedInventorySources": $deleted_assigned_inventory_sources, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists inventory sources that are accessible to the current user. The order is defined by the order_by parameter. If a filter by entity_status is not specified, inventory sources with entity status `ENTITY_STATUS_ARCHIVED` will not be included in the results.
#
# GET /v2/inventorySources
# operationId: displayvideo.inventorySources.list
export def "inventory-sources list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that has access to the inventory source.
  --filter: string # Allows filtering by inventory source properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `status.entityStatus` - `commitment` - `deliveryMethod` - `rateDetails.rateType` - `exchange` Examples: * All active inventory sources: `status.entityStatus="ENTITY_STATUS_ACTIVE"` * Inventory sources belonging to Google Ad Manager or Rubicon exchanges: `exchange="EXCHANGE_GOOGLE_AD_MANAGER" OR exchange="EXCHANGE_RUBICON"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListInventorySources` method. If not specified, the first page of results will be returned.
  --partner-id: string # The ID of the partner that has access to the inventory source.
]: nothing -> record<inventorySources: table<commitment: string, creativeConfigs: list, dealId: string, deliveryMethod: string, displayName: string, exchange: string, guaranteedOrderId: string, inventorySourceId: string, inventorySourceProductType: string, inventorySourceType: string, name: string, publisherName: string, rateDetails: record, readAdvertiserIds: list, readPartnerIds: list, readWriteAccessors: record, status: record, subSitePropertyId: string, timeRange: record, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/inventorySources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new inventory source. Returns the newly created inventory source if successful.
#
# POST /v2/inventorySources
# operationId: displayvideo.inventorySources.create
# --creativeConfigs item shape: {creativeType?: "CREATIVE_TYPE_UNSPECIFIED"|"CREATIVE_TYPE_STANDARD"|"CREATIVE_TYPE_EXPANDABLE"|"CREATIVE_TYPE_VIDEO"|"CREATIVE_TYPE_NATIVE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_SITE_SQUARE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL"|"CREATIVE_TYPE_LIGHTBOX"|"CREATIVE_TYPE_NATIVE_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE"|"CREATIVE_TYPE_AUDIO"|"CREATIVE_TYPE_PUBLISHER_HOSTED"|"CREATIVE_TYPE_NATIVE_VIDEO"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO", ... (2 more fields)}
# --rateDetails shape: {inventorySourceRateType?: "INVENTORY_SOURCE_RATE_TYPE_UNSPECIFIED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR"|"INVENTORY_SOURCE_RATE_TYPE_CPD"|"INVENTORY_SOURCE_RATE_TYPE_FLAT", minimumSpend?: record, rate?: record, unitsPurchased?: string}
# --readWriteAccessors shape: {advertisers?: record, partner?: record}
# --status shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
# --timeRange shape: {endTime?: string, startTime?: string}
export def "inventory-sources create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that the request is being made within.
  --partner-id: string # The ID of the partner that the request is being made within.
  --commitment: string@commitment-completer # Whether the inventory source has a guaranteed or non-guaranteed delivery.
  --creative-configs: list # The creative requirements of the inventory source. Not applicable for auction packages. — item shape: {creativeType?: "CREATIVE_TYPE_UNSPECIFIED"|"CREATIVE_TYPE_STANDARD"|"CREATIVE_TYPE_EXPANDABLE"|"CREATIVE_TYPE_VIDEO"|"CREATIVE_TYPE_NATIVE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_SITE_SQUARE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL"|"CREATIVE_TYPE_LIGHTBOX"|"CREATIVE_TYPE_NATIVE_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE"|"CREATIVE_TYPE_AUDIO"|"CREATIVE_TYPE_PUBLISHER_HOSTED"|"CREATIVE_TYPE_NATIVE_VIDEO"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO", ... (2 more fields)}
  --deal-id: string # The ID in the exchange space that uniquely identifies the inventory source. Must be unique across buyers within each exchange but not necessarily unique across exchanges.
  --delivery-method: string@delivery-method-completer # The delivery method of the inventory source. * For non-guaranteed inventory sources, the only acceptable value is `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`. * For guaranteed inventory sources, acceptable values are `INVENTORY_SOURCE_DELIVERY_METHOD_TAG` and `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`.
  --display-name: string # The display name of the inventory source. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --exchange: string@exchange-completer # The exchange to which the inventory source belongs.
  --guaranteed-order-id: string # Immutable. The ID of the guaranteed order that this inventory source belongs to. Only applicable when commitment is `INVENTORY_SOURCE_COMMITMENT_GUARANTEED`.
  --inventory-source-type: string@inventory-source-type-completer # Denotes the type of the inventory source.
  --publisher-name: string # The publisher/seller name of the inventory source.
  --rate-details: record # The rate related settings of the inventory source. — shape: {inventorySourceRateType?: "INVENTORY_SOURCE_RATE_TYPE_UNSPECIFIED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR"|"INVENTORY_SOURCE_RATE_TYPE_CPD"|"INVENTORY_SOURCE_RATE_TYPE_FLAT", minimumSpend?: record, rate?: record, unitsPurchased?: string}
  --read-write-accessors: record # The partner or advertisers with access to the inventory source. — shape: {advertisers?: record, partner?: record}
  --status: record # The status related settings of the inventory source. — shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
  --sub-site-property-id: string # Immutable. The unique ID of the sub-site property assigned to this inventory source. (format: int64)
  --time-range: record # A time range. — shape: {endTime?: string, startTime?: string}
]: any -> record<commitment: string, creativeConfigs: table<creativeType: string, displayCreativeConfig: record, videoCreativeConfig: record>, dealId: string, deliveryMethod: string, displayName: string, exchange: string, guaranteedOrderId: string, inventorySourceId: string, inventorySourceProductType: string, inventorySourceType: string, name: string, publisherName: string, rateDetails: record<inventorySourceRateType: string, minimumSpend: record<currencyCode: string, nanos: int, units: string>, rate: record<currencyCode: string, nanos: int, units: string>, unitsPurchased: string>, readAdvertiserIds: list<string>, readPartnerIds: list<string>, readWriteAccessors: record<advertisers: record<advertiserIds: list>, partner: record<partnerId: string>>, status: record<configStatus: string, entityPauseReason: string, entityStatus: string, sellerPauseReason: string, sellerStatus: string>, subSitePropertyId: string, timeRange: record<endTime: string, startTime: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/inventorySources" $qp)
  let req_body = {"commitment": $commitment, "creativeConfigs": $creative_configs, "dealId": $deal_id, "deliveryMethod": $delivery_method, "displayName": $display_name, "exchange": $exchange, "guaranteedOrderId": $guaranteed_order_id, "inventorySourceType": $inventory_source_type, "publisherName": $publisher_name, "rateDetails": $rate_details, "readWriteAccessors": $read_write_accessors, "status": $status, "subSitePropertyId": $sub_site_property_id, "timeRange": $time_range} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets an inventory source.
#
# GET /v2/inventorySources/{inventorySourceId}
# operationId: displayvideo.inventorySources.get
export def "inventory-sources get" [
  inventory_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --partner-id: string # Required. The ID of the DV360 partner to which the fetched inventory source is permissioned.
]: nothing -> record<commitment: string, creativeConfigs: table<creativeType: string, displayCreativeConfig: record, videoCreativeConfig: record>, dealId: string, deliveryMethod: string, displayName: string, exchange: string, guaranteedOrderId: string, inventorySourceId: string, inventorySourceProductType: string, inventorySourceType: string, name: string, publisherName: string, rateDetails: record<inventorySourceRateType: string, minimumSpend: record<currencyCode: string, nanos: int, units: string>, rate: record<currencyCode: string, nanos: int, units: string>, unitsPurchased: string>, readAdvertiserIds: list<string>, readPartnerIds: list<string>, readWriteAccessors: record<advertisers: record<advertiserIds: list>, partner: record<partnerId: string>>, status: record<configStatus: string, entityPauseReason: string, entityStatus: string, sellerPauseReason: string, sellerStatus: string>, subSitePropertyId: string, timeRange: record<endTime: string, startTime: string>, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "partnerId" $partner_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_id: (encode-path-segment $inventory_source_id)} | format pattern "/v2/inventorySources/{inventory_source_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing inventory source. Returns the updated inventory source if successful.
#
# PATCH /v2/inventorySources/{inventorySourceId}
# operationId: displayvideo.inventorySources.patch
# --creativeConfigs item shape: {creativeType?: "CREATIVE_TYPE_UNSPECIFIED"|"CREATIVE_TYPE_STANDARD"|"CREATIVE_TYPE_EXPANDABLE"|"CREATIVE_TYPE_VIDEO"|"CREATIVE_TYPE_NATIVE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_SITE_SQUARE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL"|"CREATIVE_TYPE_LIGHTBOX"|"CREATIVE_TYPE_NATIVE_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE"|"CREATIVE_TYPE_AUDIO"|"CREATIVE_TYPE_PUBLISHER_HOSTED"|"CREATIVE_TYPE_NATIVE_VIDEO"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO", ... (2 more fields)}
# --rateDetails shape: {inventorySourceRateType?: "INVENTORY_SOURCE_RATE_TYPE_UNSPECIFIED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR"|"INVENTORY_SOURCE_RATE_TYPE_CPD"|"INVENTORY_SOURCE_RATE_TYPE_FLAT", minimumSpend?: record, rate?: record, unitsPurchased?: string}
# --readWriteAccessors shape: {advertisers?: record, partner?: record}
# --status shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
# --timeRange shape: {endTime?: string, startTime?: string}
export def "inventory-sources update" [
  inventory_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that the request is being made within.
  --partner-id: string # The ID of the partner that the request is being made within.
  --update-mask: string # Required. The mask to control which fields to update.
  --commitment: string@commitment-completer # Whether the inventory source has a guaranteed or non-guaranteed delivery.
  --creative-configs: list # The creative requirements of the inventory source. Not applicable for auction packages. — item shape: {creativeType?: "CREATIVE_TYPE_UNSPECIFIED"|"CREATIVE_TYPE_STANDARD"|"CREATIVE_TYPE_EXPANDABLE"|"CREATIVE_TYPE_VIDEO"|"CREATIVE_TYPE_NATIVE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_SITE_SQUARE"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_INTERSTITIAL"|"CREATIVE_TYPE_LIGHTBOX"|"CREATIVE_TYPE_NATIVE_APP_INSTALL"|"CREATIVE_TYPE_NATIVE_APP_INSTALL_SQUARE"|"CREATIVE_TYPE_AUDIO"|"CREATIVE_TYPE_PUBLISHER_HOSTED"|"CREATIVE_TYPE_NATIVE_VIDEO"|"CREATIVE_TYPE_TEMPLATED_APP_INSTALL_VIDEO", ... (2 more fields)}
  --deal-id: string # The ID in the exchange space that uniquely identifies the inventory source. Must be unique across buyers within each exchange but not necessarily unique across exchanges.
  --delivery-method: string@delivery-method-completer # The delivery method of the inventory source. * For non-guaranteed inventory sources, the only acceptable value is `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`. * For guaranteed inventory sources, acceptable values are `INVENTORY_SOURCE_DELIVERY_METHOD_TAG` and `INVENTORY_SOURCE_DELIVERY_METHOD_PROGRAMMATIC`.
  --display-name: string # The display name of the inventory source. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --exchange: string@exchange-completer # The exchange to which the inventory source belongs.
  --guaranteed-order-id: string # Immutable. The ID of the guaranteed order that this inventory source belongs to. Only applicable when commitment is `INVENTORY_SOURCE_COMMITMENT_GUARANTEED`.
  --inventory-source-type: string@inventory-source-type-completer # Denotes the type of the inventory source.
  --publisher-name: string # The publisher/seller name of the inventory source.
  --rate-details: record # The rate related settings of the inventory source. — shape: {inventorySourceRateType?: "INVENTORY_SOURCE_RATE_TYPE_UNSPECIFIED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FIXED"|"INVENTORY_SOURCE_RATE_TYPE_CPM_FLOOR"|"INVENTORY_SOURCE_RATE_TYPE_CPD"|"INVENTORY_SOURCE_RATE_TYPE_FLAT", minimumSpend?: record, rate?: record, unitsPurchased?: string}
  --read-write-accessors: record # The partner or advertisers with access to the inventory source. — shape: {advertisers?: record, partner?: record}
  --status: record # The status related settings of the inventory source. — shape: {entityPauseReason?: string, entityStatus?: "ENTITY_STATUS_UNSPECIFIED"|"ENTITY_STATUS_ACTIVE"|"ENTITY_STATUS_ARCHIVED"|"ENTITY_STATUS_DRAFT"|"ENTITY_STATUS_PAUSED"|"ENTITY_STATUS_SCHEDULED_FOR_DELETION"}
  --sub-site-property-id: string # Immutable. The unique ID of the sub-site property assigned to this inventory source. (format: int64)
  --time-range: record # A time range. — shape: {endTime?: string, startTime?: string}
]: any -> record<commitment: string, creativeConfigs: table<creativeType: string, displayCreativeConfig: record, videoCreativeConfig: record>, dealId: string, deliveryMethod: string, displayName: string, exchange: string, guaranteedOrderId: string, inventorySourceId: string, inventorySourceProductType: string, inventorySourceType: string, name: string, publisherName: string, rateDetails: record<inventorySourceRateType: string, minimumSpend: record<currencyCode: string, nanos: int, units: string>, rate: record<currencyCode: string, nanos: int, units: string>, unitsPurchased: string>, readAdvertiserIds: list<string>, readPartnerIds: list<string>, readWriteAccessors: record<advertisers: record<advertiserIds: list>, partner: record<partnerId: string>>, status: record<configStatus: string, entityPauseReason: string, entityStatus: string, sellerPauseReason: string, sellerStatus: string>, subSitePropertyId: string, timeRange: record<endTime: string, startTime: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "partnerId" $partner_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_id: (encode-path-segment $inventory_source_id)} | format pattern "/v2/inventorySources/{inventory_source_id}") $qp)
  let req_body = {"commitment": $commitment, "creativeConfigs": $creative_configs, "dealId": $deal_id, "deliveryMethod": $delivery_method, "displayName": $display_name, "exchange": $exchange, "guaranteedOrderId": $guaranteed_order_id, "inventorySourceType": $inventory_source_type, "publisherName": $publisher_name, "rateDetails": $rate_details, "readWriteAccessors": $read_write_accessors, "status": $status, "subSitePropertyId": $sub_site_property_id, "timeRange": $time_range} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Edits read/write accessors of an inventory source. Returns the updated read_write_accessors for the inventory source.
#
# POST /v2/inventorySources/{inventorySourceId}:editInventorySourceReadWriteAccessors
# operationId: displayvideo.inventorySources.editInventorySourceReadWriteAccessors
# --advertisersUpdate shape: {addedAdvertisers?: list<string>, removedAdvertisers?: list<string>}
export def "inventory-sources get-edit-write-accessors" [
  inventory_source_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertisers-update: record # Update to the list of advertisers with read/write access to the inventory source. — shape: {addedAdvertisers?: list<string>, removedAdvertisers?: list<string>}
  --assign-partner: oneof<nothing, bool> # Set the partner context as read/write accessor of the inventory source. This will remove all other current read/write advertiser accessors.
  --partner-id: string # Required. The partner context by which the accessors change is being made. (format: int64)
]: any -> record<advertisers: record<advertiserIds: list<string>>, partner: record<partnerId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({inventory_source_id: (encode-path-segment $inventory_source_id)} | format pattern "/v2/inventorySources/{inventory_source_id}:editInventorySourceReadWriteAccessors") $qp)
  let req_body = {"advertisersUpdate": $advertisers_update, "assignPartner": $assign_partner, "partnerId": $partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists partners that are accessible to the current user. The order is defined by the order_by parameter.
#
# GET /v2/partners
# operationId: displayvideo.partners.list
export def "partners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by partner properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `AND` or `OR` logical operators. A sequence of restrictions implicitly uses `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `entityStatus` Examples: * All active partners: `entityStatus="ENTITY_STATUS_ACTIVE"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListPartners` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, partners: table<adServerConfig: record, dataAccessConfig: record, displayName: string, entityStatus: string, exchangeConfig: record, generalConfig: record, name: string, partnerId: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/partners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a partner.
#
# GET /v2/partners/{partnerId}
# operationId: displayvideo.partners.get
export def "partners get" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<adServerConfig: record<measurementConfig: record<dv360ToCmCostReportingEnabled: bool, dv360ToCmDataSharingEnabled: bool>>, dataAccessConfig: record<sdfConfig: record<adminEmail: string, version: string>>, displayName: string, entityStatus: string, exchangeConfig: record<enabledExchanges: list<record>>, generalConfig: record<currencyCode: string, timeZone: string>, name: string, partnerId: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/v2/partners/{partner_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists channels for a partner or advertiser.
#
# GET /v2/partners/{partnerId}/channels
# operationId: displayvideo.partners.channels.list
export def "partners-channels list" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the channels.
  --filter: string # Allows filtering by channel fields. Supported syntax: * Filter expressions for channel currently can only contain at most one * restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `displayName` Examples: * All channels for which the display name contains "google": `displayName : "google"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) * `channelId` The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListChannels` method. If not specified, the first page of results will be returned.
]: nothing -> record<channels: table<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/v2/partners/{partner_id}/channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new channel. Returns the newly created channel if successful.
#
# POST /v2/partners/{partnerId}/channels
# operationId: displayvideo.partners.channels.create
export def "partners-channels create" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the created channel.
  --advertiser-id: string # The ID of the advertiser that owns the channel. (format: int64)
  --display-name: string # Required. The display name of the channel. Must be UTF-8 encoded with a maximum length of 240 bytes.
  --body-partner-id: string # The ID of the partner that owns the channel. (format: int64)
]: any -> record<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/v2/partners/{partner_id}/channels") $qp)
  let req_body = {"advertiserId": $advertiser_id, "displayName": $display_name, "partnerId": $body_partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates a channel. Returns the updated channel if successful.
#
# PATCH /v2/partners/{partnerId}/channels/{channelId}
# operationId: displayvideo.partners.channels.patch
export def "partners-channels update" [
  partner_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the created channel.
  --update-mask: string # Required. The mask to control which fields to update.
  --advertiser-id: string # The ID of the advertiser that owns the channel. (format: int64)
  --display-name: string # Required. The display name of the channel. Must be UTF-8 encoded with a maximum length of 240 bytes.
  --body-partner-id: string # The ID of the partner that owns the channel. (format: int64)
]: any -> record<advertiserId: string, channelId: string, displayName: string, name: string, negativelyTargetedLineItemCount: string, partnerId: string, positivelyTargetedLineItemCount: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/partners/{partner_id}/channels/{channel_id}") $qp)
  let req_body = {"advertiserId": $advertiser_id, "displayName": $display_name, "partnerId": $body_partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists sites in a channel.
#
# GET /v2/partners/{partnerId}/channels/{channelId}/sites
# operationId: displayvideo.partners.channels.sites.list
export def "partners-channels-sites list" [
  partner_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent channel.
  --filter: string # Allows filtering by site fields. Supported syntax: * Filter expressions for site currently can only contain at most one * restriction. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)`. * Supported fields: - `urlOrAppId` Examples: * All sites for which the URL or app ID contains "google": `urlOrAppId : "google"`
  --order-by: string # Field by which to sort the list. Acceptable values are: * `urlOrAppId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix " desc" should be added to the field name. Example: `urlOrAppId desc`.
  --page-size: int # Requested page size. Must be between `1` and `10000`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListSites` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, sites: table<name: string, urlOrAppId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/partners/{partner_id}/channels/{channel_id}/sites") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a site from a channel.
#
# DELETE /v2/partners/{partnerId}/channels/{channelId}/sites/{urlOrAppId}
# operationId: displayvideo.partners.channels.sites.delete
export def "partners-channels-sites delete" [
  partner_id: string
  channel_id: string
  url_or_app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent channel.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), channel_id: (encode-path-segment $channel_id), url_or_app_id: (encode-path-segment $url_or_app_id)} | format pattern "/v2/partners/{partner_id}/channels/{channel_id}/sites/{url_or_app_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk edits sites under a single channel. The operation will delete the sites provided in BulkEditSitesRequest.deleted_sites and then create the sites provided in BulkEditSitesRequest.created_sites.
#
# POST /v2/partners/{partnerId}/channels/{channelId}/sites:bulkEdit
# operationId: displayvideo.partners.channels.sites.bulkEdit
# --createdSites item shape: {urlOrAppId?: string}
export def "partners-channels-sites-bulk-edit create" [
  partner_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent channel. (format: int64)
  --created-sites: list # The sites to create in batch, specified as a list of Sites. — item shape: {urlOrAppId?: string}
  --deleted-sites: list<string> # The sites to delete in batch, specified as a list of site url_or_app_ids.
  --body-partner-id: string # The ID of the partner that owns the parent channel. (format: int64)
]: any -> record<sites: table<name: string, urlOrAppId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/partners/{partner_id}/channels/{channel_id}/sites:bulkEdit") $qp)
  let req_body = {"advertiserId": $advertiser_id, "createdSites": $created_sites, "deletedSites": $deleted_sites, "partnerId": $body_partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replaces all of the sites under a single channel. The operation will replace the sites under a channel with the sites provided in ReplaceSitesRequest.new_sites.
#
# POST /v2/partners/{partnerId}/channels/{channelId}/sites:replace
# operationId: displayvideo.partners.channels.sites.replace
# --newSites item shape: {urlOrAppId?: string}
export def "partners-channels-sites-replace update" [
  partner_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser that owns the parent channel. (format: int64)
  --new-sites: list # The sites that will replace the existing sites assigned to the channel, specified as a list of Sites. — item shape: {urlOrAppId?: string}
  --body-partner-id: string # The ID of the partner that owns the parent channel. (format: int64)
]: any -> record<sites: table<name: string, urlOrAppId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/partners/{partner_id}/channels/{channel_id}/sites:replace") $qp)
  let req_body = {"advertiserId": $advertiser_id, "newSites": $new_sites, "partnerId": $body_partner_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the targeting options assigned to a partner.
#
# GET /v2/partners/{partnerId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.partners.targetingTypes.assignedTargetingOptions.list
export def "partners-targeting-types-assigned-targeting-options list" [
  partner_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by assigned targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `OR`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `EQUALS (=)`. * Supported fields: - `assignedTargetingOptionId` Examples: * AssignedTargetingOption with ID 123456 `assignedTargetingOptionId="123456"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `assignedTargetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `assignedTargetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListPartnerAssignedTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<assignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/partners/{partner_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assigns a targeting option to a partner. Returns the assigned targeting option if successful.
#
# POST /v2/partners/{partnerId}/targetingTypes/{targetingType}/assignedTargetingOptions
# operationId: displayvideo.partners.targetingTypes.assignedTargetingOptions.create
# --ageRangeDetails shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
# --appCategoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --appDetails shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
# --audienceGroupDetails shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
# --audioContentTypeDetails shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
# --authorizedSellerStatusDetails shape: {targetingOptionId?: string}
# --browserDetails shape: {negative?: bool, targetingOptionId?: string}
# --businessChainDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --carrierAndIspDetails shape: {negative?: bool, targetingOptionId?: string}
# --categoryDetails shape: {negative?: bool, targetingOptionId?: string}
# --channelDetails shape: {channelId?: string, negative?: bool}
# --contentDurationDetails shape: {targetingOptionId?: string}
# --contentGenreDetails shape: {negative?: bool, targetingOptionId?: string}
# --contentInstreamPositionDetails shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
# --contentOutstreamPositionDetails shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
# --contentStreamTypeDetails shape: {targetingOptionId?: string}
# --dayAndTimeDetails shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
# --deviceMakeModelDetails shape: {negative?: bool, targetingOptionId?: string}
# --deviceTypeDetails shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
# --digitalContentLabelExclusionDetails shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
# --environmentDetails shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
# --exchangeDetails shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
# --genderDetails shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
# --geoRegionDetails shape: {negative?: bool, targetingOptionId?: string}
# --householdIncomeDetails shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
# --inventorySourceDetails shape: {inventorySourceId?: string}
# --inventorySourceGroupDetails shape: {inventorySourceGroupId?: string}
# --keywordDetails shape: {keyword?: string, negative?: bool}
# --languageDetails shape: {negative?: bool, targetingOptionId?: string}
# --nativeContentPositionDetails shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
# --negativeKeywordListDetails shape: {negativeKeywordListId?: string}
# --omidDetails shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
# --onScreenPositionDetails shape: {targetingOptionId?: string}
# --operatingSystemDetails shape: {negative?: bool, targetingOptionId?: string}
# --parentalStatusDetails shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
# --poiDetails shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
# --proximityLocationListDetails shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
# --regionalLocationListDetails shape: {negative?: bool, regionalLocationListId?: string}
# --sensitiveCategoryExclusionDetails shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
# --sessionPositionDetails shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
# --subExchangeDetails shape: {targetingOptionId?: string}
# --thirdPartyVerifierDetails shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
# --urlDetails shape: {negative?: bool, url?: string}
# --userRewardedContentDetails shape: {targetingOptionId?: string}
# --videoPlayerSizeDetails shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
# --viewabilityDetails shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
# --youtubeChannelDetails shape: {channelId?: string, negative?: bool}
# --youtubeVideoDetails shape: {negative?: bool, videoId?: string}
export def "partners-targeting-types-assigned-targeting-options create" [
  partner_id: string
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --age-range-details: record # Represents a targetable age range. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AGE_RANGE`. — shape: {ageRange?: "AGE_RANGE_UNSPECIFIED"|"AGE_RANGE_18_24"|"AGE_RANGE_25_34"|"AGE_RANGE_35_44"|"AGE_RANGE_45_54"|"AGE_RANGE_55_64"|"AGE_RANGE_65_PLUS"|"AGE_RANGE_UNKNOWN"|"AGE_RANGE_18_20"|"AGE_RANGE_21_24"|"AGE_RANGE_25_29"|"AGE_RANGE_30_34"|"AGE_RANGE_35_39"|"AGE_RANGE_40_44"|"AGE_RANGE_45_49"|"AGE_RANGE_50_54"|"AGE_RANGE_55_59"|"AGE_RANGE_60_64"}
  --app-category-details: record # Details for assigned app category targeting option. This will be populated in the app_category_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --app-details: record # Details for assigned app targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_APP`. — shape: {appId?: string, appPlatform?: "APP_PLATFORM_UNSPECIFIED"|"APP_PLATFORM_IOS"|"APP_PLATFORM_ANDROID"|"APP_PLATFORM_ROKU"|"APP_PLATFORM_AMAZON_FIRETV"|"APP_PLATFORM_PLAYSTATION"|"APP_PLATFORM_APPLE_TV"|"APP_PLATFORM_XBOX"|"APP_PLATFORM_SAMSUNG_TV"|"APP_PLATFORM_ANDROID_TV"|"APP_PLATFORM_GENERIC_CTV", negative?: bool}
  --audience-group-details: record # Assigned audience group targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUDIENCE_GROUP`. The relation between each group is UNION, except for excluded_first_and_third_party_audience_group and excluded_google_audience_group, of which COMPLEMENT is used as an INTERSECTION with other groups. — shape: {excludedFirstAndThirdPartyAudienceGroup?: record, excludedGoogleAudienceGroup?: record, includedCombinedAudienceGroup?: record, includedCustomListGroup?: record, includedFirstAndThirdPartyAudienceGroups?: list, includedGoogleAudienceGroup?: record}
  --audio-content-type-details: record # Details for audio content type assigned targeting option. This will be populated in the audio_content_type_details field when targeting_type is `TARGETING_TYPE_AUDIO_CONTENT_TYPE`. Explicitly targeting all options is not supported. Remove all audio content type targeting options to achieve this effect. — shape: {audioContentType?: "AUDIO_CONTENT_TYPE_UNSPECIFIED"|"AUDIO_CONTENT_TYPE_UNKNOWN"|"AUDIO_CONTENT_TYPE_MUSIC"|"AUDIO_CONTENT_TYPE_BROADCAST"|"AUDIO_CONTENT_TYPE_PODCAST"}
  --authorized-seller-status-details: record # Represents an assigned authorized seller status. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_AUTHORIZED_SELLER_STATUS`. — shape: {targetingOptionId?: string}
  --browser-details: record # Details for assigned browser targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BROWSER`. — shape: {negative?: bool, targetingOptionId?: string}
  --business-chain-details: record # Details for assigned Business chain targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_BUSINESS_CHAIN`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --carrier-and-isp-details: record # Details for assigned carrier and ISP targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CARRIER_AND_ISP`. — shape: {negative?: bool, targetingOptionId?: string}
  --category-details: record # Assigned category targeting option details. This will be populated in the category_details field when targeting_type is `TARGETING_TYPE_CATEGORY`. — shape: {negative?: bool, targetingOptionId?: string}
  --channel-details: record # Details for assigned channel targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --content-duration-details: record # Details for content duration assigned targeting option. This will be populated in the content_duration_details field when targeting_type is `TARGETING_TYPE_CONTENT_DURATION`. Explicitly targeting all options is not supported. Remove all content duration targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --content-genre-details: record # Details for content genre assigned targeting option. This will be populated in the content_genre_details field when targeting_type is `TARGETING_TYPE_CONTENT_GENRE`. Explicitly targeting all options is not supported. Remove all content genre targeting options to achieve this effect. — shape: {negative?: bool, targetingOptionId?: string}
  --content-instream-position-details: record # Assigned content instream position targeting option details. This will be populated in the content_instream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_INSTREAM_POSITION`. — shape: {contentInstreamPosition?: "CONTENT_INSTREAM_POSITION_UNSPECIFIED"|"CONTENT_INSTREAM_POSITION_PRE_ROLL"|"CONTENT_INSTREAM_POSITION_MID_ROLL"|"CONTENT_INSTREAM_POSITION_POST_ROLL"|"CONTENT_INSTREAM_POSITION_UNKNOWN"}
  --content-outstream-position-details: record # Assigned content outstream position targeting option details. This will be populated in the content_outstream_position_details field when targeting_type is `TARGETING_TYPE_CONTENT_OUTSTREAM_POSITION`. — shape: {contentOutstreamPosition?: "CONTENT_OUTSTREAM_POSITION_UNSPECIFIED"|"CONTENT_OUTSTREAM_POSITION_UNKNOWN"|"CONTENT_OUTSTREAM_POSITION_IN_ARTICLE"|"CONTENT_OUTSTREAM_POSITION_IN_BANNER"|"CONTENT_OUTSTREAM_POSITION_IN_FEED"|"CONTENT_OUTSTREAM_POSITION_INTERSTITIAL"}
  --content-stream-type-details: record # Details for content stream type assigned targeting option. This will be populated in the content_stream_type_details field when targeting_type is `TARGETING_TYPE_CONTENT_STREAM_TYPE`. Explicitly targeting all options is not supported. Remove all content stream type targeting options to achieve this effect. — shape: {targetingOptionId?: string}
  --day-and-time-details: record # Representation of a segment of time defined on a specific day of the week and with a start and end time. The time represented by `start_hour` must be before the time represented by `end_hour`. — shape: {dayOfWeek?: "DAY_OF_WEEK_UNSPECIFIED"|"MONDAY"|"TUESDAY"|"WEDNESDAY"|"THURSDAY"|"FRIDAY"|"SATURDAY"|"SUNDAY", endHour?: int, startHour?: int, timeZoneResolution?: "TIME_ZONE_RESOLUTION_UNSPECIFIED"|"TIME_ZONE_RESOLUTION_END_USER"|"TIME_ZONE_RESOLUTION_ADVERTISER"}
  --device-make-model-details: record # Assigned device make and model targeting option details. This will be populated in the device_make_model_details field when targeting_type is `TARGETING_TYPE_DEVICE_MAKE_MODEL`. — shape: {negative?: bool, targetingOptionId?: string}
  --device-type-details: record # Targeting details for device type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DEVICE_TYPE`. — shape: {deviceType?: "DEVICE_TYPE_UNSPECIFIED"|"DEVICE_TYPE_COMPUTER"|"DEVICE_TYPE_CONNECTED_TV"|"DEVICE_TYPE_SMART_PHONE"|"DEVICE_TYPE_TABLET"}
  --digital-content-label-exclusion-details: record # Targeting details for digital content label. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_DIGITAL_CONTENT_LABEL_EXCLUSION`. — shape: {excludedContentRatingTier?: "CONTENT_RATING_TIER_UNSPECIFIED"|"CONTENT_RATING_TIER_UNRATED"|"CONTENT_RATING_TIER_GENERAL"|"CONTENT_RATING_TIER_PARENTAL_GUIDANCE"|"CONTENT_RATING_TIER_TEENS"|"CONTENT_RATING_TIER_MATURE"|"CONTENT_RATING_TIER_FAMILIES"}
  --environment-details: record # Assigned environment targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_ENVIRONMENT`. — shape: {environment?: "ENVIRONMENT_UNSPECIFIED"|"ENVIRONMENT_WEB_OPTIMIZED"|"ENVIRONMENT_WEB_NOT_OPTIMIZED"|"ENVIRONMENT_APP"}
  --exchange-details: record # Details for assigned exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_EXCHANGE`. — shape: {exchange?: "EXCHANGE_UNSPECIFIED"|"EXCHANGE_GOOGLE_AD_MANAGER"|"EXCHANGE_APPNEXUS"|"EXCHANGE_BRIGHTROLL"|"EXCHANGE_ADFORM"|"EXCHANGE_ADMETA"|"EXCHANGE_ADMIXER"|"EXCHANGE_ADSMOGO"|"EXCHANGE_ADSWIZZ"|"EXCHANGE_BIDSWITCH"|"EXCHANGE_BRIGHTROLL_DISPLAY"|"EXCHANGE_CADREON"|"EXCHANGE_DAILYMOTION"|"EXCHANGE_FIVE"|"EXCHANGE_FLUCT"|"EXCHANGE_FREEWHEEL"|"EXCHANGE_GENIEE"|"EXCHANGE_GUMGUM"|"EXCHANGE_IMOBILE"|"EXCHANGE_IBILLBOARD"|"EXCHANGE_IMPROVE_DIGITAL"|"EXCHANGE_INDEX"|"EXCHANGE_KARGO"|"EXCHANGE_MICROAD"|"EXCHANGE_MOPUB"|"EXCHANGE_NEND"|"EXCHANGE_ONE_BY_AOL_DISPLAY"|"EXCHANGE_ONE_BY_AOL_MOBILE"|"EXCHANGE_ONE_BY_AOL_VIDEO"|"EXCHANGE_OOYALA"|"EXCHANGE_OPENX"|"EXCHANGE_PERMODO"|"EXCHANGE_PLATFORMONE"|"EXCHANGE_PLATFORMID"|"EXCHANGE_PUBMATIC"|"EXCHANGE_PULSEPOINT"|"EXCHANGE_REVENUEMAX"|"EXCHANGE_RUBICON"|"EXCHANGE_SMARTCLIP"|"EXCHANGE_SMARTRTB"|"EXCHANGE_SMARTSTREAMTV"|"EXCHANGE_SOVRN"|"EXCHANGE_SPOTXCHANGE"|"EXCHANGE_STROER"|"EXCHANGE_TEADSTV"|"EXCHANGE_TELARIA"|"EXCHANGE_TVN"|"EXCHANGE_UNITED"|"EXCHANGE_YIELDLAB"|"EXCHANGE_YIELDMO"|"EXCHANGE_UNRULYX"|"EXCHANGE_OPEN8"|"EXCHANGE_TRITON"|"EXCHANGE_TRIPLELIFT"|"EXCHANGE_TABOOLA"|"EXCHANGE_INMOBI"|"EXCHANGE_SMAATO"|"EXCHANGE_AJA"|"EXCHANGE_SUPERSHIP"|"EXCHANGE_NEXSTAR_DIGITAL"|"EXCHANGE_WAZE"|"EXCHANGE_SOUNDCAST"|"EXCHANGE_SHARETHROUGH"|"EXCHANGE_FYBER"|"EXCHANGE_RED_FOR_PUBLISHERS"|"EXCHANGE_MEDIANET"|"EXCHANGE_TAPJOY"|"EXCHANGE_VISTAR"|"EXCHANGE_DAX"|"EXCHANGE_JCD"|"EXCHANGE_PLACE_EXCHANGE"|"EXCHANGE_APPLOVIN"|"EXCHANGE_CONNATIX"|"EXCHANGE_RESET_DIGITAL"|"EXCHANGE_HIVESTACK"}
  --gender-details: record # Details for assigned gender targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GENDER`. — shape: {gender?: "GENDER_UNSPECIFIED"|"GENDER_MALE"|"GENDER_FEMALE"|"GENDER_UNKNOWN"}
  --geo-region-details: record # Details for assigned geographic region targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_GEO_REGION`. — shape: {negative?: bool, targetingOptionId?: string}
  --household-income-details: record # Details for assigned household income targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_HOUSEHOLD_INCOME`. — shape: {householdIncome?: "HOUSEHOLD_INCOME_UNSPECIFIED"|"HOUSEHOLD_INCOME_UNKNOWN"|"HOUSEHOLD_INCOME_LOWER_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_41_TO_50_PERCENT"|"HOUSEHOLD_INCOME_TOP_31_TO_40_PERCENT"|"HOUSEHOLD_INCOME_TOP_21_TO_30_PERCENT"|"HOUSEHOLD_INCOME_TOP_11_TO_20_PERCENT"|"HOUSEHOLD_INCOME_TOP_10_PERCENT"}
  --inventory-source-details: record # Targeting details for inventory source. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE`. — shape: {inventorySourceId?: string}
  --inventory-source-group-details: record # Targeting details for inventory source group. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_INVENTORY_SOURCE_GROUP`. — shape: {inventorySourceGroupId?: string}
  --keyword-details: record # Details for assigned keyword targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_KEYWORD`. — shape: {keyword?: string, negative?: bool}
  --language-details: record # Details for assigned language targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_LANGUAGE`. — shape: {negative?: bool, targetingOptionId?: string}
  --native-content-position-details: record # Details for native content position assigned targeting option. This will be populated in the native_content_position_details field when targeting_type is `TARGETING_TYPE_NATIVE_CONTENT_POSITION`. Explicitly targeting all options is not supported. Remove all native content position targeting options to achieve this effect. — shape: {contentPosition?: "NATIVE_CONTENT_POSITION_UNSPECIFIED"|"NATIVE_CONTENT_POSITION_UNKNOWN"|"NATIVE_CONTENT_POSITION_IN_ARTICLE"|"NATIVE_CONTENT_POSITION_IN_FEED"|"NATIVE_CONTENT_POSITION_PERIPHERAL"|"NATIVE_CONTENT_POSITION_RECOMMENDATION"}
  --negative-keyword-list-details: record # Targeting details for negative keyword list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_NEGATIVE_KEYWORD_LIST`. — shape: {negativeKeywordListId?: string}
  --omid-details: record # Represents a targetable Open Measurement enabled inventory type. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_OMID`. — shape: {omid?: "OMID_UNSPECIFIED"|"OMID_FOR_MOBILE_DISPLAY_ADS"}
  --on-screen-position-details: record # On screen position targeting option details. This will be populated in the on_screen_position_details field when targeting_type is `TARGETING_TYPE_ON_SCREEN_POSITION`. — shape: {targetingOptionId?: string}
  --operating-system-details: record # Assigned operating system targeting option details. This will be populated in the operating_system_details field when targeting_type is `TARGETING_TYPE_OPERATING_SYSTEM`. — shape: {negative?: bool, targetingOptionId?: string}
  --parental-status-details: record # Details for assigned parental status targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PARENTAL_STATUS`. — shape: {parentalStatus?: "PARENTAL_STATUS_UNSPECIFIED"|"PARENTAL_STATUS_PARENT"|"PARENTAL_STATUS_NOT_A_PARENT"|"PARENTAL_STATUS_UNKNOWN"}
  --poi-details: record # Details for assigned POI targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_POI`. — shape: {proximityRadiusAmount?: float, proximityRadiusUnit?: "DISTANCE_UNIT_UNSPECIFIED"|"DISTANCE_UNIT_MILES"|"DISTANCE_UNIT_KILOMETERS", targetingOptionId?: string}
  --proximity-location-list-details: record # Targeting details for proximity location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_PROXIMITY_LOCATION_LIST`. — shape: {proximityLocationListId?: string, proximityRadius?: float, proximityRadiusUnit?: "PROXIMITY_RADIUS_UNIT_UNSPECIFIED"|"PROXIMITY_RADIUS_UNIT_MILES"|"PROXIMITY_RADIUS_UNIT_KILOMETERS"}
  --regional-location-list-details: record # Targeting details for regional location list. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_REGIONAL_LOCATION_LIST`. — shape: {negative?: bool, regionalLocationListId?: string}
  --sensitive-category-exclusion-details: record # Targeting details for sensitive category. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SENSITIVE_CATEGORY_EXCLUSION`. — shape: {excludedSensitiveCategory?: "SENSITIVE_CATEGORY_UNSPECIFIED"|"SENSITIVE_CATEGORY_ADULT"|"SENSITIVE_CATEGORY_DEROGATORY"|"SENSITIVE_CATEGORY_DOWNLOADS_SHARING"|"SENSITIVE_CATEGORY_WEAPONS"|"SENSITIVE_CATEGORY_GAMBLING"|"SENSITIVE_CATEGORY_VIOLENCE"|"SENSITIVE_CATEGORY_SUGGESTIVE"|"SENSITIVE_CATEGORY_PROFANITY"|"SENSITIVE_CATEGORY_ALCOHOL"|"SENSITIVE_CATEGORY_DRUGS"|"SENSITIVE_CATEGORY_TOBACCO"|"SENSITIVE_CATEGORY_POLITICS"|"SENSITIVE_CATEGORY_RELIGION"|"SENSITIVE_CATEGORY_TRAGEDY"|"SENSITIVE_CATEGORY_TRANSPORTATION_ACCIDENTS"|"SENSITIVE_CATEGORY_SENSITIVE_SOCIAL_ISSUES"|"SENSITIVE_CATEGORY_SHOCKING"|"SENSITIVE_CATEGORY_EMBEDDED_VIDEO"|"SENSITIVE_CATEGORY_LIVE_STREAMING_VIDEO"}
  --session-position-details: record # Details for session position assigned targeting option. This will be populated in the session_position_details field when targeting_type is `TARGETING_TYPE_SESSION_POSITION`. — shape: {sessionPosition?: "SESSION_POSITION_UNSPECIFIED"|"SESSION_POSITION_FIRST_IMPRESSION"}
  --sub-exchange-details: record # Details for assigned sub-exchange targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_SUB_EXCHANGE`. — shape: {targetingOptionId?: string}
  --third-party-verifier-details: record # Assigned third party verifier targeting option details. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_THIRD_PARTY_VERIFIER`. — shape: {adloox?: record, doubleVerify?: record, integralAdScience?: record}
  --url-details: record # Details for assigned URL targeting option. This will be populated in the details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_URL`. — shape: {negative?: bool, url?: string}
  --user-rewarded-content-details: record # User rewarded content targeting option details. This will be populated in the user_rewarded_content_details field when targeting_type is `TARGETING_TYPE_USER_REWARDED_CONTENT`. — shape: {targetingOptionId?: string}
  --video-player-size-details: record # Video player size targeting option details. This will be populated in the video_player_size_details field when targeting_type is `TARGETING_TYPE_VIDEO_PLAYER_SIZE`. Explicitly targeting all options is not supported. Remove all video player size targeting options to achieve this effect. — shape: {videoPlayerSize?: "VIDEO_PLAYER_SIZE_UNSPECIFIED"|"VIDEO_PLAYER_SIZE_SMALL"|"VIDEO_PLAYER_SIZE_LARGE"|"VIDEO_PLAYER_SIZE_HD"|"VIDEO_PLAYER_SIZE_UNKNOWN"}
  --viewability-details: record # Assigned viewability targeting option details. This will be populated in the viewability_details field of an AssignedTargetingOption when targeting_type is `TARGETING_TYPE_VIEWABILITY`. — shape: {viewability?: "VIEWABILITY_UNSPECIFIED"|"VIEWABILITY_10_PERCENT_OR_MORE"|"VIEWABILITY_20_PERCENT_OR_MORE"|"VIEWABILITY_30_PERCENT_OR_MORE"|"VIEWABILITY_40_PERCENT_OR_MORE"|"VIEWABILITY_50_PERCENT_OR_MORE"|"VIEWABILITY_60_PERCENT_OR_MORE"|"VIEWABILITY_70_PERCENT_OR_MORE"|"VIEWABILITY_80_PERCENT_OR_MORE"|"VIEWABILITY_90_PERCENT_OR_MORE"}
  --youtube-channel-details: record # Details for YouTube channel assigned targeting option. This will be populated in the youtube_channel_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_CHANNEL`. — shape: {channelId?: string, negative?: bool}
  --youtube-video-details: record # Details for YouTube video assigned targeting option. This will be populated in the youtube_video_details field when targeting_type is `TARGETING_TYPE_YOUTUBE_VIDEO`. — shape: {negative?: bool, videoId?: string}
]: any -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/partners/{partner_id}/targetingTypes/{targeting_type}/assignedTargetingOptions") $qp)
  let req_body = {"ageRangeDetails": $age_range_details, "appCategoryDetails": $app_category_details, "appDetails": $app_details, "audienceGroupDetails": $audience_group_details, "audioContentTypeDetails": $audio_content_type_details, "authorizedSellerStatusDetails": $authorized_seller_status_details, "browserDetails": $browser_details, "businessChainDetails": $business_chain_details, "carrierAndIspDetails": $carrier_and_isp_details, "categoryDetails": $category_details, "channelDetails": $channel_details, "contentDurationDetails": $content_duration_details, "contentGenreDetails": $content_genre_details, "contentInstreamPositionDetails": $content_instream_position_details, "contentOutstreamPositionDetails": $content_outstream_position_details, "contentStreamTypeDetails": $content_stream_type_details, "dayAndTimeDetails": $day_and_time_details, "deviceMakeModelDetails": $device_make_model_details, "deviceTypeDetails": $device_type_details, "digitalContentLabelExclusionDetails": $digital_content_label_exclusion_details, "environmentDetails": $environment_details, "exchangeDetails": $exchange_details, "genderDetails": $gender_details, "geoRegionDetails": $geo_region_details, "householdIncomeDetails": $household_income_details, "inventorySourceDetails": $inventory_source_details, "inventorySourceGroupDetails": $inventory_source_group_details, "keywordDetails": $keyword_details, "languageDetails": $language_details, "nativeContentPositionDetails": $native_content_position_details, "negativeKeywordListDetails": $negative_keyword_list_details, "omidDetails": $omid_details, "onScreenPositionDetails": $on_screen_position_details, "operatingSystemDetails": $operating_system_details, "parentalStatusDetails": $parental_status_details, "poiDetails": $poi_details, "proximityLocationListDetails": $proximity_location_list_details, "regionalLocationListDetails": $regional_location_list_details, "sensitiveCategoryExclusionDetails": $sensitive_category_exclusion_details, "sessionPositionDetails": $session_position_details, "subExchangeDetails": $sub_exchange_details, "thirdPartyVerifierDetails": $third_party_verifier_details, "urlDetails": $url_details, "userRewardedContentDetails": $user_rewarded_content_details, "videoPlayerSizeDetails": $video_player_size_details, "viewabilityDetails": $viewability_details, "youtubeChannelDetails": $youtube_channel_details, "youtubeVideoDetails": $youtube_video_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes an assigned targeting option from a partner.
#
# DELETE /v2/partners/{partnerId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.partners.targetingTypes.assignedTargetingOptions.delete
export def "partners-targeting-types-assigned-targeting-options delete" [
  partner_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/partners/{partner_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option assigned to a partner.
#
# GET /v2/partners/{partnerId}/targetingTypes/{targetingType}/assignedTargetingOptions/{assignedTargetingOptionId}
# operationId: displayvideo.partners.targetingTypes.assignedTargetingOptions.get
export def "partners-targeting-types-assigned-targeting-options get" [
  partner_id: string
  targeting_type: string
  assigned_targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, appDetails: record<appId: string, appPlatform: string, displayName: string, negative: bool>, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record<excludedFirstAndThirdPartyAudienceGroup: record<settings: list>, excludedGoogleAudienceGroup: record<settings: list>, includedCombinedAudienceGroup: record<settings: list>, includedCustomListGroup: record<settings: list>, includedFirstAndThirdPartyAudienceGroups: list<record>, includedGoogleAudienceGroup: record<settings: list>>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string, targetingOptionId: string>, browserDetails: record<displayName: string, negative: bool, targetingOptionId: string>, businessChainDetails: record<displayName: string, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, carrierAndIspDetails: record<displayName: string, negative: bool, targetingOptionId: string>, categoryDetails: record<displayName: string, negative: bool, targetingOptionId: string>, channelDetails: record<channelId: string, negative: bool>, contentDurationDetails: record<contentDuration: string, targetingOptionId: string>, contentGenreDetails: record<displayName: string, negative: bool, targetingOptionId: string>, contentInstreamPositionDetails: record<adType: string, contentInstreamPosition: string>, contentOutstreamPositionDetails: record<adType: string, contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string, targetingOptionId: string>, dayAndTimeDetails: record<dayOfWeek: string, endHour: int, startHour: int, timeZoneResolution: string>, deviceMakeModelDetails: record<displayName: string, negative: bool, targetingOptionId: string>, deviceTypeDetails: record<deviceType: string, youtubeAndPartnersBidMultiplier: float>, digitalContentLabelExclusionDetails: record<excludedContentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string, negative: bool, targetingOptionId: string>, householdIncomeDetails: record<householdIncome: string>, inheritance: string, inventorySourceDetails: record<inventorySourceId: string>, inventorySourceGroupDetails: record<inventorySourceGroupId: string>, keywordDetails: record<keyword: string, negative: bool>, languageDetails: record<displayName: string, negative: bool, targetingOptionId: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, negativeKeywordListDetails: record<negativeKeywordListId: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<adType: string, onScreenPosition: string, targetingOptionId: string>, operatingSystemDetails: record<displayName: string, negative: bool, targetingOptionId: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float, proximityRadiusAmount: float, proximityRadiusUnit: string, targetingOptionId: string>, proximityLocationListDetails: record<proximityLocationListId: string, proximityRadius: float, proximityRadiusUnit: string>, regionalLocationListDetails: record<negative: bool, regionalLocationListId: string>, sensitiveCategoryExclusionDetails: record<excludedSensitiveCategory: string>, sessionPositionDetails: record<sessionPosition: string>, subExchangeDetails: record<targetingOptionId: string>, targetingType: string, thirdPartyVerifierDetails: record<adloox: record<excludedAdlooxCategories: list>, doubleVerify: record<appStarRating: record, avoidedAgeRatings: list, brandSafetyCategories: record, customSegmentId: string, displayViewability: record, fraudInvalidTraffic: record, videoViewability: record>, integralAdScience: record<customSegmentId: list, displayViewability: string, excludeUnrateable: bool, excludedAdFraudRisk: string, excludedAdultRisk: string, excludedAlcoholRisk: string, excludedDrugsRisk: string, excludedGamblingRisk: string, excludedHateSpeechRisk: string, excludedIllegalDownloadsRisk: string, excludedOffensiveLanguageRisk: string, excludedViolenceRisk: string, traqScoreOption: string, videoViewability: string>>, urlDetails: record<negative: bool, url: string>, userRewardedContentDetails: record<targetingOptionId: string, userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>, youtubeChannelDetails: record<channelId: string, negative: bool>, youtubeVideoDetails: record<negative: bool, videoId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), targeting_type: (encode-path-segment $targeting_type), assigned_targeting_option_id: (encode-path-segment $assigned_targeting_option_id)} | format pattern "/v2/partners/{partner_id}/targetingTypes/{targeting_type}/assignedTargetingOptions/{assigned_targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edits targeting options under a single partner. The operation will delete the assigned targeting options provided in BulkEditPartnerAssignedTargetingOptionsRequest.deleteRequests and then create the assigned targeting options provided in BulkEditPartnerAssignedTargetingOptionsRequest.createRequests .
#
# POST /v2/partners/{partnerId}:editAssignedTargetingOptions
# operationId: displayvideo.partners.editAssignedTargetingOptions
# --createRequests item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
# --deleteRequests item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
export def "partners create-edit-assigned-targeting-options" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --create-requests: list # The assigned targeting options to create in batch, specified as a list of `CreateAssignedTargetingOptionsRequest`. Supported targeting types: * `TARGETING_TYPE_CHANNEL` — item shape: {assignedTargetingOptions?: list, ... (1 more fields)}
  --delete-requests: list # The assigned targeting options to delete in batch, specified as a list of `DeleteAssignedTargetingOptionsRequest`. Supported targeting types: * `TARGETING_TYPE_CHANNEL` — item shape: {assignedTargetingOptionIds?: list<string>, ... (1 more fields)}
]: any -> record<createdAssignedTargetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, appDetails: record, assignedTargetingOptionId: string, assignedTargetingOptionIdAlias: string, audienceGroupDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, channelDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, dayAndTimeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelExclusionDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, inheritance: string, inventorySourceDetails: record, inventorySourceGroupDetails: record, keywordDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, negativeKeywordListDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, proximityLocationListDetails: record, regionalLocationListDetails: record, sensitiveCategoryExclusionDetails: record, sessionPositionDetails: record, subExchangeDetails: record, targetingType: string, thirdPartyVerifierDetails: record, urlDetails: record, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record, youtubeChannelDetails: record, youtubeVideoDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/v2/partners/{partner_id}:editAssignedTargetingOptions") $qp)
  let req_body = {"createRequests": $create_requests, "deleteRequests": $delete_requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates an SDF Download Task. Returns an Operation. An SDF Download Task is a long-running, asynchronous operation. The metadata type of this operation is SdfDownloadTaskMetadata. If the request is successful, the response type of the operation is SdfDownloadTask. The response will not include the download files, which must be retrieved with media.download. The state of operation can be retrieved with sdfdownloadtask.operations.get. Any errors can be found in the error.message. Note that error.details is expected to be empty.
#
# POST /v2/sdfdownloadtasks
# operationId: displayvideo.sdfdownloadtasks.create
# --idFilter shape: {adGroupAdIds?: list<string>, adGroupIds?: list<string>, campaignIds?: list<string>, insertionOrderIds?: list<string>, lineItemIds?: list<string>, mediaProductIds?: list<string>}
# --inventorySourceFilter shape: {inventorySourceIds?: list<string>}
# --parentEntityFilter shape: {fileType?: list<string>, filterIds?: list<string>, filterType?: "FILTER_TYPE_UNSPECIFIED"|"FILTER_TYPE_NONE"|"FILTER_TYPE_ADVERTISER_ID"|"FILTER_TYPE_CAMPAIGN_ID"|"FILTER_TYPE_MEDIA_PRODUCT_ID"|"FILTER_TYPE_INSERTION_ORDER_ID"|"FILTER_TYPE_LINE_ITEM_ID"}
export def "sdfdownloadtasks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # The ID of the advertiser to download SDF for. (format: int64)
  --id-filter: record # A filtering option that filters entities by their entity IDs. — shape: {adGroupAdIds?: list<string>, adGroupIds?: list<string>, campaignIds?: list<string>, insertionOrderIds?: list<string>, lineItemIds?: list<string>, mediaProductIds?: list<string>}
  --inventory-source-filter: record # A filtering option for filtering on Inventory Source entities. — shape: {inventorySourceIds?: list<string>}
  --parent-entity-filter: record # A filtering option that filters on selected file types belonging to a chosen set of filter entities. — shape: {fileType?: list<string>, filterIds?: list<string>, filterType?: "FILTER_TYPE_UNSPECIFIED"|"FILTER_TYPE_NONE"|"FILTER_TYPE_ADVERTISER_ID"|"FILTER_TYPE_CAMPAIGN_ID"|"FILTER_TYPE_MEDIA_PRODUCT_ID"|"FILTER_TYPE_INSERTION_ORDER_ID"|"FILTER_TYPE_LINE_ITEM_ID"}
  --partner-id: string # The ID of the partner to download SDF for. (format: int64)
  --version: string@version-completer # Required. The SDF version of the downloaded file. If set to `SDF_VERSION_UNSPECIFIED`, this will default to the version specified by the advertiser or partner identified by `root_id`. An advertiser inherits its SDF version from its partner unless configured otherwise.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sdfdownloadtasks" $qp)
  let req_body = {"advertiserId": $advertiser_id, "idFilter": $id_filter, "inventorySourceFilter": $inventory_source_filter, "parentEntityFilter": $parent_entity_filter, "partnerId": $partner_id, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists targeting options of a given type.
#
# GET /v2/targetingTypes/{targetingType}/targetingOptions
# operationId: displayvideo.targetingTypes.targetingOptions.list
export def "targeting-types-targeting-options list" [
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Required. The Advertiser this request is being made in the context of.
  --filter: string # Allows filtering by targeting option properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by `OR` logical operators. * A restriction has the form of `{field} {operator} {value}`. * The operator must be "=" (equal sign). * Supported fields: - `carrierAndIspDetails.type` - `geoRegionDetails.geoRegionType` - `targetingOptionId` Examples: * All `GEO REGION` targeting options that belong to sub type `GEO_REGION_TYPE_COUNTRY` or `GEO_REGION_TYPE_STATE`: `geoRegionDetails.geoRegionType="GEO_REGION_TYPE_COUNTRY" OR geoRegionDetails.geoRegionType="GEO_REGION_TYPE_STATE"` * All `CARRIER AND ISP` targeting options that belong to sub type `CARRIER_AND_ISP_TYPE_CARRIER`: `carrierAndIspDetails.type="CARRIER_AND_ISP_TYPE_CARRIER"`. The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `targetingOptionId` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. Example: `targetingOptionId desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListTargetingOptions` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, targetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, sensitiveCategoryDetails: record, subExchangeDetails: record, targetingOptionId: string, targetingType: string, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/targetingTypes/{targeting_type}/targetingOptions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a single targeting option.
#
# GET /v2/targetingTypes/{targetingType}/targetingOptions/{targetingOptionId}
# operationId: displayvideo.targetingTypes.targetingOptions.get
export def "targeting-types-targeting-options get" [
  targeting_type: string
  targeting_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Required. The Advertiser this request is being made in the context of.
]: nothing -> record<ageRangeDetails: record<ageRange: string>, appCategoryDetails: record<displayName: string>, audioContentTypeDetails: record<audioContentType: string>, authorizedSellerStatusDetails: record<authorizedSellerStatus: string>, browserDetails: record<displayName: string>, businessChainDetails: record<businessChain: string, geoRegion: string, geoRegionType: string>, carrierAndIspDetails: record<displayName: string, type: string>, categoryDetails: record<displayName: string>, contentDurationDetails: record<contentDuration: string>, contentGenreDetails: record<displayName: string>, contentInstreamPositionDetails: record<contentInstreamPosition: string>, contentOutstreamPositionDetails: record<contentOutstreamPosition: string>, contentStreamTypeDetails: record<contentStreamType: string>, deviceMakeModelDetails: record<displayName: string>, deviceTypeDetails: record<deviceType: string>, digitalContentLabelDetails: record<contentRatingTier: string>, environmentDetails: record<environment: string>, exchangeDetails: record<exchange: string>, genderDetails: record<gender: string>, geoRegionDetails: record<displayName: string, geoRegionType: string>, householdIncomeDetails: record<householdIncome: string>, languageDetails: record<displayName: string>, name: string, nativeContentPositionDetails: record<contentPosition: string>, omidDetails: record<omid: string>, onScreenPositionDetails: record<onScreenPosition: string>, operatingSystemDetails: record<displayName: string>, parentalStatusDetails: record<parentalStatus: string>, poiDetails: record<displayName: string, latitude: float, longitude: float>, sensitiveCategoryDetails: record<sensitiveCategory: string>, subExchangeDetails: record<displayName: string>, targetingOptionId: string, targetingType: string, userRewardedContentDetails: record<userRewardedContent: string>, videoPlayerSizeDetails: record<videoPlayerSize: string>, viewabilityDetails: record<viewability: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "advertiserId" $advertiser_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({targeting_type: (encode-path-segment $targeting_type), targeting_option_id: (encode-path-segment $targeting_option_id)} | format pattern "/v2/targetingTypes/{targeting_type}/targetingOptions/{targeting_option_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for targeting options of a given type based on the given search terms.
#
# POST /v2/targetingTypes/{targetingType}/targetingOptions:search
# operationId: displayvideo.targetingTypes.targetingOptions.search
# --businessChainSearchTerms shape: {businessChainQuery?: string, regionQuery?: string}
# --geoRegionSearchTerms shape: {geoRegionQuery?: string}
# --poiSearchTerms shape: {poiQuery?: string}
export def "targeting-types-targeting-options-search list" [
  targeting_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --advertiser-id: string # Required. The Advertiser this request is being made in the context of. (format: int64)
  --business-chain-search-terms: record # Search terms for Business Chain targeting options. At least one of the field should be populated. — shape: {businessChainQuery?: string, regionQuery?: string}
  --geo-region-search-terms: record # Search terms for geo region targeting options. — shape: {geoRegionQuery?: string}
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`. Returns error code `INVALID_ARGUMENT` if an invalid value is specified. (format: int32)
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `SearchTargetingOptions` method. If not specified, the first page of results will be returned.
  --poi-search-terms: record # Search terms for POI targeting options. — shape: {poiQuery?: string}
]: any -> record<nextPageToken: string, targetingOptions: table<ageRangeDetails: record, appCategoryDetails: record, audioContentTypeDetails: record, authorizedSellerStatusDetails: record, browserDetails: record, businessChainDetails: record, carrierAndIspDetails: record, categoryDetails: record, contentDurationDetails: record, contentGenreDetails: record, contentInstreamPositionDetails: record, contentOutstreamPositionDetails: record, contentStreamTypeDetails: record, deviceMakeModelDetails: record, deviceTypeDetails: record, digitalContentLabelDetails: record, environmentDetails: record, exchangeDetails: record, genderDetails: record, geoRegionDetails: record, householdIncomeDetails: record, languageDetails: record, name: string, nativeContentPositionDetails: record, omidDetails: record, onScreenPositionDetails: record, operatingSystemDetails: record, parentalStatusDetails: record, poiDetails: record, sensitiveCategoryDetails: record, subExchangeDetails: record, targetingOptionId: string, targetingType: string, userRewardedContentDetails: record, videoPlayerSizeDetails: record, viewabilityDetails: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({targeting_type: (encode-path-segment $targeting_type)} | format pattern "/v2/targetingTypes/{targeting_type}/targetingOptions:search") $qp)
  let req_body = {"advertiserId": $advertiser_id, "businessChainSearchTerms": $business_chain_search_terms, "geoRegionSearchTerms": $geo_region_search_terms, "pageSize": $page_size, "pageToken": $page_token, "poiSearchTerms": $poi_search_terms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists users that are accessible to the current user. If two users have user roles on the same partner or advertiser, they can access each other.
#
# GET /v2/users
# operationId: displayvideo.users.list
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --filter: string # Allows filtering by user properties. Supported syntax: * Filter expressions are made up of one or more restrictions. * Restrictions can be combined by the logical operator `AND`. * A restriction has the form of `{field} {operator} {value}`. * The operator must be `CONTAINS (:)` or `EQUALS (=)`. * The operator must be `CONTAINS (:)` for the following fields: - `displayName` - `email` * The operator must be `EQUALS (=)` for the following fields: - `assignedUserRole.userRole` - `assignedUserRole.partnerId` - `assignedUserRole.advertiserId` - `assignedUserRole.entityType`: A synthetic field of AssignedUserRole used for filtering. Identifies the type of entity to which the user role is assigned. Valid values are `Partner` and `Advertiser`. - `assignedUserRole.parentPartnerId`: A synthetic field of AssignedUserRole used for filtering. Identifies the parent partner of the entity to which the user role is assigned." Examples: * The user with displayName containing `foo`: `displayName:"foo"` * The user with email containing `bar`: `email:"bar"` * All users with standard user roles: `assignedUserRole.userRole="STANDARD"` * All users with user roles for partner 123: `assignedUserRole.partnerId="123"` * All users with user roles for advertiser 123: `assignedUserRole.advertiserId="123"` * All users with partner level user roles: `entityType="PARTNER"` * All users with user roles for partner 123 and advertisers under partner 123: `parentPartnerId="123"` The length of this field should be no more than 500 characters.
  --order-by: string # Field by which to sort the list. Acceptable values are: * `displayName` (default) The default sorting order is ascending. To specify descending order for a field, a suffix "desc" should be added to the field name. For example, `displayName desc`.
  --page-size: int # Requested page size. Must be between `1` and `200`. If unspecified will default to `100`.
  --page-token: string # A token identifying a page of results the server should return. Typically, this is the value of next_page_token returned from the previous call to `ListUsers` method. If not specified, the first page of results will be returned.
]: nothing -> record<nextPageToken: string, users: table<assignedUserRoles: list, displayName: string, email: string, name: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new user. Returns the newly created user if successful.
#
# POST /v2/users
# operationId: displayvideo.users.create
# --assignedUserRoles item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --assigned-user-roles: list # The assigned user roles. Required in CreateUser. Output only in UpdateUser. Can only be updated through BulkEditAssignedUserRoles. — item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
  --display-name: string # Required. The display name of the user. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --email: string # Required. Immutable. The email address used to identify the user.
]: any -> record<assignedUserRoles: table<advertiserId: string, assignedUserRoleId: string, partnerId: string, userRole: string>, displayName: string, email: string, name: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let req_body = {"assignedUserRoles": $assigned_user_roles, "displayName": $display_name, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a user.
#
# DELETE /v2/users/{userId}
# operationId: displayvideo.users.delete
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a user.
#
# GET /v2/users/{userId}
# operationId: displayvideo.users.get
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<assignedUserRoles: table<advertiserId: string, assignedUserRoleId: string, partnerId: string, userRole: string>, displayName: string, email: string, name: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing user. Returns the updated user if successful.
#
# PATCH /v2/users/{userId}
# operationId: displayvideo.users.patch
# --assignedUserRoles item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
export def "users update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --update-mask: string # Required. The mask to control which fields to update.
  --assigned-user-roles: list # The assigned user roles. Required in CreateUser. Output only in UpdateUser. Can only be updated through BulkEditAssignedUserRoles. — item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
  --display-name: string # Required. The display name of the user. Must be UTF-8 encoded with a maximum size of 240 bytes.
  --email: string # Required. Immutable. The email address used to identify the user.
]: any -> record<assignedUserRoles: table<advertiserId: string, assignedUserRoleId: string, partnerId: string, userRole: string>, displayName: string, email: string, name: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}") $qp)
  let req_body = {"assignedUserRoles": $assigned_user_roles, "displayName": $display_name, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk edits user roles for a user. The operation will delete the assigned user roles provided in BulkEditAssignedUserRolesRequest.deletedAssignedUserRoles and then assign the user roles provided in BulkEditAssignedUserRolesRequest.createdAssignedUserRoles.
#
# POST /v2/users/{userId}:bulkEditAssignedUserRoles
# operationId: displayvideo.users.bulkEditAssignedUserRoles
# --createdAssignedUserRoles item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
export def "users create-bulk-edit-assigned-roles" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --created-assigned-user-roles: list # The assigned user roles to create in batch, specified as a list of AssignedUserRoles. — item shape: {advertiserId?: string, partnerId?: string, userRole?: "USER_ROLE_UNSPECIFIED"|"ADMIN"|"ADMIN_PARTNER_CLIENT"|"STANDARD"|"STANDARD_PLANNER"|"STANDARD_PLANNER_LIMITED"|"STANDARD_PARTNER_CLIENT"|"READ_ONLY"|"REPORTING_ONLY"|"LIMITED_REPORTING_ONLY"|"CREATIVE"|"CREATIVE_ADMIN"}
  --deleted-assigned-user-roles: list<string> # The assigned user roles to delete in batch, specified as a list of assigned_user_role_ids. The format of assigned_user_role_id is `entityType-entityid`, for example `partner-123`.
]: any -> record<createdAssignedUserRoles: table<advertiserId: string, assignedUserRoleId: string, partnerId: string, userRole: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}:bulkEditAssignedUserRoles") $qp)
  let req_body = {"createdAssignedUserRoles": $created_assigned_user_roles, "deletedAssignedUserRoles": $deleted_assigned_user_roles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the latest state of an asynchronous SDF download task operation. Clients should poll this method at intervals of 30 seconds.
#
# GET /v2/{name}
# operationId: displayvideo.sdfdownloadtasks.operations.get
export def "sdfdownloadtasks get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
