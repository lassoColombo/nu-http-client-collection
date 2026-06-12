# Auto-generated client for PeerTube v8.1.0
# Source: https://raw.githubusercontent.com/Chocobozzz/PeerTube/develop/support/doc/api/openapi.yaml
# Auth: --token flag or $env.PEERTUBE_TOKEN

const BASE_URL = "https://peertube2.cpy.re"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PEERTUBE_TOKEN | default "" }
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

def base-url-completer [] { ["https://peertube2.cpy.re" "https://peertube3.cpy.re" "https://peertube.cpy.re"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/atom+xml" "application/json" "application/rss+xml" "application/xml" "text/xml"] }
def nsfw-completer [] { ["false" "true"] }
def include-completer [] { ["0" "1" "16" "2" "32" "4" "8"] }
def privacyOneOf-completer [] { ["1" "2" "3" "4" "5"] }
def skipCount-completer [] { ["false" "true"] }
def sort-completer [] { ["-best" "-comments" "-createdAt" "-duration" "-hot" "-likes" "-publishedAt" "-trending" "-views" "name"] }
def nsfwFlagsIncluded-completer [] { ["0" "1" "2" "4"] }
def nsfwFlagsExcluded-completer [] { ["0" "1" "2" "4"] }
def sort-completer-1 [] { ["createdAt"] }
def jobType-completer [] { ["activitypub-follow" "activitypub-http-broadcast" "activitypub-http-fetcher" "activitypub-http-unicast" "activitypub-refresher" "email" "video-channel-import" "video-file-import" "video-import" "video-live-ending" "video-redundancy" "video-transcoding" "videos-stats"] }
def state-completer [] { ["accepted" "pending"] }
def actorType-completer [] { ["Application" "Group" "Organization" "Person" "Service"] }
def role-completer [] { ["0" "1" "2"] }
def adminFlags-completer [] { ["0" "1"] }
def sort-completer-2 [] { ["-createdAt" "-id" "-username"] }
def nsfwPolicy-completer [] { ["both" "false" "true"] }
def nsfwFlagsDisplayed-completer [] { ["0" "1" "2" "4"] }
def nsfwFlagsHidden-completer [] { ["0" "1" "2" "4"] }
def nsfwFlagsWarned-completer [] { ["0" "1" "2" "4"] }
def nsfwFlagsBlurred-completer [] { ["0" "1" "2" "4"] }
def sort-completer-3 [] { ["-channelUpdatedAt" "-createdAt" "-id"] }
def feature-completer [] { ["1"] }
def sort-completer-4 [] { ["-createdAt" "-state" "createdAt" "state"] }
def sort-completer-5 [] { ["-createdAt" "createdAt"] }
def state-completer-1 [] { ["1" "2" "3"] }
def scope-completer [] { ["subtitle"] }
def privacy-completer [] { ["1" "2" "3" "4" "5"] }
def nsfwFlags-completer [] { ["0" "1" "2" "4"] }
def commentsPolicy-completer [] { ["1" "2" "3"] }
def viewEvent-completer [] { ["seek"] }
def sort-completer-6 [] { ["-createdAt" "-id" "-state"] }
def videoIs-completer [] { ["blacklisted" "deleted"] }
def filter-completer [] { ["account" "comment" "video"] }
def type-completer [] { ["1" "2"] }
def sort-completer-7 [] { ["-createdAt" "-dislikes" "-duration" "-id" "-likes" "-uuid" "-views" "name"] }
def policy-completer [] { ["1" "2" "3"] }
def playlistType-completer [] { ["1" "2"] }
def theme-completer [] { ["channel-default" "galaxy" "instance-default" "lucide"] }
def theme-completer-1 [] { ["galaxy" "instance-default" "lucide"] }
def privacy-completer-1 [] { ["1" "2" "3"] }
def rating-completer [] { ["dislike" "like"] }
def sort-completer-8 [] { ["-createdAt" "-totalReplies"] }
def transcodingType-completer [] { ["hls" "web-video"] }
def searchTarget-completer [] { ["local" "search-index"] }
def target-completer [] { ["my-videos" "remote-videos"] }
def sort-completer-9 [] { ["name"] }
def command-completer [] { ["process-remove-old-stats" "process-update-videos-scheduler" "process-video-channel-sync-latest" "process-video-stats-buffer" "process-video-viewers" "remove-dandling-resumable-uploads" "remove-expired-user-exports"] }
def level-completer [] { ["error" "warn"] }
def playerMode-completer [] { ["p2p-media-loader" "web-video"] }
def sort-completer-10 [] { ["createdAt" "priority" "progress" "state" "updatedAt"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "static-web-videos get" } } | get name | first)
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

# Get public Web Video file
#
# GET /static/web-videos/{filename}
export def "static-web-videos get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/static/web-videos/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get private Web Video file
#
# GET /static/web-videos/private/{filename}
export def "static-web-videos-private get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --videoFileToken: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoFileToken" $videoFileToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/static/web-videos/private/($filename)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public HLS video file
#
# GET /static/streaming-playlists/hls/{filename}
export def "static-streaming-playlists-hls get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/static/streaming-playlists/hls/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get private HLS video file
#
# GET /static/streaming-playlists/hls/private/{filename}
export def "static-streaming-playlists-hls-private get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --videoFileToken: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
  --reinjectVideoFileToken: oneof<nothing, bool> # Ask the server to reinject videoFileToken in URLs in m3u8 playlist
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoFileToken" $videoFileToken "scalar") (serialize-qp "reinjectVideoFileToken" $reinjectVideoFileToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/static/streaming-playlists/hls/private/($filename)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download video file
#
# GET /download/videos/generate/{videoIdOrUUID}
export def "download-videos-generate get" [
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --videoFileIds: list # streams of video files to mux in the output
  --videoFileToken: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoFileIds" $videoFileIds "multi") (serialize-qp "videoFileToken" $videoFileToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/download/videos/generate/($videoIdOrUUID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Comments on videos feeds
#
# GET /feeds/video-comments.{format}
# operationId: getSyndicatedComments
export def "feeds-video-comments-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --videoId: string # limit listing comments to a specific video
  --accountId: string # limit listing comments to videos of a specific account
  --accountName: string # limit listing comments to videos of a specific account
  --videoChannelId: string # limit listing comments to videos of a specific video channel
  --videoChannelName: string # limit listing comments to videos of a specific video channel
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoId" $videoId "scalar") (serialize-qp "accountId" $accountId "scalar") (serialize-qp "accountName" $accountName "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "videoChannelName" $videoChannelName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/video-comments.($format)" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Common videos feeds
#
# GET /feeds/videos.{format}
# operationId: getSyndicatedVideos
export def "feeds-videos-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accountId: string # limit listing to a specific account
  --accountName: string # limit listing to a specific account
  --videoChannelId: string # limit listing to a specific video channel
  --videoChannelName: string # limit listing to a specific video channel
  --qp-sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "accountName" $accountName "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "videoChannelName" $videoChannelName "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/videos.($format)" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Videos of subscriptions feeds
#
# GET /feeds/subscriptions.{format}
# operationId: getSyndicatedSubscriptionVideos
export def "feeds-subscriptions-format get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accountId: string # limit listing to a specific account
  --qp-token: string # private token allowing access
  --qp-sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/subscriptions.($format)" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Videos podcast feed
#
# GET /feeds/podcast/videos.xml
# operationId: getVideosPodcastFeed
export def "feeds-podcast-videosxml get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --videoChannelId: string # Limit listing to a specific video channel
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoChannelId" $videoChannelId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feeds/podcast/videos.xml" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an account
#
# GET /api/v1/accounts/{name}
# operationId: getAccount
export def "accounts get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, name: record, avatars: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of an account
#
# GET /api/v1/accounts/{name}/videos
# operationId: getAccountVideos
export def "accounts-videos get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List followers of an account
#
# GET /api/v1/accounts/{name}/followers
# operationId: getAccountFollowers
export def "accounts-followers get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: int, follower: record, following: record, score: float, state: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List accounts
#
# GET /api/v1/accounts
# operationId: getAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance public configuration
#
# GET /api/v1/config
# operationId: getConfig
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instance: record<name: string, shortDescription: string, defaultClientRoute: string, isNSFW: bool, defaultNSFWPolicy: string, serverCountry: string, defaultLanguage: string, support: record<text: string>, social: record<externalLink: string, mastodonLink: string, blueskyLink: string, xLink: string>, customizations: record<javascript: string, css: string>, avatars: list<record>, banners: list<record>>, search: record<remoteUri: record<users: bool, anonymous: bool>>, plugin: record<registered: list<string>>, theme: record<registered: list<string>>, email: record<enabled: bool>, contactForm: record<enabled: bool>, serverVersion: string, serverCommit: string, signup: record<allowed: bool, allowedForCurrentIP: bool, requiresEmailVerification: bool>, transcoding: record<hls: record<enabled: bool>, web_videos: record<enabled: bool>, enabledResolutions: list<int>>, import: record<videos: record<http: record, torrent: record>, videoChannelSynchronization: record<enabled: bool>, users: record<enabled: bool>>, export: record<users: record<enabled: bool, exportExpiration: float, maxUserVideoQuota: float>>, autoBlacklist: record<videos: record<ofUsers: record>>, avatar: record<file: record<size: record>, extensions: list<string>>, video: record<image: record<extensions: list, size: record>, file: record<extensions: list>>, videoCaption: record<file: record<size: record, extensions: list>>, user: record<videoQuota: int, videoQuotaDaily: int>, trending: record<videos: record<intervalDays: int>>, tracker: record<enabled: bool>, followings: record<instance: record<autoFollowIndex: record>>, federation: record<enabled: bool>, homepage: record<enabled: bool>, openTelemetry: record<metrics: record<enabled: bool, playbackStatsInterval: float>>, views: record<views: record<watchingInterval: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance "About" information
#
# GET /api/v1/config/about
# operationId: getAbout
export def "config-about get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instance: record<name: string, shortDescription: string, description: string, terms: string, codeOfConduct: string, hardwareInformation: string, creationReason: string, moderationInformation: string, administrator: string, maintenanceLifetime: string, businessModel: string, languages: list<string>, categories: list<int>, avatars: list<record>, banners: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/about")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance runtime configuration
#
# GET /api/v1/config/custom
# operationId: getCustomConfig
export def "config-custom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instance: record<name: string, shortDescription: string, description: string, terms: string, codeOfConduct: string, creationReason: string, moderationInformation: string, administrator: string, maintenanceLifetime: string, businessModel: string, hardwareInformation: string, languages: list<string>, categories: list<float>, isNSFW: bool, defaultNSFWPolicy: string, serverCountry: string, support: record<text: string>, social: record<externalLink: string, mastodonLink: string, blueskyLink: string, xLink: string>, defaultClientRoute: string, customizations: record<javascript: string, css: string>>, theme: record<default: string>, services: record<twitter: record<username: string>>, cache: record<previews: record<size: int>, captions: record<size: int>>, signup: record<enabled: bool, limit: int, requiresEmailVerification: bool>, admin: record<email: string>, contactForm: record<enabled: bool>, user: record<videoQuota: int, videoQuotaDaily: int>, transcoding: record<enabled: bool, originalFile: record<keep: bool>, allowAdditionalExtensions: bool, allowAudioFiles: bool, threads: int, concurrency: float, profile: string, resolutions: record<0p: bool, 144p: bool, 240p: bool, 360p: bool, 480p: bool, 720p: bool, 1080p: bool, 1440p: bool, 2160p: bool>, web_videos: record<enabled: bool>, hls: record<enabled: bool, splitAudioAndVideo: bool>>, import: record<videos: record<http: record, torrent: record>, video_channel_synchronization: record<enabled: bool>>, autoBlacklist: record<videos: record<ofUsers: record>>, followers: record<instance: record<enabled: bool, manualApproval: bool>>, storyboard: record<enabled: bool>, defaults: record<publish: record<downloadEnabled: bool, commentsPolicy: int, privacy: int, licence: int>, p2p: record<webapp: record, embed: record>, player: record<autoPlay: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set instance runtime configuration
#
# PUT /api/v1/config/custom
# operationId: putCustomConfig
export def "config-custom put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete instance runtime configuration
#
# DELETE /api/v1/config/custom
# operationId: delCustomConfig
export def "config-custom delCustomConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance banner
#
# POST /api/v1/config/instance-banner/pick
export def "config-instance-banner-pick post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bannerfile: string # The file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/instance-banner/pick")
  let body = {bannerfile: $bannerfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete instance banner
#
# DELETE /api/v1/config/instance-banner
export def "config-instance-banner delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/instance-banner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance avatar
#
# POST /api/v1/config/instance-avatar/pick
export def "config-instance-avatar-pick post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/instance-avatar/pick")
  let body = {avatarfile: $avatarfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete instance avatar
#
# DELETE /api/v1/config/instance-avatar
export def "config-instance-avatar delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/instance-avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update instance logo
#
# POST /api/v1/config/instance-logo/{logoType}/pick
export def "config-instance-logo-pick post" [
  logoType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logofile: string # The file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/instance-logo/($logoType)/pick")
  let body = {logofile: $logofile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete instance logo
#
# DELETE /api/v1/config/instance-logo/{logoType}
export def "config-instance-logo delete" [
  logoType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/config/instance-logo/($logoType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance custom homepage
#
# GET /api/v1/custom-pages/homepage/instance
export def "custom-pages-homepage-instance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom-pages/homepage/instance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set instance custom homepage
#
# PUT /api/v1/custom-pages/homepage/instance
export def "custom-pages-homepage-instance put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # content of the homepage, that will be injected in the client
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom-pages/homepage/instance")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause job queue
#
# POST /api/v1/jobs/pause
export def "jobs-pause post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/jobs/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume job queue
#
# POST /api/v1/jobs/resume
export def "jobs-resume post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/jobs/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List instance jobs
#
# GET /api/v1/jobs/{state}
# operationId: getJobs
export def "jobs get" [
  state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jobType: string@jobType-completer # job type
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, state: string, type: string, data: record, error: record, createdAt: string, finishedOn: string, processedOn: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jobType" $jobType "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/jobs/($state)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List instances following the server
#
# GET /api/v1/server/followers
export def "server-followers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer
  --actorType: string@actorType-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, follower: record, following: record, score: float, state: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "actorType" $actorType "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove or reject a follower to your server
#
# DELETE /api/v1/server/followers/{handle}
export def "server-followers delete" [
  handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/followers/($handle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject a pending follower to your server
#
# POST /api/v1/server/followers/{handle}/reject
export def "server-followers-reject post" [
  handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/followers/($handle)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept a pending follower to your server
#
# POST /api/v1/server/followers/{handle}/accept
export def "server-followers-accept post" [
  handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/followers/($handle)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List instances followed by the server
#
# GET /api/v1/server/following
export def "server-following get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer
  --actorType: string@actorType-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, follower: record, following: record, score: float, state: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "actorType" $actorType "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow a list of actors (PeerTube instance, channel or account)
#
# POST /api/v1/server/following
export def "server-following post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hosts: list
  --handles: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/following")
  let body = {hosts: $hosts, handles: $handles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unfollow an actor (PeerTube instance, channel or account)
#
# DELETE /api/v1/server/following/{hostOrHandle}
export def "server-following delete" [
  hostOrHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/following/($hostOrHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user
#
# POST /api/v1/users
# operationId: addUser
export def "users addUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string # immutable name of the user, used to find or mention its actor (e.g. chocobozzz)
  password: string # format: password
  email: string # The user email (format: email)
  --videoQuota: int # The user video quota in bytes (e.g. -1)
  --videoQuotaDaily: int # The user daily video quota in bytes (e.g. -1)
  --channelName: string # immutable name of the channel, used to interact with its actor (e.g. framasoft_videos)
  role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  --adminFlags: int@adminFlags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
]: any -> record<user: record<id: int, account: record<id: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let body = {username: $username, password: $password, email: $email, videoQuota: $videoQuota, videoQuotaDaily: $videoQuotaDaily, channelName: $channelName, role: $role, adminFlags: $adminFlags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /api/v1/users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Plain text search that will match with user usernames or emails
  --blocked: oneof<nothing, bool> # Filter results down to (un)banned users
  --role: int@role-completer # Filter results down to users with a specific role (e.g. 2)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2 # Sort users by criteria
]: nothing -> table<id: int, username: string, email: string, emailVerified: bool, emailPublic: bool, nsfwPolicy: string, nsfwFlagsDisplayed: int, nsfwFlagsHidden: int, nsfwFlagsWarned: int, nsfwFlagsBlurred: int, adminFlags: int, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, p2pEnabled: bool, videosHistoryEnabled: bool, videoLanguages: list<string>, language: string, videoQuota: int, videoQuotaDaily: int, role: record<id: int, label: string>, theme: string, account: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>, notificationSettings: record<abuseAsModerator: int, videoAutoBlacklistAsModerator: int, newUserRegistration: int, newVideoFromSubscription: int, blacklistOnMyVideo: int, myVideoPublished: int, myVideoImportFinished: int, commentMention: int, newCommentOnMyVideo: int, newFollow: int, newInstanceFollower: int, autoInstanceFollowing: int, abuseStateChange: int, abuseNewMessage: int, newPeerTubeVersion: int, newPluginVersion: int, myVideoStudioEditionFinished: int, myVideoTranscriptionGenerated: int>, videoChannels: list<record>, blocked: bool, blockedReason: string, noInstanceConfigWarningModal: bool, noAccountSetupWarningModal: bool, noWelcomeModal: bool, createdAt: string, pluginAuth: string, lastLoginDate: string, twoFactorEnabled: bool, newFeaturesInfoRead: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user
#
# DELETE /api/v1/users/{id}
# operationId: delUser
export def "users delUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /api/v1/users/{id}
# operationId: getUser
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withStats: oneof<nothing, bool> # include statistics about the user (only available as a moderator/admin)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withStats" $withStats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api/v1/users/{id}
# operationId: putUser
export def "users put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: any # The updated email of the user
  --emailVerified: oneof<nothing, bool> # Set the email as verified
  --videoQuota: int # The updated video quota of the user in bytes
  --videoQuotaDaily: int # The updated daily video quota of the user in bytes
  --pluginAuth: string # The auth plugin to use to authenticate the user (nullable, e.g. peertube-plugin-auth-saml2)
  --role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  --adminFlags: int@adminFlags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --password: string # format: password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let body = {email: $email, emailVerified: $emailVerified, videoQuota: $videoQuota, videoQuotaDaily: $videoQuotaDaily, pluginAuth: $pluginAuth, role: $role, adminFlags: $adminFlags, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Block a user
#
# POST /api/v1/users/{id}/block
export def "users-block post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Optional reason for blocking the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/block")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock a user
#
# POST /api/v1/users/{id}/unblock
export def "users-unblock post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/unblock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login prerequisite
#
# GET /api/v1/oauth-clients/local
# operationId: getOAuthClient
export def "oauth-clients-local get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, client_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/oauth-clients/local")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login
#
# POST /api/v1/users/token
# Discriminator (request): grant_type = password, refresh_token
# operationId: getOAuthToken
export def "users-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-otp: string # If the user enabled two factor authentication, you need to provide the OTP code in this header
  --body: record
]: any -> record<token_type: string, access_token: string, refresh_token: string, expires_in: int, refresh_token_expires_in: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/token")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-peertube-otp": $x_peertube_otp} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Logout
#
# POST /api/v1/users/revoke-token
# operationId: revokeOAuthToken
export def "users-revoke-token revokeOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/revoke-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List token sessions
#
# GET /api/v1/users/{id}/token-sessions
export def "users-token-sessions get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, data: table<id: int, currentSession: bool, loginDevice: string, loginIP: string, loginDate: string, lastActivityDevice: string, lastActivityIP: string, lastActivityDate: string, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/token-sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List token sessions
#
# GET /api/v1/users/{id}/token-sessions/{tokenSessionId}/revoke
export def "users-token-sessions-revoke get" [
  id: int
  tokenSessionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/token-sessions/($tokenSessionId)/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend user verification link
#
# POST /api/v1/users/ask-send-verify-email
# operationId: resendEmailToVerifyUser
export def "users-ask-send-verify-email resendEmailToVerifyUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/ask-send-verify-email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend verification link to registration request email
#
# POST /api/v1/users/registrations/ask-send-verify-email
# operationId: resendEmailToVerifyRegistration
export def "users-registrations-ask-send-verify-email resendEmailToVerifyRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Registration email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/registrations/ask-send-verify-email")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify a user
#
# POST /api/v1/users/{id}/verify-email
# operationId: verifyUser
export def "users-verify-email verifyUser" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verificationString: string # format: url
  --isPendingEmail: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/verify-email")
  let body = {verificationString: $verificationString, isPendingEmail: $isPendingEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify a registration email
#
# POST /api/v1/users/registrations/{registrationId}/verify-email
# operationId: verifyRegistrationEmail
export def "users-registrations-verify-email verifyRegistrationEmail" [
  registrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verificationString: string # format: url
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/registrations/($registrationId)/verify-email")
  let body = {verificationString: $verificationString} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ask to reset password
#
# POST /api/v1/users/ask-reset-password
export def "users-ask-reset-password post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/ask-reset-password")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset password
#
# POST /api/v1/users/{id}/reset-password
export def "users-reset-password post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verificationString: string # format: url
  password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/reset-password")
  let body = {verificationString: $verificationString, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request two factor auth
#
# POST /api/v1/users/{id}/two-factor/request
# operationId: requestTwoFactor
export def "users-two-factor-request requestTwoFactor" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentPassword: string # Password of the currently authenticated user
]: any -> table<otpRequest: record<requestToken: string, secret: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/two-factor/request")
  let body = {currentPassword: $currentPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirm two factor auth
#
# POST /api/v1/users/{id}/two-factor/confirm-request
# operationId: confirmTwoFactorRequest
export def "users-two-factor-confirm-request confirmTwoFactorRequest" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requestToken: string # Token to identify the two factor request
  otpToken: string # OTP token generated by the app
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/two-factor/confirm-request")
  let body = {requestToken: $requestToken, otpToken: $otpToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable two factor auth
#
# POST /api/v1/users/{id}/two-factor/disable
# operationId: disableTwoFactor
export def "users-two-factor-disable disableTwoFactor" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentPassword: string # Password of the currently authenticated user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/two-factor/disable")
  let body = {currentPassword: $currentPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initialize the resumable user import
#
# POST /api/v1/users/{userId}/imports/import-resumable
# operationId: userImportResumableInit
export def "users-imports-import-resumable userImportResumableInit" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Upload-Content-Length: float # Number of bytes that will be uploaded in subsequent requests. Set this value to the size of the file you are uploading. (e.g. 2469036)
  --X-Upload-Content-Type: string # MIME type of the file that you are uploading. Depending on your instance settings, acceptable values might vary. (e.g. video/mp4)
  --filename: string # Archive filename including extension (format: filename, e.g. user-export-6-2024-02-09T10_12_11.682Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($userId)/imports/import-resumable")
  let body = {filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Upload-Content-Length": $X_Upload_Content_Length, "X-Upload-Content-Type": $X_Upload_Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send chunk for the resumable user import
#
# PUT /api/v1/users/{userId}/imports/import-resumable
# operationId: userImportResumable
export def "users-imports-import-resumable userImportResumable" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Range: string # Specifies the bytes in the file that the request is uploading.  For example, a value of `bytes 0-262143/1000000` shows that the request is sending the first 262144 bytes (256 x 1024) in a 2,469,036 byte file.  (e.g. bytes 0-262143/2469036)
  --Content-Length: float # Size of the chunk that the request is sending.  Remember that larger chunks are more efficient. PeerTube's web client uses chunks varying from 1048576 bytes (~1MB) and increases or reduces size depending on connection health.  (e.g. 262144)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/users/($userId)/imports/import-resumable" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $Content_Range, "Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Cancel the resumable user import
#
# DELETE /api/v1/users/{userId}/imports/import-resumable
# operationId: userImportResumableCancel
export def "users-imports-import-resumable userImportResumableCancel" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Length: float # e.g. 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/users/($userId)/imports/import-resumable" $qp)
  let extra_headers = {"Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get latest user import
#
# GET /api/v1/users/{userId}/imports/latest
# operationId: getLatestUserImport
export def "users-imports-latest get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, state: record<id: int, label: string>, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($userId)/imports/latest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user export
#
# POST /api/v1/users/{userId}/exports/request
# operationId: requestUserExport
export def "users-exports-request requestUserExport" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withVideoFiles: oneof<nothing, bool> # Whether to include video files in the archive
]: any -> record<export: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($userId)/exports/request")
  let body = {withVideoFiles: $withVideoFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user exports
#
# GET /api/v1/users/{userId}/exports
# operationId: listUserExports
export def "users-exports listUserExports" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, state: record<id: int, label: string>, size: int, privateDownloadUrl: string, createdAt: string, expiresOn: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($userId)/exports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user export
#
# DELETE /api/v1/users/{userId}/exports/{id}
# operationId: deleteUserExport
export def "users-exports delete" [
  userId: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($userId)/exports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get my user information
#
# GET /api/v1/users/me
# operationId: getUserInfo
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, username: string, email: string, emailVerified: bool, emailPublic: bool, nsfwPolicy: string, nsfwFlagsDisplayed: int, nsfwFlagsHidden: int, nsfwFlagsWarned: int, nsfwFlagsBlurred: int, adminFlags: int, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, p2pEnabled: bool, videosHistoryEnabled: bool, videoLanguages: list<string>, language: string, videoQuota: int, videoQuotaDaily: int, role: record<id: int, label: string>, theme: string, account: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>, notificationSettings: record<abuseAsModerator: int, videoAutoBlacklistAsModerator: int, newUserRegistration: int, newVideoFromSubscription: int, blacklistOnMyVideo: int, myVideoPublished: int, myVideoImportFinished: int, commentMention: int, newCommentOnMyVideo: int, newFollow: int, newInstanceFollower: int, autoInstanceFollowing: int, abuseStateChange: int, abuseNewMessage: int, newPeerTubeVersion: int, newPluginVersion: int, myVideoStudioEditionFinished: int, myVideoTranscriptionGenerated: int>, videoChannels: list<record>, blocked: bool, blockedReason: string, noInstanceConfigWarningModal: bool, noAccountSetupWarningModal: bool, noWelcomeModal: bool, createdAt: string, pluginAuth: string, lastLoginDate: string, twoFactorEnabled: bool, newFeaturesInfoRead: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update my user information
#
# PUT /api/v1/users/me
# operationId: putUserInfo
export def "users-me put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # format: password
  --currentPassword: string # format: password
  --email: any # new email used for login and service communications
  --displayName: string # new name of the user in its representations
  --nsfwPolicy: string@nsfwPolicy-completer # new NSFW display policy
  --nsfwFlagsDisplayed: int@nsfwFlagsDisplayed-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --nsfwFlagsHidden: int@nsfwFlagsHidden-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --nsfwFlagsWarned: int@nsfwFlagsWarned-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --nsfwFlagsBlurred: int@nsfwFlagsBlurred-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --p2pEnabled: oneof<nothing, bool> # whether to enable P2P in the player or not
  --autoPlayVideo: oneof<nothing, bool> # new preference regarding playing videos automatically
  --autoPlayNextVideo: oneof<nothing, bool> # new preference regarding playing following videos automatically
  --autoPlayNextVideoPlaylist: oneof<nothing, bool> # new preference regarding playing following playlist videos automatically
  --videosHistoryEnabled: oneof<nothing, bool> # whether to keep track of watched history or not
  --videoLanguages: list # list of languages to filter videos down to
  --language: string # default language for this user
  --theme: string
  --noInstanceConfigWarningModal: oneof<nothing, bool>
  --noAccountSetupWarningModal: oneof<nothing, bool>
  --noWelcomeModal: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let body = {password: $password, currentPassword: $currentPassword, email: $email, displayName: $displayName, nsfwPolicy: $nsfwPolicy, nsfwFlagsDisplayed: $nsfwFlagsDisplayed, nsfwFlagsHidden: $nsfwFlagsHidden, nsfwFlagsWarned: $nsfwFlagsWarned, nsfwFlagsBlurred: $nsfwFlagsBlurred, p2pEnabled: $p2pEnabled, autoPlayVideo: $autoPlayVideo, autoPlayNextVideo: $autoPlayNextVideo, autoPlayNextVideoPlaylist: $autoPlayNextVideoPlaylist, videosHistoryEnabled: $videosHistoryEnabled, videoLanguages: $videoLanguages, language: $language, theme: $theme, noInstanceConfigWarningModal: $noInstanceConfigWarningModal, noAccountSetupWarningModal: $noAccountSetupWarningModal, noWelcomeModal: $noWelcomeModal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete my account
#
# DELETE /api/v1/users/me
# operationId: deleteMe
export def "users-me delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List comments on user's videos
#
# GET /api/v1/users/me/videos/comments
export def "users-me-videos-comments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --searchAccount: string # Filter comments by searching on the account
  --searchVideo: string # Filter comments by searching on the video
  --videoId: int # Limit results on this specific video
  --videoChannelId: int # Limit results on this specific video channel
  --autoTagOneOf: string # **PeerTube >= 6.2** filter on comments that contain one of these automatic tags
  --isHeldForReview: oneof<nothing, bool> # only display comments that are held for review
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
]: nothing -> record<total: int, data: table<id: int, url: any, text: any, heldForReview: any, threadId: any, inReplyToCommentId: any, createdAt: any, updatedAt: any, account: any, video: record, automaticTags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "searchAccount" $searchAccount "scalar") (serialize-qp "searchVideo" $searchVideo "scalar") (serialize-qp "videoId" $videoId "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "isHeldForReview" $isHeldForReview "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get video imports of my user
#
# GET /api/v1/users/me/videos/imports
export def "users-me-videos-imports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
  --videoId: int # Filter on import video ID
  --targetUrl: string # Filter on import target URL
  --videoChannelSyncId: float # Filter on imports created by a specific channel synchronization
  --search: string # Search in video names
]: nothing -> record<total: int, data: table<id: int, targetUrl: string, magnetUri: string, torrentfile: string, torrentName: string, state: record, error: string, createdAt: string, updatedAt: string, video: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar") (serialize-qp "videoId" $videoId "scalar") (serialize-qp "targetUrl" $targetUrl "scalar") (serialize-qp "videoChannelSyncId" $videoChannelSyncId "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos/imports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get my user used quota
#
# GET /api/v1/users/me/video-quota-used
export def "users-me-video-quota-used get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<videoQuotaUsed: float, videoQuotaUsedDaily: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/video-quota-used")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rate of my user for a video
#
# GET /api/v1/users/me/videos/{videoIdOrUUID}/rating
export def "users-me-videos-rating get" [
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, rating: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/videos/($videoIdOrUUID)/rating")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of my user
#
# GET /api/v1/users/me/videos
export def "users-me-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channelNameOneOf: string # **PeerTube >= 7.2** Filter on videos that are published by a channel with one of these names
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelNameOneOf" $channelNameOneOf "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List my user subscriptions
#
# GET /api/v1/users/me/subscriptions
export def "users-me-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-3
]: nothing -> record<total: int, data: table<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add subscription to my user
#
# POST /api/v1/users/me/subscriptions
export def "users-me-subscriptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  uri: string # uri of the video channels to subscribe to (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/subscriptions")
  let body = {uri: $uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get if subscriptions exist for my user
#
# GET /api/v1/users/me/subscriptions/exist
export def "users-me-subscriptions-exist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: list # list of uris to check if each is part of the user subscriptions
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uris" $uris "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions/exist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of subscriptions of my user
#
# GET /api/v1/users/me/subscriptions/videos
export def "users-me-subscriptions-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subscription of my user
#
# GET /api/v1/users/me/subscriptions/{subscriptionHandle}
export def "users-me-subscriptions get" [
  subscriptionHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, name: record, avatars: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, displayName: string, description: string, support: string, isLocal: bool, banners: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>, ownerAccount: record<id: int, url: string, name: record, avatars: list<record>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/subscriptions/($subscriptionHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete subscription of my user
#
# DELETE /api/v1/users/me/subscriptions/{subscriptionHandle}
export def "users-me-subscriptions delete" [
  subscriptionHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/subscriptions/($subscriptionHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List my notifications
#
# GET /api/v1/users/me/notifications
export def "users-me-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeOneOf: list # only list notifications of these types
  --unread: oneof<nothing, bool> # only list unread notifications
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, type: int, read: bool, video: record, videoImport: record, comment: record, videoAbuse: record, videoBlacklist: record, account: record, actorFollow: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeOneOf" $typeOneOf "multi") (serialize-qp "unread" $unread "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark notifications as read by their id
#
# POST /api/v1/users/me/notifications/read
export def "users-me-notifications-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list # ids of the notifications to mark as read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notifications/read")
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark all my notification as read
#
# POST /api/v1/users/me/notifications/read-all
export def "users-me-notifications-read-all post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notifications/read-all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update my notification settings
#
# PUT /api/v1/users/me/notification-settings
export def "users-me-notification-settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --abuseAsModerator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --videoAutoBlacklistAsModerator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newUserRegistration: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newVideoFromSubscription: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --blacklistOnMyVideo: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoPublished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoImportFinished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --commentMention: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newCommentOnMyVideo: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newFollow: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newInstanceFollower: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --autoInstanceFollowing: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --abuseStateChange: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --abuseNewMessage: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newPeerTubeVersion: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newPluginVersion: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoStudioEditionFinished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoTranscriptionGenerated: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notification-settings")
  let body = {abuseAsModerator: $abuseAsModerator, videoAutoBlacklistAsModerator: $videoAutoBlacklistAsModerator, newUserRegistration: $newUserRegistration, newVideoFromSubscription: $newVideoFromSubscription, blacklistOnMyVideo: $blacklistOnMyVideo, myVideoPublished: $myVideoPublished, myVideoImportFinished: $myVideoImportFinished, commentMention: $commentMention, newCommentOnMyVideo: $newCommentOnMyVideo, newFollow: $newFollow, newInstanceFollower: $newInstanceFollower, autoInstanceFollowing: $autoInstanceFollowing, abuseStateChange: $abuseStateChange, abuseNewMessage: $abuseNewMessage, newPeerTubeVersion: $newPeerTubeVersion, newPluginVersion: $newPluginVersion, myVideoStudioEditionFinished: $myVideoStudioEditionFinished, myVideoTranscriptionGenerated: $myVideoTranscriptionGenerated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Mark feature info as read
#
# POST /api/v1/users/me/new-feature-info/read
export def "users-me-new-feature-info-read post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feature: int@feature-completer # Represent a new feature that can be displayed to inform users. One of the following values:    - `1` CHANNEL_COLLABORATION
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/new-feature-info/read")
  let body = {feature: $feature} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List watched videos history
#
# GET /api/v1/users/me/history/videos
export def "users-me-history-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/history/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete history element
#
# DELETE /api/v1/users/me/history/videos/{videoIdOrUUID}
export def "users-me-history-videos delete" [
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/history/videos/($videoIdOrUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear video history
#
# POST /api/v1/users/me/history/videos/remove
export def "users-me-history-videos-remove post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --beforeDate: string # history before this date will be deleted (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/history/videos/remove")
  let body = {beforeDate: $beforeDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Update my user avatar
#
# POST /api/v1/users/me/avatar/pick
export def "users-me-avatar-pick post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload (format: binary)
]: any -> record<avatars: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/avatar/pick")
  let body = {avatarfile: $avatarfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete my avatar
#
# DELETE /api/v1/users/me/avatar
export def "users-me-avatar delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a user
#
# POST /api/v1/users/register
# operationId: registerUser
# --channel shape: {name?: string, displayName?: string}
export def "users-register registerUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: any # immutable name of the user, used to find or mention its actor
  password: string # format: password
  email: string # email of the user, used for login or service communications (format: email)
  --displayName: string # editable name of the user, displayed in its representations
  --channel: record # channel base information used to create the first channel of the user — shape: {name?: string, displayName?: string}
]: any -> record<state: record<id: int, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/register")
  let body = {username: $username, password: $password, email: $email, displayName: $displayName, channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request registration
#
# POST /api/v1/users/registrations/request
# operationId: requestRegistration
# --channel shape: {name?: string, displayName?: string}
export def "users-registrations-request requestRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: any # immutable name of the user, used to find or mention its actor
  password: string # format: password
  email: string # email of the user, used for login or service communications (format: email)
  --displayName: string # editable name of the user, displayed in its representations
  --channel: record # channel base information used to create the first channel of the user — shape: {name?: string, displayName?: string}
  registrationReason: string # reason for the user to register on the instance
]: any -> record<state: record<id: int, label: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/registrations/request")
  let body = {username: $username, password: $password, email: $email, displayName: $displayName, channel: $channel, registrationReason: $registrationReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept registration
#
# POST /api/v1/users/registrations/{registrationId}/accept
# operationId: acceptRegistration
export def "users-registrations-accept acceptRegistration" [
  registrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  moderationResponse: string # Moderation response to send to the user
  --preventEmailDelivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/registrations/($registrationId)/accept")
  let body = {moderationResponse: $moderationResponse, preventEmailDelivery: $preventEmailDelivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reject registration
#
# POST /api/v1/users/registrations/{registrationId}/reject
# operationId: rejectRegistration
export def "users-registrations-reject rejectRegistration" [
  registrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  moderationResponse: string # Moderation response to send to the user
  --preventEmailDelivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/registrations/($registrationId)/reject")
  let body = {moderationResponse: $moderationResponse, preventEmailDelivery: $preventEmailDelivery} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete registration
#
# DELETE /api/v1/users/registrations/{registrationId}
# operationId: deleteRegistration
export def "users-registrations delete" [
  registrationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/registrations/($registrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List registrations
#
# GET /api/v1/users/registrations
# operationId: listRegistrations
export def "users-registrations listRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string
  --qp-sort: string@sort-completer-4
  --stateOneOf: list
]: nothing -> record<total: int, data: table<id: int, state: record, registrationReason: string, moderationResponse: string, username: string, email: string, emailVerified: bool, accountDisplayName: string, channelHandle: string, channelDisplayName: string, createdAt: string, updatedAt: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "stateOneOf" $stateOneOf "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video ownership changes
#
# GET /api/v1/videos/ownership
export def "videos-ownership list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5
]: nothing -> record<total: int, data: table<id: int, state: record, initiatorAccount: record, nextOwnerAccount: record, video: record, videoChannel: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/ownership" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept ownership change request
#
# POST /api/v1/videos/ownership/{id}/accept
export def "videos-ownership-accept post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: int # Target channel id owned by the authenticated user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/ownership/($id)/accept")
  let body = {channelId: $channelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refuse ownership change request
#
# POST /api/v1/videos/ownership/{id}/refuse
export def "videos-ownership-refuse post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/ownership/($id)/refuse")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete ownership change request
#
# DELETE /api/v1/videos/ownership/{id}
export def "videos-ownership delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/ownership/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ownership change requests for a video
#
# GET /api/v1/videos/{videoIdOrUUID}/ownership
export def "videos-ownership get" [
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: int@state-completer-1 # Filter by ownership change state
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5
]: nothing -> record<total: int, data: table<id: int, state: record, initiatorAccount: record, nextOwnerAccount: record, video: record, videoChannel: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($videoIdOrUUID)/ownership" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request ownership change
#
# POST /api/v1/videos/{videoIdOrUUID}/give-ownership
export def "videos-give-ownership post" [
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($videoIdOrUUID)/give-ownership")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List channel ownership changes
#
# GET /api/v1/video-channels/ownership
export def "video-channels-ownership list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5
]: nothing -> record<total: int, data: table<id: int, state: record, initiatorAccount: record, nextOwnerAccount: record, video: record, videoChannel: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/video-channels/ownership" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept channel ownership change request
#
# POST /api/v1/video-channels/ownership/{id}/accept
export def "video-channels-ownership-accept post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/ownership/($id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refuse channel ownership change request
#
# POST /api/v1/video-channels/ownership/{id}/refuse
export def "video-channels-ownership-refuse post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/ownership/($id)/refuse")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete channel ownership change request
#
# DELETE /api/v1/video-channels/ownership/{id}
export def "video-channels-ownership delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/ownership/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ownership change requests for a channel
#
# GET /api/v1/video-channels/{channelHandle}/ownership
export def "video-channels-ownership get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: int@state-completer-1 # Filter by ownership change state
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5
]: nothing -> record<total: int, data: table<id: int, state: record, initiatorAccount: record, nextOwnerAccount: record, video: record, videoChannel: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/ownership" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request channel ownership change
#
# POST /api/v1/video-channels/{channelHandle}/give-ownership
export def "video-channels-give-ownership post" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/give-ownership")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request video token
#
# POST /api/v1/videos/{id}/token
# operationId: requestVideoToken
export def "videos-token requestVideoToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<files: record<token: string, expires: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/token")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a studio task
#
# POST /api/v1/videos/{id}/studio/edit
export def "videos-studio-edit post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/studio/edit")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# List videos
#
# GET /api/v1/videos
# operationId: getVideos
export def "videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available video categories
#
# GET /api/v1/videos/categories
# operationId: getCategories
export def "videos-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available video licences
#
# GET /api/v1/videos/licences
# operationId: getLicences
export def "videos-licences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/licences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available video languages
#
# GET /api/v1/videos/languages
# operationId: getLanguages
export def "videos-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # **PeerTube >= 8.2** Filter languages by scope. Use `subtitle` to exclude sign languages and other languages that don't make sense for subtitles.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/languages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available video privacy policies
#
# GET /api/v1/videos/privacies
# operationId: getVideoPrivacyPolicies
export def "videos-privacies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/privacies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a video
#
# PUT /api/v1/videos/{id}
# operationId: putVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
@deprecated --flag previewfile
export def "videos put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channelId: int # New channel of the video. The channel must be owned by the same account as the previous one. Use the "change ownership" endpoints to give a video to a channel owned by another account on the local PeerTube instance.
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --previewfile: string # Deprecated in PeerTube v8.1, use thumbnailfile instead (DEPRECATED, format: binary)
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --privacy: int@privacy-completer # privacy id of the video (see [/videos/privacies](#operation/getVideoPrivacyPolicies))
  --description: string # Video description
  --waitTranscoding: string # Whether or not we wait transcoding before publish the video
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --nsfwSummary: any # More information about the sensitive content of the video
  --nsfwFlags: int@nsfwFlags-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --name: string # Video name
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters)
  --commentsPolicy: int@commentsPolicy-completer # Comments policy of the video (Enabled = `1`, Disabled = `2`, Requires Approval = `3`)
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --originallyPublishedAt: string # Date when the content was originally published (nullable, format: date-time)
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
  --videoPasswords: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)")
  let body = {channelId: $channelId, thumbnailfile: $thumbnailfile, previewfile: $previewfile, category: $category, licence: $licence, language: $language, privacy: $privacy, description: $description, waitTranscoding: $waitTranscoding, support: $support, nsfw: $nsfw, nsfwSummary: $nsfwSummary, nsfwFlags: $nsfwFlags, name: $name, tags: $tags, commentsPolicy: $commentsPolicy, downloadEnabled: $downloadEnabled, originallyPublishedAt: $originallyPublishedAt, scheduleUpdate: $scheduleUpdate, videoPasswords: $videoPasswords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get a video
#
# GET /api/v1/videos/{id}
# operationId: getVideo
export def "videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: table<startAt: string>, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record<id: int, label: string>, licence: record<id: int, label: string>, language: record<id: string, label: string>, privacy: record<id: int, label: string>, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: table<fileUrl: string, width: int, height: int, aspectRatio: string>, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record<id: int, label: string>, scheduledUpdate: record<privacy: int, updateAt: string>, blacklisted: bool, blacklistedReason: string, account: record<id: int, url: string, name: record, avatars: list<record>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>, channel: record<id: int, url: string, name: record, avatars: list<record>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, displayName: string, description: string, support: string, isLocal: bool, banners: list<record>, ownerAccount: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>>, userHistory: record<currentTime: int>, viewers: int, description: string, support: string, tags: list<string>, commentsPolicy: record<id: int, label: string>, downloadEnabled: bool, inputFileUpdatedAt: string, trackerUrls: list<string>, files: table<id: int, magnetUri: string, resolution: record, size: int, torrentUrl: string, torrentDownloadUrl: string, fileUrl: string, playlistUrl: string, fileDownloadUrl: string, fps: float, width: float, height: float, metadataUrl: string, hasAudio: bool, hasVideo: bool, storage: int>, streamingPlaylists: table<id: int, type: int, playlistUrl: string, segmentsSha256Url: string, files: list, redundancies: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a video
#
# DELETE /api/v1/videos/{id}
# operationId: delVideo
export def "videos delVideo" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Notify user is watching a video
#
# POST /api/v1/videos/{id}/views
# operationId: addView
export def "videos-views addView" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  currentTime: int # timestamp within the video, in seconds (format: seconds, e.g. 5)
  --viewEvent: string@viewEvent-completer # Event since last viewing call:  * `seek` - If the user seeked the video
  --sessionId: string # Optional param to represent the current viewer session. Used by the backend to properly count one view per session per video. PeerTube admin can configure the server to not trust this `sessionId` parameter but use the request IP address instead to identify a viewer.
  --client: string # Client software used to watch the video. For example "Firefox", "PeerTube Approval Android", etc.
  --device: any # Device used to watch the video. For example "desktop", "mobile", "smarttv", etc.
  --operatingSystem: string # Operating system used to watch the video. For example "Windows", "Ubuntu", etc.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/views")
  let body = {currentTime: $currentTime, viewEvent: $viewEvent, sessionId: $sessionId, client: $client, device: $device, operatingSystem: $operatingSystem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get overall stats of a video
#
# GET /api/v1/videos/{id}/stats/overall
export def "videos-stats-overall get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Filter stats by start date (format: date-time)
  --endDate: string # Filter stats by end date (format: date-time)
]: nothing -> record<averageWatchTime: float, totalWatchTime: float, viewersPeak: float, totalViewers: float, viewersPeakDate: string, countries: table<isoCode: string, viewers: float>, subdivisions: table<name: string, viewers: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/stats/overall" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user agent stats of a video
#
# GET /api/v1/videos/{id}/stats/user-agent
export def "videos-stats-user-agent get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Filter stats by start date (format: date-time)
  --endDate: string # Filter stats by end date (format: date-time)
]: nothing -> record<clients: table<name: string, viewers: float>, devices: table<name: any, viewers: float>, operatingSystem: table<name: string, viewers: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/stats/user-agent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get retention stats of a video
#
# GET /api/v1/videos/{id}/stats/retention
export def "videos-stats-retention get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<second: float, retentionPercent: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/stats/retention")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get timeserie stats of a video
#
# GET /api/v1/videos/{id}/stats/timeseries/{metric}
export def "videos-stats-timeseries get" [
  id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Filter stats by start date (format: date-time)
  --endDate: string # Filter stats by end date (format: date-time)
]: nothing -> record<data: table<date: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/stats/timeseries/($metric)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a video
#
# POST /api/v1/videos/upload
# operationId: uploadLegacy
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
@deprecated --flag previewfile
export def "videos-upload uploadLegacy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Video name (e.g. What is PeerTube?)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --privacy: int@privacy-completer # privacy id of the video (see [/videos/privacies](#operation/getVideoPrivacyPolicies))
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  --generateTranscription: oneof<nothing, bool> # **PeerTube >= 6.2** If enabled by the admin, automatically generate a subtitle of the video
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --nsfwSummary: any # More information about the sensitive content of the video
  --nsfwFlags: int@nsfwFlags-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --commentsPolicy: int@commentsPolicy-completer # Comments policy of the video (Enabled = `1`, Disabled = `2`, Requires Approval = `3`)
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --previewfile: string # Deprecated in PeerTube v8.1, use thumbnailfile instead (DEPRECATED, format: binary)
  --videoPasswords: list
  videofile: string # Video file (format: binary)
]: any -> record<video: record<id: int, uuid: any, shortUUID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload")
  let body = {name: $name, channelId: $channelId, privacy: $privacy, category: $category, licence: $licence, language: $language, description: $description, waitTranscoding: $waitTranscoding, generateTranscription: $generateTranscription, support: $support, nsfw: $nsfw, nsfwSummary: $nsfwSummary, nsfwFlags: $nsfwFlags, tags: $tags, commentsPolicy: $commentsPolicy, downloadEnabled: $downloadEnabled, originallyPublishedAt: $originallyPublishedAt, scheduleUpdate: $scheduleUpdate, thumbnailfile: $thumbnailfile, previewfile: $previewfile, videoPasswords: $videoPasswords, videofile: $videofile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Initialize the resumable upload of a video
#
# POST /api/v1/videos/upload-resumable
# operationId: uploadResumableInit
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
@deprecated --flag previewfile
export def "videos-upload-resumable uploadResumableInit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Upload-Content-Length: float # Number of bytes that will be uploaded in subsequent requests. Set this value to the size of the file you are uploading. (e.g. 2469036)
  --X-Upload-Content-Type: string # MIME type of the file that you are uploading. Depending on your instance settings, acceptable values might vary. (e.g. video/mp4)
  name: string # Video name (e.g. What is PeerTube?)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --privacy: int@privacy-completer # privacy id of the video (see [/videos/privacies](#operation/getVideoPrivacyPolicies))
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  --generateTranscription: oneof<nothing, bool> # **PeerTube >= 6.2** If enabled by the admin, automatically generate a subtitle of the video
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --nsfwSummary: any # More information about the sensitive content of the video
  --nsfwFlags: int@nsfwFlags-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --commentsPolicy: int@commentsPolicy-completer # Comments policy of the video (Enabled = `1`, Disabled = `2`, Requires Approval = `3`)
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --previewfile: string # Deprecated in PeerTube v8.1, use thumbnailfile instead (DEPRECATED, format: binary)
  --videoPasswords: list
  filename: string # Video filename including extension (format: filename, e.g. what_is_peertube.mp4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload-resumable")
  let body = {name: $name, channelId: $channelId, privacy: $privacy, category: $category, licence: $licence, language: $language, description: $description, waitTranscoding: $waitTranscoding, generateTranscription: $generateTranscription, support: $support, nsfw: $nsfw, nsfwSummary: $nsfwSummary, nsfwFlags: $nsfwFlags, tags: $tags, commentsPolicy: $commentsPolicy, downloadEnabled: $downloadEnabled, originallyPublishedAt: $originallyPublishedAt, scheduleUpdate: $scheduleUpdate, thumbnailfile: $thumbnailfile, previewfile: $previewfile, videoPasswords: $videoPasswords, filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Upload-Content-Length": $X_Upload_Content_Length, "X-Upload-Content-Type": $X_Upload_Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send chunk for the resumable upload of a video
#
# PUT /api/v1/videos/upload-resumable
# operationId: uploadResumable
export def "videos-upload-resumable uploadResumable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Range: string # Specifies the bytes in the file that the request is uploading.  For example, a value of `bytes 0-262143/1000000` shows that the request is sending the first 262144 bytes (256 x 1024) in a 2,469,036 byte file.  (e.g. bytes 0-262143/2469036)
  --Content-Length: float # Size of the chunk that the request is sending.  Remember that larger chunks are more efficient. PeerTube's web client uses chunks varying from 1048576 bytes (~1MB) and increases or reduces size depending on connection health.  (e.g. 262144)
  --body: record
]: any -> record<video: record<id: int, uuid: any, shortUUID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/upload-resumable" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $Content_Range, "Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Cancel the resumable upload of a video, deleting any data uploaded so far
#
# DELETE /api/v1/videos/upload-resumable
# operationId: uploadResumableCancel
export def "videos-upload-resumable uploadResumableCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Length: float # e.g. 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/upload-resumable" $qp)
  let extra_headers = {"Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a video
#
# POST /api/v1/videos/imports
# operationId: importVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
@deprecated --flag previewfile
export def "videos-imports importVideo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Video name (e.g. What is PeerTube?)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --privacy: int@privacy-completer # privacy id of the video (see [/videos/privacies](#operation/getVideoPrivacyPolicies))
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  --generateTranscription: oneof<nothing, bool> # **PeerTube >= 6.2** If enabled by the admin, automatically generate a subtitle of the video
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --nsfwSummary: any # More information about the sensitive content of the video
  --nsfwFlags: int@nsfwFlags-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --commentsPolicy: int@commentsPolicy-completer # Comments policy of the video (Enabled = `1`, Disabled = `2`, Requires Approval = `3`)
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4"|"5", updateAt: string}
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --previewfile: string # Deprecated in PeerTube v8.1, use thumbnailfile instead (DEPRECATED, format: binary)
  --videoPasswords: list
]: any -> record<video: record<id: int, uuid: any, shortUUID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/imports")
  let body = {name: $name, channelId: $channelId, privacy: $privacy, category: $category, licence: $licence, language: $language, description: $description, waitTranscoding: $waitTranscoding, generateTranscription: $generateTranscription, support: $support, nsfw: $nsfw, nsfwSummary: $nsfwSummary, nsfwFlags: $nsfwFlags, tags: $tags, commentsPolicy: $commentsPolicy, downloadEnabled: $downloadEnabled, originallyPublishedAt: $originallyPublishedAt, scheduleUpdate: $scheduleUpdate, thumbnailfile: $thumbnailfile, previewfile: $previewfile, videoPasswords: $videoPasswords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Cancel video import
#
# POST /api/v1/videos/imports/{id}/cancel
export def "videos-imports-cancel post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/imports/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry video import
#
# POST /api/v1/videos/imports/{id}/retry
export def "videos-imports-retry post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/imports/($id)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete video import
#
# DELETE /api/v1/videos/imports/{id}
export def "videos-imports delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/imports/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a live
#
# POST /api/v1/videos/live
# operationId: addLive
# --replaySettings shape: {privacy?: "1"|"2"|"3"|"4"|"5"}
# --schedules item shape: {startAt?: string}
@deprecated --flag previewfile
export def "videos-live addLive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: int # Channel id that will contain this live video
  --saveReplay: oneof<nothing, bool>
  --replaySettings: record # shape: {privacy?: "1"|"2"|"3"|"4"|"5"}
  --permanentLive: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --latencyMode: any # User can select live latency mode if enabled by the instance
  --thumbnailfile: string # Live video/replay thumbnail file (format: binary)
  --previewfile: string # Deprecated in PeerTube v8.1, use thumbnailfile instead (DEPRECATED, format: binary)
  --privacy: int@privacy-completer # privacy id of the video (see [/videos/privacies](#operation/getVideoPrivacyPolicies))
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --description: string # Live video/replay description
  --support: string # A text tell the audience how to support the creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --nsfw: oneof<nothing, bool> # Whether or not this live video/replay contains sensitive content
  --nsfwSummary: any # More information about the sensitive content of the video
  --nsfwFlags: int@nsfwFlags-completer #  NSFW flags (can be combined using bitwise or operator) - `0` NONE - `1` VIOLENT - `2` EXPLICIT_SEX
  name: string # Live video/replay name
  --tags: list # Live video/replay tags (maximum 5 tags each between 2 and 30 characters)
  --commentsPolicy: int@commentsPolicy-completer # Comments policy of the video (Enabled = `1`, Disabled = `2`, Requires Approval = `3`)
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for the replay of this live video
  --schedules: list # item shape: {startAt?: string}
]: any -> record<video: record<id: int, uuid: any, shortUUID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/live")
  let body = {channelId: $channelId, saveReplay: $saveReplay, replaySettings: $replaySettings, permanentLive: $permanentLive, latencyMode: $latencyMode, thumbnailfile: $thumbnailfile, previewfile: $previewfile, privacy: $privacy, category: $category, licence: $licence, language: $language, description: $description, support: $support, nsfw: $nsfw, nsfwSummary: $nsfwSummary, nsfwFlags: $nsfwFlags, name: $name, tags: $tags, commentsPolicy: $commentsPolicy, downloadEnabled: $downloadEnabled, schedules: $schedules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get information about a live
#
# GET /api/v1/videos/live/{id}
# operationId: getLiveId
export def "videos-live get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rtmpUrl: string, rtmpsUrl: string, streamKey: string, saveReplay: bool, replaySettings: record<privacy: int>, permanentLive: bool, latencyMode: record, schedules: table<startAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/live/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update information about a live
#
# PUT /api/v1/videos/live/{id}
# operationId: updateLiveId
# --replaySettings shape: {privacy?: "1"|"2"|"3"|"4"|"5"}
# --schedules item shape: {startAt?: string}
export def "videos-live updateLiveId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --saveReplay: oneof<nothing, bool>
  --replaySettings: record # shape: {privacy?: "1"|"2"|"3"|"4"|"5"}
  --permanentLive: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --latencyMode: any # User can select live latency mode if enabled by the instance
  --schedules: list # item shape: {startAt?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/live/($id)")
  let body = {saveReplay: $saveReplay, replaySettings: $replaySettings, permanentLive: $permanentLive, latencyMode: $latencyMode, schedules: $schedules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List live sessions
#
# GET /api/v1/videos/live/{id}/sessions
export def "videos-live-sessions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, startDate: string, endDate: string, error: int, replayVideo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/live/($id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get live session of a replay
#
# GET /api/v1/videos/{id}/live-session
export def "videos-live-session get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<id: int, startDate: string, endDate: string, error: int, replayVideo: record<id: float, uuid: string, shortUUID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/live-session")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get video source file metadata
#
# GET /api/v1/videos/{id}/source
# operationId: getVideoSource
export def "videos-source get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<inputFilename: string, fileDownloadUrl: string, resolution: record<id: int, label: string>, size: int, fps: float, width: int, height: int, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/source")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete video source file
#
# DELETE /api/v1/videos/{id}/source/file
# operationId: deleteVideoSourceFile
export def "videos-source-file delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/source/file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initialize the resumable replacement of a video
#
# POST /api/v1/videos/{id}/source/replace-resumable
# operationId: replaceVideoSourceResumableInit
export def "videos-source-replace-resumable replaceVideoSourceResumableInit" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Upload-Content-Length: float # Number of bytes that will be uploaded in subsequent requests. Set this value to the size of the file you are uploading. (e.g. 2469036)
  --X-Upload-Content-Type: string # MIME type of the file that you are uploading. Depending on your instance settings, acceptable values might vary. (e.g. video/mp4)
  --filename: string # Video filename including extension (format: filename, e.g. what_is_peertube.mp4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/source/replace-resumable")
  let body = {filename: $filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Upload-Content-Length": $X_Upload_Content_Length, "X-Upload-Content-Type": $X_Upload_Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send chunk for the resumable replacement of a video
#
# PUT /api/v1/videos/{id}/source/replace-resumable
# operationId: replaceVideoSourceResumable
export def "videos-source-replace-resumable replaceVideoSourceResumable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Range: string # Specifies the bytes in the file that the request is uploading.  For example, a value of `bytes 0-262143/1000000` shows that the request is sending the first 262144 bytes (256 x 1024) in a 2,469,036 byte file.  (e.g. bytes 0-262143/2469036)
  --Content-Length: float # Size of the chunk that the request is sending.  Remember that larger chunks are more efficient. PeerTube's web client uses chunks varying from 1048576 bytes (~1MB) and increases or reduces size depending on connection health.  (e.g. 262144)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/source/replace-resumable" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $Content_Range, "Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Cancel the resumable replacement of a video
#
# DELETE /api/v1/videos/{id}/source/replace-resumable
# operationId: replaceVideoSourceResumableCancel
export def "videos-source-replace-resumable replaceVideoSourceResumableCancel" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --Content-Length: float # e.g. 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/source/replace-resumable" $qp)
  let extra_headers = {"Content-Length": $Content_Length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List my abuses
#
# GET /api/v1/users/me/abuses
# operationId: getMyAbuses
export def "users-me-abuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --state: int@state-completer-1
  --qp-sort: string@sort-completer-6 # Sort abuses by criteria
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> record<total: int, data: table<id: int, reason: string, predefinedReasons: list, reporterAccount: record, state: record, moderationComment: string, video: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/abuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List abuses
#
# GET /api/v1/abuses
# operationId: getAbuses
export def "abuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --predefinedReason: list # predefined reason the listed reports should contain
  --search: string # plain search that will match with video titles, reporter names and more
  --state: int@state-completer-1
  --searchReporter: string # only list reports of a specific reporter
  --searchReportee: string # only list reports of a specific reportee
  --searchVideo: string # only list reports of a specific video
  --searchVideoChannel: string # only list reports of a specific video channel
  --videoIs: string@videoIs-completer # only list deleted or blocklisted videos
  --filter: string@filter-completer # only list account, comment or video reports
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-6 # Sort abuses by criteria
]: nothing -> record<total: int, data: table<id: int, reason: string, predefinedReasons: list, reporterAccount: record, state: record, moderationComment: string, video: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "predefinedReason" $predefinedReason "multi") (serialize-qp "search" $search "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "searchReporter" $searchReporter "scalar") (serialize-qp "searchReportee" $searchReportee "scalar") (serialize-qp "searchVideo" $searchVideo "scalar") (serialize-qp "searchVideoChannel" $searchVideoChannel "scalar") (serialize-qp "videoIs" $videoIs "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/abuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Report an abuse
#
# POST /api/v1/abuses
# --video shape: {id?: any, startAt?: int, endAt?: int}
# --comment shape: {id?: any}
# --account shape: {id?: int}
export def "abuses post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Reason why the user reports this video
  --predefinedReasons: list # Reason categories that help triage reports
  --video: record # shape: {id?: any, startAt?: int, endAt?: int}
  --comment: record # shape: {id?: any}
  --account: record # shape: {id?: int}
]: any -> record<abuse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/abuses")
  let body = {reason: $reason, predefinedReasons: $predefinedReasons, video: $video, comment: $comment, account: $account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an abuse
#
# PUT /api/v1/abuses/{abuseId}
export def "abuses put" [
  abuseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: int@state-completer-1 # The abuse state (Pending = `1`, Rejected = `2`, Accepted = `3`)
  --moderationComment: string # Update the report comment visible only to the moderation team
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)")
  let body = {state: $state, moderationComment: $moderationComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an abuse
#
# DELETE /api/v1/abuses/{abuseId}
export def "abuses delete" [
  abuseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List messages of an abuse
#
# GET /api/v1/abuses/{abuseId}/messages
export def "abuses-messages get" [
  abuseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, data: table<id: int, message: string, byModerator: bool, createdAt: string, account: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add message to an abuse
#
# POST /api/v1/abuses/{abuseId}/messages
export def "abuses-messages post" [
  abuseId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # Message to send
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)/messages")
  let body = {message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an abuse message
#
# DELETE /api/v1/abuses/{abuseId}/messages/{abuseMessageId}
export def "abuses-messages delete" [
  abuseId: int
  abuseMessageId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)/messages/($abuseMessageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block a video
#
# POST /api/v1/videos/{id}/blacklist
# operationId: addVideoBlock
export def "videos-blacklist addVideoBlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/blacklist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unblock a video by its id
#
# DELETE /api/v1/videos/{id}/blacklist
# operationId: delVideoBlock
export def "videos-blacklist delVideoBlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/blacklist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video blocks
#
# GET /api/v1/videos/blacklist
# operationId: getVideoBlocks
export def "videos-blacklist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: int@type-completer # list only blocks that match this type: - `1`: manual block - `2`: automatic block that needs review
  --search: string # plain search that will match with video titles, and more
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-7 # Sort blocklists by criteria
]: nothing -> record<total: int, data: table<id: int, videoId: int, createdAt: string, updatedAt: string, name: string, uuid: string, description: string, duration: int, views: int, likes: int, dislikes: int, nsfw: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/blacklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List storyboards of a video
#
# GET /api/v1/videos/{id}/storyboards
# operationId: listVideoStoryboards
export def "videos-storyboards listVideoStoryboards" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<storyboards: table<storyboardPath: string, fileUrl: string, totalHeight: int, totalWidth: int, spriteHeight: int, spriteWidth: int, spriteDuration: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/storyboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List captions of a video
#
# GET /api/v1/videos/{id}/captions
# operationId: getVideoCaptions
export def "videos-captions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<total: int, data: table<language: record, automaticallyGenerated: bool, captionPath: string, fileUrl: string, m3u8Url: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/captions")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a video caption
#
# POST /api/v1/videos/{id}/captions/generate
# operationId: generateVideoCaption
export def "videos-captions-generate generateVideoCaption" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceTranscription: oneof<nothing, bool> # default: false
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/captions/generate")
  let body = {forceTranscription: $forceTranscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or replace a video caption
#
# PUT /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: addVideoCaption
export def "videos-captions addVideoCaption" [
  id: string
  captionLanguage: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --captionfile: string # The file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/captions/($captionLanguage)")
  let body = {captionfile: $captionfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a video caption
#
# DELETE /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: delVideoCaption
export def "videos-captions delVideoCaption" [
  id: string
  captionLanguage: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/captions/($captionLanguage)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get chapters of a video
#
# GET /api/v1/videos/{id}/chapters
# operationId: getVideoChapters
export def "videos-chapters get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<chapters: record<title: string, timecode: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/chapters")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace video chapters
#
# PUT /api/v1/videos/{id}/chapters
# operationId: replaceVideoChapters
# --chapters item shape: {title?: string, timecode?: int}
export def "videos-chapters replaceVideoChapters" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chapters: list # item shape: {title?: string, timecode?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/chapters")
  let body = {chapters: $chapters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get video embed privacy
#
# GET /api/v1/videos/{id}/embed-privacy
# operationId: getVideoEmbedPrivacy
export def "videos-embed-privacy get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<policy: record<id: int, label: string>, domains: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/embed-privacy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update video embed privacy
#
# PUT /api/v1/videos/{id}/embed-privacy
# operationId: updateVideoEmbedPrivacy
export def "videos-embed-privacy updateVideoEmbedPrivacy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --policy: int@policy-completer # The video embed privacy level:   - `1` All allowed: anyone can embed the video   - `2` Allowlist: only the domains in the allowlist can embed the video   - `3` Remote restrictions: the remote instance has restrictions on where the video can be embedded
  --domains: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/embed-privacy")
  let body = {policy: $policy, domains: $domains} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check if embed is allowed
#
# GET /api/v1/videos/{id}/embed-privacy/allowed
# operationId: isVideoEmbedOnDomainAllowed
export def "videos-embed-privacy-allowed isVideoEmbedOnDomainAllowed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --domain: string # The domain to check if embed is allowed
]: nothing -> record<domainAllowed: bool, userBypassAllowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/embed-privacy/allowed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video passwords
#
# GET /api/v1/videos/{id}/passwords
# operationId: listVideoPasswords
export def "videos-passwords listVideoPasswords" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, password: string, videoId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/passwords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update video passwords
#
# PUT /api/v1/videos/{id}/passwords
# operationId: updateVideoPasswordList
export def "videos-passwords updateVideoPasswordList" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --passwords: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/passwords")
  let body = {passwords: $passwords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a video password
#
# POST /api/v1/videos/{id}/passwords
# operationId: addVideoPassword
export def "videos-passwords addVideoPassword" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/passwords")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a video password
#
# DELETE /api/v1/videos/{id}/passwords/{passwordId}
# operationId: removeVideoPassword
export def "videos-passwords removeVideoPassword" [
  id: string
  passwordId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/passwords/($passwordId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video channels
#
# GET /api/v1/video-channels
# operationId: getVideoChannels
export def "video-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/video-channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a video channel
#
# POST /api/v1/video-channels
# operationId: addVideoChannel
export def "video-channels addVideoChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: any # Channel display name
  --description: any # Channel description
  --support: any # How to support/fund the channel
  name: any # username of the channel to create
]: any -> record<videoChannel: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-channels")
  let body = {displayName: $displayName, description: $description, support: $support, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a video channel
#
# GET /api/v1/video-channels/{channelHandle}
# operationId: getVideoChannel
export def "video-channels get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, url: string, name: record, avatars: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, displayName: string, description: string, support: string, isLocal: bool, banners: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>, ownerAccount: record<id: int, url: string, name: record, avatars: list<record>, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a video channel
#
# PUT /api/v1/video-channels/{channelHandle}
# operationId: putVideoChannel
export def "video-channels put" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: any # Channel display name
  --description: any # Channel description
  --support: any # How to support/fund the channel
  --bulkVideosSupportUpdate: oneof<nothing, bool> # Update the support field for all videos of this channel
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)")
  let body = {displayName: $displayName, description: $description, support: $support, bulkVideosSupportUpdate: $bulkVideosSupportUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a video channel
#
# DELETE /api/v1/video-channels/{channelHandle}
# operationId: delVideoChannel
export def "video-channels delVideoChannel" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/videos
# operationId: getVideoChannelVideos
export def "video-channels-videos get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List activities of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/activities
# operationId: listVideoChannelActivities
export def "video-channels-activities listVideoChannelActivities" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<id: int, account: record, action: record, targetType: record, details: record, createdAt: string, channel: record, video: record, videoImport: record, playlist: record, channelSync: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List playlists of a channel
#
# GET /api/v1/video-channels/{channelHandle}/video-playlists
export def "video-channels-video-playlists get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --playlistType: int@playlistType-completer
]: nothing -> record<total: int, data: table<id: int, uuid: string, shortUUID: record, createdAt: string, updatedAt: string, description: string, displayName: string, isLocal: bool, videoLength: int, thumbnailPath: string, thumbnails: list, privacy: record, type: record, ownerAccount: record, videoChannel: record, videoChannelPosition: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "playlistType" $playlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reorder channel playlists
#
# POST /api/v1/video-channels/{channelHandle}/video-playlists/reorder
# operationId: reorderVideoPlaylistsOfChannel
export def "video-channels-video-playlists-reorder reorderVideoPlaylistsOfChannel" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  startPosition: int # Start position of the element to reorder
  insertAfterPosition: int # New position for the block to reorder, to add the block before the first element
  --reorderLength: int # How many element from `startPosition` to reorder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/video-playlists/reorder")
  let body = {startPosition: $startPosition, insertAfterPosition: $insertAfterPosition, reorderLength: $reorderLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List followers of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/followers
# operationId: getVideoChannelFollowers
export def "video-channels-followers get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<total: int, data: table<id: int, follower: record, following: record, score: float, state: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update channel avatar
#
# POST /api/v1/video-channels/{channelHandle}/avatar/pick
export def "video-channels-avatar-pick post" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload. (format: binary)
]: any -> record<avatars: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/avatar/pick")
  let body = {avatarfile: $avatarfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete channel avatar
#
# DELETE /api/v1/video-channels/{channelHandle}/avatar
export def "video-channels-avatar delete" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update channel banner
#
# POST /api/v1/video-channels/{channelHandle}/banner/pick
export def "video-channels-banner-pick post" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bannerfile: string # The file to upload. (format: binary)
]: any -> record<banners: table<path: string, fileUrl: string, width: int, height: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/banner/pick")
  let body = {bannerfile: $bannerfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete channel banner
#
# DELETE /api/v1/video-channels/{channelHandle}/banner
export def "video-channels-banner delete" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/banner")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import videos in channel
#
# POST /api/v1/video-channels/{channelHandle}/import-videos
export def "video-channels-import-videos post" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  externalChannelUrl: string # e.g. https://youtube.com/c/UC_myfancychannel
  --videoChannelSyncId: int # If part of a channel sync process, specify its id to assign video imports to this channel synchronization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/import-videos")
  let body = {externalChannelUrl: $externalChannelUrl, videoChannelSyncId: $videoChannelSyncId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a synchronization for a video channel
#
# POST /api/v1/video-channel-syncs
# operationId: addVideoChannelSync
export def "video-channel-syncs addVideoChannelSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externalChannelUrl: string # e.g. https://youtube.com/c/UC_myfancychannel
  --videoChannelId: int # e.g. 42
]: any -> record<videoChannelSync: record<id: int, state: record<id: int, label: string>, externalChannelUrl: string, createdAt: string, lastSyncAt: string, channel: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, displayName: string, description: string, support: string, isLocal: bool, banners: list, ownerAccount: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-channel-syncs")
  let body = {externalChannelUrl: $externalChannelUrl, videoChannelId: $videoChannelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a video channel synchronization
#
# DELETE /api/v1/video-channel-syncs/{channelSyncId}
# operationId: delVideoChannelSync
export def "video-channel-syncs delVideoChannelSync" [
  channelSyncId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channel-syncs/($channelSyncId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers the channel synchronization job, fetching all the videos from the remote channel
#
# POST /api/v1/video-channel-syncs/{channelSyncId}/sync
# operationId: triggerVideoChannelSync
export def "video-channel-syncs-sync triggerVideoChannelSync" [
  channelSyncId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channel-syncs/($channelSyncId)/sync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get video player settings
#
# GET /api/v1/player-settings/videos/{id}
# operationId: getVideoPlayerSettings
export def "player-settings-videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Return raw settings without merging channel defaults (default: false)
]: nothing -> record<theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/player-settings/videos/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update video player settings
#
# PUT /api/v1/player-settings/videos/{id}
# operationId: updateVideoPlayerSettings
export def "player-settings-videos updateVideoPlayerSettings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  theme: string@theme-completer # Player theme setting for a video:   - `channel-default` Use the channel default theme   - `instance-default` Use the instance default theme   - `galaxy` Use the galaxy theme   - `lucide` Use the lucide theme
]: any -> record<theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/player-settings/videos/($id)")
  let body = {theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channel player settings
#
# GET /api/v1/player-settings/video-channels/{channelHandle}
# operationId: getChannelPlayerSettings
export def "player-settings-video-channels get" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Return raw settings without applying instance defaults (default: false)
]: nothing -> record<theme: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/player-settings/video-channels/($channelHandle)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update channel player settings
#
# PUT /api/v1/player-settings/video-channels/{channelHandle}
# operationId: updateChannelPlayerSettings
export def "player-settings-video-channels updateChannelPlayerSettings" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  theme: string@theme-completer-1 # Player theme setting for a channel:   - `instance-default` Use the instance default theme   - `galaxy` Use the galaxy theme   - `lucide` Use the lucide theme
]: any -> record<theme: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/player-settings/video-channels/($channelHandle)")
  let body = {theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List available playlist privacy policies
#
# GET /api/v1/video-playlists/privacies
# operationId: getPlaylistPrivacyPolicies
export def "video-playlists-privacies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-playlists/privacies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video playlists
#
# GET /api/v1/video-playlists
# operationId: getPlaylists
export def "video-playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --playlistType: int@playlistType-completer
]: nothing -> record<total: int, data: table<id: int, uuid: string, shortUUID: record, createdAt: string, updatedAt: string, description: string, displayName: string, isLocal: bool, videoLength: int, thumbnailPath: string, thumbnails: list, privacy: record, type: record, ownerAccount: record, videoChannel: record, videoChannelPosition: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "playlistType" $playlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a video playlist
#
# POST /api/v1/video-playlists
# operationId: addPlaylist
export def "video-playlists addPlaylist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: string # Video playlist display name
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --privacy: int@privacy-completer-1 # Video playlist privacy policy (see [/video-playlists/privacies](#operation/getPlaylistPrivacyPolicies))
  --description: string # Video playlist description
  --videoChannelId: any # Video channel in which the playlist will be published
]: any -> record<videoPlaylist: record<id: int, uuid: any, shortUUID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-playlists")
  let body = {displayName: $displayName, thumbnailfile: $thumbnailfile, privacy: $privacy, description: $description, videoChannelId: $videoChannelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get a video playlist
#
# GET /api/v1/video-playlists/{playlistId}
export def "video-playlists get" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, uuid: string, shortUUID: record, createdAt: string, updatedAt: string, description: string, displayName: string, isLocal: bool, videoLength: int, thumbnailPath: string, thumbnails: table<fileUrl: string, width: int, height: int, aspectRatio: string>, privacy: record<id: int, label: string>, type: record<id: int, label: string>, ownerAccount: record<id: int, name: string, displayName: string, url: string, host: string, avatars: list<record>>, videoChannel: record<id: int, name: string, displayName: string, url: string, host: string, avatars: list<record>>, videoChannelPosition: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a video playlist
#
# PUT /api/v1/video-playlists/{playlistId}
export def "video-playlists put" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --displayName: string # Video playlist display name
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --privacy: int@privacy-completer-1 # Video playlist privacy policy (see [/video-playlists/privacies](#operation/getPlaylistPrivacyPolicies))
  --description: string # Video playlist description
  --videoChannelId: any # Video channel in which the playlist will be published
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)")
  let body = {displayName: $displayName, thumbnailfile: $thumbnailfile, privacy: $privacy, description: $description, videoChannelId: $videoChannelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete a video playlist
#
# DELETE /api/v1/video-playlists/{playlistId}
export def "video-playlists delete" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of a playlist
#
# GET /api/v1/video-playlists/{playlistId}/videos
# operationId: getVideoPlaylistVideos
export def "video-playlists-videos get" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> record<total: int, data: table<id: record, position: int, startTimestamp: int, stopTimestamp: int, video: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video in a playlist
#
# POST /api/v1/video-playlists/{playlistId}/videos
# operationId: addVideoPlaylistVideo
export def "video-playlists-videos addVideoPlaylistVideo" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  videoId: any # Video to add in the playlist
  --startTimestamp: int # Start the video at this specific timestamp (format: seconds)
  --stopTimestamp: int # Stop the video at this specific timestamp (format: seconds)
]: any -> record<videoPlaylistElement: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos")
  let body = {videoId: $videoId, startTimestamp: $startTimestamp, stopTimestamp: $stopTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder playlist elements
#
# POST /api/v1/video-playlists/{playlistId}/videos/reorder
# operationId: reorderVideoPlaylist
export def "video-playlists-videos-reorder reorderVideoPlaylist" [
  playlistId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  startPosition: int # Start position of the element to reorder
  insertAfterPosition: int # New position for the block to reorder, to add the block before the first element
  --reorderLength: int # How many element from `startPosition` to reorder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos/reorder")
  let body = {startPosition: $startPosition, insertAfterPosition: $insertAfterPosition, reorderLength: $reorderLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a playlist element
#
# PUT /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: putVideoPlaylistVideo
export def "video-playlists-videos put" [
  playlistId: int
  playlistElementId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startTimestamp: int # Start the video at this specific timestamp (format: seconds)
  --stopTimestamp: int # Stop the video at this specific timestamp (format: seconds)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos/($playlistElementId)")
  let body = {startTimestamp: $startTimestamp, stopTimestamp: $stopTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an element from a playlist
#
# DELETE /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: delVideoPlaylistVideo
export def "video-playlists-videos delVideoPlaylistVideo" [
  playlistId: int
  playlistElementId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos/($playlistElementId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check video exists in my playlists
#
# GET /api/v1/users/me/video-playlists/videos-exist
export def "users-me-video-playlists-videos-exist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --videoIds: list # The video ids to check
]: nothing -> record<videoId: table<playlistElementId: int, playlistId: int, startTimestamp: int, stopTimestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoIds" $videoIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/video-playlists/videos-exist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List playlists of an account
#
# GET /api/v1/accounts/{name}/video-playlists
export def "accounts-video-playlists get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --playlistType: int@playlistType-completer
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
  --channelNameOneOf: string # **PeerTube >= 8.0** Filter on playlists that are published on a channel with one of these names
]: nothing -> record<total: int, data: table<id: int, uuid: string, shortUUID: record, createdAt: string, updatedAt: string, description: string, displayName: string, isLocal: bool, videoLength: int, thumbnailPath: string, thumbnails: list, privacy: record, type: record, ownerAccount: record, videoChannel: record, videoChannelPosition: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "playlistType" $playlistType "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar") (serialize-qp "channelNameOneOf" $channelNameOneOf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video channels of an account
#
# GET /api/v1/accounts/{name}/video-channels
export def "accounts-video-channels get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withStats: oneof<nothing, bool> # include daily view statistics for the last 30 days and total views (only if authenticated as the account user)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --qp-sort: string # Sort column (e.g. -createdAt)
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
]: nothing -> record<total: int, data: table<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withStats" $withStats "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the synchronizations of video channels of an account
#
# GET /api/v1/accounts/{name}/video-channel-syncs
export def "accounts-video-channel-syncs get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --includeCollaborations: oneof<nothing, bool> # **PeerTube >= 8.0** Include objects from collaborated channels
]: nothing -> record<total: int, data: table<id: int, state: record, externalChannelUrl: string, createdAt: string, lastSyncAt: string, channel: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeCollaborations" $includeCollaborations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-channel-syncs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List ratings of an account
#
# GET /api/v1/accounts/{name}/ratings
export def "accounts-ratings get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --rating: string@rating-completer # Optionally filter which ratings to retrieve
]: nothing -> table<video: record<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>, rating: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/ratings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List threads of a video
#
# GET /api/v1/videos/{id}/comment-threads
export def "videos-comment-threads list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-8 # Sort comments by criteria
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<total: int, totalNotDeletedComments: int, data: table<id: int, url: string, text: string, threadId: int, inReplyToCommentId: record, videoId: int, createdAt: string, updatedAt: string, deletedAt: string, isDeleted: bool, heldForReview: bool, totalRepliesFromVideoAuthor: int, totalReplies: int, account: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/comment-threads" $qp)
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a thread
#
# POST /api/v1/videos/{id}/comment-threads
export def "videos-comment-threads post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: any # format: markdown
]: any -> record<comment: record<id: int, url: string, text: string, threadId: int, inReplyToCommentId: record, videoId: int, createdAt: string, updatedAt: string, deletedAt: string, isDeleted: bool, heldForReview: bool, totalRepliesFromVideoAuthor: int, totalReplies: int, account: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comment-threads")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a thread
#
# GET /api/v1/videos/{id}/comment-threads/{threadId}
export def "videos-comment-threads get" [
  id: string
  threadId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
]: nothing -> record<comment: record<id: int, url: string, text: string, threadId: int, inReplyToCommentId: record, videoId: int, createdAt: string, updatedAt: string, deletedAt: string, isDeleted: bool, heldForReview: bool, totalRepliesFromVideoAuthor: int, totalReplies: int, account: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>>, children: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comment-threads/($threadId)")
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List instance comments
#
# GET /api/v1/videos/comments
export def "videos-comments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --searchAccount: string # Filter comments by searching on the account
  --searchVideo: string # Filter comments by searching on the video
  --videoId: int # Limit results on this specific video
  --videoChannelId: int # Limit results on this specific video channel
  --autoTagOneOf: string # **PeerTube >= 6.2** filter on comments that contain one of these automatic tags
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --onLocalVideo: oneof<nothing, bool> # Display only objects of local or remote videos
  --includeMuted: oneof<nothing, bool> # **PeerTube >= 8.2** Include comments from muted accounts
]: nothing -> record<total: int, data: table<id: int, url: any, text: any, heldForReview: any, threadId: any, inReplyToCommentId: any, createdAt: any, updatedAt: any, account: any, video: record, automaticTags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "searchAccount" $searchAccount "scalar") (serialize-qp "searchVideo" $searchVideo "scalar") (serialize-qp "videoId" $videoId "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "onLocalVideo" $onLocalVideo "scalar") (serialize-qp "includeMuted" $includeMuted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reply to a thread of a video
#
# POST /api/v1/videos/{id}/comments/{commentId}
export def "videos-comments post" [
  id: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
  text: any # format: markdown
]: any -> record<comment: record<id: int, url: string, text: string, threadId: int, inReplyToCommentId: record, videoId: int, createdAt: string, updatedAt: string, deletedAt: string, isDeleted: bool, heldForReview: bool, totalRepliesFromVideoAuthor: int, totalReplies: int, account: record<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string, userId: record, displayName: string, description: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comments/($commentId)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a comment or a reply
#
# DELETE /api/v1/videos/{id}/comments/{commentId}
export def "videos-comments delete" [
  id: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comments/($commentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve a comment
#
# POST /api/v1/videos/{id}/comments/{commentId}/approve
export def "videos-comments-approve post" [
  id: string
  commentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comments/($commentId)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like/dislike a video
#
# PUT /api/v1/videos/{id}/rate
export def "videos-rate put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-peertube-video-password: string # Required on password protected video
  rating: string@rating-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/rate")
  let body = {rating: $rating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-peertube-video-password": $x_peertube_video_password} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete video HLS files
#
# DELETE /api/v1/videos/{id}/hls
# operationId: delVideoHLS
export def "videos-hls delVideoHLS" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/hls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete video Web Video files
#
# DELETE /api/v1/videos/{id}/web-videos
# operationId: delVideoWebVideos
export def "videos-web-videos delVideoWebVideos" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/web-videos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transcoding job
#
# POST /api/v1/videos/{id}/transcoding
# operationId: createVideoTranscoding
export def "videos-transcoding createVideoTranscoding" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transcodingType: string@transcodingType-completer
  --forceTranscoding: oneof<nothing, bool> # If the video is stuck in transcoding state, do it anyway (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/transcoding")
  let body = {transcodingType: $transcodingType, forceTranscoding: $forceTranscoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search videos
#
# GET /api/v1/search/videos
# operationId: searchVideos
export def "search-videos searchVideos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete video information and interact with it.
  --uuids: string # Find elements with specific UUIDs
  --searchTarget: string@searchTarget-completer # If the administrator enabled search index support, you can override the default search target.  **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information:   * If the current user has the ability to make a remote URI search (this information is available in the config endpoint),   then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database.   After that, you can use the classic REST API endpoints to fetch the complete object or interact with it   * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch   the data from the origin instance API
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --qp-sort: string@sort-completer
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --nsfwFlagsIncluded: int@nsfwFlagsIncluded-completer
  --nsfwFlagsExcluded: int@nsfwFlagsExcluded-completer
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --includeScheduledLive: oneof<nothing, bool> # whether or not include live that are scheduled for later
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote objects
  --include: int@include-completer # **Only administrators and moderators can use this parameter**  Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES - `16` CAPTIONS - `32` VIDEO SOURCE
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebVideoFiles: oneof<nothing, bool> # **PeerTube >= 6.0** Display only videos that have Web Video files
  --host: string # Find elements owned by this host
  --autoTagOneOf: string # **PeerTube >= 6.2** **Admins and moderators only** filter on videos that contain one of these automatic tags
  --stateOneOf: string # **PeerTube >= 8.2** **Admins and moderators only** filter on videos that have one of these states
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --excludeAlreadyWatched: oneof<nothing, bool> # Whether or not to exclude videos that are in the user's video history
  --startDate: string # Get videos that are published after this date (format: date-time)
  --endDate: string # Get videos that are published before this date (format: date-time)
  --originallyPublishedStartDate: string # Get videos that are originally published after this date (format: date-time)
  --originallyPublishedEndDate: string # Get videos that are originally published before this date (format: date-time)
  --durationMin: int # Get videos that have this minimum duration
  --durationMax: int # Get videos that have this maximum duration
]: nothing -> record<total: int, data: table<id: record, uuid: record, shortUUID: record, isLive: bool, liveSchedules: list, createdAt: string, publishedAt: string, updatedAt: string, originallyPublishedAt: string, category: record, licence: record, language: record, privacy: record, truncatedDescription: string, duration: int, aspectRatio: float, isLocal: bool, name: string, thumbnailPath: string, previewPath: string, thumbnails: list, embedPath: string, views: int, likes: int, dislikes: int, comments: int, nsfw: bool, nsfwFlags: record, nsfwSummary: string, waitTranscoding: bool, state: record, scheduledUpdate: record, blacklisted: bool, blacklistedReason: string, account: record, channel: record, userHistory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "uuids" $uuids "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "nsfwFlagsIncluded" $nsfwFlagsIncluded "scalar") (serialize-qp "nsfwFlagsExcluded" $nsfwFlagsExcluded "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "includeScheduledLive" $includeScheduledLive "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebVideoFiles" $hasWebVideoFiles "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "autoTagOneOf" $autoTagOneOf "scalar") (serialize-qp "stateOneOf" $stateOneOf "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "excludeAlreadyWatched" $excludeAlreadyWatched "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "originallyPublishedStartDate" $originallyPublishedStartDate "scalar") (serialize-qp "originallyPublishedEndDate" $originallyPublishedEndDate "scalar") (serialize-qp "durationMin" $durationMin "scalar") (serialize-qp "durationMax" $durationMax "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search channels
#
# GET /api/v1/search/video-channels
# operationId: searchChannels
export def "search-video-channels searchChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete channel information and interact with it.
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --searchTarget: string@searchTarget-completer # If the administrator enabled search index support, you can override the default search target.  **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information:   * If the current user has the ability to make a remote URI search (this information is available in the config endpoint),   then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database.   After that, you can use the classic REST API endpoints to fetch the complete object or interact with it   * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch   the data from the origin instance API
  --qp-sort: string # Sort column (e.g. -createdAt)
  --host: string # Find elements owned by this host
  --handles: string # Find elements with these handles
]: nothing -> record<total: int, data: table<id: int, url: string, name: record, avatars: list, host: string, hostRedundancyAllowed: bool, followingCount: int, followersCount: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "handles" $handles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/video-channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search playlists
#
# GET /api/v1/search/video-playlists
# operationId: searchPlaylists
export def "search-video-playlists searchPlaylists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete playlist information and interact with it.
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --searchTarget: string@searchTarget-completer # If the administrator enabled search index support, you can override the default search target.  **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information:   * If the current user has the ability to make a remote URI search (this information is available in the config endpoint),   then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database.   After that, you can use the classic REST API endpoints to fetch the complete object or interact with it   * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch   the data from the origin instance API
  --qp-sort: string # Sort column (e.g. -createdAt)
  --host: string # Find elements owned by this host
  --uuids: string # Find elements with specific UUIDs
]: nothing -> record<total: int, data: table<id: int, uuid: string, shortUUID: record, createdAt: string, updatedAt: string, description: string, displayName: string, isLocal: bool, videoLength: int, thumbnailPath: string, thumbnails: list, privacy: record, type: record, ownerAccount: record, videoChannel: record, videoChannelPosition: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "host" $host "scalar") (serialize-qp "uuids" $uuids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get block status of accounts/hosts
#
# GET /api/v1/blocklist/status
export def "blocklist-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounts: list # Check if these accounts are blocked (e.g. [goofy@example.com, donald@example.com])
  --hosts: list # Check if these hosts are blocked (e.g. [example.com])
]: nothing -> record<accounts: record, hosts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accounts" $accounts "multi") (serialize-qp "hosts" $hosts "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/blocklist/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List accounts blocked by my account
#
# GET /api/v1/users/me/blocklist/accounts
# operationId: getMyBlockedAccounts
export def "users-me-blocklist-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --search: string # Search query string
]: nothing -> record<total: int, data: table<byAccount: record, blockedAccount: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/blocklist/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block an account by my account
#
# POST /api/v1/users/me/blocklist/accounts
# operationId: blockAccount
export def "users-me-blocklist-accounts blockAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountName: string # Account name to block (format: name@host) (e.g. user@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/blocklist/accounts")
  let body = {accountName: $accountName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock an account by my account
#
# DELETE /api/v1/users/me/blocklist/accounts/{accountName}
# operationId: unblockAccount
export def "users-me-blocklist-accounts unblockAccount" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/blocklist/accounts/($accountName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List servers blocked by my account
#
# GET /api/v1/users/me/blocklist/servers
# operationId: getMyBlockedServers
export def "users-me-blocklist-servers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --search: string # Search query string
]: nothing -> record<total: int, data: table<byAccount: record, blockedServer: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/blocklist/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block a server by my account
#
# POST /api/v1/users/me/blocklist/servers
# operationId: blockServer
export def "users-me-blocklist-servers blockServer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string # Server host to block (e.g. example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/blocklist/servers")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock a server by my account
#
# DELETE /api/v1/users/me/blocklist/servers/{host}
# operationId: unblockServer
export def "users-me-blocklist-servers unblockServer" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/blocklist/servers/($host)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List blocked accounts by server
#
# GET /api/v1/server/blocklist/accounts
export def "server-blocklist-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<byAccount: record, blockedAccount: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block an account by server
#
# POST /api/v1/server/blocklist/accounts
export def "server-blocklist-accounts post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountName: string # account to block, in the form `username@domain` (e.g. chocobozzz@example.org)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/blocklist/accounts")
  let body = {accountName: $accountName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock an account by server
#
# DELETE /api/v1/server/blocklist/accounts/{accountName}
export def "server-blocklist-accounts delete" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/blocklist/accounts/($accountName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List blocked servers by server
#
# GET /api/v1/server/blocklist/servers
export def "server-blocklist-servers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<byAccount: record, blockedServer: record, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block a server by server
#
# POST /api/v1/server/blocklist/servers
export def "server-blocklist-servers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string # server domain to block (format: hostname)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/blocklist/servers")
  let body = {host: $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock a server by server
#
# DELETE /api/v1/server/blocklist/servers/{host}
export def "server-blocklist-servers delete" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/blocklist/servers/($host)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a server redundancy policy
#
# PUT /api/v1/server/redundancy/{host}
export def "server-redundancy put" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redundancyAllowed: oneof<nothing, bool> # allow mirroring of the host's local videos
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/redundancy/($host)")
  let body = {redundancyAllowed: $redundancyAllowed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List videos being mirrored
#
# GET /api/v1/server/redundancy/videos
# operationId: getMirroredVideos
export def "server-redundancy-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target: string@target-completer # direction of the mirror
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-9 # Sort abuses by criteria
]: nothing -> table<id: int, name: string, url: string, uuid: string, redundancies: record<streamingPlaylists: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target" $target "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/redundancy/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mirror a video
#
# POST /api/v1/server/redundancy/videos
# operationId: putMirroredVideo
export def "server-redundancy-videos post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  videoId: int # e.g. 42
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/redundancy/videos")
  let body = {videoId: $videoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a mirror done on a video
#
# DELETE /api/v1/server/redundancy/videos/{redundancyId}
# operationId: delMirroredVideo
export def "server-redundancy-videos delMirroredVideo" [
  redundancyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/server/redundancy/videos/($redundancyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance stats
#
# GET /api/v1/server/stats
# operationId: getInstanceStats
export def "server-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<totalUsers: float, totalDailyActiveUsers: float, totalWeeklyActiveUsers: float, totalMonthlyActiveUsers: float, totalModerators: float, totalAdmins: float, totalLocalVideos: float, totalLocalVideoViews: float, totalLocalVideoDownloads: float, totalLocalVideoComments: float, totalLocalVideoFilesSize: float, totalVideos: float, totalVideoComments: float, totalLocalVideoChannels: float, totalLocalDailyActiveVideoChannels: float, totalLocalWeeklyActiveVideoChannels: float, totalLocalMonthlyActiveVideoChannels: float, totalLocalPlaylists: float, totalInstanceFollowers: float, totalInstanceFollowing: float, videosRedundancy: table<strategy: string, totalSize: float, totalUsed: float, totalVideoFiles: float, totalVideos: float>, totalActivityPubMessagesProcessed: float, totalActivityPubMessagesSuccesses: float, totalActivityPubMessagesErrors: float, activityPubMessagesProcessedPerSecond: float, totalActivityPubMessagesWaiting: float, averageRegistrationRequestResponseTimeMs: float, totalRegistrationRequestsProcessed: float, totalRegistrationRequests: float, averageAbuseResponseTimeMs: float, totalAbusesProcessed: float, totalAbuses: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Contact the instance administrators
#
# POST /api/v1/server/contact
# operationId: contactAdministrator
export def "server-contact contactAdministrator" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fromName: string # Display name of the sender
  fromEmail: string # Email address of the sender (format: email)
  --subject: string # Subject of the message
  --body-body: string # Message body
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/contact")
  let body = {fromName: $fromName, fromEmail: $fromEmail, subject: $subject, body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get debug information
#
# GET /api/v1/server/debug
# operationId: getDebug
export def "server-debug get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ip: string, activityPubMessagesWaiting: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/debug")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a debug command
#
# POST /api/v1/server/debug/run-command
# operationId: runDebugCommand
export def "server-debug-run-command runDebugCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --command: string@command-completer
  --email: string # format: email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/debug/run-command")
  let body = {command: $command, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send client log
#
# POST /api/v1/server/logs/client
# operationId: sendClientLog
export def "server-logs-client sendClientLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string
  --body-url: string # URL of the current user page
  level: any@level-completer
  --stackTrace: string # Stack trace of the error if there is one
  --userAgent: string # User agent of the web browser that sends the message
  --meta: string # Additional information regarding this log
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/logs/client")
  let body = {message: $message, url: $body_url, level: $level, stackTrace: $stackTrace, userAgent: $userAgent, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get instance logs
#
# GET /api/v1/server/logs
# operationId: getInstanceLogs
export def "server-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instance audit logs
#
# GET /api/v1/server/audit-logs
# operationId: getInstanceAuditLogs
export def "server-audit-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/audit-logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List plugins
#
# GET /api/v1/plugins
# operationId: getPlugins
export def "plugins list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pluginType: int
  --uninstalled: oneof<nothing, bool>
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<name: string, type: int, latestVersion: string, version: string, enabled: bool, uninstalled: bool, peertubeEngine: string, description: string, homepage: string, settings: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pluginType" $pluginType "scalar") (serialize-qp "uninstalled" $uninstalled "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List available plugins
#
# GET /api/v1/plugins/available
# operationId: getAvailablePlugins
export def "plugins-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --pluginType: int
  --currentPeerTubeEngine: string
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<total: int, data: table<name: string, type: int, latestVersion: string, version: string, enabled: bool, uninstalled: bool, peertubeEngine: string, description: string, homepage: string, settings: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "pluginType" $pluginType "scalar") (serialize-qp "currentPeerTubeEngine" $currentPeerTubeEngine "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/plugins/available" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Install a plugin
#
# POST /api/v1/plugins/install
# operationId: addPlugin
export def "plugins-install addPlugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --npmName: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/install")
  let body = {npmName: $npmName, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a plugin
#
# POST /api/v1/plugins/update
# operationId: updatePlugin
export def "plugins-update updatePlugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --npmName: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/update")
  let body = {npmName: $npmName, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uninstall a plugin
#
# POST /api/v1/plugins/uninstall
# operationId: uninstallPlugin
export def "plugins-uninstall uninstallPlugin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  npmName: string # name of the plugin/theme in its package.json (e.g. peertube-plugin-auth-ldap)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/uninstall")
  let body = {npmName: $npmName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a plugin
#
# GET /api/v1/plugins/{npmName}
# operationId: getPlugin
export def "plugins get" [
  npmName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, type: int, latestVersion: string, version: string, enabled: bool, uninstalled: bool, peertubeEngine: string, description: string, homepage: string, settings: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($npmName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a plugin's settings
#
# PUT /api/v1/plugins/{npmName}/settings
export def "plugins-settings put" [
  npmName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($npmName)/settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a plugin's public settings
#
# GET /api/v1/plugins/{npmName}/public-settings
export def "plugins-public-settings get" [
  npmName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($npmName)/public-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a plugin's registered settings
#
# GET /api/v1/plugins/{npmName}/registered-settings
export def "plugins-registered-settings get" [
  npmName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($npmName)/registered-settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create playback metrics
#
# POST /api/v1/metrics/playback
export def "metrics-playback post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  playerMode: string@playerMode-completer
  --resolution: float # Current player video resolution
  --fps: float # Current player video fps
  --p2pEnabled: oneof<nothing, bool>
  --p2pPeers: float # P2P peers connected (doesn't include WebSeed peers)
  resolutionChanges: float # How many resolution changes occurred since the last metric creation
  --bufferStalled: float # How many times buffer has been stalled since the last metric creation
  errors: float # How many errors occurred since the last metric creation
  downloadedBytesP2P: float # How many bytes were downloaded with P2P since the last metric creation
  downloadedBytesHTTP: float # How many bytes were downloaded with HTTP since the last metric creation
  uploadedBytesP2P: float # How many bytes were uploaded with P2P since the last metric creation
  videoId: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metrics/playback")
  let body = {playerMode: $playerMode, resolution: $resolution, fps: $fps, p2pEnabled: $p2pEnabled, p2pPeers: $p2pPeers, resolutionChanges: $resolutionChanges, bufferStalled: $bufferStalled, errors: $errors, downloadedBytesP2P: $downloadedBytesP2P, downloadedBytesHTTP: $downloadedBytesHTTP, uploadedBytesP2P: $uploadedBytesP2P, videoId: $videoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate registration token
#
# POST /api/v1/runners/registration-tokens/generate
export def "runners-registration-tokens-generate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/runners/registration-tokens/generate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove registration token
#
# DELETE /api/v1/runners/registration-tokens/{registrationTokenId}
export def "runners-registration-tokens delete" [
  registrationTokenId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/registration-tokens/($registrationTokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List registration tokens
#
# GET /api/v1/runners/registration-tokens
export def "runners-registration-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort registration tokens by criteria
]: nothing -> record<total: int, data: table<id: int, registrationToken: string, createdAt: string, updatedAt: string, registeredRunnersCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/runners/registration-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a new runner
#
# POST /api/v1/runners/register
export def "runners-register post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  registrationToken: string
  name: string
  --description: string
]: any -> record<id: int, runnerToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/runners/register")
  let body = {registrationToken: $registrationToken, name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unregister a runner
#
# POST /api/v1/runners/unregister
export def "runners-unregister post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/runners/unregister")
  let body = {runnerToken: $runnerToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a runner
#
# DELETE /api/v1/runners/{runnerId}
export def "runners delete" [
  runnerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/($runnerId)")
  let body = {runnerToken: $runnerToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List runners
#
# GET /api/v1/runners
export def "runners get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort runners by criteria
]: nothing -> record<total: int, data: table<id: int, name: string, description: string, ip: string, updatedAt: string, createdAt: string, lastContact: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a new job
#
# POST /api/v1/runners/jobs/request
export def "runners-jobs-request post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  --jobTypes: list # Filter jobs depending on their types
]: any -> record<availableJobs: table<uuid: string, type: string, payload: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/runners/jobs/request")
  let body = {runnerToken: $runnerToken, jobTypes: $jobTypes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept job
#
# POST /api/v1/runners/jobs/{jobUUID}/accept
export def "runners-jobs-accept post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
]: any -> record<job: record<uuid: string, type: string, state: record<id: int, label: string>, payload: any, failures: int, error: string, progress: int, priority: int, updatedAt: string, createdAt: string, startedAt: string, finishedAt: string, parent: record<type: string, state: record, uuid: string>, runner: record<id: float, name: string, description: string>, jobToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/accept")
  let body = {runnerToken: $runnerToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Abort job
#
# POST /api/v1/runners/jobs/{jobUUID}/abort
export def "runners-jobs-abort post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
  reason: string # Why the runner aborts this job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/abort")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update job
#
# POST /api/v1/runners/jobs/{jobUUID}/update
export def "runners-jobs-update post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
  --progress: int # Update job progression percentage (optional)
  --payload: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/update")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken, progress: $progress, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post job error
#
# POST /api/v1/runners/jobs/{jobUUID}/error
export def "runners-jobs-error post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
  message: string # Why the runner failed to process this job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/error")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post job success
#
# POST /api/v1/runners/jobs/{jobUUID}/success
export def "runners-jobs-success post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
  payload: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/success")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the max-quality audio file for a job video
#
# POST /api/v1/runners/jobs/{jobUUID}/files/videos/{videoIdOrUUID}/max-quality/audio
export def "runners-jobs-files-videos-max-quality-audio post" [
  jobUUID: string
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/files/videos/($videoIdOrUUID)/max-quality/audio")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the max-quality video file for a job video
#
# POST /api/v1/runners/jobs/{jobUUID}/files/videos/{videoIdOrUUID}/max-quality
export def "runners-jobs-files-videos-max-quality post" [
  jobUUID: string
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/files/videos/($videoIdOrUUID)/max-quality")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the max-quality thumbnail for a job video
#
# POST /api/v1/runners/jobs/{jobUUID}/files/videos/{videoIdOrUUID}/thumbnails/max-quality
export def "runners-jobs-files-videos-thumbnails-max-quality post" [
  jobUUID: string
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/files/videos/($videoIdOrUUID)/thumbnails/max-quality")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download the max-quality preview for a job video
#
# POST /api/v1/runners/jobs/{jobUUID}/files/videos/{videoIdOrUUID}/previews/max-quality
export def "runners-jobs-files-videos-previews-max-quality post" [
  jobUUID: string
  videoIdOrUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/files/videos/($videoIdOrUUID)/previews/max-quality")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a video studio task file for a job video
#
# POST /api/v1/runners/jobs/{jobUUID}/files/videos/{videoIdOrUUID}/studio/task-files/{filename}
export def "runners-jobs-files-videos-studio-task-files post" [
  jobUUID: string
  videoIdOrUUID: string
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runnerToken: string
  jobToken: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/files/videos/($videoIdOrUUID)/studio/task-files/($filename)")
  let body = {runnerToken: $runnerToken, jobToken: $jobToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a job
#
# POST /api/v1/runners/jobs/{jobUUID}/cancel
export def "runners-jobs-cancel post" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a job
#
# DELETE /api/v1/runners/jobs/{jobUUID}
export def "runners-jobs delete" [
  jobUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/runners/jobs/($jobUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List jobs
#
# GET /api/v1/runners/jobs
export def "runners-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-10 # Sort runner jobs by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --stateOneOf: list
  --typeOneOf: list
]: nothing -> record<total: int, data: table<uuid: string, type: string, state: record, payload: any, failures: int, error: string, progress: int, priority: int, updatedAt: string, createdAt: string, startedAt: string, finishedAt: string, parent: record, runner: record, privatePayload: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "stateOneOf" $stateOneOf "multi") (serialize-qp "typeOneOf" $typeOneOf "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/runners/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account auto tag policies on comments
#
# GET /api/v1/automatic-tags/policies/accounts/{accountName}/comments
export def "automatic-tags-policies-accounts-comments get" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<review: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/automatic-tags/policies/accounts/($accountName)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update account auto tag policies on comments
#
# PUT /api/v1/automatic-tags/policies/accounts/{accountName}/comments
export def "automatic-tags-policies-accounts-comments put" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --review: list # Auto tags that automatically set the comment in review state
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/automatic-tags/policies/accounts/($accountName)/comments")
  let body = {review: $review} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get account available auto tags
#
# GET /api/v1/automatic-tags/accounts/{accountName}/available
export def "automatic-tags-accounts-available get" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: table<name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/automatic-tags/accounts/($accountName)/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get server available auto tags
#
# GET /api/v1/automatic-tags/server/available
export def "automatic-tags-server-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<available: table<name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/automatic-tags/server/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List account watched words
#
# GET /api/v1/watched-words/accounts/{accountName}/lists
export def "watched-words-accounts-lists get" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, data: table<id: int, listName: string, words: list, updatedAt: string, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/accounts/($accountName)/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add account watched words
#
# POST /api/v1/watched-words/accounts/{accountName}/lists
export def "watched-words-accounts-lists post" [
  accountName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listName: string
  --words: list
]: any -> record<watchedWordsList: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/accounts/($accountName)/lists")
  let body = {listName: $listName, words: $words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update account watched words
#
# PUT /api/v1/watched-words/accounts/{accountName}/lists/{listId}
export def "watched-words-accounts-lists put" [
  accountName: string
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listName: string
  --words: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/accounts/($accountName)/lists/($listId)")
  let body = {listName: $listName, words: $words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete account watched words
#
# DELETE /api/v1/watched-words/accounts/{accountName}/lists/{listId}
export def "watched-words-accounts-lists delete" [
  accountName: string
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/accounts/($accountName)/lists/($listId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List server watched words
#
# GET /api/v1/watched-words/server/lists
export def "watched-words-server-lists get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, data: table<id: int, listName: string, words: list, updatedAt: string, createdAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/watched-words/server/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add server watched words
#
# POST /api/v1/watched-words/server/lists
export def "watched-words-server-lists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listName: string
  --words: list
]: any -> record<watchedWordsList: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/watched-words/server/lists")
  let body = {listName: $listName, words: $words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update server watched words
#
# PUT /api/v1/watched-words/server/lists/{listId}
export def "watched-words-server-lists put" [
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --listName: string
  --words: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/server/lists/($listId)")
  let body = {listName: $listName, words: $words} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete server watched words
#
# DELETE /api/v1/watched-words/server/lists/{listId}
export def "watched-words-server-lists delete" [
  listId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/watched-words/server/lists/($listId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update client language
#
# POST /api/v1/client-config/update-language
# DEPRECATED
# operationId: updateClientLanguage
@deprecated
export def "client-config-update-language updateClientLanguage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language code to set (nullable, e.g. en-US)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/client-config/update-language")
  let body = {language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update client language
#
# POST /api/v1/client-config/update-interface-language
# operationId: updateClientInterfaceLanguage
export def "client-config-update-interface-language updateClientInterfaceLanguage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Language code to set, or `null` to clear the preference (nullable, e.g. en-US)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/client-config/update-interface-language")
  let body = {language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List channel collaborators
#
# GET /api/v1/video-channels/{channelHandle}/collaborators
# operationId: listVideoChannelCollaborators
export def "video-channels-collaborators listVideoChannelCollaborators" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<total: int, data: table<id: int, account: record, state: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/collaborators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite a collaborator
#
# POST /api/v1/video-channels/{channelHandle}/collaborators/invite
# operationId: inviteVideoChannelCollaborator
export def "video-channels-collaborators-invite inviteVideoChannelCollaborator" [
  channelHandle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountHandle: string # Local user username to invite
]: any -> record<collaborator: record<id: int, account: record<id: int, name: string, displayName: string, url: string, host: string, avatars: list>, state: record<id: int, label: string>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/collaborators/invite")
  let body = {accountHandle: $accountHandle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept a collaboration invitation
#
# POST /api/v1/video-channels/{channelHandle}/collaborators/{collaboratorId}/accept
# operationId: acceptVideoChannelCollaborator
export def "video-channels-collaborators-accept acceptVideoChannelCollaborator" [
  channelHandle: string
  collaboratorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/collaborators/($collaboratorId)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject a collaboration invitation
#
# POST /api/v1/video-channels/{channelHandle}/collaborators/{collaboratorId}/reject
# operationId: rejectVideoChannelCollaborator
export def "video-channels-collaborators-reject rejectVideoChannelCollaborator" [
  channelHandle: string
  collaboratorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/collaborators/($collaboratorId)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a channel collaborator
#
# DELETE /api/v1/video-channels/{channelHandle}/collaborators/{collaboratorId}
# operationId: removeVideoChannelCollaborator
export def "video-channels-collaborators removeVideoChannelCollaborator" [
  channelHandle: string
  collaboratorId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/collaborators/($collaboratorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
