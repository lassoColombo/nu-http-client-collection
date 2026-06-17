# Auto-generated client for YouTube Data API v3 vv3
# Source: https://api.apis.guru/v2/specs/googleapis.com/youtube/v3/openapi.json
# Auth: --token flag or $env.YOUTUBE_DATA_API_V3_TOKEN

const BASE_URL = "https://youtube.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o YOUTUBE_DATA_API_V3_TOKEN | default "" }
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

def base-url-completer [] { ["https://youtube.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def moderation-status-completer [] { ["heldForReview" "likelySpam" "published" "rejected"] }
def order-completer [] { ["orderUnspecified" "relevance" "time"] }
def text-format-completer [] { ["html" "plainText" "textFormatUnspecified"] }
def broadcast-status-completer [] { ["active" "all" "broadcastStatusFilterUnspecified" "completed" "upcoming"] }
def broadcast-type-completer [] { ["all" "broadcastTypeFilterUnspecified" "event" "persistent"] }
def cue-type-completer [] { ["cueTypeAd" "cueTypeUnspecified"] }
def broadcast-status-completer-1 [] { ["complete" "live" "statusUnspecified" "testing"] }
def mode-completer [] { ["all_current" "listMembersModeUnknown" "updates"] }
def channel-type-completer [] { ["any" "channelTypeUnspecified" "show"] }
def event-type-completer [] { ["completed" "live" "none" "upcoming"] }
def order-completer-1 [] { ["date" "rating" "relevance" "searchSortUnspecified" "title" "videoCount" "viewCount"] }
def safe-search-completer [] { ["moderate" "none" "safeSearchSettingUnspecified" "strict"] }
def video-caption-completer [] { ["any" "closedCaption" "none" "videoCaptionUnspecified"] }
def video-definition-completer [] { ["any" "high" "standard"] }
def video-dimension-completer [] { ["2d" "3d" "any"] }
def video-duration-completer [] { ["any" "long" "medium" "short" "videoDurationUnspecified"] }
def video-embeddable-completer [] { ["any" "true" "videoEmbeddableUnspecified"] }
def video-license-completer [] { ["any" "creativeCommon" "youtube"] }
def video-syndicated-completer [] { ["any" "true" "videoSyndicatedUnspecified"] }
def video-type-completer [] { ["any" "episode" "movie" "videoTypeUnspecified"] }
def order-completer-2 [] { ["alphabetical" "relevance" "subscriptionOrderUnspecified" "unread"] }
def type-completer [] { ["channelToStoreLink" "linkUnspecified"] }
def chart-completer [] { ["chartUnspecified" "mostPopular"] }
def my-rating-completer [] { ["dislike" "like" "none"] }
def rating-completer [] { ["dislike" "like" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "youtube-abuse-reports youtubeabuseReportsinsert" } } | get name | first)
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

# Inserts a new resource into this collection.
#
# POST /youtube/v3/abuseReports
# operationId: youtube.abuseReports.insert
# --abuseTypes item shape: {id?: string}
# --relatedEntities item shape: {entity?: record}
# --subject shape: {id?: string, typeId?: string, url?: string}
export def "youtube-abuse-reports youtubeabuseReportsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include.
  --abuse-types: list # item shape: {id?: string}
  --description: string
  --related-entities: list # item shape: {entity?: record}
  --subject: record # shape: {id?: string, typeId?: string, url?: string}
]: any -> record<abuseTypes: table<id: string>, description: string, relatedEntities: table<entity: record>, subject: record<id: string, typeId: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/abuseReports" $qp)
  let body = {"abuseTypes": $abuse_types, "description": $description, "relatedEntities": $related_entities, "subject": $subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/activities
# operationId: youtube.activities.list
export def "youtube-activities youtubeactivitieslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more activity resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in an activity resource, the snippet property contains other properties that identify the type of activity, a display title for the activity, and so forth. If you set *part=snippet*, the API response will also contain all of those nested properties.
  --channel-id: string
  --home: oneof<nothing, bool>
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --published-after: string
  --published-before: string
  --region-code: string
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "home" $home "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "publishedAfter" $published_after "scalar") (serialize-qp "publishedBefore" $published_before "scalar") (serialize-qp "regionCode" $region_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource.
#
# DELETE /youtube/v3/captions
# operationId: youtube.captions.delete
export def "youtube-captions youtubecaptionsdelete" [
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
  --id: string
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOf" $on_behalf_of "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/captions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/captions
# operationId: youtube.captions.list
export def "youtube-captions youtubecaptionslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more caption resource parts that the API response will include. The part names that you can include in the parameter value are id and snippet.
  --video-id: string # Returns the captions for the specified video.
  --id: list # Returns the captions with the given IDs for Stubby or Apiary.
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is on behalf of.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "videoId" $video_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "onBehalfOf" $on_behalf_of "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/captions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/captions
# operationId: youtube.captions.insert
export def "youtube-captions youtubecaptionsinsert" [
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
  --part: list # The *part* parameter specifies the caption resource parts that the API response will include. Set the parameter value to snippet.
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --sync: oneof<nothing, bool> # Extra parameter to allow automatically syncing the uploaded caption/transcript with the audio.
  --body: record
]: any -> record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOf" $on_behalf_of "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "sync" $sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/captions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/captions
# operationId: youtube.captions.update
export def "youtube-captions youtubecaptionsupdate" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more caption resource parts that the API response will include. The part names that you can include in the parameter value are id and snippet.
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is on behalf of.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --sync: oneof<nothing, bool> # Extra parameter to allow automatically syncing the uploaded caption/transcript with the audio.
  --body: record
]: any -> record<etag: string, id: string, kind: string, snippet: record<audioTrackType: string, failureReason: string, isAutoSynced: bool, isCC: bool, isDraft: bool, isEasyReader: bool, isLarge: bool, language: string, lastUpdated: string, name: string, status: string, trackKind: string, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOf" $on_behalf_of "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "sync" $sync "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/captions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Downloads a caption track.
#
# GET /youtube/v3/captions/{id}
# operationId: youtube.captions.download
export def "youtube-captions youtubecaptionsdownload" [
  id: string
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
  --on-behalf-of: string # ID of the Google+ Page for the channel that the request is be on behalf of
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --tfmt: string # Convert the captions into this format. Supported options are sbv, srt, and vtt.
  --tlang: string # tlang is the language code; machine translate the captions into this language.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "onBehalfOf" $on_behalf_of "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "tfmt" $tfmt "scalar") (serialize-qp "tlang" $tlang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/youtube/v3/captions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/channelBanners/insert
# operationId: youtube.channelBanners.insert
export def "youtube-channel-banners-insert youtubechannelBannersinsert" [
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
  --channel-id: string # Unused, channel_id is currently derived from the security context of the requestor.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --body: record
]: any -> record<etag: string, kind: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channelBanners/insert" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Deletes a resource.
#
# DELETE /youtube/v3/channelSections
# operationId: youtube.channelSections.delete
export def "youtube-channel-sections youtubechannelSectionsdelete" [
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
  --id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channelSections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/channelSections
# operationId: youtube.channelSections.list
export def "youtube-channel-sections youtubechannelSectionslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more channelSection resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, and contentDetails. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a channelSection resource, the snippet property contains other properties, such as a display title for the channelSection. If you set *part=snippet*, the API response will also contain all of those nested properties.
  --channel-id: string # Return the ChannelSections owned by the specified channel ID.
  --hl: string # Return content in specified language
  --id: list # Return the ChannelSections with the given IDs for Stubby or Apiary.
  --mine: oneof<nothing, bool> # Return the ChannelSections owned by the authenticated user.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, snippet: record, targeting: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "id" $id "multi") (serialize-qp "mine" $mine "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channelSections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/channelSections
# operationId: youtube.channelSections.insert
# --contentDetails shape: {channels?: list, playlists?: list}
# --snippet shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
# --targeting shape: {countries?: list, languages?: list, regions?: list}
export def "youtube-channel-sections youtubechannelSectionsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part names that you can include in the parameter value are snippet and contentDetails.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Details about a channelsection, including playlists and channels. — shape: {channels?: list, playlists?: list}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel section.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channelSection". (default: youtube#channelSection)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel section, including title, style and position. — shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
  --targeting: record # ChannelSection targeting setting. — shape: {countries?: list, languages?: list, regions?: list}
]: any -> record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channelSections" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "localizations": $localizations, "snippet": $snippet, "targeting": $targeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/channelSections
# operationId: youtube.channelSections.update
# --contentDetails shape: {channels?: list, playlists?: list}
# --snippet shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
# --targeting shape: {countries?: list, languages?: list, regions?: list}
export def "youtube-channel-sections youtubechannelSectionsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part names that you can include in the parameter value are snippet and contentDetails.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # Details about a channelsection, including playlists and channels. — shape: {channels?: list, playlists?: list}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel section.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channelSection". (default: youtube#channelSection)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel section, including title, style and position. — shape: {channelId?: string, defaultLanguage?: string, localized?: record, position?: int, style?: "channelsectionStyleUnspecified"|"horizontalRow"|"verticalList", title?: string, type?: "channelsectionTypeUndefined"|"singlePlaylist"|"multiplePlaylists"|"popularUploads"|"recentUploads"|"likes"|"allPlaylists"|"likedPlaylists"|"recentPosts"|"recentActivity"|"liveEvents"|"upcomingEvents"|"completedEvents"|"multipleChannels"|"postedVideos"|"postedPlaylists"|"subscriptions"}
  --targeting: record # ChannelSection targeting setting. — shape: {countries?: list, languages?: list, regions?: list}
]: any -> record<contentDetails: record<channels: list<string>, playlists: list<string>>, etag: string, id: string, kind: string, localizations: record, snippet: record<channelId: string, defaultLanguage: string, localized: record<title: string>, position: int, style: string, title: string, type: string>, targeting: record<countries: list<string>, languages: list<string>, regions: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channelSections" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "localizations": $localizations, "snippet": $snippet, "targeting": $targeting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/channels
# operationId: youtube.channels.list
export def "youtube-channels youtubechannelslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more channel resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a channel resource, the contentDetails property contains other properties, such as the uploads properties. As such, if you set *part=contentDetails*, the API response will also contain all of those nested properties.
  --category-id: string # Return the channels within the specified guide category ID.
  --for-username: string # Return the channel associated with a YouTube username.
  --hl: string # Stands for "host language". Specifies the localization language of the metadata to be filled into snippet.localized. The field is filled with the default metadata if there is no localization in the specified language. The parameter value must be a language code included in the list returned by the i18nLanguages.list method (e.g. en_US, es_MX).
  --id: list # Return the channels with the specified IDs.
  --managed-by-me: oneof<nothing, bool> # Return the channels managed by the authenticated user.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Return the ids of channels owned by the authenticated user.
  --my-subscribers: oneof<nothing, bool> # Return the channels subscribed to the authenticated user
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<auditDetails: record, brandingSettings: record, contentDetails: record, contentOwnerDetails: record, conversionPings: record, etag: string, id: string, kind: string, localizations: record, snippet: record, statistics: record, status: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "forUsername" $for_username "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "id" $id "multi") (serialize-qp "managedByMe" $managed_by_me "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "mySubscribers" $my_subscribers "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing resource.
#
# PUT /youtube/v3/channels
# operationId: youtube.channels.update
# --auditDetails shape: {communityGuidelinesGoodStanding?: bool, contentIdClaimsGoodStanding?: bool, copyrightStrikesGoodStanding?: bool}
# --brandingSettings shape: {channel?: record, hints?: list, image?: record, watch?: record}
# --contentDetails shape: {relatedPlaylists?: record}
# --contentOwnerDetails shape: {contentOwner?: string, timeLinked?: string}
# --conversionPings shape: {pings?: list}
# --snippet shape: {country?: string, customUrl?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, thumbnails?: record, title?: string}
# --statistics shape: {commentCount?: string, hiddenSubscriberCount?: bool, subscriberCount?: string, videoCount?: string, viewCount?: string}
# --status shape: {isLinked?: bool, longUploadsStatus?: "longUploadsUnspecified"|"allowed"|"eligible"|"disallowed", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", selfDeclaredMadeForKids?: bool}
# --topicDetails shape: {topicCategories?: list, topicIds?: list}
export def "youtube-channels youtubechannelsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The API currently only allows the parameter value to be set to either brandingSettings or invideoPromotion. (You cannot update both of those parts with a single request.) Note that this method overrides the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies.
  --on-behalf-of-content-owner: string # The *onBehalfOfContentOwner* parameter indicates that the authenticated user is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with needs to be linked to the specified YouTube content owner.
  --audit-details: record # The auditDetails object encapsulates channel data that is relevant for YouTube Partners during the audit process. — shape: {communityGuidelinesGoodStanding?: bool, contentIdClaimsGoodStanding?: bool, copyrightStrikesGoodStanding?: bool}
  --branding-settings: record # Branding properties of a YouTube channel. — shape: {channel?: record, hints?: list, image?: record, watch?: record}
  --content-details: record # Details about the content of a channel. — shape: {relatedPlaylists?: record}
  --content-owner-details: record # The contentOwnerDetails object encapsulates channel data that is relevant for YouTube Partners linked with the channel. — shape: {contentOwner?: string, timeLinked?: string}
  --conversion-pings: record # The conversionPings object encapsulates information about conversion pings that need to be respected by the channel. — shape: {pings?: list}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the channel.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#channel". (default: youtube#channel)
  --localizations: record # Localizations for different languages
  --snippet: record # Basic details about a channel, including title, description and thumbnails. — shape: {country?: string, customUrl?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about a channel: number of subscribers, number of videos in the channel, etc. — shape: {commentCount?: string, hiddenSubscriberCount?: bool, subscriberCount?: string, videoCount?: string, viewCount?: string}
  --status: record # JSON template for the status part of a channel. — shape: {isLinked?: bool, longUploadsStatus?: "longUploadsUnspecified"|"allowed"|"eligible"|"disallowed", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", selfDeclaredMadeForKids?: bool}
  --topic-details: record # Freebase topic information related to the channel. — shape: {topicCategories?: list, topicIds?: list}
]: any -> record<auditDetails: record<communityGuidelinesGoodStanding: bool, contentIdClaimsGoodStanding: bool, copyrightStrikesGoodStanding: bool>, brandingSettings: record<channel: record<country: string, defaultLanguage: string, defaultTab: string, description: string, featuredChannelsTitle: string, featuredChannelsUrls: list, keywords: string, moderateComments: bool, profileColor: string, showBrowseView: bool, showRelatedChannels: bool, title: string, trackingAnalyticsAccountId: string, unsubscribedTrailer: string>, hints: list<record>, image: record<backgroundImageUrl: record, bannerExternalUrl: string, bannerImageUrl: string, bannerMobileExtraHdImageUrl: string, bannerMobileHdImageUrl: string, bannerMobileImageUrl: string, bannerMobileLowImageUrl: string, bannerMobileMediumHdImageUrl: string, bannerTabletExtraHdImageUrl: string, bannerTabletHdImageUrl: string, bannerTabletImageUrl: string, bannerTabletLowImageUrl: string, bannerTvHighImageUrl: string, bannerTvImageUrl: string, bannerTvLowImageUrl: string, bannerTvMediumImageUrl: string, largeBrandedBannerImageImapScript: record, largeBrandedBannerImageUrl: record, smallBrandedBannerImageImapScript: record, smallBrandedBannerImageUrl: record, trackingImageUrl: string, watchIconImageUrl: string>, watch: record<backgroundColor: string, featuredPlaylistId: string, textColor: string>>, contentDetails: record<relatedPlaylists: record<favorites: string, likes: string, uploads: string, watchHistory: string, watchLater: string>>, contentOwnerDetails: record<contentOwner: string, timeLinked: string>, conversionPings: record<pings: list<record>>, etag: string, id: string, kind: string, localizations: record, snippet: record<country: string, customUrl: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, hiddenSubscriberCount: bool, subscriberCount: string, videoCount: string, viewCount: string>, status: record<isLinked: bool, longUploadsStatus: string, madeForKids: bool, privacyStatus: string, selfDeclaredMadeForKids: bool>, topicDetails: record<topicCategories: list<string>, topicIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/channels" $qp)
  let body = {"auditDetails": $audit_details, "brandingSettings": $branding_settings, "contentDetails": $content_details, "contentOwnerDetails": $content_owner_details, "conversionPings": $conversion_pings, "etag": $etag, "id": $id, "kind": $kind, "localizations": $localizations, "snippet": $snippet, "statistics": $statistics, "status": $status, "topicDetails": $topic_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/commentThreads
# operationId: youtube.commentThreads.list
export def "youtube-comment-threads youtubecommentThreadslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more commentThread resource properties that the API response will include.
  --all-threads-related-to-channel-id: string # Returns the comment threads of all videos of the channel and the channel comments as well.
  --channel-id: string # Returns the comment threads for all the channel comments (ie does not include comments left on videos).
  --id: list # Returns the comment threads with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --moderation-status: string@moderation-status-completer # Limits the returned comment threads to those with the specified moderation status. Not compatible with the 'id' filter. Valid values: published, heldForReview, likelySpam.
  --order: string@order-completer
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --search-terms: string # Limits the returned comment threads to those matching the specified key words. Not compatible with the 'id' filter.
  --text-format: string@text-format-completer # The requested text format for the returned comments.
  --video-id: string # Returns the comment threads of the specified video.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, replies: record, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "allThreadsRelatedToChannelId" $all_threads_related_to_channel_id "scalar") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "moderationStatus" $moderation_status "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "searchTerms" $search_terms "scalar") (serialize-qp "textFormat" $text_format "scalar") (serialize-qp "videoId" $video_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/commentThreads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/commentThreads
# operationId: youtube.commentThreads.insert
# --replies shape: {comments?: list}
# --snippet shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
export def "youtube-comment-threads youtubecommentThreadsinsert" [
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
  --part: list # The *part* parameter identifies the properties that the API response will include. Set the parameter value to snippet. The snippet part has a quota cost of 2 units.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment thread.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#commentThread". (default: youtube#commentThread)
  --replies: record # Comments written in (direct or indirect) reply to the top level comment. — shape: {comments?: list}
  --snippet: record # Basic details about a comment thread. — shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
]: any -> record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/commentThreads" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "replies": $replies, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/commentThreads
# operationId: youtube.youtube.v3.updateCommentThreads
# --replies shape: {comments?: list}
# --snippet shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
export def "youtube-comment-threads youtubeyoutubev3updateCommentThreads" [
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
  --part: list # The *part* parameter specifies a comma-separated list of commentThread resource properties that the API response will include. You must at least include the snippet part in the parameter value since that part contains all of the properties that the API request can update.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment thread.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#commentThread". (default: youtube#commentThread)
  --replies: record # Comments written in (direct or indirect) reply to the top level comment. — shape: {comments?: list}
  --snippet: record # Basic details about a comment thread. — shape: {canReply?: bool, channelId?: string, isPublic?: bool, topLevelComment?: record, totalReplyCount?: int, videoId?: string}
]: any -> record<etag: string, id: string, kind: string, replies: record<comments: list<record>>, snippet: record<canReply: bool, channelId: string, isPublic: bool, topLevelComment: record<etag: string, id: string, kind: string, snippet: record>, totalReplyCount: int, videoId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/commentThreads" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "replies": $replies, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a resource.
#
# DELETE /youtube/v3/comments
# operationId: youtube.comments.delete
export def "youtube-comments youtubecommentsdelete" [
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
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/comments
# operationId: youtube.comments.list
export def "youtube-comments youtubecommentslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more comment resource properties that the API response will include.
  --id: list # Returns the comments with the given IDs for One Platform.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --parent-id: string # Returns replies to the specified comment. Note, currently YouTube features only one level of replies (ie replies to top level comments). However replies to replies may be supported in the future.
  --text-format: string@text-format-completer # The requested text format for the returned comments.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "parentId" $parent_id "scalar") (serialize-qp "textFormat" $text_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/comments
# operationId: youtube.comments.insert
# --snippet shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
export def "youtube-comments youtubecommentsinsert" [
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
  --part: list # The *part* parameter identifies the properties that the API response will include. Set the parameter value to snippet. The snippet part has a quota cost of 2 units.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#comment". (default: youtube#comment)
  --snippet: record # Basic details about a comment, such as its author and text. — shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
]: any -> record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/comments
# operationId: youtube.comments.update
# --snippet shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
export def "youtube-comments youtubecommentsupdate" [
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
  --part: list # The *part* parameter identifies the properties that the API response will include. You must at least include the snippet part in the parameter value since that part contains all of the properties that the API request can update.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the comment.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#comment". (default: youtube#comment)
  --snippet: record # Basic details about a comment, such as its author and text. — shape: {authorChannelId?: record, authorChannelUrl?: string, authorDisplayName?: string, authorProfileImageUrl?: string, canRate?: bool, channelId?: string, likeCount?: int, moderationStatus?: "published"|"heldForReview"|"likelySpam"|"rejected", parentId?: string, publishedAt?: string, textDisplay?: string, textOriginal?: string, updatedAt?: string, videoId?: string, viewerRating?: "none"|"like"|"dislike"}
]: any -> record<etag: string, id: string, kind: string, snippet: record<authorChannelId: record<value: string>, authorChannelUrl: string, authorDisplayName: string, authorProfileImageUrl: string, canRate: bool, channelId: string, likeCount: int, moderationStatus: string, parentId: string, publishedAt: string, textDisplay: string, textOriginal: string, updatedAt: string, videoId: string, viewerRating: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Expresses the caller's opinion that one or more comments should be flagged as spam.
#
# POST /youtube/v3/comments/markAsSpam
# operationId: youtube.comments.markAsSpam
export def "youtube-comments-mark-as-spam youtubecommentsmarkAsSpam" [
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
  --id: list # Flags the comments with the given IDs as spam in the caller's opinion.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments/markAsSpam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the moderation status of one or more comments.
#
# POST /youtube/v3/comments/setModerationStatus
# operationId: youtube.comments.setModerationStatus
export def "youtube-comments-set-moderation-status youtubecommentssetModerationStatus" [
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
  --id: list # Modifies the moderation status of the comments with the given IDs
  --moderation-status: string@moderation-status-completer # Specifies the requested moderation status. Note, comments can be in statuses, which are not available through this call. For example, this call does not allow to mark a comment as 'likely spam'. Valid values: MODERATION_STATUS_PUBLISHED, MODERATION_STATUS_HELD_FOR_REVIEW, MODERATION_STATUS_REJECTED.
  --ban-author: oneof<nothing, bool> # If set to true the author of the comment gets added to the ban list. This means all future comments of the author will autmomatically be rejected. Only valid in combination with STATUS_REJECTED.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "multi") (serialize-qp "moderationStatus" $moderation_status "scalar") (serialize-qp "banAuthor" $ban_author "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/comments/setModerationStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/i18nLanguages
# operationId: youtube.i18nLanguages.list
export def "youtube-i18n-languages youtubei18nLanguageslist" [
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
  --part: list # The *part* parameter specifies the i18nLanguage resource properties that the API response will include. Set the parameter value to snippet.
  --hl: string
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/i18nLanguages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/i18nRegions
# operationId: youtube.i18nRegions.list
export def "youtube-i18n-regions youtubei18nRegionslist" [
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
  --part: list # The *part* parameter specifies the i18nRegion resource properties that the API response will include. Set the parameter value to snippet.
  --hl: string
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/i18nRegions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a given broadcast.
#
# DELETE /youtube/v3/liveBroadcasts
# operationId: youtube.liveBroadcasts.delete
export def "youtube-live-broadcasts youtubeliveBroadcastsdelete" [
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
  --id: string # Broadcast to delete.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the list of broadcasts associated with the given channel.
#
# GET /youtube/v3/liveBroadcasts
# operationId: youtube.liveBroadcasts.list
export def "youtube-live-broadcasts youtubeliveBroadcastslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, status and statistics.
  --broadcast-status: string@broadcast-status-completer # Return broadcasts with a certain status, e.g. active broadcasts.
  --broadcast-type: string@broadcast-type-completer # Return only broadcasts with the selected type.
  --id: list # Return broadcasts with the given ids from Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, statistics: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "broadcastStatus" $broadcast_status "scalar") (serialize-qp "broadcastType" $broadcast_type "scalar") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new stream for the authenticated user.
#
# POST /youtube/v3/liveBroadcasts
# operationId: youtube.liveBroadcasts.insert
# --contentDetails shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, projection?: "projectionUnspecified"|"rectangular"|"360"|"mesh", recordFromStart?: bool, startWithSlate?: bool, stereoLayout?: "stereoLayoutUnspecified"|"mono"|"leftRight"|"topBottom"}
# --snippet shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
# --statistics shape: {concurrentViewers?: string}
# --status shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
export def "youtube-live-broadcasts youtubeliveBroadcastsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, contentDetails, and status.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Detailed settings of a broadcast. — shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, projection?: "projectionUnspecified"|"rectangular"|"360"|"mesh", recordFromStart?: bool, startWithSlate?: bool, stereoLayout?: "stereoLayoutUnspecified"|"mono"|"leftRight"|"topBottom"}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the broadcast.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveBroadcast". (default: youtube#liveBroadcast)
  --snippet: record # Basic broadcast information. — shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the live broadcast. These represent a snapshot of the values at the time of the request. Statistics are only returned for live broadcasts. — shape: {concurrentViewers?: string}
  --status: record # Live broadcast state. — shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
]: any -> record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "statistics": $statistics, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing broadcast for the authenticated user.
#
# PUT /youtube/v3/liveBroadcasts
# operationId: youtube.liveBroadcasts.update
# --contentDetails shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, projection?: "projectionUnspecified"|"rectangular"|"360"|"mesh", recordFromStart?: bool, startWithSlate?: bool, stereoLayout?: "stereoLayoutUnspecified"|"mono"|"leftRight"|"topBottom"}
# --snippet shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
# --statistics shape: {concurrentViewers?: string}
# --status shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
export def "youtube-live-broadcasts youtubeliveBroadcastsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, contentDetails, and status. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a broadcast's privacy status is defined in the status part. As such, if your request is updating a private or unlisted broadcast, and the request's part parameter value includes the status part, the broadcast's privacy setting will be updated to whatever value the request body specifies. If the request body does not specify a value, the existing privacy setting will be removed and the broadcast will revert to the default privacy setting.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # Detailed settings of a broadcast. — shape: {boundStreamId?: string, boundStreamLastUpdateTimeMs?: string, closedCaptionsType?: "closedCaptionsTypeUnspecified"|"closedCaptionsDisabled"|"closedCaptionsHttpPost"|"closedCaptionsEmbedded", enableAutoStart?: bool, enableAutoStop?: bool, enableClosedCaptions?: bool, enableContentEncryption?: bool, enableDvr?: bool, enableEmbed?: bool, enableLowLatency?: bool, latencyPreference?: "latencyPreferenceUnspecified"|"normal"|"low"|"ultraLow", mesh?: string, monitorStream?: record, projection?: "projectionUnspecified"|"rectangular"|"360"|"mesh", recordFromStart?: bool, startWithSlate?: bool, stereoLayout?: "stereoLayoutUnspecified"|"mono"|"leftRight"|"topBottom"}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the broadcast.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveBroadcast". (default: youtube#liveBroadcast)
  --snippet: record # Basic broadcast information. — shape: {actualEndTime?: string, actualStartTime?: string, channelId?: string, description?: string, isDefaultBroadcast?: bool, liveChatId?: string, publishedAt?: string, scheduledEndTime?: string, scheduledStartTime?: string, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the live broadcast. These represent a snapshot of the values at the time of the request. Statistics are only returned for live broadcasts. — shape: {concurrentViewers?: string}
  --status: record # Live broadcast state. — shape: {lifeCycleStatus?: "lifeCycleStatusUnspecified"|"created"|"ready"|"testing"|"live"|"complete"|"revoked"|"testStarting"|"liveStarting", liveBroadcastPriority?: "liveBroadcastPriorityUnspecified"|"low"|"normal"|"high", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", recordingStatus?: "liveBroadcastRecordingStatusUnspecified"|"notRecording"|"recording"|"recorded", selfDeclaredMadeForKids?: bool}
]: any -> record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "statistics": $statistics, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Bind a broadcast to a stream.
#
# POST /youtube/v3/liveBroadcasts/bind
# operationId: youtube.liveBroadcasts.bind
export def "youtube-live-broadcasts-bind youtubeliveBroadcastsbind" [
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
  --id: string # Broadcast to bind to the stream
  --part: list # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --stream-id: string # Stream to bind, if not set unbind the current one.
]: nothing -> record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "streamId" $stream_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts/bind" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert cuepoints in a broadcast
#
# POST /youtube/v3/liveBroadcasts/cuepoint
# operationId: youtube.liveBroadcasts.insertCuepoint
export def "youtube-live-broadcasts-cuepoint youtubeliveBroadcastsinsertCuepoint" [
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
  --id: string # Broadcast to insert ads to, or equivalently `external_video_id` for internal use.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --part: list # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status.
  --cue-type: string@cue-type-completer
  --duration-secs: int # The duration of this cuepoint. (format: uint32)
  --etag: string
  --id: string # The identifier for cuepoint resource.
  --insertion-offset-time-ms: string # The time when the cuepoint should be inserted by offset to the broadcast actual start time. (format: int64)
  --walltime-ms: string # The wall clock time at which the cuepoint should be inserted. Only one of insertion_offset_time_ms and walltime_ms may be set at a time. (format: uint64)
]: any -> record<cueType: string, durationSecs: int, etag: string, id: string, insertionOffsetTimeMs: string, walltimeMs: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts/cuepoint" $qp)
  let body = {"cueType": $cue_type, "durationSecs": $duration_secs, "etag": $etag, "id": $id, "insertionOffsetTimeMs": $insertion_offset_time_ms, "walltimeMs": $walltime_ms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transition a broadcast to a given status.
#
# POST /youtube/v3/liveBroadcasts/transition
# operationId: youtube.liveBroadcasts.transition
export def "youtube-live-broadcasts-transition youtubeliveBroadcaststransition" [
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
  --broadcast-status: string@broadcast-status-completer-1 # The status to which the broadcast is going to transition.
  --id: string # Broadcast to transition.
  --part: list # The *part* parameter specifies a comma-separated list of one or more liveBroadcast resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, contentDetails, and status.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> record<contentDetails: record<boundStreamId: string, boundStreamLastUpdateTimeMs: string, closedCaptionsType: string, enableAutoStart: bool, enableAutoStop: bool, enableClosedCaptions: bool, enableContentEncryption: bool, enableDvr: bool, enableEmbed: bool, enableLowLatency: bool, latencyPreference: string, mesh: string, monitorStream: record<broadcastStreamDelayMs: int, embedHtml: string, enableMonitorStream: bool>, projection: string, recordFromStart: bool, startWithSlate: bool, stereoLayout: string>, etag: string, id: string, kind: string, snippet: record<actualEndTime: string, actualStartTime: string, channelId: string, description: string, isDefaultBroadcast: bool, liveChatId: string, publishedAt: string, scheduledEndTime: string, scheduledStartTime: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<concurrentViewers: string>, status: record<lifeCycleStatus: string, liveBroadcastPriority: string, madeForKids: bool, privacyStatus: string, recordingStatus: string, selfDeclaredMadeForKids: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "broadcastStatus" $broadcast_status "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveBroadcasts/transition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a chat ban.
#
# DELETE /youtube/v3/liveChat/bans
# operationId: youtube.liveChatBans.delete
export def "youtube-live-chat-bans youtubeliveChatBansdelete" [
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
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/bans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/bans
# operationId: youtube.liveChatBans.insert
# --snippet shape: {banDurationSeconds?: string, bannedUserDetails?: record, liveChatId?: string, type?: "liveChatBanTypeUnspecified"|"permanent"|"temporary"}
export def "youtube-live-chat-bans youtubeliveChatBansinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response returns. Set the parameter value to snippet.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the ban.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string `"youtube#liveChatBan"`. (default: youtube#liveChatBan)
  --snippet: record # shape: {banDurationSeconds?: string, bannedUserDetails?: record, liveChatId?: string, type?: "liveChatBanTypeUnspecified"|"permanent"|"temporary"}
]: any -> record<etag: string, id: string, kind: string, snippet: record<banDurationSeconds: string, bannedUserDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>, liveChatId: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/bans" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a chat message.
#
# DELETE /youtube/v3/liveChat/messages
# operationId: youtube.liveChatMessages.delete
export def "youtube-live-chat-messages youtubeliveChatMessagesdelete" [
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
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/liveChat/messages
# operationId: youtube.liveChatMessages.list
export def "youtube-live-chat-messages youtubeliveChatMessageslist" [
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
  --live-chat-id: string # The id of the live chat for which comments should be returned.
  --part: list # The *part* parameter specifies the liveChatComment resource parts that the API response will include. Supported values are id and snippet.
  --hl: string # Specifies the localization language in which the system messages should be returned.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken property identify other pages that could be retrieved.
  --profile-image-size: int # Specifies the size of the profile image that should be returned for each user.
]: nothing -> record<etag: string, eventId: string, items: table<authorDetails: record, etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, offlineAt: string, pageInfo: record<resultsPerPage: int, totalResults: int>, pollingIntervalMillis: int, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "liveChatId" $live_chat_id "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "profileImageSize" $profile_image_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/messages
# operationId: youtube.liveChatMessages.insert
# --authorDetails shape: {channelId?: string, channelUrl?: string, displayName?: string, isChatModerator?: bool, isChatOwner?: bool, isChatSponsor?: bool, isVerified?: bool, profileImageUrl?: string}
# --snippet shape: {authorChannelId?: string, displayMessage?: string, fanFundingEventDetails?: record, giftMembershipReceivedDetails?: record, hasDisplayContent?: bool, liveChatId?: string, memberMilestoneChatDetails?: record, membershipGiftingDetails?: record, messageDeletedDetails?: record, messageRetractedDetails?: record, newSponsorDetails?: record, publishedAt?: string, superChatDetails?: record, superStickerDetails?: record, textMessageDetails?: record, type?: "invalidType"|"textMessageEvent"|"tombstone"|"fanFundingEvent"|"chatEndedEvent"|"sponsorOnlyModeStartedEvent"|"sponsorOnlyModeEndedEvent"|"newSponsorEvent"|"memberMilestoneChatEvent"|"membershipGiftingEvent"|"giftMembershipReceivedEvent"|"messageDeletedEvent"|"messageRetractedEvent"|"userBannedEvent"|"superChatEvent"|"superStickerEvent", userBannedDetails?: record}
export def "youtube-live-chat-messages youtubeliveChatMessagesinsert" [
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
  --part: list # The *part* parameter serves two purposes. It identifies the properties that the write operation will set as well as the properties that the API response will include. Set the parameter value to snippet.
  --author-details: record # shape: {channelId?: string, channelUrl?: string, displayName?: string, isChatModerator?: bool, isChatOwner?: bool, isChatSponsor?: bool, isVerified?: bool, profileImageUrl?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the message.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveChatMessage". (default: youtube#liveChatMessage)
  --snippet: record # Next ID: 33 — shape: {authorChannelId?: string, displayMessage?: string, fanFundingEventDetails?: record, giftMembershipReceivedDetails?: record, hasDisplayContent?: bool, liveChatId?: string, memberMilestoneChatDetails?: record, membershipGiftingDetails?: record, messageDeletedDetails?: record, messageRetractedDetails?: record, newSponsorDetails?: record, publishedAt?: string, superChatDetails?: record, superStickerDetails?: record, textMessageDetails?: record, type?: "invalidType"|"textMessageEvent"|"tombstone"|"fanFundingEvent"|"chatEndedEvent"|"sponsorOnlyModeStartedEvent"|"sponsorOnlyModeEndedEvent"|"newSponsorEvent"|"memberMilestoneChatEvent"|"membershipGiftingEvent"|"giftMembershipReceivedEvent"|"messageDeletedEvent"|"messageRetractedEvent"|"userBannedEvent"|"superChatEvent"|"superStickerEvent", userBannedDetails?: record}
]: any -> record<authorDetails: record<channelId: string, channelUrl: string, displayName: string, isChatModerator: bool, isChatOwner: bool, isChatSponsor: bool, isVerified: bool, profileImageUrl: string>, etag: string, id: string, kind: string, snippet: record<authorChannelId: string, displayMessage: string, fanFundingEventDetails: record<amountDisplayString: string, amountMicros: string, currency: string, userComment: string>, giftMembershipReceivedDetails: record<associatedMembershipGiftingMessageId: string, gifterChannelId: string, memberLevelName: string>, hasDisplayContent: bool, liveChatId: string, memberMilestoneChatDetails: record<memberLevelName: string, memberMonth: int, userComment: string>, membershipGiftingDetails: record<giftMembershipsCount: int, giftMembershipsLevelName: string>, messageDeletedDetails: record<deletedMessageId: string>, messageRetractedDetails: record<retractedMessageId: string>, newSponsorDetails: record<isUpgrade: bool, memberLevelName: string>, publishedAt: string, superChatDetails: record<amountDisplayString: string, amountMicros: string, currency: string, tier: int, userComment: string>, superStickerDetails: record<amountDisplayString: string, amountMicros: string, currency: string, superStickerMetadata: record, tier: int>, textMessageDetails: record<messageText: string>, type: string, userBannedDetails: record<banDurationSeconds: string, banType: string, bannedUserDetails: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/messages" $qp)
  let body = {"authorDetails": $author_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a chat moderator.
#
# DELETE /youtube/v3/liveChat/moderators
# operationId: youtube.liveChatModerators.delete
export def "youtube-live-chat-moderators youtubeliveChatModeratorsdelete" [
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
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/moderators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/liveChat/moderators
# operationId: youtube.liveChatModerators.list
export def "youtube-live-chat-moderators youtubeliveChatModeratorslist" [
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
  --live-chat-id: string # The id of the live chat for which moderators should be returned.
  --part: list # The *part* parameter specifies the liveChatModerator resource parts that the API response will include. Supported values are id and snippet.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "liveChatId" $live_chat_id "scalar") (serialize-qp "part" $part "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/moderators" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/liveChat/moderators
# operationId: youtube.liveChatModerators.insert
# --snippet shape: {liveChatId?: string, moderatorDetails?: record}
export def "youtube-live-chat-moderators youtubeliveChatModeratorsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response returns. Set the parameter value to snippet.
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the moderator.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveChatModerator". (default: youtube#liveChatModerator)
  --snippet: record # shape: {liveChatId?: string, moderatorDetails?: record}
]: any -> record<etag: string, id: string, kind: string, snippet: record<liveChatId: string, moderatorDetails: record<channelId: string, channelUrl: string, displayName: string, profileImageUrl: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveChat/moderators" $qp)
  let body = {"etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an existing stream for the authenticated user.
#
# DELETE /youtube/v3/liveStreams
# operationId: youtube.liveStreams.delete
export def "youtube-live-streams youtubeliveStreamsdelete" [
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
  --id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveStreams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the list of streams associated with the given channel. --
#
# GET /youtube/v3/liveStreams
# operationId: youtube.liveStreams.list
export def "youtube-live-streams youtubeliveStreamslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more liveStream resource properties that the API response will include. The part names that you can include in the parameter value are id, snippet, cdn, and status.
  --id: list # Return LiveStreams with the given ids from Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool>
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<cdn: record, contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveStreams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new stream for the authenticated user.
#
# POST /youtube/v3/liveStreams
# operationId: youtube.liveStreams.insert
# --cdn shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
# --contentDetails shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
# --snippet shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
# --status shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
export def "youtube-live-streams youtubeliveStreamsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, cdn, content_details, and status.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --cdn: record # Brief description of the live stream cdn settings. — shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
  --content-details: record # Detailed settings of a stream. — shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the stream.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveStream". (default: youtube#liveStream)
  --snippet: record # shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
  --status: record # Brief description of the live stream status. — shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
]: any -> record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveStreams" $qp)
  let body = {"cdn": $cdn, "contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing stream for the authenticated user.
#
# PUT /youtube/v3/liveStreams
# operationId: youtube.liveStreams.update
# --cdn shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
# --contentDetails shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
# --snippet shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
# --status shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
export def "youtube-live-streams youtubeliveStreamsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. The part properties that you can include in the parameter value are id, snippet, cdn, and status. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. If the request body does not specify a value for a mutable property, the existing value for that property will be removed.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --cdn: record # Brief description of the live stream cdn settings. — shape: {format?: string, frameRate?: "30fps"|"60fps"|"variable", ingestionInfo?: record, ingestionType?: "rtmp"|"dash"|"webrtc"|"hls", resolution?: "240p"|"360p"|"480p"|"720p"|"1080p"|"1440p"|"2160p"|"variable"}
  --content-details: record # Detailed settings of a stream. — shape: {closedCaptionsIngestionUrl?: string, isReusable?: bool}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube assigns to uniquely identify the stream.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#liveStream". (default: youtube#liveStream)
  --snippet: record # shape: {channelId?: string, description?: string, isDefaultStream?: bool, publishedAt?: string, title?: string}
  --status: record # Brief description of the live stream status. — shape: {healthStatus?: record, streamStatus?: "created"|"ready"|"active"|"inactive"|"error"}
]: any -> record<cdn: record<format: string, frameRate: string, ingestionInfo: record<backupIngestionAddress: string, ingestionAddress: string, rtmpsBackupIngestionAddress: string, rtmpsIngestionAddress: string, streamName: string>, ingestionType: string, resolution: string>, contentDetails: record<closedCaptionsIngestionUrl: string, isReusable: bool>, etag: string, id: string, kind: string, snippet: record<channelId: string, description: string, isDefaultStream: bool, publishedAt: string, title: string>, status: record<healthStatus: record<configurationIssues: list, lastUpdateTimeSeconds: string, status: string>, streamStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/liveStreams" $qp)
  let body = {"cdn": $cdn, "contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of members that match the request criteria for a channel.
#
# GET /youtube/v3/members
# operationId: youtube.members.list
export def "youtube-members youtubememberslist" [
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
  --part: list # The *part* parameter specifies the member resource parts that the API response will include. Set the parameter value to snippet.
  --filter-by-member-channel-id: string # Comma separated list of channel IDs. Only data about members that are part of this list will be included in the response.
  --has-access-to-level: string # Filter members in the results set to the ones that have access to a level.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mode: string@mode-completer # Parameter that specifies which channel members to return.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "filterByMemberChannelId" $filter_by_member_channel_id "scalar") (serialize-qp "hasAccessToLevel" $has_access_to_level "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of all pricing levels offered by a creator to the fans.
#
# GET /youtube/v3/membershipsLevels
# operationId: youtube.membershipsLevels.list
export def "youtube-memberships-levels youtubemembershipsLevelslist" [
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
  --part: list # The *part* parameter specifies the membershipsLevel resource parts that the API response will include. Supported values are id and snippet.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/membershipsLevels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource.
#
# DELETE /youtube/v3/playlistItems
# operationId: youtube.playlistItems.delete
export def "youtube-playlist-items youtubeplaylistItemsdelete" [
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
  --id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlistItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/playlistItems
# operationId: youtube.playlistItems.list
export def "youtube-playlist-items youtubeplaylistItemslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more playlistItem resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a playlistItem resource, the snippet property contains numerous fields, including the title, description, position, and resourceId properties. As such, if you set *part=snippet*, the API response will contain all of those properties.
  --id: list
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --playlist-id: string # Return the playlist items within the given playlist.
  --video-id: string # Return the playlist items associated with the given video ID.
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "playlistId" $playlist_id "scalar") (serialize-qp "videoId" $video_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlistItems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/playlistItems
# operationId: youtube.playlistItems.insert
# --contentDetails shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
# --snippet shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
# --status shape: {privacyStatus?: "public"|"unlisted"|"private"}
export def "youtube-playlist-items youtubeplaylistItemsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist item.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlistItem". (default: youtube#playlistItem)
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. Basic details of a YouTube Playlist item provided by the author. Next ID: 15 — shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
  --status: record # Information about the playlist item's privacy status. — shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlistItems" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/playlistItems
# operationId: youtube.playlistItems.update
# --contentDetails shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
# --snippet shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
# --status shape: {privacyStatus?: "public"|"unlisted"|"private"}
export def "youtube-playlist-items youtubeplaylistItemsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a playlist item can specify a start time and end time, which identify the times portion of the video that should play when users watch the video in the playlist. If your request is updating a playlist item that sets these values, and the request's part parameter value includes the contentDetails part, the playlist item's start and end times will be updated to whatever value the request body specifies. If the request body does not specify values, the existing start and end times will be removed and replaced with the default settings.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {endAt?: string, note?: string, startAt?: string, videoId?: string, videoPublishedAt?: string}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist item.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlistItem". (default: youtube#playlistItem)
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. Basic details of a YouTube Playlist item provided by the author. Next ID: 15 — shape: {channelId?: string, channelTitle?: string, description?: string, playlistId?: string, position?: int, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string, videoOwnerChannelId?: string, videoOwnerChannelTitle?: string}
  --status: record # Information about the playlist item's privacy status. — shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> record<contentDetails: record<endAt: string, note: string, startAt: string, videoId: string, videoPublishedAt: string>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, playlistId: string, position: int, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string, videoOwnerChannelId: string, videoOwnerChannelTitle: string>, status: record<privacyStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlistItems" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a resource.
#
# DELETE /youtube/v3/playlists
# operationId: youtube.playlists.delete
export def "youtube-playlists youtubeplaylistsdelete" [
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
  --id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/playlists
# operationId: youtube.playlists.list
export def "youtube-playlists youtubeplaylistslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more playlist resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a playlist resource, the snippet property contains properties like author, title, description, tags, and timeCreated. As such, if you set *part=snippet*, the API response will contain all of those properties.
  --channel-id: string # Return the playlists owned by the specified channel ID.
  --hl: string # Return content in specified language
  --id: list # Return the playlists with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Return the playlists owned by the authenticated user.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, localizations: record, player: record, snippet: record, status: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/playlists
# operationId: youtube.playlists.insert
# --contentDetails shape: {itemCount?: int}
# --player shape: {embedHtml?: string}
# --snippet shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list, thumbnailVideoId?: string, thumbnails?: record, title?: string}
# --status shape: {privacyStatus?: "public"|"unlisted"|"private"}
export def "youtube-playlists youtubeplaylistsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --content-details: record # shape: {itemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlist". (default: youtube#playlist)
  --localizations: record # Localizations for different languages
  --player: record # shape: {embedHtml?: string}
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. — shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list, thumbnailVideoId?: string, thumbnails?: record, title?: string}
  --status: record # shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlists" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "localizations": $localizations, "player": $player, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/playlists
# operationId: youtube.playlists.update
# --contentDetails shape: {itemCount?: int}
# --player shape: {embedHtml?: string}
# --snippet shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list, thumbnailVideoId?: string, thumbnails?: record, title?: string}
# --status shape: {privacyStatus?: "public"|"unlisted"|"private"}
export def "youtube-playlists youtubeplaylistsupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for mutable properties that are contained in any parts that the request body specifies. For example, a playlist's description is contained in the snippet part, which must be included in the request body. If the request does not specify a value for the snippet.description property, the playlist's existing description will be deleted.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --content-details: record # shape: {itemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the playlist.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#playlist". (default: youtube#playlist)
  --localizations: record # Localizations for different languages
  --player: record # shape: {embedHtml?: string}
  --snippet: record # Basic details about a playlist, including title, description and thumbnails. — shape: {channelId?: string, channelTitle?: string, defaultLanguage?: string, description?: string, localized?: record, publishedAt?: string, tags?: list, thumbnailVideoId?: string, thumbnails?: record, title?: string}
  --status: record # shape: {privacyStatus?: "public"|"unlisted"|"private"}
]: any -> record<contentDetails: record<itemCount: int>, etag: string, id: string, kind: string, localizations: record, player: record<embedHtml: string>, snippet: record<channelId: string, channelTitle: string, defaultLanguage: string, description: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnailVideoId: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, status: record<privacyStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/playlists" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "localizations": $localizations, "player": $player, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of search resources
#
# GET /youtube/v3/search
# operationId: youtube.search.list
export def "youtube-search youtubesearchlist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more search resource properties that the API response will include. Set the parameter value to snippet.
  --channel-id: string # Filter on resources belonging to this channelId.
  --channel-type: string@channel-type-completer # Add a filter on the channel search.
  --event-type: string@event-type-completer # Filter on the livestream status of the videos.
  --for-content-owner: oneof<nothing, bool> # Search owned by a content owner.
  --for-developer: oneof<nothing, bool> # Restrict the search to only retrieve videos uploaded using the project id of the authenticated user.
  --for-mine: oneof<nothing, bool> # Search for the private videos of the authenticated user.
  --location: string # Filter on location of the video
  --location-radius: string # Filter on distance from the location (specified above).
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --order: string@order-completer-1 # Sort order of the results.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
  --published-after: string # Filter on resources published after this date.
  --published-before: string # Filter on resources published before this date.
  --q: string # Textual search terms to match.
  --region-code: string # Display the content as seen by viewers in this country.
  --related-to-video-id: string # Search related to a resource.
  --relevance-language: string # Return results relevant to this language.
  --safe-search: string@safe-search-completer # Indicates whether the search results should include restricted content as well as standard content.
  --topic-id: string # Restrict results to a particular topic.
  --type: list # Restrict results to a particular set of resource types from One Platform.
  --video-caption: string@video-caption-completer # Filter on the presence of captions on the videos.
  --video-category-id: string # Filter on videos in a specific category.
  --video-definition: string@video-definition-completer # Filter on the definition of the videos.
  --video-dimension: string@video-dimension-completer # Filter on 3d videos.
  --video-duration: string@video-duration-completer # Filter on the duration of the videos.
  --video-embeddable: string@video-embeddable-completer # Filter on embeddable videos.
  --video-license: string@video-license-completer # Filter on the license of the videos.
  --video-syndicated: string@video-syndicated-completer # Filter on syndicated videos.
  --video-type: string@video-type-completer # Filter on videos of a specific type.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: record, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, regionCode: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "channelType" $channel_type "scalar") (serialize-qp "eventType" $event_type "scalar") (serialize-qp "forContentOwner" $for_content_owner "scalar") (serialize-qp "forDeveloper" $for_developer "scalar") (serialize-qp "forMine" $for_mine "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "locationRadius" $location_radius "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "publishedAfter" $published_after "scalar") (serialize-qp "publishedBefore" $published_before "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "regionCode" $region_code "scalar") (serialize-qp "relatedToVideoId" $related_to_video_id "scalar") (serialize-qp "relevanceLanguage" $relevance_language "scalar") (serialize-qp "safeSearch" $safe_search "scalar") (serialize-qp "topicId" $topic_id "scalar") (serialize-qp "type" $type "multi") (serialize-qp "videoCaption" $video_caption "scalar") (serialize-qp "videoCategoryId" $video_category_id "scalar") (serialize-qp "videoDefinition" $video_definition "scalar") (serialize-qp "videoDimension" $video_dimension "scalar") (serialize-qp "videoDuration" $video_duration "scalar") (serialize-qp "videoEmbeddable" $video_embeddable "scalar") (serialize-qp "videoLicense" $video_license "scalar") (serialize-qp "videoSyndicated" $video_syndicated "scalar") (serialize-qp "videoType" $video_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource.
#
# DELETE /youtube/v3/subscriptions
# operationId: youtube.subscriptions.delete
export def "youtube-subscriptions youtubesubscriptionsdelete" [
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
  --id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/subscriptions
# operationId: youtube.subscriptions.list
export def "youtube-subscriptions youtubesubscriptionslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more subscription resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a subscription resource, the snippet property contains other properties, such as a display title for the subscription. If you set *part=snippet*, the API response will also contain all of those nested properties.
  --channel-id: string # Return the subscriptions of the given channel owner.
  --for-channel-id: string # Return the subscriptions to the subset of these channels that the authenticated user is subscribed to.
  --id: list # Return the subscriptions with the given IDs for Stubby or Apiary.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --mine: oneof<nothing, bool> # Flag for returning the subscriptions of the authenticated user.
  --my-recent-subscribers: oneof<nothing, bool>
  --my-subscribers: oneof<nothing, bool> # Return the subscribers of the given channel owner.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --order: string@order-completer-2 # The order of the returned subscriptions
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<contentDetails: record, etag: string, id: string, kind: string, snippet: record, subscriberSnippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "forChannelId" $for_channel_id "scalar") (serialize-qp "id" $id "multi") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "mine" $mine "scalar") (serialize-qp "myRecentSubscribers" $my_recent_subscribers "scalar") (serialize-qp "mySubscribers" $my_subscribers "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/subscriptions
# operationId: youtube.subscriptions.insert
# --contentDetails shape: {activityType?: "subscriptionActivityTypeUnspecified"|"all"|"uploads", newItemCount?: int, totalItemCount?: int}
# --snippet shape: {channelId?: string, channelTitle?: string, description?: string, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string}
# --subscriberSnippet shape: {channelId?: string, description?: string, thumbnails?: record, title?: string}
export def "youtube-subscriptions youtubesubscriptionsinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include.
  --content-details: record # Details about the content to witch a subscription refers. — shape: {activityType?: "subscriptionActivityTypeUnspecified"|"all"|"uploads", newItemCount?: int, totalItemCount?: int}
  --etag: string # Etag of this resource.
  --id: string # The ID that YouTube uses to uniquely identify the subscription.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#subscription". (default: youtube#subscription)
  --snippet: record # Basic details about a subscription, including title, description and thumbnails of the subscribed item. — shape: {channelId?: string, channelTitle?: string, description?: string, publishedAt?: string, resourceId?: record, thumbnails?: record, title?: string}
  --subscriber-snippet: record # Basic details about a subscription's subscriber including title, description, channel ID and thumbnails. — shape: {channelId?: string, description?: string, thumbnails?: record, title?: string}
]: any -> record<contentDetails: record<activityType: string, newItemCount: int, totalItemCount: int>, etag: string, id: string, kind: string, snippet: record<channelId: string, channelTitle: string, description: string, publishedAt: string, resourceId: record<channelId: string, kind: string, playlistId: string, videoId: string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, subscriberSnippet: record<channelId: string, description: string, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/subscriptions" $qp)
  let body = {"contentDetails": $content_details, "etag": $etag, "id": $id, "kind": $kind, "snippet": $snippet, "subscriberSnippet": $subscriber_snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/superChatEvents
# operationId: youtube.superChatEvents.list
export def "youtube-super-chat-events youtubesuperChatEventslist" [
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
  --part: list # The *part* parameter specifies the superChatEvent resource parts that the API response will include. This parameter is currently not supported.
  --hl: string # Return rendered funding amounts in specified language.
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved.
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/superChatEvents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST method.
#
# POST /youtube/v3/tests
# operationId: youtube.tests.insert
export def "youtube-tests youtubetestsinsert" [
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
  --part: list
  --external-channel-id: string
  --featured-part: oneof<nothing, bool>
  --gaia: string # format: int64
  --id: string
  --snippet: record
]: any -> record<featuredPart: bool, gaia: string, id: string, snippet: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "externalChannelId" $external_channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/tests" $qp)
  let body = {"featuredPart": $featured_part, "gaia": $gaia, "id": $id, "snippet": $snippet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a resource.
#
# DELETE /youtube/v3/thirdPartyLinks
# operationId: youtube.thirdPartyLinks.delete
export def "youtube-third-party-links youtubethirdPartyLinksdelete" [
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
  --linking-token: string # Delete the partner links with the given linking token.
  --type: string@type-completer # Type of the link to be deleted.
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --part: list # Do not use. Required for compatibility.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "linkingToken" $linking_token "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "externalChannelId" $external_channel_id "scalar") (serialize-qp "part" $part "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/thirdPartyLinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/thirdPartyLinks
# operationId: youtube.thirdPartyLinks.list
export def "youtube-third-party-links youtubethirdPartyLinkslist" [
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
  --part: list # The *part* parameter specifies the thirdPartyLink resource parts that the API response will include. Supported values are linkingToken, status, and snippet.
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --linking-token: string # Get a third party link with the given linking token.
  --type: string@type-completer # Get a third party link of the given type.
]: nothing -> record<etag: string, items: table<etag: string, kind: string, linkingToken: string, snippet: record, status: record>, kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "externalChannelId" $external_channel_id "scalar") (serialize-qp "linkingToken" $linking_token "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/thirdPartyLinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/thirdPartyLinks
# operationId: youtube.thirdPartyLinks.insert
# --snippet shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
# --status shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
export def "youtube-third-party-links youtubethirdPartyLinksinsert" [
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
  --part: list # The *part* parameter specifies the thirdPartyLink resource parts that the API request and response will include. Supported values are linkingToken, status, and snippet.
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --etag: string # Etag of this resource
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#thirdPartyLink". (default: youtube#thirdPartyLink)
  --linking-token: string # The linking_token identifies a YouTube account and channel with which the third party account is linked.
  --snippet: record # Basic information about a third party account link, including its type and type-specific information. — shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
  --status: record # The third-party link status object contains information about the status of the link. — shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
]: any -> record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "externalChannelId" $external_channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/thirdPartyLinks" $qp)
  let body = {"etag": $etag, "kind": $kind, "linkingToken": $linking_token, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/thirdPartyLinks
# operationId: youtube.thirdPartyLinks.update
# --snippet shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
# --status shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
export def "youtube-third-party-links youtubethirdPartyLinksupdate" [
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
  --part: list # The *part* parameter specifies the thirdPartyLink resource parts that the API request and response will include. Supported values are linkingToken, status, and snippet.
  --external-channel-id: string # Channel ID to which changes should be applied, for delegation.
  --etag: string # Etag of this resource
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#thirdPartyLink". (default: youtube#thirdPartyLink)
  --linking-token: string # The linking_token identifies a YouTube account and channel with which the third party account is linked.
  --snippet: record # Basic information about a third party account link, including its type and type-specific information. — shape: {channelToStoreLink?: record, type?: "linkUnspecified"|"channelToStoreLink"}
  --status: record # The third-party link status object contains information about the status of the link. — shape: {linkStatus?: "unknown"|"failed"|"pending"|"linked"}
]: any -> record<etag: string, kind: string, linkingToken: string, snippet: record<channelToStoreLink: record<merchantId: string, storeName: string, storeUrl: string>, type: string>, status: record<linkStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "externalChannelId" $external_channel_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/thirdPartyLinks" $qp)
  let body = {"etag": $etag, "kind": $kind, "linkingToken": $linking_token, "snippet": $snippet, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# As this is not an insert in a strict sense (it supports uploading/setting of a thumbnail for multiple videos, which doesn't result in creation of a single resource), I use a custom verb here.
#
# POST /youtube/v3/thumbnails/set
# operationId: youtube.thumbnails.set
export def "youtube-thumbnails-set youtubethumbnailsset" [
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
  --video-id: string # Returns the Thumbnail with the given video IDs for Stubby or Apiary.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> record<etag: string, eventId: string, items: table<high: record, maxres: record, medium: record, standard: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "videoId" $video_id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/thumbnails/set" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videoAbuseReportReasons
# operationId: youtube.videoAbuseReportReasons.list
export def "youtube-video-abuse-report-reasons youtubevideoAbuseReportReasonslist" [
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
  --part: list # The *part* parameter specifies the videoCategory resource parts that the API response will include. Supported values are id and snippet.
  --hl: string
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videoAbuseReportReasons" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videoCategories
# operationId: youtube.videoCategories.list
export def "youtube-video-categories youtubevideoCategorieslist" [
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
  --part: list # The *part* parameter specifies the videoCategory resource properties that the API response will include. Set the parameter value to snippet.
  --hl: string
  --id: list # Returns the video categories with the given IDs for Stubby or Apiary.
  --region-code: string
]: nothing -> record<etag: string, eventId: string, items: table<etag: string, id: string, kind: string, snippet: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "hl" $hl "scalar") (serialize-qp "id" $id "multi") (serialize-qp "regionCode" $region_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videoCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a resource.
#
# DELETE /youtube/v3/videos
# operationId: youtube.videos.delete
export def "youtube-videos youtubevideosdelete" [
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
  --id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of resources, possibly filtered.
#
# GET /youtube/v3/videos
# operationId: youtube.videos.list
export def "youtube-videos youtubevideoslist" [
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
  --part: list # The *part* parameter specifies a comma-separated list of one or more video resource properties that the API response will include. If the parameter identifies a property that contains child properties, the child properties will be included in the response. For example, in a video resource, the snippet property contains the channelId, title, description, tags, and categoryId properties. As such, if you set *part=snippet*, the API response will contain all of those properties.
  --chart: string@chart-completer # Return the videos that are in the specified chart.
  --hl: string # Stands for "host language". Specifies the localization language of the metadata to be filled into snippet.localized. The field is filled with the default metadata if there is no localization in the specified language. The parameter value must be a language code included in the list returned by the i18nLanguages.list method (e.g. en_US, es_MX).
  --id: list # Return videos with the given ids.
  --locale: string
  --max-height: int
  --max-results: int # The *maxResults* parameter specifies the maximum number of items that should be returned in the result set. *Note:* This parameter is supported for use in conjunction with the myRating and chart parameters, but it is not supported for use in conjunction with the id parameter.
  --max-width: int # Return the player with maximum height specified in
  --my-rating: string@my-rating-completer # Return videos liked/disliked by the authenticated user. Does not support RateType.RATED_TYPE_NONE.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --page-token: string # The *pageToken* parameter identifies a specific page in the result set that should be returned. In an API response, the nextPageToken and prevPageToken properties identify other pages that could be retrieved. *Note:* This parameter is supported for use in conjunction with the myRating and chart parameters, but it is not supported for use in conjunction with the id parameter.
  --region-code: string # Use a chart that is specific to the specified region
  --video-category-id: string # Use chart that is specific to the specified video category
]: nothing -> record<etag: string, eventId: string, items: table<ageGating: record, contentDetails: record, etag: string, fileDetails: record, id: string, kind: string, liveStreamingDetails: record, localizations: record, monetizationDetails: record, player: record, processingDetails: record, projectDetails: record, recordingDetails: record, snippet: record, statistics: record, status: record, suggestions: record, topicDetails: record>, kind: string, nextPageToken: string, pageInfo: record<resultsPerPage: int, totalResults: int>, prevPageToken: string, tokenPagination: record, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "chart" $chart "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "id" $id "multi") (serialize-qp "locale" $locale "scalar") (serialize-qp "maxHeight" $max_height "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "maxWidth" $max_width "scalar") (serialize-qp "myRating" $my_rating "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "regionCode" $region_code "scalar") (serialize-qp "videoCategoryId" $video_category_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inserts a new resource into this collection.
#
# POST /youtube/v3/videos
# operationId: youtube.videos.insert
export def "youtube-videos youtubevideosinsert" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that not all parts contain properties that can be set when inserting or updating a video. For example, the statistics object encapsulates statistics that YouTube calculates for a video and does not contain values that you can set or modify. If the parameter value specifies a part that does not contain mutable values, that part will still be included in the API response.
  --auto-levels: oneof<nothing, bool> # Should auto-levels be applied to the upload.
  --notify-subscribers: oneof<nothing, bool> # Notify the channel subscribers about the new video. As default, the notification is enabled.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --on-behalf-of-content-owner-channel: string # This parameter can only be used in a properly authorized request. *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwnerChannel* parameter specifies the YouTube channel ID of the channel to which a video is being added. This parameter is required when a request specifies a value for the onBehalfOfContentOwner parameter, and it can only be used in conjunction with that parameter. In addition, the request must be authorized using a CMS account that is linked to the content owner that the onBehalfOfContentOwner parameter specifies. Finally, the channel that the onBehalfOfContentOwnerChannel parameter value specifies must be linked to the content owner that the onBehalfOfContentOwner parameter specifies. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and perform actions on behalf of the channel specified in the parameter value, without having to provide authentication credentials for each separate channel.
  --stabilize: oneof<nothing, bool> # Should stabilize be applied to the upload.
  --body: record
]: any -> record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "autoLevels" $auto_levels "scalar") (serialize-qp "notifySubscribers" $notify_subscribers "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar") (serialize-qp "onBehalfOfContentOwnerChannel" $on_behalf_of_content_owner_channel "scalar") (serialize-qp "stabilize" $stabilize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Updates an existing resource.
#
# PUT /youtube/v3/videos
# operationId: youtube.videos.update
# --ageGating shape: {alcoholContent?: bool, restricted?: bool, videoGameRating?: "anyone"|"m15Plus"|"m16Plus"|"m17Plus"}
# --contentDetails shape: {caption?: "true"|"false", contentRating?: record, countryRestriction?: record, definition?: "sd"|"hd", dimension?: string, duration?: string, hasCustomThumbnail?: bool, licensedContent?: bool, projection?: "rectangular"|"360", regionRestriction?: record}
# --fileDetails shape: {audioStreams?: list, bitrateBps?: string, container?: string, creationTime?: string, durationMs?: string, fileName?: string, fileSize?: string, fileType?: "video"|"audio"|"image"|"archive"|"document"|"project"|"other", videoStreams?: list}
# --liveStreamingDetails shape: {activeLiveChatId?: string, actualEndTime?: string, actualStartTime?: string, concurrentViewers?: string, scheduledEndTime?: string, scheduledStartTime?: string}
# --monetizationDetails shape: {access?: record}
# --player shape: {embedHeight?: string, embedHtml?: string, embedWidth?: string}
# --processingDetails shape: {editorSuggestionsAvailability?: string, fileDetailsAvailability?: string, processingFailureReason?: "uploadFailed"|"transcodeFailed"|"streamingFailed"|"other", processingIssuesAvailability?: string, processingProgress?: record, processingStatus?: "processing"|"succeeded"|"failed"|"terminated", tagSuggestionsAvailability?: string, thumbnailsAvailability?: string}
# --recordingDetails shape: {location?: record, locationDescription?: string, recordingDate?: string}
# --snippet shape: {categoryId?: string, channelId?: string, channelTitle?: string, defaultAudioLanguage?: string, defaultLanguage?: string, description?: string, liveBroadcastContent?: "none"|"upcoming"|"live"|"completed", localized?: record, publishedAt?: string, tags?: list, thumbnails?: record, title?: string}
# --statistics shape: {commentCount?: string, dislikeCount?: string, favoriteCount?: string, likeCount?: string, viewCount?: string}
# --status shape: {embeddable?: bool, failureReason?: "conversion"|"invalidFile"|"emptyFile"|"tooSmall"|"codec"|"uploadAborted", license?: "youtube"|"creativeCommon", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", publicStatsViewable?: bool, publishAt?: string, rejectionReason?: "copyright"|"inappropriate"|"duplicate"|"termsOfUse"|"uploaderAccountSuspended"|"length"|"claim"|"uploaderAccountClosed"|"trademark"|"legal", selfDeclaredMadeForKids?: bool, uploadStatus?: "uploaded"|"processed"|"failed"|"rejected"|"deleted"}
# --suggestions shape: {editorSuggestions?: list, processingErrors?: list, processingHints?: list, processingWarnings?: list, tagSuggestions?: list}
# --topicDetails shape: {relevantTopicIds?: list, topicCategories?: list, topicIds?: list}
export def "youtube-videos youtubevideosupdate" [
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
  --part: list # The *part* parameter serves two purposes in this operation. It identifies the properties that the write operation will set as well as the properties that the API response will include. Note that this method will override the existing values for all of the mutable properties that are contained in any parts that the parameter value specifies. For example, a video's privacy setting is contained in the status part. As such, if your request is updating a private video, and the request's part parameter value includes the status part, the video's privacy setting will be updated to whatever value the request body specifies. If the request body does not specify a value, the existing privacy setting will be removed and the video will revert to the default privacy setting. In addition, not all parts contain properties that can be set when inserting or updating a video. For example, the statistics object encapsulates statistics that YouTube calculates for a video and does not contain values that you can set or modify. If the parameter value specifies a part that does not contain mutable values, that part will still be included in the API response.
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The actual CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --age-gating: record # shape: {alcoholContent?: bool, restricted?: bool, videoGameRating?: "anyone"|"m15Plus"|"m16Plus"|"m17Plus"}
  --content-details: record # Details about the content of a YouTube Video. — shape: {caption?: "true"|"false", contentRating?: record, countryRestriction?: record, definition?: "sd"|"hd", dimension?: string, duration?: string, hasCustomThumbnail?: bool, licensedContent?: bool, projection?: "rectangular"|"360", regionRestriction?: record}
  --etag: string # Etag of this resource.
  --file-details: record # Describes original video file properties, including technical details about audio and video streams, but also metadata information like content length, digitization time, or geotagging information. — shape: {audioStreams?: list, bitrateBps?: string, container?: string, creationTime?: string, durationMs?: string, fileName?: string, fileSize?: string, fileType?: "video"|"audio"|"image"|"archive"|"document"|"project"|"other", videoStreams?: list}
  --id: string # The ID that YouTube uses to uniquely identify the video.
  --kind: string # Identifies what kind of resource this is. Value: the fixed string "youtube#video". (default: youtube#video)
  --live-streaming-details: record # Details about the live streaming metadata. — shape: {activeLiveChatId?: string, actualEndTime?: string, actualStartTime?: string, concurrentViewers?: string, scheduledEndTime?: string, scheduledStartTime?: string}
  --localizations: record # The localizations object contains localized versions of the basic details about the video, such as its title and description.
  --monetization-details: record # Details about monetization of a YouTube Video. — shape: {access?: record}
  --player: record # Player to be used for a video playback. — shape: {embedHeight?: string, embedHtml?: string, embedWidth?: string}
  --processing-details: record # Describes processing status and progress and availability of some other Video resource parts. — shape: {editorSuggestionsAvailability?: string, fileDetailsAvailability?: string, processingFailureReason?: "uploadFailed"|"transcodeFailed"|"streamingFailed"|"other", processingIssuesAvailability?: string, processingProgress?: record, processingStatus?: "processing"|"succeeded"|"failed"|"terminated", tagSuggestionsAvailability?: string, thumbnailsAvailability?: string}
  --project-details: record # DEPRECATED. b/157517979: This part was never populated after it was added. However, it sees non-zero traffic because there is generated client code in the wild that refers to it [1]. We keep this field and do NOT remove it because otherwise V3 would return an error when this part gets requested [2]. [1] https://developers.google.com/resources/api-libraries/documentation/youtube/v3/csharp/latest/classGoogle_1_1Apis_1_1YouTube_1_1v3_1_1Data_1_1VideoProjectDetails.html [2] http://google3/video/youtube/src/python/servers/data_api/common.py?l=1565-1569&rcl=344141677
  --recording-details: record # Recording information associated with the video. — shape: {location?: record, locationDescription?: string, recordingDate?: string}
  --snippet: record # Basic details about a video, including title, description, uploader, thumbnails and category. — shape: {categoryId?: string, channelId?: string, channelTitle?: string, defaultAudioLanguage?: string, defaultLanguage?: string, description?: string, liveBroadcastContent?: "none"|"upcoming"|"live"|"completed", localized?: record, publishedAt?: string, tags?: list, thumbnails?: record, title?: string}
  --statistics: record # Statistics about the video, such as the number of times the video was viewed or liked. — shape: {commentCount?: string, dislikeCount?: string, favoriteCount?: string, likeCount?: string, viewCount?: string}
  --status: record # Basic details about a video category, such as its localized title. Next Id: 18 — shape: {embeddable?: bool, failureReason?: "conversion"|"invalidFile"|"emptyFile"|"tooSmall"|"codec"|"uploadAborted", license?: "youtube"|"creativeCommon", madeForKids?: bool, privacyStatus?: "public"|"unlisted"|"private", publicStatsViewable?: bool, publishAt?: string, rejectionReason?: "copyright"|"inappropriate"|"duplicate"|"termsOfUse"|"uploaderAccountSuspended"|"length"|"claim"|"uploaderAccountClosed"|"trademark"|"legal", selfDeclaredMadeForKids?: bool, uploadStatus?: "uploaded"|"processed"|"failed"|"rejected"|"deleted"}
  --suggestions: record # Specifies suggestions on how to improve video content, including encoding hints, tag suggestions, and editor suggestions. — shape: {editorSuggestions?: list, processingErrors?: list, processingHints?: list, processingWarnings?: list, tagSuggestions?: list}
  --topic-details: record # Freebase topic information related to the video. — shape: {relevantTopicIds?: list, topicCategories?: list, topicIds?: list}
]: any -> record<ageGating: record<alcoholContent: bool, restricted: bool, videoGameRating: string>, contentDetails: record<caption: string, contentRating: record<acbRating: string, agcomRating: string, anatelRating: string, bbfcRating: string, bfvcRating: string, bmukkRating: string, catvRating: string, catvfrRating: string, cbfcRating: string, cccRating: string, cceRating: string, chfilmRating: string, chvrsRating: string, cicfRating: string, cnaRating: string, cncRating: string, csaRating: string, cscfRating: string, czfilmRating: string, djctqRating: string, djctqRatingReasons: list, ecbmctRating: string, eefilmRating: string, egfilmRating: string, eirinRating: string, fcbmRating: string, fcoRating: string, fmocRating: string, fpbRating: string, fpbRatingReasons: list, fskRating: string, grfilmRating: string, icaaRating: string, ifcoRating: string, ilfilmRating: string, incaaRating: string, kfcbRating: string, kijkwijzerRating: string, kmrbRating: string, lsfRating: string, mccaaRating: string, mccypRating: string, mcstRating: string, mdaRating: string, medietilsynetRating: string, mekuRating: string, menaMpaaRating: string, mibacRating: string, mocRating: string, moctwRating: string, mpaaRating: string, mpaatRating: string, mtrcbRating: string, nbcRating: string, nbcplRating: string, nfrcRating: string, nfvcbRating: string, nkclvRating: string, nmcRating: string, oflcRating: string, pefilmRating: string, rcnofRating: string, resorteviolenciaRating: string, rtcRating: string, rteRating: string, russiaRating: string, skfilmRating: string, smaisRating: string, smsaRating: string, tvpgRating: string, ytRating: string>, countryRestriction: record<allowed: bool, exception: list>, definition: string, dimension: string, duration: string, hasCustomThumbnail: bool, licensedContent: bool, projection: string, regionRestriction: record<allowed: list, blocked: list>>, etag: string, fileDetails: record<audioStreams: list<record>, bitrateBps: string, container: string, creationTime: string, durationMs: string, fileName: string, fileSize: string, fileType: string, videoStreams: list<record>>, id: string, kind: string, liveStreamingDetails: record<activeLiveChatId: string, actualEndTime: string, actualStartTime: string, concurrentViewers: string, scheduledEndTime: string, scheduledStartTime: string>, localizations: record, monetizationDetails: record<access: record<allowed: bool, exception: list>>, player: record<embedHeight: string, embedHtml: string, embedWidth: string>, processingDetails: record<editorSuggestionsAvailability: string, fileDetailsAvailability: string, processingFailureReason: string, processingIssuesAvailability: string, processingProgress: record<partsProcessed: string, partsTotal: string, timeLeftMs: string>, processingStatus: string, tagSuggestionsAvailability: string, thumbnailsAvailability: string>, projectDetails: record, recordingDetails: record<location: record<altitude: float, latitude: float, longitude: float>, locationDescription: string, recordingDate: string>, snippet: record<categoryId: string, channelId: string, channelTitle: string, defaultAudioLanguage: string, defaultLanguage: string, description: string, liveBroadcastContent: string, localized: record<description: string, title: string>, publishedAt: string, tags: list<string>, thumbnails: record<high: record, maxres: record, medium: record, standard: record>, title: string>, statistics: record<commentCount: string, dislikeCount: string, favoriteCount: string, likeCount: string, viewCount: string>, status: record<embeddable: bool, failureReason: string, license: string, madeForKids: bool, privacyStatus: string, publicStatsViewable: bool, publishAt: string, rejectionReason: string, selfDeclaredMadeForKids: bool, uploadStatus: string>, suggestions: record<editorSuggestions: list<string>, processingErrors: list<string>, processingHints: list<string>, processingWarnings: list<string>, tagSuggestions: list<record>>, topicDetails: record<relevantTopicIds: list<string>, topicCategories: list<string>, topicIds: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "part" $part "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos" $qp)
  let body = {"ageGating": $age_gating, "contentDetails": $content_details, "etag": $etag, "fileDetails": $file_details, "id": $id, "kind": $kind, "liveStreamingDetails": $live_streaming_details, "localizations": $localizations, "monetizationDetails": $monetization_details, "player": $player, "processingDetails": $processing_details, "projectDetails": $project_details, "recordingDetails": $recording_details, "snippet": $snippet, "statistics": $statistics, "status": $status, "suggestions": $suggestions, "topicDetails": $topic_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves the ratings that the authorized user gave to a list of specified videos.
#
# GET /youtube/v3/videos/getRating
# operationId: youtube.videos.getRating
export def "youtube-videos-get-rating youtubevideosgetRating" [
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
  --id: list
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> record<etag: string, eventId: string, items: table<rating: string, videoId: string>, kind: string, visitorId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "multi") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos/getRating" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a like or dislike rating to a video or removes a rating from a video.
#
# POST /youtube/v3/videos/rate
# operationId: youtube.videos.rate
export def "youtube-videos-rate youtubevideosrate" [
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
  --id: string
  --rating: string@rating-completer
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos/rate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report abuse for a video.
#
# POST /youtube/v3/videos/reportAbuse
# operationId: youtube.videos.reportAbuse
export def "youtube-videos-report-abuse youtubevideosreportAbuse" [
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
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --comments: string # Additional comments regarding the abuse report.
  --language: string # The language that the content was viewed in.
  --reason-id: string # The high-level, or primary, reason that the content is abusive. The value is an abuse report reason ID.
  --secondary-reason-id: string # The specific, or secondary, reason that this content is abusive (if available). The value is an abuse report reason ID that is a valid secondary reason for the primary reason.
  --video-id: string # The ID that YouTube uses to uniquely identify the video.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/videos/reportAbuse" $qp)
  let body = {"comments": $comments, "language": $language, "reasonId": $reason_id, "secondaryReasonId": $secondary_reason_id, "videoId": $video_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Allows upload of watermark image and setting it for a channel.
#
# POST /youtube/v3/watermarks/set
# operationId: youtube.watermarks.set
export def "youtube-watermarks-set youtubewatermarksset" [
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
  --channel-id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/watermarks/set" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Allows removal of channel watermark.
#
# POST /youtube/v3/watermarks/unset
# operationId: youtube.watermarks.unset
export def "youtube-watermarks-unset youtubewatermarksunset" [
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
  --channel-id: string
  --on-behalf-of-content-owner: string # *Note:* This parameter is intended exclusively for YouTube content partners. The *onBehalfOfContentOwner* parameter indicates that the request's authorization credentials identify a YouTube CMS user who is acting on behalf of the content owner specified in the parameter value. This parameter is intended for YouTube content partners that own and manage many different YouTube channels. It allows content owners to authenticate once and get access to all their video and channel data, without having to provide authentication credentials for each individual channel. The CMS account that the user authenticates with must be linked to the specified YouTube content owner.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "channelId" $channel_id "scalar") (serialize-qp "onBehalfOfContentOwner" $on_behalf_of_content_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/youtube/v3/watermarks/unset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
