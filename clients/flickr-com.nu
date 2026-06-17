# Auto-generated client for Flickr API Schema v1.0.0
# Source: https://api.apis.guru/v2/specs/flickr.com/1.0.0/openapi.json
# Auth: --token flag or $env.FLICKR_API_SCHEMA_TOKEN

const BASE_URL = "https://api.flickr.com/services"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FLICKR_API_SCHEMA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.flickr.com/services"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["1" "2" "3"] }
def hidden-completer [] { ["1" "2"] }
def is-family-completer [] { ["0" "1"] }
def is-friend-completer [] { ["0" "1"] }
def is-public-completer [] { ["0" "1"] }
def safety-level-completer [] { ["1" "2" "3"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "oauth-access-token get" } } | get name | first)
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

# Returns an access token
#
# GET /oauth/access_token
# operationId: getAccessToken
export def "oauth-access-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-nonce: string
  --oauth-timestamp: string
  --oauth-signature-method: string
  --oauth-version: string
  --oauth-signature: string
  --oauth-verifier: string
  --oauth-token: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "oauth_consumer_key" $oauth_consumer_key "scalar") (serialize-qp "oauth_nonce" $oauth_nonce "scalar") (serialize-qp "oauth_timestamp" $oauth_timestamp "scalar") (serialize-qp "oauth_signature_method" $oauth_signature_method "scalar") (serialize-qp "oauth_version" $oauth_version "scalar") (serialize-qp "oauth_signature" $oauth_signature "scalar") (serialize-qp "oauth_verifier" $oauth_verifier "scalar") (serialize-qp "oauth_token" $oauth_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/access_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an oauth token and oauth token secret
#
# GET /oauth/request_token
# operationId: getRequestToken
export def "oauth-request-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string
  --oauth-nonce: string
  --oauth-timestamp: string
  --oauth-signature-method: string
  --oauth-version: string
  --oauth-signature: string
  --oauth-callback: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "oauth_consumer_key" $oauth_consumer_key "scalar") (serialize-qp "oauth_nonce" $oauth_nonce "scalar") (serialize-qp "oauth_timestamp" $oauth_timestamp "scalar") (serialize-qp "oauth_signature_method" $oauth_signature_method "scalar") (serialize-qp "oauth_version" $oauth_version "scalar") (serialize-qp "oauth_signature" $oauth_signature "scalar") (serialize-qp "oauth_callback" $oauth_callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/request_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns next and previous favorites for a photo in a user's favorites
#
# GET /rest?method=flickr.favorites.getContext
# operationId: getFavoritesContextByID
export def "rest-methodflickrfavoritesget-context get-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
  --user-id: string
]: nothing -> record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.favorites.getContext" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of the user's favorite photos. Only photos which the calling user has permission to see are returned.
#
# GET /rest?method=flickr.favorites.getList
# operationId: getFavoritesByPersonID
export def "rest-methodflickrfavoritesget-list get-favorites" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --user-id: string
  --min-fave-date: float
  --max-fave-date: float
  --page: float
  --per-page: float
]: nothing -> record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "min_fave_date" $min_fave_date "scalar") (serialize-qp "max_fave_date" $max_fave_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.favorites.getList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of photos in a gallery.
#
# GET /rest?method=flickr.galleries.getPhotos
# operationId: getGalleryPhotosByID
export def "rest-methodflickrgalleriesget-photos get-gallery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --gallery-id: string
]: nothing -> record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "gallery_id" $gallery_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.galleries.getPhotos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information on a group topic reply
#
# GET /rest?method=flickr.groups.discuss.replies.getInfo
# operationId: getGroupTopicRepliesByID
export def "rest-methodflickrgroupsdiscussrepliesget-info get-group-topic-replies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --group-id: string
  --topic-id: string
  --reply-id: string
]: nothing -> record<reply: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, datecreate: string, iconfarm: string, iconserver: string, id: string, is_pro: bool, lastedit: string, message: record<_content: string>>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "topic_id" $topic_id "scalar") (serialize-qp "reply_id" $reply_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.discuss.replies.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a group discussion topic
#
# GET /rest?method=flickr.groups.discuss.topics.getInfo
# operationId: getGroupTopicByID
export def "rest-methodflickrgroupsdiscusstopicsget-info get-group-topic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --group-id: string
  --topic-id: string
]: nothing -> record<stat: string, topic: record<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record<_content: string>, role: string, subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "topic_id" $topic_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.discuss.topics.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of discussion topics in a group.
#
# GET /rest?method=flickr.groups.discuss.topics.getList
# operationId: getGroupDiscussionsByID
export def "rest-methodflickrgroupsdiscusstopicsget-list get-group-discussions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --group-id: string
  --page: float
  --per-page: float
]: nothing -> record<iconfarm: float, iconserver: float, ispoolmoderated: bool, lang: string, members: float, name: string, page: float, pages: float, per_page: float, privacy: float, topics: table<author: string, author_is_deleted: bool, author_path_alias: string, authorname: string, can_delete: bool, can_edit: bool, can_reply: bool, count_replies: int, datecreate: string, datelastpost: string, iconfarm: string, iconserver: string, id: string, is_locked: bool, is_pro: bool, is_sticky: bool, last_reply: string, lastedit: string, message: record, role: string, subject: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.discuss.topics.getList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about a group
#
# GET /rest?method=flickr.groups.getInfo
# operationId: getGroupByID
export def "rest-methodflickrgroupsget-info get-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --group-id: string
  --group-path-alias: string
  --lang: string
]: nothing -> record<group: record<blast: record<_content: string, date_blast_added: string, user_id: string>, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto_farm: string, coverphoto_server: string, coverphoto_url: record<h: string, l: string, s: string, t: string>, description: record<_content: string>, iconfarm: string, iconserver: string, id: string, is_admin: bool, is_member: bool, is_moderator: bool, ispoolmoderated: bool, lang: string, members: record<_content: string>, name: record<_content: string>, path_alias: string, pool_count: record<_content: string>, pool_rows: int, privacy: record<_content: string>, restrictions: record<art_ok: bool, has_geo: bool, images_ok: bool, moderate_ok: bool, photos_ok: bool, restricted_ok: bool, safe_ok: bool, screens_ok: bool, videos_ok: bool>, roles: record<admin: string, member: string, moderator: string>, rules: record<_content: string>, throttle: record<count: int, mode: string, remaining: string>, topic_count: record<_content: string>>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "group_path_alias" $group_path_alias "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns next and previous photos for a photo in a group pool
#
# GET /rest?method=flickr.groups.pools.getContext
export def "rest-methodflickrgroupspoolsget-context get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
  --group-id: string
]: nothing -> record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.pools.getContext" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of pool photos for a given group
#
# GET /rest?method=flickr.groups.pools.getPhotos
# operationId: getGroupPhotosByID
export def "rest-methodflickrgroupspoolsget-photos get-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --group-id: string
]: nothing -> record<photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "group_id" $group_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.groups.pools.getPhotos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a person
#
# GET /rest?method=flickr.people.getInfo
# operationId: getPersonByID
export def "rest-methodflickrpeopleget-info get-person" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --user-id: string
]: nothing -> record<person: record<can_buy_pro: bool, cover: record<farm: string, id: string, isfamily: bool, isfriend: bool, ispublic: bool, owner: string, secret: string, server: string, title: string, y: string>, coverphoto: record<h: string, l: string, s: string, t: string>, coverphoto_farm: string, coverphoto_server: string, description: record<_content: string>, disable_keyboard_shortcuts: record<_content: string>, expire: bool, has_stats: bool, iconfarm: string, iconserver: string, id: string, is_ad_free: bool, ispro: bool, location: record<_content: string>, mbox_sha1sum: record<_content: string>, mobileurl: record<_content: string>, nsid: string, path_alias: string, photos: record<count: record, firstdate: record, firstdatetaken: record, views: record>, photosurl: record<_content: string>, profileurl: record<_content: string>, realname: record<_content: string>, timezone: record<label: string, offset: string, timezone_id: string>, unread_messages: record<_content: string>, user_secret: string, username: record<_content: string>, yintl: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.people.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return photos from the given user's photostream
#
# GET /rest?method=flickr.people.getPhotos
# operationId: getMediaByPersonID
export def "rest-methodflickrpeopleget-photos get-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --user-id: string
  --safe-search: float
  --min-upload-date: float
  --max-upload-date: float
  --min-taken-date: float
  --max-taken-date: float
  --content-type: float
  --privacy-filter: float
  --page: float
  --per-page: float
]: nothing -> record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "safe_search" $safe_search "scalar") (serialize-qp "min_upload_date" $min_upload_date "scalar") (serialize-qp "max_upload_date" $max_upload_date "scalar") (serialize-qp "min_taken_date" $min_taken_date "scalar") (serialize-qp "max_taken_date" $max_taken_date "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "privacy_filter" $privacy_filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.people.getPhotos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns next and previous photos in a photo list
#
# GET /rest?method=flickr.photolist.getContext
# operationId: getPhotolistContextByID
export def "rest-methodflickrphotolistget-context get-photolist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
  --photolist-id: string
]: nothing -> record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar") (serialize-qp "photolist_id" $photolist_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photolist.getContext" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns next and previous photos for a photo in a photostream
#
# GET /rest?method=flickr.photos.getContext
# operationId: getPhotostreamContextByID
export def "rest-methodflickrphotosget-context get-photostream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
]: nothing -> record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.getContext" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a list of EXIF/TIFF/GPS tags for a given photo. The calling user must have permission to view the photo.
#
# GET /rest?method=flickr.photos.getExif
# operationId: getPhotoExifByID
export def "rest-methodflickrphotosget-exif get-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
  --secret: string
]: nothing -> record<photo: record<camera: string, exif: list<record>, farm: string, id: string, secret: string, server: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar") (serialize-qp "secret" $secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.getExif" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a photo
#
# GET /rest?method=flickr.photos.getInfo
# operationId: getPhotoByID
export def "rest-methodflickrphotosget-info get-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
]: nothing -> record<photo: record<comments: record<_content: string>, dates: record<lastupdate: string, posted: string, taken: string, takengranularity: string, takenunknown: bool>, dateuploaded: string, description: record<_content: string>, editability: record<canaddmeta: bool, cancomment: bool>, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record<note: list>, originalsecret: string, owner: record<iconfarm: string, iconserver: string, is_ad_free: bool, ispro: bool, location: string, noindexfollow: bool, nsid: string, path_alias: string, realname: string, username: string>, people: record<haspeople: bool>, permissions: record<permaddmeta: string, permcomment: string>, publiceditability: record<canaddmeta: bool, cancomment: bool>, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record<tag: list>, title: record<_content: string>, urls: record<url: list>, usage: record<canblog: bool, candownload: bool, canprint: bool, canshare: bool>, views: string, visibility: record<isfamily: bool, isfriend: bool, ispublic: bool>>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns photo sizes
#
# GET /rest?method=flickr.photos.getSizes
# operationId: getPhotoSizesByID
export def "rest-methodflickrphotosget-sizes get-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
]: nothing -> record<sizes: record<canblog: float, candownload: float, canprint: float, sizes: list<record>>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.getSizes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetches a list of available photo licenses for Flickr
#
# GET /rest?method=flickr.photos.licenses.getInfo
# operationId: getLicenseByID
export def "rest-methodflickrphotoslicensesget-info get-license" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
]: nothing -> record<licenses: record<license: list<record>>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.licenses.getInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of photos matching some criteria.
#
# GET /rest?method=flickr.photos.search
# operationId: getMediaBySearch
export def "rest-methodflickrphotossearch get-media" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --text: string # A free text search. Photos who's title, description or tags contain the text will be returned. You can exclude results that match a term by prepending it with a - character.
  --tags: string # A comma-delimited list of tags. Photos with one or more of the tags listed will be returned. You can exclude results that match a term by prepending it with a - character.
  --user-id: string # The NSID of the user who's photo to search. If this parameter isn't passed then everybody's public photos will be searched. A value of "me" will search against the calling user's photos for authenticated calls.
  --min-upload-date: string # Minimum upload date. Photos with an upload date greater than or equal to this value will be returned. The date can be in the form of a unix timestamp or mysql datetime.
  --max-upload-date: string # Maximum upload date. Photos with an upload date less than or equal to this value will be returned. The date can be in the form of a unix timestamp or mysql datetime.
  --min-taken-date: string # Minimum taken date. Photos with an taken date greater than or equal to this value will be returned. The date can be in the form of a mysql datetime or unix timestamp.
  --max-taken-date: string # Maximum taken date. Photos with an taken date less than or equal to this value will be returned. The date can be in the form of a mysql datetime or unix timestamp.
  --license: string # The license id for photos (for possible values see the flickr.photos.licenses.getInfo method). Multiple licenses may be comma-separated.
  --qp-sort: string # The order in which to sort returned photos. Deafults to date-posted-desc (unless you are doing a radial geo query, in which case the default sorting is by ascending distance from the point specified). The possible values are:   date-posted-asc,   date-posted-desc,   date-taken-asc,   date-taken-desc,   interestingness-desc,   interestingness-asc, and   relevance.
  --privacy-filter: float # Return photos only matching a certain privacy level. This only applies when making an authenticated call to view photos you own. Valid values are:,   1: public photos,   2: private photos visible to friends,   3: private photos visible to family,   4: private photos visible to friends & family,   5: completely private photos
  --bbox: string # A comma-delimited list of 4 values defining the Bounding Box of the area that will be searched.
  --accuracy: string # Recorded accuracy level of the location information. Current range is 1-16:   World level is 1   Country is ~3   Region is ~6   City is ~11   Street is ~16
  --safe-search: float # Safe search setting:   1: for safe,   2: for moderate,   3: for restricted
  --content-type: float # Content Type setting:   1: photos only.   2: screenshots only.   3: 'other' only.   4: photos and screenshots.   5: screenshots and 'other'.   6: photos and 'other'.   7: photos, screenshots, and 'other' (all).
  --machine-tags: string # Aside from passing in a fully formed machine tag, there is a special syntax for searching on specific properties : Find photos using the 'dc' namespace : "machine_tags" => "dc:" Find photos with a title in the 'dc' namespace : "machine_tags" => "dc:title=" Find photos titled "mr. camera" in the 'dc' namespace : "machine_tags" => "dc:title=\"mr. camera\" Find photos whose value is "mr. camera" : "machine_tags" => "*:*=\"mr. camera\"" Find photos that have a title, in any namespace : "machine_tags" => "*:title=" Find photos that have a title, in any namespace, whose value is "mr. camera" : "machine_tags" => "*:title=\"mr. camera\"" Find photos, in the 'dc' namespace whose value is "mr. camera" : "machine_tags" => "dc:*=\"mr. camera\"" Multiple machine tags may be queried by passing a comma-separated list. The number of machine tags you can pass in a single query depends on the tag mode (AND or OR) that you are querying with. "AND" queries are limited to (16) machine tags. "OR" queries are limited to (8).
  --machine-tag-mode: string # Either 'any' for an OR combination of tags, or 'all' for an AND combination. Defaults to 'any' if not specified.
  --group-id: string # The id of a group who's pool to search. If specified, only matching photos posted to the group's pool will be returned.
  --contacts: string # Search your contacts. Either 'all' or 'ff' for just friends and family. (Experimental)
  --woe-id: string # A 32-bit identifier that uniquely represents spatial entities. (not used if bbox argument is present).
  --place-id: string # A Flickr place id. (not used if bbox argument is present). Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --media: string # Filter results by media type. Possible values are all (default), photos or videos
  --has-geo: string # Any photo that has been geotagged, or if the value is "0" any photo that has not been geotagged. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --geo-context: string # Geo context is a numeric value representing the photo's geotagginess beyond latitude and longitude. For example, you may wish to search for photos that were taken "indoors" or "outdoors". The current list of context IDs is: 0, not defined. 1, indoors. 2, outdoors. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --lat: string # A valid latitude, in decimal format, for doing radial geo queries. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --lon: string # A valid longitude, in decimal format, for doing radial geo queries. Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component. A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
  --radius: float # A valid radius used for geo queries, greater than zero and less than 20 miles (or 32 kilometers), for use with point-based geo queries. The default value is 5 (km).
  --radius-units: string # The unit of measure when doing radial geo queries. Valid options are "mi" (miles) and "km" (kilometers). The default is "km".
  --is-commons: oneof<nothing, bool> # Limit the scope of the search to only photos that are part of the Flickr Commons project. Default is false.
  --in-gallery: oneof<nothing, bool> # Limit the scope of the search to only photos that are in a gallery? Default is false, search all photos.
  --is-getty: oneof<nothing, bool> # Limit the scope of the search to only photos that are for sale on Getty. Default is false.
  --per-page: float # Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
  --page: float # The page of results to return. If this argument is omitted, it defaults to 1.
]: nothing -> record<page: float, pages: float, perpage: float, photos: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "min_upload_date" $min_upload_date "scalar") (serialize-qp "max_upload_date" $max_upload_date "scalar") (serialize-qp "min_taken_date" $min_taken_date "scalar") (serialize-qp "max_taken_date" $max_taken_date "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "privacy_filter" $privacy_filter "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "accuracy" $accuracy "scalar") (serialize-qp "safe_search" $safe_search "scalar") (serialize-qp "content_type" $content_type "scalar") (serialize-qp "machine_tags" $machine_tags "scalar") (serialize-qp "machine_tag_mode" $machine_tag_mode "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "contacts" $contacts "scalar") (serialize-qp "woe_id" $woe_id "scalar") (serialize-qp "place_id" $place_id "scalar") (serialize-qp "media" $media "scalar") (serialize-qp "has_geo" $has_geo "scalar") (serialize-qp "geo_context" $geo_context "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "radius_units" $radius_units "scalar") (serialize-qp "is_commons" $is_commons "scalar") (serialize-qp "in_gallery" $in_gallery "scalar") (serialize-qp "is_getty" $is_getty "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photos.search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns next and previous photos for a photo in a set
#
# GET /rest?method=flickr.photosets.getContext
# operationId: getAlbumContextByID
export def "rest-methodflickrphotosetsget-context get-album" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photo-id: string
  --photoset-id: string
]: nothing -> record<count: record<_content: string>, nextphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, prevphoto: record<farm: string, id: string, is_faved: bool, license: int, media: string, owner: string, safe: bool, secret: string, server: string, thumb: string, title: string, url: string>, stat: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photo_id" $photo_id "scalar") (serialize-qp "photoset_id" $photoset_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photosets.getContext" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the albums belonging to the specified user
#
# GET /rest?method=flickr.photosets.getList
# operationId: getAlbumsByPersonID
export def "rest-methodflickrphotosetsget-list get-albums" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --user-id: string
  --page: float
  --per-page: float
]: nothing -> record<page: float, pages: float, perpage: float, photosets: table<can_comment: bool, count_comments: float, count_views: float, date_create: float, date_update: float, description: string, farm: string, id: string, photos: float, primary: string, secret: string, server: string, title: string, videos: float>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photosets.getList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of photos in an album.
#
# GET /rest?method=flickr.photosets.getPhotos
# operationId: getAlbumByID
export def "rest-methodflickrphotosetsget-photos get-album" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --photoset-id: string
]: nothing -> record<photoset: table<comments: record, dates: record, dateuploaded: string, description: record, editability: record, farm: string, id: string, isfavorite: bool, license: string, media: string, notes: record, originalsecret: string, owner: record, people: record, permissions: record, publiceditability: record, rotation: string, safe: bool, safety_level: string, secret: string, server: string, tags: record, title: record, urls: record, usage: record, views: string, visibility: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "photoset_id" $photoset_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.photosets.getPhotos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Echos the input parameters back in the response
#
# GET /rest?method=flickr.test.echo
# operationId: echo
export def "rest-methodflickrtestecho echo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string
  --echo: string
]: nothing -> record<echo: record<_content: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api_key" $api_key "scalar") (serialize-qp "echo" $echo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest?method=flickr.test.echo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a new photo to Flickr
#
# POST /upload
# operationId: uploadPhoto
export def "upload upload-photo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string
  --content-type: string@content-type-completer
  --description: string
  --hidden: string@hidden-completer
  --is-family: string@is-family-completer
  --is-friend: string@is-friend-completer
  --is-public: string@is-public-completer
  photo: string # format: binary
  --safety-level: string@safety-level-completer
  --tags: string
  --title: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upload")
  let body = {"api_key": $api_key, "content_type": $content_type, "description": $description, "hidden": $hidden, "is_family": $is_family, "is_friend": $is_friend, "is_public": $is_public, "photo": $photo, "safety_level": $safety_level, "tags": $tags, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}
