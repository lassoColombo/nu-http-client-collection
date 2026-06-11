# Auto-generated client for Twitter OpenAPI v0.0.1
# Source: https://raw.githubusercontent.com/fa0311/twitter-openapi/main/dist/compatible/openapi-3.0.yaml
# Auth: --token flag or $env.TWITTER_OPENAPI_TOKEN

const BASE_URL = "https://x.com/i/api"
const DEFAULT_AUTH = "accept"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWITTER_OPENAPI_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "accept" => { {headers: {Accept: $token_val}, query: ""} }
    "accept-encoding" => { {headers: {Accept-Encoding: $token_val}, query: ""} }
    "accept-language" => { {headers: {Accept-Language: $token_val}, query: ""} }
    "x-twitter-active-user" => { {headers: {x-twitter-active-user: $token_val}, query: ""} }
    "x-twitter-auth-type" => { {headers: {x-twitter-auth-type: $token_val}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "x-twitter-client-language" => { {headers: {x-twitter-client-language: $token_val}, query: ""} }
    "x-client-transaction-id" => { {headers: {x-client-transaction-id: $token_val}, query: ""} }
    "x-client-uuid" => { {headers: {x-client-uuid: $token_val}, query: ""} }
    "cookie-auth_token" => { {headers: {Cookie: $"auth_token=($token_val)"}, query: ""} }
    "cookie-ct0" => { {headers: {Cookie: $"ct0=($token_val)"}, query: ""} }
    "cookie-gt0" => { {headers: {Cookie: $"gt0=($token_val)"}, query: ""} }
    "x-csrf-token" => { {headers: {x-csrf-token: $token_val}, query: ""} }
    "x-guest-token" => { {headers: {x-guest-token: $token_val}, query: ""} }
    "priority" => { {headers: {Priority: $token_val}, query: ""} }
    "referer" => { {headers: {Referer: $token_val}, query: ""} }
    "sec-ch-ua" => { {headers: {Sec-Ch-Ua: $token_val}, query: ""} }
    "sec-ch-ua-mobile" => { {headers: {Sec-Ch-Ua-Mobile: $token_val}, query: ""} }
    "sec-ch-ua-platform" => { {headers: {Sec-Ch-Ua-Platform: $token_val}, query: ""} }
    "sec-fetch-dest" => { {headers: {Sec-Fetch-Dest: $token_val}, query: ""} }
    "sec-fetch-mode" => { {headers: {Sec-Fetch-Mode: $token_val}, query: ""} }
    "sec-fetch-site" => { {headers: {Sec-Fetch-Site: $token_val}, query: ""} }
    "user-agent" => { {headers: {user-agent: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://x.com/i/api" "https://twitter.com/i/api"] }
def auth-scheme-completer [] { ["accept" "accept-encoding" "accept-language" "x-twitter-active-user" "x-twitter-auth-type" "bearer" "x-twitter-client-language" "x-client-transaction-id" "x-client-uuid" "cookie-auth_token" "cookie-ct0" "cookie-gt0" "x-csrf-token" "x-guest-token" "priority" "referer" "sec-ch-ua" "sec-ch-ua-mobile" "sec-ch-ua-platform" "sec-fetch-dest" "sec-fetch-mode" "sec-fetch-site" "user-agent"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "11-friends-following-listjson get" } } | get name | first)
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

# get friends following list
#
# GET /1.1/friends/following/list.json
# operationId: getFriendsFollowingList
export def "11-friends-following-listjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-profile-interstitial-type: int # default: 1, e.g. 1
  --include-blocking: int # default: 1, e.g. 1
  --include-blocked-by: int # default: 1, e.g. 1
  --include-followed-by: int # default: 1, e.g. 1
  --include-want-retweets: int # default: 1, e.g. 1
  --include-mute-edge: int # default: 1, e.g. 1
  --include-can-dm: int # default: 1, e.g. 1
  --include-can-media-tag: int # default: 1, e.g. 1
  --include-ext-has-nft-avatar: int # default: 1, e.g. 1
  --include-ext-is-blue-verified: int # default: 1, e.g. 1
  --include-ext-verified-type: int # default: 1, e.g. 1
  --include-ext-profile-image-shape: int # default: 1, e.g. 1
  --skip-status: int # default: 1, e.g. 1
  --cursor: int # default: -1, e.g. -1
  --user-id: string # default: 44196397, e.g. 44196397
  --count: int # default: 3, e.g. 3
  --with-total-count: string@bool-completer # default: true, e.g. true
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_profile_interstitial_type" $include_profile_interstitial_type "scalar") (serialize-qp "include_blocking" $include_blocking "scalar") (serialize-qp "include_blocked_by" $include_blocked_by "scalar") (serialize-qp "include_followed_by" $include_followed_by "scalar") (serialize-qp "include_want_retweets" $include_want_retweets "scalar") (serialize-qp "include_mute_edge" $include_mute_edge "scalar") (serialize-qp "include_can_dm" $include_can_dm "scalar") (serialize-qp "include_can_media_tag" $include_can_media_tag "scalar") (serialize-qp "include_ext_has_nft_avatar" $include_ext_has_nft_avatar "scalar") (serialize-qp "include_ext_is_blue_verified" $include_ext_is_blue_verified "scalar") (serialize-qp "include_ext_verified_type" $include_ext_verified_type "scalar") (serialize-qp "include_ext_profile_image_shape" $include_ext_profile_image_shape "scalar") (serialize-qp "skip_status" $skip_status "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "with_total_count" $with_total_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.1/friends/following/list.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# post create friendships
#
# POST /1.1/friendships/create.json
# operationId: postCreateFriendships
export def "11-friendships-createjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  include_blocked_by: int # default: 1, e.g. 1
  include_blocking: int # default: 1, e.g. 1
  include_can_dm: int # default: 1, e.g. 1
  include_can_media_tag: int # default: 1, e.g. 1
  include_ext_has_nft_avatar: int # default: 1, e.g. 1
  include_ext_is_blue_verified: int # default: 1, e.g. 1
  include_ext_profile_image_shape: int # default: 1, e.g. 1
  include_ext_verified_type: int # default: 1, e.g. 1
  include_followed_by: int # default: 1, e.g. 1
  include_mute_edge: int # default: 1, e.g. 1
  include_profile_interstitial_type: int # default: 1, e.g. 1
  include_want_retweets: int # default: 1, e.g. 1
  skip_status: int # default: 1, e.g. 1
  user_id: string # default: 44196397, e.g. 44196397
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1.1/friendships/create.json")
  let body = {include_blocked_by: $include_blocked_by, include_blocking: $include_blocking, include_can_dm: $include_can_dm, include_can_media_tag: $include_can_media_tag, include_ext_has_nft_avatar: $include_ext_has_nft_avatar, include_ext_is_blue_verified: $include_ext_is_blue_verified, include_ext_profile_image_shape: $include_ext_profile_image_shape, include_ext_verified_type: $include_ext_verified_type, include_followed_by: $include_followed_by, include_mute_edge: $include_mute_edge, include_profile_interstitial_type: $include_profile_interstitial_type, include_want_retweets: $include_want_retweets, skip_status: $skip_status, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# post destroy friendships
#
# POST /1.1/friendships/destroy.json
# operationId: postDestroyFriendships
export def "11-friendships-destroyjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  include_blocked_by: int # default: 1, e.g. 1
  include_blocking: int # default: 1, e.g. 1
  include_can_dm: int # default: 1, e.g. 1
  include_can_media_tag: int # default: 1, e.g. 1
  include_ext_has_nft_avatar: int # default: 1, e.g. 1
  include_ext_is_blue_verified: int # default: 1, e.g. 1
  include_ext_profile_image_shape: int # default: 1, e.g. 1
  include_ext_verified_type: int # default: 1, e.g. 1
  include_followed_by: int # default: 1, e.g. 1
  include_mute_edge: int # default: 1, e.g. 1
  include_profile_interstitial_type: int # default: 1, e.g. 1
  include_want_retweets: int # default: 1, e.g. 1
  skip_status: int # default: 1, e.g. 1
  user_id: string # default: 44196397, e.g. 44196397
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1.1/friendships/destroy.json")
  let body = {include_blocked_by: $include_blocked_by, include_blocking: $include_blocking, include_can_dm: $include_can_dm, include_can_media_tag: $include_can_media_tag, include_ext_has_nft_avatar: $include_ext_has_nft_avatar, include_ext_is_blue_verified: $include_ext_is_blue_verified, include_ext_profile_image_shape: $include_ext_profile_image_shape, include_ext_verified_type: $include_ext_verified_type, include_followed_by: $include_followed_by, include_mute_edge: $include_mute_edge, include_profile_interstitial_type: $include_profile_interstitial_type, include_want_retweets: $include_want_retweets, skip_status: $skip_status, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# get search typeahead
#
# GET /1.1/search/typeahead.json
# operationId: getSearchTypeahead
export def "11-search-typeaheadjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-ext-is-blue-verified: int # default: 1, e.g. 1
  --include-ext-verified-type: int # default: 1, e.g. 1
  --include-ext-profile-image-shape: int # default: 1, e.g. 1
  --q: string # default: test, e.g. test
  --src: string # default: search_box, e.g. search_box
  --result-type: string # default: events,users,topics, e.g. events,users,topics
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_ext_is_blue_verified" $include_ext_is_blue_verified "scalar") (serialize-qp "include_ext_verified_type" $include_ext_verified_type "scalar") (serialize-qp "include_ext_profile_image_shape" $include_ext_profile_image_shape "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "src" $src "scalar") (serialize-qp "result_type" $result_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1.1/search/typeahead.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get search adaptive
#
# GET /2/search/adaptive.json
# operationId: getSearchAdaptive
export def "2-search-adaptivejson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-profile-interstitial-type: int # default: 1, e.g. 1
  --include-blocking: int # default: 1, e.g. 1
  --include-blocked-by: int # default: 1, e.g. 1
  --include-followed-by: int # default: 1, e.g. 1
  --include-want-retweets: int # default: 1, e.g. 1
  --include-mute-edge: int # default: 1, e.g. 1
  --include-can-dm: int # default: 1, e.g. 1
  --include-can-media-tag: int # default: 1, e.g. 1
  --include-ext-has-nft-avatar: int # default: 1, e.g. 1
  --include-ext-is-blue-verified: int # default: 1, e.g. 1
  --include-ext-verified-type: int # default: 1, e.g. 1
  --include-ext-profile-image-shape: int # default: 1, e.g. 1
  --skip-status: int # default: 1, e.g. 1
  --cards-platform: string # default: Web-12, e.g. Web-12
  --include-cards: int # default: 1, e.g. 1
  --include-ext-alt-text: string@bool-completer # default: true, e.g. true
  --include-ext-limited-action-results: string@bool-completer # default: false, e.g. false
  --include-quote-count: string@bool-completer # default: true, e.g. true
  --include-reply-count: int # default: 1, e.g. 1
  --tweet-mode: string # default: extended, e.g. extended
  --include-ext-views: string@bool-completer # default: true, e.g. true
  --include-entities: string@bool-completer # default: true, e.g. true
  --include-user-entities: string@bool-completer # default: true, e.g. true
  --include-ext-media-color: string@bool-completer # default: true, e.g. true
  --include-ext-media-availability: string@bool-completer # default: true, e.g. true
  --include-ext-sensitive-media-warning: string@bool-completer # default: true, e.g. true
  --include-ext-trusted-friends-metadata: string@bool-completer # default: true, e.g. true
  --send-error-codes: string@bool-completer # default: true, e.g. true
  --simple-quoted-tweet: string@bool-completer # default: true, e.g. true
  --q: string # default: elon musk, e.g. elon musk
  --query-source: string # default: trend_click, e.g. trend_click
  --count: int # default: 20, e.g. 20
  --requestContext: string # default: launch, e.g. launch
  --pc: int # default: 1, e.g. 1
  --spelling-corrections: int # default: 1, e.g. 1
  --include-ext-edit-control: string@bool-completer # default: true, e.g. true
  --ext: string # default: mediaStats,highlightedLabel,hasNftAvatar,voiceInfo,birdwatchPivot,enrichments,superFollowMetadata,unmentionInfo,editControl,vibe, e.g. mediaStats,highlightedLabel,hasNftAvatar,voiceInfo,birdwatchPivot,enrichments,superFollowMetadata,unmentionInfo,editControl,vibe
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_profile_interstitial_type" $include_profile_interstitial_type "scalar") (serialize-qp "include_blocking" $include_blocking "scalar") (serialize-qp "include_blocked_by" $include_blocked_by "scalar") (serialize-qp "include_followed_by" $include_followed_by "scalar") (serialize-qp "include_want_retweets" $include_want_retweets "scalar") (serialize-qp "include_mute_edge" $include_mute_edge "scalar") (serialize-qp "include_can_dm" $include_can_dm "scalar") (serialize-qp "include_can_media_tag" $include_can_media_tag "scalar") (serialize-qp "include_ext_has_nft_avatar" $include_ext_has_nft_avatar "scalar") (serialize-qp "include_ext_is_blue_verified" $include_ext_is_blue_verified "scalar") (serialize-qp "include_ext_verified_type" $include_ext_verified_type "scalar") (serialize-qp "include_ext_profile_image_shape" $include_ext_profile_image_shape "scalar") (serialize-qp "skip_status" $skip_status "scalar") (serialize-qp "cards_platform" $cards_platform "scalar") (serialize-qp "include_cards" $include_cards "scalar") (serialize-qp "include_ext_alt_text" $include_ext_alt_text "scalar") (serialize-qp "include_ext_limited_action_results" $include_ext_limited_action_results "scalar") (serialize-qp "include_quote_count" $include_quote_count "scalar") (serialize-qp "include_reply_count" $include_reply_count "scalar") (serialize-qp "tweet_mode" $tweet_mode "scalar") (serialize-qp "include_ext_views" $include_ext_views "scalar") (serialize-qp "include_entities" $include_entities "scalar") (serialize-qp "include_user_entities" $include_user_entities "scalar") (serialize-qp "include_ext_media_color" $include_ext_media_color "scalar") (serialize-qp "include_ext_media_availability" $include_ext_media_availability "scalar") (serialize-qp "include_ext_sensitive_media_warning" $include_ext_sensitive_media_warning "scalar") (serialize-qp "include_ext_trusted_friends_metadata" $include_ext_trusted_friends_metadata "scalar") (serialize-qp "send_error_codes" $send_error_codes "scalar") (serialize-qp "simple_quoted_tweet" $simple_quoted_tweet "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "query_source" $query_source "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "requestContext" $requestContext "scalar") (serialize-qp "pc" $pc "scalar") (serialize-qp "spelling_corrections" $spelling_corrections "scalar") (serialize-qp "include_ext_edit_control" $include_ext_edit_control "scalar") (serialize-qp "ext" $ext "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2/search/adaptive.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get blue verified followers
#
# GET /graphql/{pathQueryId}/BlueVerifiedFollowers
# operationId: getBlueVerifiedFollowers
export def "graphql-blue-verified-followers get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 20, "includePromotedContent": false}, e.g. {"userId": "44196397", "count": 20, "includePromotedContent": false}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/BlueVerifiedFollowers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get bookmarks
#
# GET /graphql/{pathQueryId}/Bookmarks
# operationId: getBookmarks
export def "graphql-bookmarks get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"count": 20, "includePromotedContent": true}, e.g. {"count": 20, "includePromotedContent": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<bookmark_timeline_v2: record<timeline: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Bookmarks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get about of community
#
# GET /graphql/{pathQueryId}/CommunityAboutTimeline
# operationId: getCommunityAboutTimeline
export def "graphql-community-about-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"communityId": "1489422448332197888", "withCommunity": true}, e.g. {"communityId": "1489422448332197888", "withCommunity": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<communityResults: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CommunityAboutTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get media list of community
#
# GET /graphql/{pathQueryId}/CommunityMediaTimeline
# operationId: getCommunityMediaTimeline
export def "graphql-community-media-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"communityId": "1489422448332197888", "count": 20, "withCommunity": true}, e.g. {"communityId": "1489422448332197888", "count": 20, "withCommunity": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<communityResults: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CommunityMediaTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tweet list of community. rankingMode:[Recency, Relevance]
#
# GET /graphql/{pathQueryId}/CommunityTweetsTimeline
# operationId: getCommunityTweetsTimeline
export def "graphql-community-tweets-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"communityId": "1489422448332197888", "count": 20, "displayLocation": "Community", "rankingMode": "Relevance", "withCommunity": true}, e.g. {"communityId": "1489422448332197888", "count": 20, "displayLocation": "Community", "rankingMode": "Relevance", "withCommunity": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<communityResults: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CommunityTweetsTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# create Bookmark
#
# POST /graphql/{pathQueryId}/CreateBookmark
# operationId: postCreateBookmark
# --variables shape: {tweet_id: string}
export def "graphql-create-bookmark post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: aoDbu3RHznuiSkQ9aNM67Q, e.g. aoDbu3RHznuiSkQ9aNM67Q
  --body-variables: record # shape: {tweet_id: string}
]: any -> record<data: record<tweet_bookmark_put: string>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CreateBookmark")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# create Retweet
#
# POST /graphql/{pathQueryId}/CreateRetweet
# operationId: postCreateRetweet
# --variables shape: {dark_request: bool, tweet_id: string}
export def "graphql-create-retweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: mbRO74GrOvSfRcJnlMapnQ, e.g. mbRO74GrOvSfRcJnlMapnQ
  --body-variables: record # shape: {dark_request: bool, tweet_id: string}
]: any -> record<data: record<create_retweet: record<retweet_results: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CreateRetweet")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# create Tweet
#
# POST /graphql/{pathQueryId}/CreateTweet
# operationId: postCreateTweet
# --features shape: {articles_preview_enabled: bool, c9s_tweet_anatomy_moderator_badge_enabled: bool, communities_web_enable_tweet_community_results_fetch: bool, content_disclosure_ai_generated_indicator_enabled: bool, content_disclosure_indicator_enabled: bool, freedom_of_speech_not_reach_fetch_enabled: bool, graphql_is_translatable_rweb_tweet_is_translatable_enabled: bool, longform_notetweets_consumption_enabled: bool, longform_notetweets_inline_media_enabled: bool, longform_notetweets_rich_text_read_enabled: bool, post_ctas_fetch_enabled: bool, premium_content_api_read_enabled: bool, profile_label_improvements_pcf_label_in_post_enabled: bool, responsive_web_edit_tweet_api_enabled: bool, responsive_web_graphql_skip_user_profile_image_extensions_enabled: bool, responsive_web_graphql_timeline_navigation_enabled: bool, responsive_web_grok_analysis_button_from_backend: bool, responsive_web_grok_analyze_button_fetch_trends_enabled: bool, responsive_web_grok_analyze_post_followups_enabled: bool, responsive_web_grok_annotations_enabled: bool, responsive_web_grok_community_note_auto_translation_is_enabled: bool, responsive_web_grok_image_annotation_enabled: bool, responsive_web_grok_imagine_annotation_enabled: bool, responsive_web_grok_share_attachment_enabled: bool, responsive_web_grok_show_grok_translated_post: bool, responsive_web_jetfuel_frame: bool, responsive_web_profile_redirect_enabled: bool, responsive_web_twitter_article_tweet_consumption_enabled: bool, rweb_cashtags_composer_attachment_enabled: bool, rweb_cashtags_enabled: bool, rweb_conversational_replies_downvote_enabled: bool, rweb_tipjar_consumption_enabled: bool, standardized_nudges_misinfo: bool, tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: bool, verified_phone_label_enabled: bool, view_counts_everywhere_api_enabled: bool}
# --variables shape: {attachment_url?: string, conversation_control?: record, dark_request: bool, disallowed_reply_options?: record, media: record, reply?: record, semantic_annotation_ids: list, tweet_text: string}
export def "graphql-create-tweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  features: record # shape: {articles_preview_enabled: bool, c9s_tweet_anatomy_moderator_badge_enabled: bool, communities_web_enable_tweet_community_results_fetch: bool, content_disclosure_ai_generated_indicator_enabled: bool, content_disclosure_indicator_enabled: bool, freedom_of_speech_not_reach_fetch_enabled: bool, graphql_is_translatable_rweb_tweet_is_translatable_enabled: bool, longform_notetweets_consumption_enabled: bool, longform_notetweets_inline_media_enabled: bool, longform_notetweets_rich_text_read_enabled: bool, post_ctas_fetch_enabled: bool, premium_content_api_read_enabled: bool, profile_label_improvements_pcf_label_in_post_enabled: bool, responsive_web_edit_tweet_api_enabled: bool, responsive_web_graphql_skip_user_profile_image_extensions_enabled: bool, responsive_web_graphql_timeline_navigation_enabled: bool, responsive_web_grok_analysis_button_from_backend: bool, responsive_web_grok_analyze_button_fetch_trends_enabled: bool, responsive_web_grok_analyze_post_followups_enabled: bool, responsive_web_grok_annotations_enabled: bool, responsive_web_grok_community_note_auto_translation_is_enabled: bool, responsive_web_grok_image_annotation_enabled: bool, responsive_web_grok_imagine_annotation_enabled: bool, responsive_web_grok_share_attachment_enabled: bool, responsive_web_grok_show_grok_translated_post: bool, responsive_web_jetfuel_frame: bool, responsive_web_profile_redirect_enabled: bool, responsive_web_twitter_article_tweet_consumption_enabled: bool, rweb_cashtags_composer_attachment_enabled: bool, rweb_cashtags_enabled: bool, rweb_conversational_replies_downvote_enabled: bool, rweb_tipjar_consumption_enabled: bool, standardized_nudges_misinfo: bool, tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled: bool, verified_phone_label_enabled: bool, view_counts_everywhere_api_enabled: bool}
  queryId: string # default: 5CdvsV_zjv4L64XFifAglw, e.g. 5CdvsV_zjv4L64XFifAglw
  --body-variables: record # shape: {attachment_url?: string, conversation_control?: record, dark_request: bool, disallowed_reply_options?: record, media: record, reply?: record, semantic_annotation_ids: list, tweet_text: string}
]: any -> record<data: record<create_tweet: record<tweet_results: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/CreateTweet")
  let body = {features: $features, queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete Bookmark
#
# POST /graphql/{pathQueryId}/DeleteBookmark
# operationId: postDeleteBookmark
# --variables shape: {tweet_id: string}
export def "graphql-delete-bookmark post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: Wlmlj2-xzyS1GN3a6cj-mQ, e.g. Wlmlj2-xzyS1GN3a6cj-mQ
  --body-variables: record # shape: {tweet_id: string}
]: any -> record<data: record<tweet_bookmark_delete: string>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/DeleteBookmark")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete Retweet
#
# POST /graphql/{pathQueryId}/DeleteRetweet
# operationId: postDeleteRetweet
# --variables shape: {dark_request: bool, source_tweet_id: string}
export def "graphql-delete-retweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: ZyZigVsNiFO6v1dEks1eWg, e.g. ZyZigVsNiFO6v1dEks1eWg
  --body-variables: record # shape: {dark_request: bool, source_tweet_id: string}
]: any -> record<data: record<create_retweet: record<retweet_results: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/DeleteRetweet")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete Retweet
#
# POST /graphql/{pathQueryId}/DeleteTweet
# operationId: postDeleteTweet
# --variables shape: {dark_request: bool, tweet_id: string}
export def "graphql-delete-tweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: VaenaVgh5q5ih7kvyVjgtg, e.g. VaenaVgh5q5ih7kvyVjgtg
  --body-variables: record # shape: {dark_request: bool, tweet_id: string}
]: any -> record<data: record<delete_retweet: record<tweet_results: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/DeleteTweet")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# favorite Tweet
#
# POST /graphql/{pathQueryId}/FavoriteTweet
# operationId: postFavoriteTweet
# --variables shape: {tweet_id: string}
export def "graphql-favorite-tweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: lI07N6Otwv1PhnEgXILM7A, e.g. lI07N6Otwv1PhnEgXILM7A
  --body-variables: record # shape: {tweet_id: string}
]: any -> record<data: record<favorite_tweet: string>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/FavoriteTweet")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get tweet favoriters
#
# GET /graphql/{pathQueryId}/Favoriters
# operationId: getFavoriters
export def "graphql-favoriters get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"tweetId": "1349129669258448897", "count": 20, "includePromotedContent": true}, e.g. {"tweetId": "1349129669258448897", "count": 20, "includePromotedContent": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "rweb_xchat_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": false, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<favoriters_timeline: record<id: string, timeline: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Favoriters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user list of followers
#
# GET /graphql/{pathQueryId}/Followers
# operationId: getFollowers
export def "graphql-followers get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 20, "includePromotedContent": false}, e.g. {"userId": "44196397", "count": 20, "includePromotedContent": false}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get followers you know
#
# GET /graphql/{pathQueryId}/FollowersYouKnow
# operationId: getFollowersYouKnow
export def "graphql-followers-you-know get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 20, "includePromotedContent": false}, e.g. {"userId": "44196397", "count": 20, "includePromotedContent": false}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/FollowersYouKnow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user list of following
#
# GET /graphql/{pathQueryId}/Following
# operationId: getFollowing
export def "graphql-following get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 20, "includePromotedContent": false}, e.g. {"userId": "44196397", "count": 20, "includePromotedContent": false}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tweet list of timeline
#
# GET /graphql/{pathQueryId}/HomeLatestTimeline
# operationId: getHomeLatestTimeline
export def "graphql-home-latest-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"count": 20, "includePromotedContent": true, "latestControlAvailable": true, "requestContext": "launch", "seenTweetIds": ["1349129669258448897"]}, e.g. {"count": 20, "includePromotedContent": true, "latestControlAvailable": true, "requestContext": "launch", "seenTweetIds": ["1349129669258448897"]}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<home: record<home_timeline_urt: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/HomeLatestTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tweet list of timeline
#
# GET /graphql/{pathQueryId}/HomeTimeline
# operationId: getHomeTimeline
export def "graphql-home-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"count": 20, "includePromotedContent": true, "latestControlAvailable": true, "requestContext": "launch", "seenTweetIds": ["1349129669258448897"], "withCommunity": true}, e.g. {"count": 20, "includePromotedContent": true, "latestControlAvailable": true, "requestContext": "launch", "seenTweetIds": ["1349129669258448897"], "withCommunity": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<home: record<home_timeline_urt: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/HomeTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user likes tweets
#
# GET /graphql/{pathQueryId}/Likes
# operationId: getLikes
export def "graphql-likes get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 20, "includePromotedContent": false, "withClientEventToken": false, "withBirdwatchNotes": false, "withVoice": true}, e.g. {"userId": "44196397", "count": 20, "includePromotedContent": false, "withClientEventToken": false, "withBirdwatchNotes": false, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticlePlainText": false}, e.g. {"withArticlePlainText": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Likes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tweet list of timeline
#
# GET /graphql/{pathQueryId}/ListLatestTweetsTimeline
# operationId: getListLatestTweetsTimeline
export def "graphql-list-latest-tweets-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"listId": "1539453138322673664", "count": 20}, e.g. {"listId": "1539453138322673664", "count": 20}
  --features: string # default: {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<list: record<tweets_timeline: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/ListLatestTweetsTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get notification list. timeline_type:[All, Verified, Mentions]
#
# GET /graphql/{pathQueryId}/NotificationsTimeline
# operationId: getNotificationsTimeline
export def "graphql-notifications-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"timeline_type": "All", "count": 20}, e.g. {"timeline_type": "All", "count": 20}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<viewer_v2: record<user_results: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/NotificationsTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user by screen name
#
# GET /graphql/{pathQueryId}/ProfileSpotlightsQuery
# operationId: getProfileSpotlightsQuery
export def "graphql-profile-spotlights-query get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"screen_name": "elonmusk"}, e.g. {"screen_name": "elonmusk"}
  --features: string # default: {}, e.g. {}
]: nothing -> record<data: record<user_result_by_screen_name: record<id: string, result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/ProfileSpotlightsQuery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tweet retweeters
#
# GET /graphql/{pathQueryId}/Retweeters
# operationId: getRetweeters
export def "graphql-retweeters get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"tweetId": "1349129669258448897", "count": 20, "includePromotedContent": true}, e.g. {"tweetId": "1349129669258448897", "count": 20, "includePromotedContent": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<retweeters_timeline: record<id: string, timeline: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/Retweeters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# search tweet list. product:[Top, Latest, People, Photos, Videos]
#
# GET /graphql/{pathQueryId}/SearchTimeline
# operationId: getSearchTimeline
export def "graphql-search-timeline get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"rawQuery": "elonmusk", "count": 20, "querySource": "typed_query", "product": "Top"}, e.g. {"rawQuery": "elonmusk", "count": 20, "querySource": "typed_query", "product": "Top"}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
]: nothing -> record<data: record<search_by_raw_query: record<search_timeline: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/SearchTimeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get TweetDetail
#
# GET /graphql/{pathQueryId}/TweetDetail
# operationId: getTweetDetail
export def "graphql-tweet-detail get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"focalTweetId": "1349129669258448897", "referrer": "home", "with_rux_injections": false, "rankingMode": "Relevance", "includePromotedContent": true, "withCommunity": true, "withQuickPromoteEligibilityTweetFields": true, "withBirdwatchNotes": true, "withVoice": true}, e.g. {"focalTweetId": "1349129669258448897", "referrer": "home", "with_rux_injections": false, "rankingMode": "Relevance", "includePromotedContent": true, "withCommunity": true, "withQuickPromoteEligibilityTweetFields": true, "withBirdwatchNotes": true, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticleRichContentState": true, "withArticlePlainText": false, "withArticleSummaryText": true, "withArticleVoiceOver": true, "withGrokAnalyze": false, "withDisallowedReplyControls": false}, e.g. {"withArticleRichContentState": true, "withArticlePlainText": false, "withArticleSummaryText": true, "withArticleVoiceOver": true, "withGrokAnalyze": false, "withDisallowedReplyControls": false}
]: nothing -> record<data: record<threaded_conversation_with_injections_v2: record<instructions: list, metadata: record, responseObjects: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/TweetDetail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get TweetResultByRestId
#
# GET /graphql/{pathQueryId}/TweetResultByRestId
# operationId: getTweetResultByRestId
export def "graphql-tweet-result-by-rest-id get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"tweetId": "1691730070669517096", "withCommunity": false, "includePromotedContent": false, "withVoice": false}, e.g. {"tweetId": "1691730070669517096", "withCommunity": false, "includePromotedContent": false, "withVoice": false}
  --features: string # default: {"creator_subscriptions_tweet_preview_api_enabled": true, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"creator_subscriptions_tweet_preview_api_enabled": true, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "tweet_awards_web_tipping_enabled": false, "responsive_web_grok_show_grok_translated_post": false, "responsive_web_grok_analysis_button_from_backend": true, "creator_subscriptions_quote_tweet_preview_enabled": false, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": true, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": false, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticleRichContentState": true, "withArticlePlainText": false}, e.g. {"withArticleRichContentState": true, "withArticlePlainText": false}
]: nothing -> record<data: record<tweetResult: record<__typename: string, result: any>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/TweetResultByRestId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# unfavorite Tweet
#
# POST /graphql/{pathQueryId}/UnfavoriteTweet
# operationId: postUnfavoriteTweet
# --variables shape: {dark_request: bool, tweet_id: string}
export def "graphql-unfavorite-tweet post" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  queryId: string # default: ZYKSe-w7KEslx3JhSIk5LA, e.g. ZYKSe-w7KEslx3JhSIk5LA
  --body-variables: record # shape: {dark_request: bool, tweet_id: string}
]: any -> record<data: record<unfavorite_tweet: string>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UnfavoriteTweet")
  let body = {queryId: $queryId, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get user by rest id
#
# GET /graphql/{pathQueryId}/UserByRestId
# operationId: getUserByRestId
export def "graphql-user-by-rest-id get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "withSafetyModeUserFields": true}, e.g. {"userId": "44196397", "withSafetyModeUserFields": true}
  --features: string # default: {"hidden_profile_subscriptions_enabled": true, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "highlights_tweets_tab_ui_enabled": true, "responsive_web_twitter_article_notes_tab_enabled": true, "subscriptions_feature_can_gift_premium": true, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}, e.g. {"hidden_profile_subscriptions_enabled": true, "payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "highlights_tweets_tab_ui_enabled": true, "responsive_web_twitter_article_notes_tab_enabled": true, "subscriptions_feature_can_gift_premium": true, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}
]: nothing -> record<data: record<user: record<result: any>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserByRestId" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user by screen name
#
# GET /graphql/{pathQueryId}/UserByScreenName
# operationId: getUserByScreenName
export def "graphql-user-by-screen-name get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"screen_name": "elonmusk"}, e.g. {"screen_name": "elonmusk"}
  --features: string # default: {"hidden_profile_subscriptions_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "subscriptions_verification_info_is_identity_verified_enabled": true, "subscriptions_verification_info_verified_since_enabled": true, "highlights_tweets_tab_ui_enabled": true, "responsive_web_twitter_article_notes_tab_enabled": true, "subscriptions_feature_can_gift_premium": true, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}, e.g. {"hidden_profile_subscriptions_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "subscriptions_verification_info_is_identity_verified_enabled": true, "subscriptions_verification_info_verified_since_enabled": true, "highlights_tweets_tab_ui_enabled": true, "responsive_web_twitter_article_notes_tab_enabled": true, "subscriptions_feature_can_gift_premium": true, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}
  --fieldToggles: string # default: {"withPayments": false, "withAuxiliaryUserLabels": true}, e.g. {"withPayments": false, "withAuxiliaryUserLabels": true}
]: nothing -> record<data: record<user: record<result: any>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserByScreenName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user highlights tweets
#
# GET /graphql/{pathQueryId}/UserHighlightsTweets
# operationId: getUserHighlightsTweets
export def "graphql-user-highlights-tweets get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 40, "includePromotedContent": true, "withVoice": true}, e.g. {"userId": "44196397", "count": 40, "includePromotedContent": true, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticlePlainText": false}, e.g. {"withArticlePlainText": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserHighlightsTweets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user media tweets
#
# GET /graphql/{pathQueryId}/UserMedia
# operationId: getUserMedia
export def "graphql-user-media get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 40, "includePromotedContent": false, "withClientEventToken": false, "withBirdwatchNotes": false, "withVoice": true}, e.g. {"userId": "44196397", "count": 40, "includePromotedContent": false, "withClientEventToken": false, "withBirdwatchNotes": false, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticlePlainText": false}, e.g. {"withArticlePlainText": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserMedia" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user tweets
#
# GET /graphql/{pathQueryId}/UserTweets
# operationId: getUserTweets
export def "graphql-user-tweets get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 40, "includePromotedContent": true, "withQuickPromoteEligibilityTweetFields": true, "withVoice": true}, e.g. {"userId": "44196397", "count": 40, "includePromotedContent": true, "withQuickPromoteEligibilityTweetFields": true, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticlePlainText": false}, e.g. {"withArticlePlainText": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserTweets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user replies tweets
#
# GET /graphql/{pathQueryId}/UserTweetsAndReplies
# operationId: getUserTweetsAndReplies
export def "graphql-user-tweets-and-replies get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userId": "44196397", "count": 40, "includePromotedContent": true, "withCommunity": true, "withVoice": true}, e.g. {"userId": "44196397", "count": 40, "includePromotedContent": true, "withCommunity": true, "withVoice": true}
  --features: string # default: {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}, e.g. {"rweb_video_screen_enabled": false, "rweb_cashtags_enabled": true, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": false, "verified_phone_label_enabled": false, "creator_subscriptions_tweet_preview_api_enabled": true, "responsive_web_graphql_timeline_navigation_enabled": true, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "premium_content_api_read_enabled": false, "communities_web_enable_tweet_community_results_fetch": true, "c9s_tweet_anatomy_moderator_badge_enabled": true, "responsive_web_grok_analyze_button_fetch_trends_enabled": false, "responsive_web_grok_analyze_post_followups_enabled": true, "rweb_cashtags_composer_attachment_enabled": true, "responsive_web_jetfuel_frame": true, "responsive_web_grok_share_attachment_enabled": true, "responsive_web_grok_annotations_enabled": true, "articles_preview_enabled": true, "responsive_web_edit_tweet_api_enabled": true, "rweb_conversational_replies_downvote_enabled": false, "graphql_is_translatable_rweb_tweet_is_translatable_enabled": true, "view_counts_everywhere_api_enabled": true, "longform_notetweets_consumption_enabled": true, "responsive_web_twitter_article_tweet_consumption_enabled": true, "content_disclosure_indicator_enabled": true, "content_disclosure_ai_generated_indicator_enabled": true, "responsive_web_grok_show_grok_translated_post": true, "responsive_web_grok_analysis_button_from_backend": true, "post_ctas_fetch_enabled": true, "freedom_of_speech_not_reach_fetch_enabled": true, "standardized_nudges_misinfo": true, "tweet_with_visibility_results_prefer_gql_limited_actions_policy_enabled": true, "longform_notetweets_rich_text_read_enabled": true, "longform_notetweets_inline_media_enabled": false, "responsive_web_grok_image_annotation_enabled": true, "responsive_web_grok_imagine_annotation_enabled": true, "responsive_web_grok_community_note_auto_translation_is_enabled": true, "responsive_web_enhance_cards_enabled": false}
  --fieldToggles: string # default: {"withArticlePlainText": false}, e.g. {"withArticlePlainText": false}
]: nothing -> record<data: record<user: record<result: record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "fieldToggles" $fieldToggles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UserTweetsAndReplies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get users by rest ids
#
# GET /graphql/{pathQueryId}/UsersByRestIds
# operationId: getUsersByRestIds
export def "graphql-users-by-rest-ids get" [
  pathQueryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-variables: string # default: {"userIds": ["44196397"]}, e.g. {"userIds": ["44196397"]}
  --features: string # default: {"payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}, e.g. {"payments_enabled": false, "profile_label_improvements_pcf_label_in_post_enabled": true, "responsive_web_profile_redirect_enabled": false, "rweb_tipjar_consumption_enabled": true, "verified_phone_label_enabled": false, "responsive_web_graphql_skip_user_profile_image_extensions_enabled": false, "responsive_web_graphql_timeline_navigation_enabled": true}
]: nothing -> record<data: record<users: list<record>>, errors: table<code: int, extensions: record, kind: string, locations: list, message: string, name: string, path: list, retry_after: int, source: string, tracing: record>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variables" $qp_variables "scalar") (serialize-qp "features" $features "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/graphql/($pathQueryId)/UsersByRestIds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This is not an actual endpoint
#
# GET /other
# operationId: other
export def "other other" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<Session: record<SsoInitTokens: record, communitiesActions: record<create: bool>, country: string, guestId: string, hasCommunityMemberships: bool, isActiveCreator: bool, isRestrictedSession: bool, isSuperFollowSubscriber: bool, language: string, oneFactorLoginEligibility: record<fetchStatus: string>, superFollowersCount: int, superFollowsApplicationStatus: string, userFeatures: record<mediatool_studio_library: bool>, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "accept"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/other")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
