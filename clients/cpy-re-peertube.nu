# Auto-generated client for PeerTube v5.1.0
# Source: https://api.apis.guru/v2/specs/cpy.re/peertube/5.1.0/openapi.json
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
def state-completer [] { ["1" "2" "3"] }
def videoIs-completer [] { ["blacklisted" "deleted"] }
def filter-completer [] { ["account" "comment" "video"] }
def sort-completer [] { ["-createdAt" "-id" "-state"] }
def sort-completer-1 [] { ["createdAt"] }
def rating-completer [] { ["dislike" "like"] }
def playlistType-completer [] { ["1" "2"] }
def nsfw-completer [] { ["false" "true"] }
def include-completer [] { ["0" "1" "2" "4" "8"] }
def privacyOneOf-completer [] { ["1" "2" "3" "4"] }
def skipCount-completer [] { ["false" "true"] }
def sort-completer-2 [] { ["-best" "-createdAt" "-duration" "-hot" "-likes" "-publishedAt" "-trending" "-views" "name"] }
def jobType-completer [] { ["activitypub-follow" "activitypub-http-broadcast" "activitypub-http-fetcher" "activitypub-http-unicast" "activitypub-refresher" "email" "video-channel-import" "video-file-import" "video-import" "video-live-ending" "video-redundancy" "video-transcoding" "videos-views-stats"] }
def playerMode-completer [] { ["p2p-media-loader" "webtorrent"] }
def searchTarget-completer [] { ["local" "search-index"] }
def sort-completer-3 [] { ["-createdAt" "-duration" "-likes" "-match" "-publishedAt" "-views" "name"] }
def state-completer-1 [] { ["accepted" "pending"] }
def actorType-completer [] { ["Application" "Group" "Organization" "Person" "Service"] }
def level-completer [] { ["error" "warn"] }
def target-completer [] { ["my-videos" "remote-videos"] }
def sort-completer-4 [] { ["name"] }
def sort-completer-5 [] { ["-createdAt" "-id" "-username"] }
def adminFlags-completer [] { ["0" "1"] }
def role-completer [] { ["0" "1" "2"] }
def displayNSFW-completer [] { ["both" "false" "true"] }
def sort-completer-6 [] { ["-createdAt" "-state" "createdAt" "state"] }
def privacy-completer [] { ["1" "2" "3"] }
def type-completer [] { ["1" "2"] }
def sort-completer-7 [] { ["-createdAt" "-dislikes" "-duration" "-id" "-likes" "-uuid" "-views" "name"] }
def privacy-completer-1 [] { ["1" "2" "3" "4"] }
def latencyMode-completer [] { ["1" "2" "3"] }
def sort-completer-8 [] { ["-createdAt" "-totalReplies"] }
def transcodingType-completer [] { ["hls" "webtorrent"] }
def viewEvent-completer [] { ["seek"] }
def accept-completer [] { ["application/atom+xml" "application/json" "application/rss+xml" "application/xml" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "abuses get" } } | get name | first)
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
  --state: int@state-completer
  --searchReporter: string # only list reports of a specific reporter
  --searchReportee: string # only list reports of a specific reportee
  --searchVideo: string # only list reports of a specific video
  --searchVideoChannel: string # only list reports of a specific video channel
  --videoIs: string@videoIs-completer # only list deleted or blocklisted videos
  --filter: string@filter-completer # only list account, comment or video reports
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer # Sort abuses by criteria
]: nothing -> record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int> {
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
# --account shape: {id?: int}
# --comment shape: {id?: any}
# --video shape: {endAt?: int, id?: any, startAt?: int}
export def "abuses post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: record # shape: {id?: int}
  --comment: record # shape: {id?: any}
  --predefinedReasons: list # Reason categories that help triage reports
  reason: string # Reason why the user reports this video
  --video: record # shape: {endAt?: int, id?: any, startAt?: int}
]: any -> record<abuse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/abuses")
  let body = {account: $account, comment: $comment, predefinedReasons: $predefinedReasons, reason: $reason, video: $video} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --moderationComment: string # Update the report comment visible only to the moderation team
  --state: int@state-completer # The abuse state (Pending = `1`, Rejected = `2`, Accepted = `3`)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/abuses/($abuseId)")
  let body = {moderationComment: $moderationComment, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<data: table<account: record, byModerator: bool, createdAt: string, id: int, message: string>, total: int> {
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
]: nothing -> table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts" $qp)
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
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($name)")
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
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/followers" $qp)
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
]: nothing -> table<rating: string, video: record<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/ratings" $qp)
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
]: nothing -> record<data: table<channel: record, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-channel-syncs" $qp)
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
  --withStats: oneof<nothing, bool> # include daily view statistics for the last 30 days and total views (only if authentified as the account user)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withStats" $withStats "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-channels" $qp)
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
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "playlistType" $playlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/video-playlists" $qp)
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
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($name)/videos" $qp)
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
]: nothing -> record<autoBlacklist: record<videos: record<ofUsers: record>>, avatar: record<extensions: list<string>, file: record<size: record>>, contactForm: record<enabled: bool>, email: record<enabled: bool>, followings: record<instance: record<autoFollowIndex: record>>, homepage: record<enabled: bool>, import: record<videoChannelSynchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, isNSFW: bool, name: string, shortDescription: string>, plugin: record<registered: list<string>>, search: record<remoteUri: record<anonymous: bool, users: bool>>, serverCommit: string, serverVersion: string, signup: record<allowed: bool, allowedForCurrentIP: bool, requiresEmailVerification: bool>, theme: record<registered: list<string>>, tracker: record<enabled: bool>, transcoding: record<enabledResolutions: list<int>, hls: record<enabled: bool>, webtorrent: record<enabled: bool>>, trending: record<videos: record<intervalDays: int>>, user: record<videoQuota: int, videoQuotaDaily: int>, video: record<file: record<extensions: list>, image: record<extensions: list, size: record>>, videoCaption: record<file: record<extensions: list, size: record>>> {
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
]: nothing -> record<instance: record<description: string, name: string, shortDescription: string, terms: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/about")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<admin: record<email: string>, autoBlacklist: record<videos: record<ofUsers: record>>, cache: record<captions: record<size: int>, previews: record<size: int>>, contactForm: record<enabled: bool>, followers: record<instance: record<enabled: bool, manualApproval: bool>>, import: record<video_channel_synchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, description: string, isNSFW: bool, name: string, shortDescription: string, terms: string>, services: record<twitter: record<username: string, whitelisted: bool>>, signup: record<enabled: bool, limit: int, requiresEmailVerification: bool>, theme: record<default: string>, transcoding: record<allowAdditionalExtensions: bool, allowAudioFiles: bool, concurrency: float, enabled: bool, hls: record<enabled: bool>, profile: string, resolutions: record<0p: bool, 1080p: bool, 1440p: bool, 144p: bool, 2160p: bool, 240p: bool, 360p: bool, 480p: bool, 720p: bool>, threads: int, webtorrent: record<enabled: bool>>, user: record<videoQuota: int, videoQuotaDaily: int>> {
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
]: nothing -> record<data: table<createdAt: string, data: record, error: record, finishedOn: string, id: int, processedOn: string, state: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "jobType" $jobType "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/jobs/($state)" $qp)
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
  downloadedBytesHTTP: float # How many bytes were downloaded with HTTP since the last metric creation
  downloadedBytesP2P: float # How many bytes were downloaded with P2P since the last metric creation
  errors: float # How many errors occured since the last metric creation
  --fps: float # Current player video fps
  playerMode: string@playerMode-completer
  --resolution: float # Current player video resolution
  resolutionChanges: float # How many resolution changes occured since the last metric creation
  uploadedBytesP2P: float # How many bytes were uploaded with P2P since the last metric creation
  videoId: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metrics/playback")
  let body = {downloadedBytesHTTP: $downloadedBytesHTTP, downloadedBytesP2P: $downloadedBytesP2P, errors: $errors, fps: $fps, playerMode: $playerMode, resolution: $resolution, resolutionChanges: $resolutionChanges, uploadedBytesP2P: $uploadedBytesP2P, videoId: $videoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int> {
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
]: nothing -> record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int> {
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
]: nothing -> record<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/plugins/($npmName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
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
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --uuids: string # Find videos with specific UUIDs
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --searchTarget: string@searchTarget-completer # If the administrator enabled search index support, you can override the default search target.  **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information:   * If the current user has the ability to make a remote URI search (this information is available in the config endpoint),   then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database.   After that, you can use the classic REST API endpoints to fetch the complete object or interact with it   * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch   the data from the origin instance API
  --qp-sort: string@sort-completer-3 # Sort videos by criteria (prefixing with `-` means `DESC` order):
  --startDate: string # Get videos that are published after this date (format: date-time)
  --endDate: string # Get videos that are published before this date (format: date-time)
  --originallyPublishedStartDate: string # Get videos that are originally published after this date (format: date-time)
  --originallyPublishedEndDate: string # Get videos that are originally published before this date (format: date-time)
  --durationMin: int # Get videos that have this minimum duration
  --durationMax: int # Get videos that have this maximum duration
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "uuids" $uuids "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $searchTarget "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "originallyPublishedStartDate" $originallyPublishedStartDate "scalar") (serialize-qp "originallyPublishedEndDate" $originallyPublishedEndDate "scalar") (serialize-qp "durationMin" $durationMin "scalar") (serialize-qp "durationMax" $durationMax "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/videos" $qp)
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

# List account blocks
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block an account
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

# Unblock an account by its handle
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

# List server blocks
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Block a server
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

# Unblock a server by its domain
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
  --state: string@state-completer-1
  --actorType: string@actorType-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
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
# DELETE /api/v1/server/followers/{nameWithHost}
export def "server-followers delete" [
  nameWithHost: string
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
  let full_url = (build-url $base $"/api/v1/server/followers/($nameWithHost)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Accept a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/accept
export def "server-followers-accept post" [
  nameWithHost: string
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
  let full_url = (build-url $base $"/api/v1/server/followers/($nameWithHost)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/reject
export def "server-followers-reject post" [
  nameWithHost: string
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
  let full_url = (build-url $base $"/api/v1/server/followers/($nameWithHost)/reject")
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
  --state: string@state-completer-1
  --actorType: string@actorType-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
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
  --handles: list
  --hosts: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/following")
  let body = {handles: $handles, hosts: $hosts} | compact
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
  level: any@level-completer
  message: string
  --meta: string # Additional information regarding this log
  --stackTrace: string # Stack trace of the error if there is one
  --body-url: string # URL of the current user page
  --userAgent: string # User agent of the web browser that sends the message
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/logs/client")
  let body = {level: $level, message: $message, meta: $meta, stackTrace: $stackTrace, url: $body_url, userAgent: $userAgent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --qp-sort: string@sort-completer-4 # Sort abuses by criteria
]: nothing -> table<id: int, name: string, redundancies: record<files: list, streamingPlaylists: list>, url: string, uuid: string> {
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
]: nothing -> record<activityPubMessagesProcessedPerSecond: float, totalActivityPubMessagesErrors: float, totalActivityPubMessagesProcessed: float, totalActivityPubMessagesSuccesses: float, totalActivityPubMessagesWaiting: float, totalDailyActiveUsers: float, totalInstanceFollowers: float, totalInstanceFollowing: float, totalLocalDailyActiveVideoChannels: float, totalLocalMonthlyActiveVideoChannels: float, totalLocalPlaylists: float, totalLocalVideoChannels: float, totalLocalVideoComments: float, totalLocalVideoFilesSize: float, totalLocalVideoViews: float, totalLocalVideos: float, totalLocalWeeklyActiveVideoChannels: float, totalMonthlyActiveUsers: float, totalUsers: float, totalVideoComments: float, totalVideos: float, totalWeeklyActiveUsers: float, videosRedundancy: table<strategy: string, totalSize: float, totalUsed: float, totalVideoFiles: float, totalVideos: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5 # Sort users by criteria
]: nothing -> table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: record, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --adminFlags: int@adminFlags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --channelName: string # immutable name of the channel, used to interact with its actor (e.g. framasoft_videos)
  email: string # The user email (format: email)
  password: string # format: password
  role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  username: string # immutable name of the user, used to find or mention its actor (e.g. chocobozzz)
  videoQuota: int # The user video quota in bytes (e.g. -1)
  videoQuotaDaily: int # The user daily video quota in bytes (e.g. -1)
]: any -> record<user: record<account: record<id: int>, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let body = {adminFlags: $adminFlags, channelName: $channelName, email: $email, password: $password, role: $role, username: $username, videoQuota: $videoQuota, videoQuotaDaily: $videoQuotaDaily} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: record, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int> {
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
  --autoPlayNextVideo: oneof<nothing, bool> # new preference regarding playing following videos automatically
  --autoPlayNextVideoPlaylist: oneof<nothing, bool> # new preference regarding playing following playlist videos automatically
  --autoPlayVideo: oneof<nothing, bool> # new preference regarding playing videos automatically
  --currentPassword: string # format: password
  --displayNSFW: string@displayNSFW-completer # new NSFW display policy
  --displayName: string # new name of the user in its representations
  --email: any # new email used for login and service communications
  --noAccountSetupWarningModal: oneof<nothing, bool>
  --noInstanceConfigWarningModal: oneof<nothing, bool>
  --noWelcomeModal: oneof<nothing, bool>
  --p2pEnabled: oneof<nothing, bool> # whether to enable P2P in the player or not
  --password: string # format: password
  --theme: string
  --videoLanguages: list # list of languages to filter videos down to
  --videosHistoryEnabled: oneof<nothing, bool> # whether to keep track of watched history or not
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let body = {autoPlayNextVideo: $autoPlayNextVideo, autoPlayNextVideoPlaylist: $autoPlayNextVideoPlaylist, autoPlayVideo: $autoPlayVideo, currentPassword: $currentPassword, displayNSFW: $displayNSFW, displayName: $displayName, email: $email, noAccountSetupWarningModal: $noAccountSetupWarningModal, noInstanceConfigWarningModal: $noInstanceConfigWarningModal, noWelcomeModal: $noWelcomeModal, p2pEnabled: $p2pEnabled, password: $password, theme: $theme, videoLanguages: $videoLanguages, videosHistoryEnabled: $videosHistoryEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --state: int@state-completer
  --qp-sort: string@sort-completer # Sort abuses by criteria
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/abuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: any -> record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>> {
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
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/history/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# Delete history element
#
# DELETE /api/v1/users/me/history/videos/{videoId}
export def "users-me-history-videos delete" [
  videoId: int
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
  let full_url = (build-url $base $"/api/v1/users/me/history/videos/($videoId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --autoInstanceFollowing: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --blacklistOnMyVideo: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --commentMention: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoImportFinished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --myVideoPublished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newCommentOnMyVideo: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newFollow: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newInstanceFollower: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newUserRegistration: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --newVideoFromSubscription: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --videoAutoBlacklistAsModerator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notification-settings")
  let body = {abuseAsModerator: $abuseAsModerator, autoInstanceFollowing: $autoInstanceFollowing, blacklistOnMyVideo: $blacklistOnMyVideo, commentMention: $commentMention, myVideoImportFinished: $myVideoImportFinished, myVideoPublished: $myVideoPublished, newCommentOnMyVideo: $newCommentOnMyVideo, newFollow: $newFollow, newInstanceFollower: $newInstanceFollower, newUserRegistration: $newUserRegistration, newVideoFromSubscription: $newVideoFromSubscription, videoAutoBlacklistAsModerator: $videoAutoBlacklistAsModerator} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --unread: oneof<nothing, bool> # only list unread notifications
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<account: record, actorFollow: record, comment: record, createdAt: string, id: int, read: bool, type: int, updatedAt: string, video: record, videoAbuse: record, videoBlacklist: record, videoImport: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unread" $unread "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
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

# Get my user subscriptions
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
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
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
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions/videos" $qp)
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
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/me/subscriptions/($subscriptionHandle)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# Get videos of my user
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
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos" $qp)
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
  --targetUrl: string # Filter on import target URL
  --videoChannelSyncId: float # Filter on imports created by a specific channel synchronization
  --search: string # Search in video names
]: nothing -> record<data: table<createdAt: string, error: string, id: record, magnetUri: string, state: record, targetUrl: string, torrentName: string, torrentfile: string, updatedAt: string, video: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "targetUrl" $targetUrl "scalar") (serialize-qp "videoChannelSyncId" $videoChannelSyncId "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos/imports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get rate of my user for a video
#
# GET /api/v1/users/me/videos/{videoId}/rating
export def "users-me-videos-rating get" [
  videoId: int
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
  let full_url = (build-url $base $"/api/v1/users/me/videos/($videoId)/rating")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a user
#
# POST /api/v1/users/register
# operationId: registerUser
# --channel shape: {displayName?: string, name?: string}
export def "users-register registerUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --displayName: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: any # immutable name of the user, used to find or mention its actor
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/register")
  let body = {channel: $channel, displayName: $displayName, email: $email, password: $password, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --qp-sort: string@sort-completer-6
]: nothing -> record<data: table<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record, updatedAt: string, user: record, username: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend verification link to registration email
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

# Request registration
#
# POST /api/v1/users/registrations/request
# operationId: requestRegistration
# --channel shape: {displayName?: string, name?: string}
export def "users-registrations-request requestRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --displayName: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: any # immutable name of the user, used to find or mention its actor
  registrationReason: string # reason for the user to register on the instance
]: any -> record<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record<id: int, label: string>, updatedAt: string, user: record<id: int>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/registrations/request")
  let body = {channel: $channel, displayName: $displayName, email: $email, password: $password, username: $username, registrationReason: $registrationReason} | compact
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
  --body: record
]: any -> record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/token")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
  --adminFlags: int@adminFlags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --email: any # The updated email of the user
  --emailVerified: oneof<nothing, bool> # Set the email as verified
  --password: string # format: password
  --pluginAuth: string # The auth plugin to use to authenticate the user (nullable, e.g. peertube-plugin-auth-saml2)
  --role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  --videoQuota: int # The updated video quota of the user in bytes
  --videoQuotaDaily: int # The updated daily video quota of the user in bytes
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)")
  let body = {adminFlags: $adminFlags, email: $email, emailVerified: $emailVerified, password: $password, pluginAuth: $pluginAuth, role: $role, videoQuota: $videoQuota, videoQuotaDaily: $videoQuotaDaily} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  otpToken: string # OTP token generated by the app
  requestToken: string # Token to identify the two factor request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/two-factor/confirm-request")
  let body = {otpToken: $otpToken, requestToken: $requestToken} | compact
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
  --isPendingEmail: oneof<nothing, bool>
  verificationString: string # format: url
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($id)/verify-email")
  let body = {isPendingEmail: $isPendingEmail, verificationString: $verificationString} | compact
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
]: any -> record<videoChannelSync: record<channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record<id: int, label: string>>> {
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
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
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
  --description: any # Channel description
  displayName: any # Channel display name
  --support: any # How to support/fund the channel
  name: any # username of the channel to create
]: any -> record<videoChannel: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-channels")
  let body = {description: $description, displayName: $displayName, support: $support, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string> {
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
  --description: any # Channel description
  --displayName: any # Channel display name
  --support: any # How to support/fund the channel
  --bulkVideosSupportUpdate: oneof<nothing, bool> # Update the support field for all videos of this channel
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)")
  let body = {description: $description, displayName: $displayName, support: $support, bulkVideosSupportUpdate: $bulkVideosSupportUpdate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: any -> record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>> {
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
]: any -> record<banners: table<createdAt: string, path: string, updatedAt: string, width: int>> {
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
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "playlistType" $playlistType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/video-channels/($channelHandle)/videos" $qp)
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
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
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
  --description: string # Video playlist description
  displayName: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --videoChannelId: any # Video channel in which the playlist will be published
]: any -> record<videoPlaylist: record<id: int, shortUUID: string, uuid: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-playlists")
  let body = {description: $description, displayName: $displayName, privacy: $privacy, thumbnailfile: $thumbnailfile, videoChannelId: $videoChannelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
]: nothing -> record<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, privacy: record<id: int, label: string>, shortUUID: record, thumbnailPath: string, type: record<id: int, label: string>, updatedAt: string, uuid: string, videoChannel: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, videoLength: int> {
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
  --description: string # Video playlist description
  --displayName: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --videoChannelId: any # Video channel in which the playlist will be published
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)")
  let body = {description: $description, displayName: $displayName, privacy: $privacy, thumbnailfile: $thumbnailfile, videoChannelId: $videoChannelId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
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
  --startTimestamp: int # Start the video at this specific timestamp (format: seconds)
  --stopTimestamp: int # Stop the video at this specific timestamp (format: seconds)
  videoId: any # Video to add in the playlist
]: any -> record<videoPlaylistElement: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos")
  let body = {startTimestamp: $startTimestamp, stopTimestamp: $stopTimestamp, videoId: $videoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder a playlist
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
  insertAfterPosition: int # New position for the block to reorder, to add the block before the first element
  --reorderLength: int # How many element from `startPosition` to reorder
  startPosition: int # Start position of the element to reorder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/video-playlists/($playlistId)/videos/reorder")
  let body = {insertAfterPosition: $insertAfterPosition, reorderLength: $reorderLength, startPosition: $startPosition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --categoryOneOf: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --isLive: oneof<nothing, bool> # whether or not the video is a live
  --tagsOneOf: string # tag(s) of the video
  --tagsAllOf: string # tag(s) of the video, where all should be present in the video
  --licenceOneOf: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --languageOneOf: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skipCount: string@skipCount-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $categoryOneOf "scalar") (serialize-qp "isLive" $isLive "scalar") (serialize-qp "tagsOneOf" $tagsOneOf "scalar") (serialize-qp "tagsAllOf" $tagsAllOf "scalar") (serialize-qp "licenceOneOf" $licenceOneOf "scalar") (serialize-qp "languageOneOf" $languageOneOf "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar") (serialize-qp "skipCount" $skipCount "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<data: table<createdAt: string, description: string, dislikes: int, duration: int, id: int, likes: int, name: string, nsfw: bool, updatedAt: string, uuid: string, videoId: int, views: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/blacklist" $qp)
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

# Import a video
#
# POST /api/v1/videos/imports
# operationId: importVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos-imports importVideo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --commentsEnabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
]: any -> record<video: record<id: int, shortUUID: string, uuid: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/imports")
  let body = {category: $category, channelId: $channelId, commentsEnabled: $commentsEnabled, description: $description, downloadEnabled: $downloadEnabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originallyPublishedAt: $originallyPublishedAt, previewfile: $previewfile, privacy: $privacy, scheduleUpdate: $scheduleUpdate, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, waitTranscoding: $waitTranscoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/languages")
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

# Create a live
#
# POST /api/v1/videos/live
# operationId: addLive
export def "videos-live addLive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channelId: int # Channel id that will contain this live video
  --commentsEnabled: oneof<nothing, bool> # Enable or disable comments for this live video/replay
  --description: string # Live video/replay description
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for the replay of this live video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --latencyMode: int@latencyMode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Live video/replay name
  --nsfw: oneof<nothing, bool> # Whether or not this live video/replay contains sensitive content
  --permanentLive: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --previewfile: string # Live video/replay preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --saveReplay: oneof<nothing, bool>
  --support: string # A text tell the audience how to support the creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list # Live video/replay tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Live video/replay thumbnail file (format: binary)
]: any -> record<video: record<id: int, shortUUID: string, uuid: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/live")
  let body = {category: $category, channelId: $channelId, commentsEnabled: $commentsEnabled, description: $description, downloadEnabled: $downloadEnabled, language: $language, latencyMode: $latencyMode, licence: $licence, name: $name, nsfw: $nsfw, permanentLive: $permanentLive, previewfile: $previewfile, privacy: $privacy, saveReplay: $saveReplay, support: $support, tags: $tags, thumbnailfile: $thumbnailfile} | compact
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
]: nothing -> record<latencyMode: int, permanentLive: bool, rtmpUrl: string, rtmpsUrl: string, saveReplay: bool, streamKey: string> {
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
  --latencyMode: int@latencyMode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --permanentLive: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --saveReplay: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/live/($id)")
  let body = {latencyMode: $latencyMode, permanentLive: $permanentLive, saveReplay: $saveReplay} | compact
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
]: nothing -> record<data: table<endDate: string, error: int, id: int, replayVideo: record, startDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/live/($id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List video ownership changes
#
# GET /api/v1/videos/ownership
export def "videos-ownership get" [
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
  let full_url = (build-url $base "/api/v1/videos/ownership")
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/ownership/($id)/accept")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# List available video privacy policies
#
# GET /api/v1/videos/privacies
# operationId: getPrivacyPolicies
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

# Upload a video
#
# POST /api/v1/videos/upload
# operationId: uploadLegacy
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos-upload uploadLegacy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --commentsEnabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  videofile: string # Video file (format: binary)
]: any -> record<video: record<id: int, shortUUID: string, uuid: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload")
  let body = {category: $category, channelId: $channelId, commentsEnabled: $commentsEnabled, description: $description, downloadEnabled: $downloadEnabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originallyPublishedAt: $originallyPublishedAt, previewfile: $previewfile, privacy: $privacy, scheduleUpdate: $scheduleUpdate, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, waitTranscoding: $waitTranscoding, videofile: $videofile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last 12 hours, it is not valid anymore and the upload session has already been deleted with its data ;-)
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

# Initialize the resumable upload of a video
#
# POST /api/v1/videos/upload-resumable
# operationId: uploadResumableInit
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
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
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channelId: int # Channel id that will contain this video (e.g. 3)
  --commentsEnabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --waitTranscoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  filename: string # Video filename including extension (format: filename, e.g. what_is_peertube.mp4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload-resumable")
  let body = {category: $category, channelId: $channelId, commentsEnabled: $commentsEnabled, description: $description, downloadEnabled: $downloadEnabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originallyPublishedAt: $originallyPublishedAt, previewfile: $previewfile, privacy: $privacy, scheduleUpdate: $scheduleUpdate, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, waitTranscoding: $waitTranscoding, filename: $filename} | compact
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
]: any -> record<video: record<id: int, shortUUID: string, uuid: any>> {
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
]: nothing -> record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, blacklisted: bool, blacklistedReason: string, category: record<id: int, label: string>, channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: list<record>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record<id: string, label: string>, licence: record<id: int, label: string>, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record<id: int, label: string>, publishedAt: string, scheduledUpdate: record<privacy: int, updateAt: string>, shortUUID: record, state: record<id: int, label: string>, thumbnailPath: string, updatedAt: string, userHistory: record<currentTime: int>, uuid: record, views: int, waitTranscoding: bool, commentsEnabled: bool, descriptionPath: string, downloadEnabled: bool, files: table<fileDownloadUrl: string, fileUrl: string, fps: float, id: int, magnetUri: string, metadataUrl: string, resolution: record, size: int, torrentDownloadUrl: string, torrentUrl: string>, streamingPlaylists: table<id: int, type: int, files: list, playlistUrl: string, redundancies: list, segmentsSha256Url: string>, support: string, tags: list<string>, trackerUrls: list<string>, viewers: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a video
#
# PUT /api/v1/videos/{id}
# operationId: putVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
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
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --commentsEnabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description
  --downloadEnabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --name: string # Video name
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originallyPublishedAt: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --scheduleUpdate: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list # Video tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --waitTranscoding: string # Whether or not we wait transcoding before publish the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)")
  let body = {category: $category, commentsEnabled: $commentsEnabled, description: $description, downloadEnabled: $downloadEnabled, language: $language, licence: $licence, name: $name, nsfw: $nsfw, originallyPublishedAt: $originallyPublishedAt, previewfile: $previewfile, privacy: $privacy, scheduleUpdate: $scheduleUpdate, support: $support, tags: $tags, thumbnailfile: $thumbnailfile, waitTranscoding: $waitTranscoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
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
]: nothing -> record<data: table<captionPath: string, language: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/captions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<data: table<account: record, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/comment-threads" $qp)
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
]: any -> record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
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
]: nothing -> record<children: list<any>, comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comment-threads/($threadId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  text: any # format: markdown
]: any -> record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/comments/($commentId)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get complete video description
#
# GET /api/v1/videos/{id}/description
# operationId: getVideoDesc
export def "videos-description get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/description")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request ownership change
#
# POST /api/v1/videos/{id}/give-ownership
export def "videos-give-ownership post" [
  id: string
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
  let full_url = (build-url $base $"/api/v1/videos/($id)/give-ownership")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
]: nothing -> record<endDate: string, error: int, id: int, replayVideo: record<id: float, shortUUID: string, uuid: string>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/live-session")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  rating: string@rating-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/rate")
  let body = {rating: $rating} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get video source file metadata
#
# POST /api/v1/videos/{id}/source
# operationId: getVideoSource
export def "videos-source post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filename: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/source")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: nothing -> record<averageWatchTime: float, countries: table<isoCode: string, viewers: float>, totalWatchTime: float, viewersPeak: float, viewersPeakDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/videos/($id)/stats/overall" $qp)
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
]: nothing -> record<data: table<retentionPercent: float, second: float>> {
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
]: nothing -> record<files: record<expires: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/transcoding")
  let body = {transcodingType: $transcodingType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/views")
  let body = {currentTime: $currentTime, viewEvent: $viewEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set watching progress of a video
#
# PUT /api/v1/videos/{id}/watching
# DEPRECATED
@deprecated
export def "videos-watching put" [
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
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/videos/($id)/watching")
  let body = {currentTime: $currentTime, viewEvent: $viewEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete video WebTorrent files
#
# DELETE /api/v1/videos/{id}/webtorrent
# operationId: delVideoWebTorrent
export def "videos-webtorrent delVideoWebTorrent" [
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
  let full_url = (build-url $base $"/api/v1/videos/($id)/webtorrent")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos of subscriptions tied to a token
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
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/subscriptions.($format)" $qp)
  let accept_val = ($accept | default "application/atom+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List comments on videos
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
  --videoId: string # limit listing to a specific video
  --accountId: string # limit listing to a specific account
  --accountName: string # limit listing to a specific account
  --videoChannelId: string # limit listing to a specific video channel
  --videoChannelName: string # limit listing to a specific video channel
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoId" $videoId "scalar") (serialize-qp "accountId" $accountId "scalar") (serialize-qp "accountName" $accountName "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "videoChannelName" $videoChannelName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/video-comments.($format)" $qp)
  let accept_val = ($accept | default "application/atom+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List videos
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
  --isLocal: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacyOneOf: int@privacyOneOf-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --hasHLSFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --hasWebtorrentFiles: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "accountName" $accountName "scalar") (serialize-qp "videoChannelId" $videoChannelId "scalar") (serialize-qp "videoChannelName" $videoChannelName "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $isLocal "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacyOneOf "scalar") (serialize-qp "hasHLSFiles" $hasHLSFiles "scalar") (serialize-qp "hasWebtorrentFiles" $hasWebtorrentFiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/feeds/videos.($format)" $qp)
  let accept_val = ($accept | default "application/atom+xml")
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

# Get private WebTorrent video file
#
# GET /static/webseed/private/{filename}
export def "static-webseed-private get" [
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
  let full_url = (build-url $base $"/static/webseed/private/($filename)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public WebTorrent video file
#
# GET /static/webseed/{filename}
export def "static-webseed get" [
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
  let full_url = (build-url $base $"/static/webseed/($filename)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
