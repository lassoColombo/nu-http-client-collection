# Auto-generated client for Vimeo v3.4
# Source: https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json
# Auth: --token flag or $env.VIMEO_TOKEN

const BASE_URL = "https://api.vimeo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VIMEO_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.vimeo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def direction-completer [] { ["asc" "desc"] }
def sort-completer [] { ["last_video_featured_time" "name"] }
def sort-completer-1 [] { ["alphabetical" "date" "followers" "videos"] }
def sort-completer-2 [] { ["alphabetical" "date" "members" "videos"] }
def filter-completer [] { ["conditional_featured" "embeddable"] }
def sort-completer-3 [] { ["alphabetical" "comments" "date" "duration" "featured" "likes" "plays" "relevant"] }
def filter-completer-1 [] { ["featured"] }
def sort-completer-4 [] { ["alphabetical" "date" "followers" "relevant" "videos"] }
def sort-completer-5 [] { ["alphabetical" "date"] }
def filter-completer-2 [] { ["moderators"] }
def filter-completer-3 [] { ["embeddable"] }
def sort-completer-6 [] { ["added" "alphabetical" "comments" "date" "default" "duration" "likes" "manual" "modified_time" "plays"] }
def sort-completer-7 [] { ["alphabetical" "comments" "date" "duration" "likes" "plays"] }
def filter-completer-4 [] { ["texttracks"] }
def sort-completer-8 [] { ["alphabetical" "date" "duration" "videos"] }
def sort-completer-9 [] { ["alphabetical" "comments" "date" "default" "duration" "likes" "manual" "modified_time" "plays"] }
def sort-completer-10 [] { ["alphabetical" "date" "name"] }
def filter-completer-5 [] { ["moderated"] }
def type-completer [] { ["appears" "category_featured" "channel" "facebook_feed" "following" "group" "likes" "ondemand_publish" "share" "tagged_with" "twitter_timeline" "uploads"] }
def filter-completer-6 [] { ["online"] }
def filter-completer-7 [] { ["film" "series"] }
def sort-completer-11 [] { ["added" "alphabetical" "date" "modified_time" "name" "publish.time" "rating"] }
def accepted-currencies-completer [] { ["AUD" "CAD" "CHF" "DKK" "EUR" "GBP" "JPY" "KRW" "NOK" "PLN" "SEK" "USD"] }
def content-rating-completer [] { ["drugs" "language" "nudity" "safe" "unrated" "violence"] }
def type-completer-1 [] { ["film" "series"] }
def filter-completer-8 [] { ["all" "expiring_soon" "film" "important" "purchased" "rented" "series" "subscription" "unwatched" "watched"] }
def sort-completer-12 [] { ["added" "alphabetical" "date" "name" "purchase_time" "rating" "release_date"] }
def sort-completer-13 [] { ["alphabetical" "comments" "date" "default" "likes" "manual" "plays"] }
def sort-completer-14 [] { ["date" "default" "modified_time" "name"] }
def sort-completer-15 [] { ["alphabetical" "date" "default" "duration" "last_user_action_event_date"] }
def filter-completer-9 [] { ["app_only" "embeddable" "featured" "playable"] }
def sort-completer-16 [] { ["alphabetical" "comments" "date" "default" "duration" "last_user_action_event_date" "likes" "modified_time" "plays"] }
def filter-completer-10 [] { ["country" "my_region"] }
def sort-completer-17 [] { ["alphabetical" "date" "name" "publish.time" "videos"] }
def filter-completer-11 [] { ["extra" "main" "trailer"] }
def filter-completer-12 [] { ["batch" "default" "single" "vip"] }
def filter-completer-13 [] { ["viewable"] }
def sort-completer-18 [] { ["date" "manual"] }
def sort-completer-19 [] { ["date" "default" "manual" "name" "purchase_time" "release_date"] }
def filter-completer-14 [] { ["all" "buy" "expiring_soon" "extra" "main" "main.viewable" "rent" "trailer" "unwatched" "viewable" "watched"] }
def sort-completer-20 [] { ["date" "default" "episode" "manual" "name" "purchase_time" "release_date"] }
def sort-completer-21 [] { ["created_time" "duration" "name"] }
def filter-completer-15 [] { ["CC" "CC-BY" "CC-BY-NC" "CC-BY-NC-ND" "CC-BY-NC-SA" "CC-BY-ND" "CC-BY-SA" "CC0" "categories" "duration" "in-progress" "minimum_likes" "trending" "upload_date"] }
def sort-completer-22 [] { ["alphabetical" "comments" "date" "duration" "likes" "plays" "relevant"] }
def filter-completer-16 [] { ["related"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-information endpoints" } } | get name | first)
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

# Get an API specification
#
# GET /
# operationId: get_endpoints
export def "api-information endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --openapi: oneof<nothing, bool> # Return an OpenAPI specification. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "openapi" $openapi "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/vnd.vimeo.endpoint+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all categories
#
# GET /categories
# operationId: get_categories
export def "categories categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific category
#
# GET /categories/{category}
# operationId: get_category
export def "categories category" [
  category: string
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
  let full_url = (build-url $base $"/categories/($category)")
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the channels in a category
#
# GET /categories/{category}/channels
# operationId: get_category_channels
export def "categories-channels channels" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the groups in a category
#
# GET /categories/{category}/groups
# operationId: get_category_groups
export def "categories-groups groups" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a category
#
# GET /categories/{category}/videos
# operationId: get_category_videos
export def "categories-videos videos" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer # The attribute by which to filter the results.  Option descriptions:  * `conditional_featured` - Featured (promoted) videos
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-3 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check for a video in a category
#
# GET /categories/{category}/videos/{video_id}
# operationId: check_category_for_video
export def "categories-videos video" [
  category: string
  video_id: float
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
  let full_url = (build-url $base $"/categories/($category)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all channels
#
# GET /channels
# operationId: get_channels
export def "channels channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results.  Option descriptions:  * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a channel
#
# POST /channels
# operationId: create_channel
export def "channels channel" [
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
  let full_url = (build-url $base "/channels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.channel+json" $body
}

# Delete a channel
#
# DELETE /channels/{channel_id}
# operationId: delete_channel
export def "channels channel-by-channel_id" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific channel
#
# GET /channels/{channel_id}
# operationId: get_channel
export def "channels channel-by-channel_id-1" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)")
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a channel
#
# PATCH /channels/{channel_id}
# operationId: edit_channel
export def "channels channel-by-channel_id-2" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.channel+json" $body
}

# Get all the categories in a channel
#
# GET /channels/{channel_id}/categories
# operationId: get_channel_categories
export def "channels-categories categories-by-channel_id" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/categories")
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of categories to a channel
#
# PUT /channels/{channel_id}/categories
# operationId: add_channel_categories
export def "channels-categories categories-by-channel_id-1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: list # The array of category URIs to add.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/categories")
  let body = {channels: $channels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a category from a channel
#
# DELETE /channels/{channel_id}/categories/{category}
# operationId: delete_channel_category
export def "channels-categories category" [
  category: string
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Categorize a channel
#
# PUT /channels/{channel_id}/categories/{category}
# operationId: categorize_channel
export def "channels-categories channel" [
  category: string
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a list of channel moderators
#
# DELETE /channels/{channel_id}/moderators
# operationId: remove_channel_moderators
export def "channels-moderators moderators-by-channel_id" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/moderators")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.user+json" $body
}

# Get all the moderators in a channel
#
# GET /channels/{channel_id}/moderators
# operationId: get_channel_moderators
export def "channels-moderators moderators-by-channel_id-1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/moderators" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace the moderators of a channel
#
# PATCH /channels/{channel_id}/moderators
# operationId: replace_channel_moderators
export def "channels-moderators moderators-by-channel_id-2" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of the user to add as a moderator. (e.g. /users/152184)
]: any -> table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/moderators")
  let body = {user_uri: $user_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a list of channel moderators
#
# PUT /channels/{channel_id}/moderators
# operationId: add_channel_moderators
export def "channels-moderators moderators-by-channel_id-3" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of a user to add as a moderator. (e.g. /users/152184)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/moderators")
  let body = {user_uri: $user_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a specific channel moderator
#
# DELETE /channels/{channel_id}/moderators/{user_id}
# operationId: remove_channel_moderator
export def "channels-moderators moderator-by-channel_id-user_id" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/moderators/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific channel moderator
#
# GET /channels/{channel_id}/moderators/{user_id}
# operationId: get_channel_moderator
export def "channels-moderators moderator-by-channel_id-user_id-1" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/moderators/($user_id)")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific channel moderator
#
# PUT /channels/{channel_id}/moderators/{user_id}
# operationId: add_channel_moderator
export def "channels-moderators moderator-by-channel_id-user_id-2" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/moderators/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the users who can view a private channel
#
# GET /channels/{channel_id}/privacy/users
# operationId: get_channel_privacy_users
export def "channels-privacy-users users-by-channel_id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/privacy/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a list of users to view a private channel
#
# PUT /channels/{channel_id}/privacy/users
# operationId: set_channel_privacy_users
export def "channels-privacy-users users-by-channel_id-1" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/privacy/users")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.user+json" $body
}

# Restrict a user from viewing a private channel
#
# DELETE /channels/{channel_id}/privacy/users/{user_id}
# operationId: delete_channel_privacy_user
export def "channels-privacy-users user-by-channel_id-user_id" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/privacy/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a specific user to view a private channel
#
# PUT /channels/{channel_id}/privacy/users/{user_id}
# operationId: set_channel_privacy_user
export def "channels-privacy-users user-by-channel_id-user_id-1" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/privacy/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the tags that have been added to a channel
#
# GET /channels/{channel_id}/tags
# operationId: get_channel_tags
export def "channels-tags tags" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/tags")
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of tags to a channel
#
# PUT /channels/{channel_id}/tags
# operationId: add_tags_to_channel
export def "channels-tags channel-by-channel_id" [
  channel_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.tag+json" $body
}

# Remove a tag from a channel
#
# DELETE /channels/{channel_id}/tags/{word}
# operationId: delete_tag_from_channel
export def "channels-tags channel-by-channel_id-word" [
  channel_id: float
  word: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/tags/($word)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a tag has been added to a channel
#
# GET /channels/{channel_id}/tags/{word}
# operationId: check_if_channel_has_tag
export def "channels-tags tag-by-channel_id-word" [
  channel_id: float
  word: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/tags/($word)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific tag to a channel
#
# PUT /channels/{channel_id}/tags/{word}
# operationId: add_channel_tag
export def "channels-tags tag-by-channel_id-word-1" [
  channel_id: float
  word: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/tags/($word)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the followers of a channel
#
# GET /channels/{channel_id}/users
# operationId: get_channel_subscribers
export def "channels-users subscribers" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a list of videos from a channel
#
# DELETE /channels/{channel_id}/videos
# operationId: remove_videos_from_channel
export def "channels-videos channel-by-channel_id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to remove. (e.g. /videos/258684937)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/videos")
  let body = {video_uri: $video_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the videos in a channel
#
# GET /channels/{channel_id}/videos
# operationId: get_channel_videos
export def "channels-videos videos" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-6 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of videos to a channel
#
# PUT /channels/{channel_id}/videos
# operationId: add_videos_to_channel
export def "channels-videos channel-by-channel_id-1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to add. (e.g. /videos/258684937)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/videos")
  let body = {video_uri: $video_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a specific video from a channel
#
# DELETE /channels/{channel_id}/videos/{video_id}
# operationId: delete_video_from_channel
export def "channels-videos channel-by-channel_id-video_id" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in a channel
#
# GET /channels/{channel_id}/videos/{video_id}
# operationId: get_channel_video
export def "channels-videos video" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific video to a channel
#
# PUT /channels/{channel_id}/videos/{video_id}
# operationId: add_video_to_channel
export def "channels-videos channel-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the comments on a video
#
# GET /channels/{channel_id}/videos/{video_id}/comments
# operationId: get_comments_alt1
export def "channels-videos-comments alt1-by-channel_id-video_id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/comments" $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a comment to a video
#
# POST /channels/{channel_id}/videos/{video_id}/comments
# operationId: create_comment_alt1
export def "channels-videos-comments alt1-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/comments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.comment+json" $body
}

# Get all the credited users in a video
#
# GET /channels/{channel_id}/videos/{video_id}/credits
# operationId: get_video_credits_alt1
export def "channels-videos-credits alt1-by-channel_id-video_id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/credits" $qp)
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Credit a user in a video
#
# POST /channels/{channel_id}/videos/{video_id}/credits
# operationId: add_video_credit_alt1
export def "channels-videos-credits alt1-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/credits")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.credit+json" $body
}

# Get all the users who have liked a video
#
# GET /channels/{channel_id}/videos/{video_id}/likes
# operationId: get_video_likes_alt1
export def "channels-videos-likes alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/likes" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the thumbnails of a video
#
# GET /channels/{channel_id}/videos/{video_id}/pictures
# operationId: get_video_thumbnails_alt1
export def "channels-videos-pictures alt1-by-channel_id-video_id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/pictures" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video thumbnail
#
# POST /channels/{channel_id}/videos/{video_id}/pictures
# operationId: create_video_thumbnail_alt1
export def "channels-videos-pictures alt1-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/pictures")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the users who can view a user's private videos by default
#
# GET /channels/{channel_id}/videos/{video_id}/privacy/users
# operationId: get_video_privacy_users_alt1
export def "channels-videos-privacy-users alt1-by-channel_id-video_id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/privacy/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a list of users to view a private video
#
# PUT /channels/{channel_id}/videos/{video_id}/privacy/users
# operationId: add_video_privacy_users_alt1
export def "channels-videos-privacy-users alt1-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/privacy/users")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the text tracks of a video
#
# GET /channels/{channel_id}/videos/{video_id}/texttracks
# operationId: get_text_tracks_alt1
export def "channels-videos-texttracks alt1-by-channel_id-video_id" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/texttracks")
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a text track to a video
#
# POST /channels/{channel_id}/videos/{video_id}/texttracks
# operationId: create_text_track_alt1
export def "channels-videos-texttracks alt1-by-channel_id-video_id-1" [
  channel_id: float
  video_id: float
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
  let full_url = (build-url $base $"/channels/($channel_id)/videos/($video_id)/texttracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video.texttrack+json" $body
}

# Get all content ratings
#
# GET /contentratings
# operationId: get_content_ratings
export def "contentratings ratings" [
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
  let full_url = (build-url $base "/contentratings")
  let accept_val = "application/vnd.vimeo.contentrating+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Creative Commons licenses
#
# GET /creativecommons
# operationId: get_cc_licenses
export def "creativecommons licenses" [
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
  let full_url = (build-url $base "/creativecommons")
  let accept_val = "application/vnd.vimeo.creativecommons+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all groups
#
# GET /groups
# operationId: get_groups
export def "groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results.  Option descriptions:  * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /groups
# operationId: create_group
export def "groups group" [
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
  let full_url = (build-url $base "/groups")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.group+json" $body
}

# Delete a group
#
# DELETE /groups/{group_id}
# operationId: delete_group
export def "groups group-by-group_id" [
  group_id: float
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
  let full_url = (build-url $base $"/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific group
#
# GET /groups/{group_id}
# operationId: get_group
export def "groups group-by-group_id-1" [
  group_id: float
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
  let full_url = (build-url $base $"/groups/($group_id)")
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the members of a group
#
# GET /groups/{group_id}/users
# operationId: get_group_members
export def "groups-users members" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a group
#
# GET /groups/{group_id}/videos
# operationId: get_group_videos
export def "groups-videos videos" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($group_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from a group
#
# DELETE /groups/{group_id}/videos/{video_id}
# operationId: delete_video_from_group
export def "groups-videos group-by-group_id-video_id" [
  group_id: float
  video_id: float
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
  let full_url = (build-url $base $"/groups/($group_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in a group
#
# GET /groups/{group_id}/videos/{video_id}
# operationId: get_group_video
export def "groups-videos video" [
  group_id: float
  video_id: float
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
  let full_url = (build-url $base $"/groups/($group_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to a group
#
# PUT /groups/{group_id}/videos/{video_id}
# operationId: add_video_to_group
export def "groups-videos group-by-group_id-video_id-1" [
  group_id: float
  video_id: float
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
  let full_url = (build-url $base $"/groups/($group_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all languages
#
# GET /languages
# operationId: get_languages
export def "languages languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-4 # The attribute by which to filter the results.  Option descriptions:  * `texttracks` - Only return text track supported languages
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/languages" $qp)
  let accept_val = "application/vnd.vimeo.language+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /me
# operationId: get_user_alt1
export def "me alt1" [
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
  let full_url = (build-url $base "/me")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a user
#
# PATCH /me
# operationId: edit_user_alt1
export def "me alt1-1" [
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
  let full_url = (build-url $base "/me")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.user+json" $body
}

# Get all the albums that belong to a user
#
# GET /me/albums
# operationId: get_albums_alt1
export def "me-albums alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/albums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an album
#
# POST /me/albums
# operationId: create_album_alt1
export def "me-albums alt1-1" [
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
  let full_url = (build-url $base "/me/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.album+json" $body
}

# Delete an album
#
# DELETE /me/albums/{album_id}
# operationId: delete_album_alt1
export def "me-albums alt1-by-album_id" [
  album_id: float
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
  let full_url = (build-url $base $"/me/albums/($album_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific album
#
# GET /me/albums/{album_id}
# operationId: get_album_alt1
export def "me-albums alt1-by-album_id-1" [
  album_id: float
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
  let full_url = (build-url $base $"/me/albums/($album_id)")
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an album
#
# PATCH /me/albums/{album_id}
# operationId: edit_album_alt1
export def "me-albums alt1-by-album_id-2" [
  album_id: float
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
  let full_url = (build-url $base $"/me/albums/($album_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.album+json" $body
}

# Get all the videos in an album
#
# GET /me/albums/{album_id}/videos
# operationId: get_album_videos_alt1
export def "me-albums-videos alt1-by-album_id" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-9 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "weak_search" $weak_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/albums/($album_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace all the videos in an album
#
# PUT /me/albums/{album_id}/videos
# operationId: replace_videos_in_album_alt1
export def "me-albums-videos alt1-by-album_id-1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/albums/($album_id)/videos")
  let body = {videos: $videos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a video from an album
#
# DELETE /me/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album_alt1
export def "me-albums-videos alt1-by-album_id-video_id" [
  album_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/albums/($album_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in an album
#
# GET /me/albums/{album_id}/videos/{video_id}
# operationId: get_album_video_alt1
export def "me-albums-videos alt1-by-album_id-video_id-1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/albums/($album_id)/videos/($video_id)" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific video to an album
#
# PUT /me/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album_alt1
export def "me-albums-videos alt1-by-album_id-video_id-2" [
  album_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/albums/($album_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a video as the album thumbnail
#
# POST /me/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# operationId: set_video_as_album_thumbnail_alt1
export def "me-albums-videos-set-album-thumbnail alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/albums/($album_id)/videos/($video_id)/set_album_thumbnail")
  let body = {time_code: $time_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the videos in which a user appears
#
# GET /me/appearances
# operationId: get_appearances_alt1
export def "me-appearances alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/appearances" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the categories that a user follows
#
# GET /me/categories
# operationId: get_category_subscriptions_alt1
export def "me-categories alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-10 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/categories" $qp)
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe a user from a category
#
# DELETE /me/categories/{category}
# operationId: unsubscribe_from_category_alt1
export def "me-categories alt1-by-category" [
  category: string
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
  let full_url = (build-url $base $"/me/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user follows a category
#
# GET /me/categories/{category}
# operationId: check_if_user_subscribed_to_category_alt1
export def "me-categories alt1-by-category-1" [
  category: string
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
  let full_url = (build-url $base $"/me/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe a user to a single category
#
# PUT /me/categories/{category}
# operationId: subscribe_to_category_alt1
export def "me-categories alt1-by-category-2" [
  category: float
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
  let full_url = (build-url $base $"/me/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the channels to which a user subscribes
#
# GET /me/channels
# operationId: get_channel_subscriptions_alt1
export def "me-channels alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe a user from a specific channel
#
# DELETE /me/channels/{channel_id}
# operationId: unsubscribe_from_channel_alt1
export def "me-channels alt1-by-channel_id" [
  channel_id: float
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
  let full_url = (build-url $base $"/me/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user follows a channel
#
# GET /me/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel_alt1
export def "me-channels alt1-by-channel_id-1" [
  channel_id: float
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
  let full_url = (build-url $base $"/me/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe a user to a specific channel
#
# PUT /me/channels/{channel_id}
# operationId: subscribe_to_channel_alt1
export def "me-channels alt1-by-channel_id-2" [
  channel_id: float
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
  let full_url = (build-url $base $"/me/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the custom logos that belong to a user
#
# GET /me/customlogos
# operationId: get_custom_logos_alt1
export def "me-customlogos alt1" [
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
  let full_url = (build-url $base "/me/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a custom logo
#
# POST /me/customlogos
# operationId: create_custom_logo_alt1
export def "me-customlogos alt1-1" [
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
  let full_url = (build-url $base "/me/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific custom logo
#
# GET /me/customlogos/{logo_id}
# operationId: get_custom_logo_alt1
export def "me-customlogos alt1-by-logo_id" [
  logo_id: float
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
  let full_url = (build-url $base $"/me/customlogos/($logo_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all videos in a user's feed
#
# GET /me/feed
# operationId: get_feed_alt1
export def "me-feed alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Necessary for proper pagination. You shouldn't provide this value yourself, and instead use the pagination links in the feed response. Please see our [pagination documentation](https://developer.vimeo.com/api/common-formats#using-the-pagination-parameter) for more information. (e.g. 280)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --type: string@type-completer # The feed type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/feed" $qp)
  let accept_val = "application/vnd.vimeo.activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the followers of a user
#
# GET /me/followers
# operationId: get_followers_alt1
export def "me-followers alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/followers" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the users that a user is following
#
# GET /me/following
# operationId: get_user_following_alt1
export def "me-following alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/following" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow a list of users
#
# POST /me/following
# operationId: follow_users_alt1
export def "me-following alt1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list # An array of user URIs for the list of users to follow.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/following")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unfollow a user
#
# DELETE /me/following/{follow_user_id}
# operationId: unfollow_user_alt1
export def "me-following alt1-by-follow_user_id" [
  follow_user_id: float
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
  let full_url = (build-url $base $"/me/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user is following another user
#
# GET /me/following/{follow_user_id}
# operationId: check_if_user_is_following_alt1
export def "me-following alt1-by-follow_user_id-1" [
  follow_user_id: float
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
  let full_url = (build-url $base $"/me/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow a specific user
#
# PUT /me/following/{follow_user_id}
# operationId: follow_user_alt1
export def "me-following alt1-by-follow_user_id-2" [
  follow_user_id: float
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
  let full_url = (build-url $base $"/me/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the groups that a user has joined
#
# GET /me/groups
# operationId: get_user_groups_alt1
export def "me-groups alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a user from a group
#
# DELETE /me/groups/{group_id}
# operationId: leave_group_alt1
export def "me-groups alt1-by-group_id" [
  group_id: float
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
  let full_url = (build-url $base $"/me/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has joined a group
#
# GET /me/groups/{group_id}
# operationId: check_if_user_joined_group_alt1
export def "me-groups alt1-by-group_id-1" [
  group_id: float
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
  let full_url = (build-url $base $"/me/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user to a group
#
# PUT /me/groups/{group_id}
# operationId: join_group_alt1
export def "me-groups alt1-by-group_id-2" [
  group_id: float
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
  let full_url = (build-url $base $"/me/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos that a user has liked
#
# GET /me/likes
# operationId: get_likes_alt1
export def "me-likes alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/likes" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cause a user to unlike a video
#
# DELETE /me/likes/{video_id}
# operationId: unlike_video_alt1
export def "me-likes alt1-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/me/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has liked a video
#
# GET /me/likes/{video_id}
# operationId: check_if_user_liked_video_alt1
export def "me-likes alt1-by-video_id-1" [
  video_id: float
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
  let full_url = (build-url $base $"/me/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cause a user to like a video
#
# PUT /me/likes/{video_id}
# operationId: like_video_alt1
export def "me-likes alt1-by-video_id-2" [
  video_id: float
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
  let full_url = (build-url $base $"/me/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the On Demand pages of a user
#
# GET /me/ondemand/pages
# operationId: get_user_vods_alt1
export def "me-ondemand-pages alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-7 # The type of On Demand pages to return.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-11 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/ondemand/pages" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an On Demand page
#
# POST /me/ondemand/pages
# operationId: create_vod_alt1
# --buy shape: {active?: bool, download?: bool, price?: record}
# --episodes shape: {buy?: record, rent?: record}
# --rent shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
# --subscription shape: {monthly?: record}
export def "me-ondemand-pages alt1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies.  Option descriptions:  * `AUD` - Australian Dollar  * `CAD` - Canadian Dollar  * `CHF` - Swiss Franc  * `DKK` - Danish Krone  * `EUR` - Euro  * `GBP` - British Pound  * `JPY` - Japanese Yen  * `KRW` - South Korean Won  * `NOK` - Norwegian Krone  * `PLN` - Polish Zloty  * `SEK` - Swedish Krona  * `USD` - US Dollar
  --buy: record # shape: {active?: bool, download?: bool, price?: record}
  content_rating: string@content-rating-completer # One or more ratings, either as a comma-separated list or as a JSON array depending on the request format.
  description: string # The description of the On Demand page. (e.g. DARBY FOREVER follows the fantasies of Darby, a shopgirl at "Bobbins & Notions".)
  --domain-link: string # The custom domain of the On Demand page. (e.g. https://example.com)
  --episodes: record # shape: {buy?: record, rent?: record}
  --link: string # The custom string to use in this On Demand page's Vimeo URL. (e.g. darbyforever)
  name: string # The name of the On Demand page. (e.g. Darby Forever)
  --rent: record # shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
  --subscription: record # shape: {monthly?: record}
  type: string@type-completer-1 # The type of On Demand page.
]: any -> record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/ondemand/pages")
  let body = {accepted_currencies: $accepted_currencies, buy: $buy, content_rating: $content_rating, description: $description, domain_link: $domain_link, episodes: $episodes, link: $link, name: $name, rent: $rent, subscription: $subscription, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the On Demand purchases and rentals that a user has made
#
# GET /me/ondemand/purchases
# operationId: get_vod_purchases
export def "me-ondemand-purchases purchases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-8 # The type of On Demand videos to show.  Option descriptions:  * `important` - Will show all pages which are about to expire.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-12 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/ondemand/purchases" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /me/ondemand/purchases/{ondemand_id}
# operationId: check_if_vod_was_purchased_alt1
export def "me-ondemand-purchases alt1" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/me/ondemand/purchases/($ondemand_id)")
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the pictures that belong to a user
#
# GET /me/pictures
# operationId: get_pictures_alt1
export def "me-pictures alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/pictures" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user picture
#
# POST /me/pictures
# operationId: create_picture_alt1
export def "me-pictures alt1-1" [
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
  let full_url = (build-url $base "/me/pictures")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user picture
#
# DELETE /me/pictures/{portraitset_id}
# operationId: delete_picture_alt1
export def "me-pictures alt1-by-portraitset_id" [
  portraitset_id: float
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
  let full_url = (build-url $base $"/me/pictures/($portraitset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific user picture
#
# GET /me/pictures/{portraitset_id}
# operationId: get_picture_alt1
export def "me-pictures alt1-by-portraitset_id-1" [
  portraitset_id: float
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
  let full_url = (build-url $base $"/me/pictures/($portraitset_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a user picture
#
# PATCH /me/pictures/{portraitset_id}
# operationId: edit_picture_alt1
export def "me-pictures alt1-by-portraitset_id-2" [
  portraitset_id: float
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
  let full_url = (build-url $base $"/me/pictures/($portraitset_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the portfolios that belong to a user
#
# GET /me/portfolios
# operationId: get_portfolios_alt1
export def "me-portfolios list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/portfolios" $qp)
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific portfolio
#
# GET /me/portfolios/{portfolio_id}
# operationId: get_portfolio_alt1
export def "me-portfolios alt1" [
  portfolio_id: float
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
  let full_url = (build-url $base $"/me/portfolios/($portfolio_id)")
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos
# operationId: get_portfolio_videos_alt1
export def "me-portfolios-videos alt1-by-portfolio_id" [
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-13 # The way to sort the results.  Option descriptions:  * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/portfolios/($portfolio_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from a portfolio
#
# DELETE /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio_alt1
export def "me-portfolios-videos alt1-by-portfolio_id-video_id" [
  portfolio_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: get_portfolio_video_alt1
export def "me-portfolios-videos alt1-by-portfolio_id-video_id-1" [
  portfolio_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to a portfolio
#
# PUT /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio_alt1
export def "me-portfolios-videos alt1-by-portfolio_id-video_id-2" [
  portfolio_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the embed presets that a user has created
#
# GET /me/presets
# operationId: get_embed_presets_alt1
export def "me-presets alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/presets" $qp)
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific embed preset
#
# GET /me/presets/{preset_id}
# operationId: get_embed_preset_alt1
export def "me-presets alt1-by-preset_id" [
  preset_id: float
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
  let full_url = (build-url $base $"/me/presets/($preset_id)")
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an embed preset
#
# PATCH /me/presets/{preset_id}
# operationId: edit_embed_preset_alt1
export def "me-presets alt1-by-preset_id-1" [
  preset_id: float
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
  let full_url = (build-url $base $"/me/presets/($preset_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.preset+json" $body
}

# Get all the videos that have been added to an embed preset
#
# GET /me/presets/{preset_id}/videos
# operationId: get_embed_preset_videos_alt1
export def "me-presets-videos alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/presets/($preset_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the projects that belong to a user
#
# GET /me/projects
# operationId: get_projects_alt1
export def "me-projects alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-14 # The way to sort the results.
]: nothing -> table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project
#
# POST /me/projects
# operationId: create_project_alt1
export def "me-projects alt1-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/projects")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a project
#
# DELETE /me/projects/{project_id}
# operationId: delete_project_alt1
export def "me-projects alt1-by-project_id" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/projects/($project_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific project
#
# GET /me/projects/{project_id}
# operationId: get_project_alt1
export def "me-projects alt1-by-project_id-1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a project
#
# PATCH /me/projects/{project_id}
# operationId: edit_project_alt1
export def "me-projects alt1-by-project_id-2" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/me/projects/($project_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a list of videos from a project
#
# DELETE /me/projects/{project_id}/videos
# operationId: remove_videos_from_project_alt1
export def "me-projects-videos alt1-by-project_id" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a project
#
# GET /me/projects/{project_id}/videos
# operationId: get_project_videos_alt1
export def "me-projects-videos alt1-by-project_id-1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of videos to a project
#
# PUT /me/projects/{project_id}/videos
# operationId: add_videos_to_project_alt1
export def "me-projects-videos alt1-by-project_id-2" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/me/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a specific video from a project
#
# DELETE /me/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project_alt1
export def "me-projects-videos alt1-by-project_id-video_id" [
  project_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/projects/($project_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific video to a project
#
# PUT /me/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project_alt1
export def "me-projects-videos alt1-by-project_id-video_id-1" [
  project_id: float
  video_id: float
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
  let full_url = (build-url $base $"/me/projects/($project_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos that a user has uploaded
#
# GET /me/videos
# operationId: get_videos_alt1
export def "me-videos alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not  playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "filter_playable" $filter_playable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a video
#
# POST /me/videos
# operationId: upload_video_alt1
export def "me-videos alt1-1" [
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
  let full_url = (build-url $base "/me/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video+json" $body
}

# Check if a user owns a video
#
# GET /me/videos/{video_id}
# operationId: check_if_user_owns_video_alt1
export def "me-videos alt1-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/me/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user's watch history
#
# DELETE /me/watched/videos
# operationId: delete_watch_history
export def "me-watched-videos history" [
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
  let full_url = (build-url $base "/me/watched/videos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos that a user has watched
#
# GET /me/watched/videos
# operationId: get_watch_history
export def "me-watched-videos history-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/watched/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific video from a user's watch history
#
# DELETE /me/watched/videos/{video_id}
# operationId: delete_from_watch_history
export def "me-watched-videos history-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/me/watched/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a user's Watch Later queue
#
# GET /me/watchlater
# operationId: get_watch_later_queue_alt1
export def "me-watchlater alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/watchlater" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from a user's Watch Later queue
#
# DELETE /me/watchlater/{video_id}
# operationId: delete_video_from_watch_later_alt1
export def "me-watchlater alt1-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/me/watchlater/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /me/watchlater/{video_id}
# operationId: check_watch_later_queue_alt1
export def "me-watchlater alt1-by-video_id-1" [
  video_id: float
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
  let full_url = (build-url $base $"/me/watchlater/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to a user's Watch Later queue
#
# PUT /me/watchlater/{video_id}
# operationId: add_video_to_watch_later_alt1
export def "me-watchlater alt1-by-video_id-2" [
  video_id: float
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
  let full_url = (build-url $base $"/me/watchlater/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exchange an authorization code for an access token
#
# POST /oauth/access_token
# operationId: exchange_auth_code
export def "oauth-access-token code" [
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
  let full_url = (build-url $base "/oauth/access_token")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.auth+json" $body
}

# Authorize a client with OAuth
#
# POST /oauth/authorize/client
# operationId: client_auth
export def "oauth-authorize-client auth" [
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
  let full_url = (build-url $base "/oauth/authorize/client")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.auth+json" $body
}

# Convert OAuth 1 access tokens to OAuth 2 access tokens
#
# POST /oauth/authorize/vimeo_oauth1
# operationId: convert_access_token
export def "oauth-authorize-vimeo-oauth1 token" [
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
  let full_url = (build-url $base "/oauth/authorize/vimeo_oauth1")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.auth+json" $body
}

# Verify an OAuth 2 token
#
# GET /oauth/verify
# operationId: verify_token
export def "oauth-verify token" [
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
  let full_url = (build-url $base "/oauth/verify")
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all On Demand genres
#
# GET /ondemand/genres
# operationId: get_vod_genres
export def "ondemand-genres genres" [
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
  let full_url = (build-url $base "/ondemand/genres")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific On Demand genre
#
# GET /ondemand/genres/{genre_id}
# operationId: get_vod_genre
export def "ondemand-genres genre" [
  genre_id: string
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
  let full_url = (build-url $base $"/ondemand/genres/($genre_id)")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the On Demand pages in a genre
#
# GET /ondemand/genres/{genre_id}/pages
# operationId: get_genre_vods
export def "ondemand-genres-pages vods" [
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-10 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-17 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/genres/($genre_id)/pages" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific On Demand page in a genre
#
# GET /ondemand/genres/{genre_id}/pages/{ondemand_id}
# operationId: get_genre_vod
export def "ondemand-genres-pages vod" [
  genre_id: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/genres/($genre_id)/pages/($ondemand_id)")
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a draft of an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}
# operationId: delete_vod_draft
export def "ondemand-pages draft" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific On Demand page
#
# GET /ondemand/pages/{ondemand_id}
# operationId: get_vod
export def "ondemand-pages vod-by-ondemand_id" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)")
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}
# operationId: edit_vod
export def "ondemand-pages vod-by-ondemand_id-1" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.ondemand.page+json" $body
}

# Get all the backgrounds of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds
# operationId: get_vod_backgrounds
export def "ondemand-pages-backgrounds backgrounds" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/backgrounds" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a background to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/backgrounds
# operationId: create_vod_background
export def "ondemand-pages-backgrounds background-by-ondemand_id" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/backgrounds")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a background from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: delete_vod_background
export def "ondemand-pages-backgrounds background-by-background_id-ondemand_id" [
  background_id: float
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/backgrounds/($background_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific background of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: get_vod_background
export def "ondemand-pages-backgrounds background-by-background_id-ondemand_id-1" [
  background_id: float
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/backgrounds/($background_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a background of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: edit_vod_background
export def "ondemand-pages-backgrounds background-by-background_id-ondemand_id-2" [
  background_id: float
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/backgrounds/($background_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the genres of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/genres
# operationId: get_vod_genres_by_ondemand_id
export def "ondemand-pages-genres list" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/genres")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a genre from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: delete_vod_genre
export def "ondemand-pages-genres genre-by-genre_id-ondemand_id" [
  genre_id: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/genres/($genre_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check whether an On Demand page belongs to a genre
#
# GET /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: get_vod_genre_by_ondemand_id
export def "ondemand-pages-genres id" [
  genre_id: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/genres/($genre_id)")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a genre to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: add_vod_genre
export def "ondemand-pages-genres genre-by-genre_id-ondemand_id-1" [
  genre_id: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/genres/($genre_id)")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the users who have liked a video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/likes
# operationId: get_vod_likes
export def "ondemand-pages-likes likes" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-11 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/likes" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the posters of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures
# operationId: get_vod_posters
export def "ondemand-pages-pictures posters" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/pictures" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a poster to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/pictures
# operationId: add_vod_poster
export def "ondemand-pages-pictures poster-by-ondemand_id" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/pictures")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific poster of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# operationId: get_vod_poster
export def "ondemand-pages-pictures poster-by-ondemand_id-poster_id" [
  ondemand_id: float
  poster_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/pictures/($poster_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a poster of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# operationId: edit_vod_poster
export def "ondemand-pages-pictures poster-by-ondemand_id-poster_id-1" [
  ondemand_id: float
  poster_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/pictures/($poster_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the promotions on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions
# operationId: get_vod_promotions
export def "ondemand-pages-promotions promotions" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-12 # The filter to apply to the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/promotions" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a promotion to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/promotions
# operationId: create_vod_promotion
export def "ondemand-pages-promotions promotion-by-ondemand_id" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/promotions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.ondemand.promotion+json" $body
}

# Remove a promotion from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# operationId: delete_vod_promotion
export def "ondemand-pages-promotions promotion-by-ondemand_id-promotion_id" [
  ondemand_id: float
  promotion_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/promotions/($promotion_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# operationId: get_vod_promotion
export def "ondemand-pages-promotions promotion-by-ondemand_id-promotion_id-1" [
  ondemand_id: float
  promotion_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/promotions/($promotion_id)")
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the codes of a promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}/codes
# operationId: get_vod_promotion_codes
export def "ondemand-pages-promotions-codes codes" [
  ondemand_id: float
  promotion_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/promotions/($promotion_id)/codes" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.promocode+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a list of regions from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions
# operationId: delete_vod_regions
export def "ondemand-pages-regions regions-by-ondemand_id" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.ondemand.region+json" $body
}

# Get all the regions of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions
# operationId: get_vod_regions
export def "ondemand-pages-regions regions-by-ondemand_id-1" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of regions to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions
# operationId: set_vod_regions
export def "ondemand-pages-regions regions-by-ondemand_id-2" [
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.ondemand.region+json" $body
}

# Remove a specific region from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: delete_vod_region
export def "ondemand-pages-regions region-by-country-ondemand_id" [
  country: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions/($country)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific region of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: get_vod_region
export def "ondemand-pages-regions region-by-country-ondemand_id-1" [
  country: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions/($country)")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific region to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: add_vod_region
export def "ondemand-pages-regions region-by-country-ondemand_id-2" [
  country: string
  ondemand_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/regions/($country)")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the seasons on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons
# operationId: get_vod_seasons
export def "ondemand-pages-seasons seasons" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-18 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/seasons" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.season+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}
# operationId: get_vod_season
export def "ondemand-pages-seasons season" [
  ondemand_id: float
  season_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/seasons/($season_id)")
  let accept_val = "application/vnd.vimeo.ondemand.season+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}/videos
# operationId: get_vod_season_videos
export def "ondemand-pages-seasons-videos videos" [
  ondemand_id: float
  season_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-19 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/seasons/($season_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos
# operationId: get_vod_videos
export def "ondemand-pages-videos videos" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-14 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-20 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: delete_video_from_vod
export def "ondemand-pages-videos vod-by-ondemand_id-video_id" [
  ondemand_id: float
  video_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: get_vod_video
export def "ondemand-pages-videos video" [
  ondemand_id: float
  video_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: add_video_to_vod
export def "ondemand-pages-videos vod-by-ondemand_id-video_id-1" [
  ondemand_id: float
  video_id: float
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
  let full_url = (build-url $base $"/ondemand/pages/($ondemand_id)/videos/($video_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.ondemand.video+json" $body
}

# Get all the On Demand regions
#
# GET /ondemand/regions
# operationId: get_regions
export def "ondemand-regions regions" [
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
  let full_url = (build-url $base "/ondemand/regions")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific On Demand region
#
# GET /ondemand/regions/{country}
# operationId: get_region
export def "ondemand-regions region" [
  country: string
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
  let full_url = (build-url $base $"/ondemand/regions/($country)")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific tag
#
# GET /tags/{word}
# operationId: get_tag
export def "tags tag" [
  word: string
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
  let full_url = (build-url $base $"/tags/($word)")
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos with a specific tag
#
# GET /tags/{word}/videos
# operationId: get_videos_with_tag
export def "tags-videos tag" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-21 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($word)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke the current access token
#
# DELETE /tokens
# operationId: delete_token
export def "tokens token" [
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
  let full_url = (build-url $base "/tokens")
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for users
#
# GET /users
# operationId: search_users
export def "users users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user
#
# GET /users/{user_id}
# operationId: get_user
export def "users user-by-user_id" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a user
#
# PATCH /users/{user_id}
# operationId: edit_user
export def "users user-by-user_id-1" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.user+json" $body
}

# Get all the albums that belong to a user
#
# GET /users/{user_id}/albums
# operationId: get_albums
export def "users-albums albums" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/albums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an album
#
# POST /users/{user_id}/albums
# operationId: create_album
export def "users-albums album-by-user_id" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.album+json" $body
}

# Delete an album
#
# DELETE /users/{user_id}/albums/{album_id}
# operationId: delete_album
export def "users-albums album-by-album_id-user_id" [
  album_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific album
#
# GET /users/{user_id}/albums/{album_id}
# operationId: get_album
export def "users-albums album-by-album_id-user_id-1" [
  album_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)")
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an album
#
# PATCH /users/{user_id}/albums/{album_id}
# operationId: edit_album
export def "users-albums album-by-album_id-user_id-2" [
  album_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.album+json" $body
}

# Get all the custom upload thumbnails of an album
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails
# operationId: get_album_custom_thumbs
export def "users-albums-custom-thumbnails thumbs" [
  album_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/custom_thumbnails" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a custom uploaded thumbnail
#
# POST /users/{user_id}/albums/{album_id}/custom_thumbnails
# operationId: create_album_custom_thumb
export def "users-albums-custom-thumbnails thumb-by-album_id-user_id" [
  album_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/custom_thumbnails")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a custom uploaded album thumbnail
#
# DELETE /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: delete_album_custom_thumbnail
export def "users-albums-custom-thumbnails thumbnail-by-album_id-thumbnail_id-user_id" [
  album_id: float
  thumbnail_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/custom_thumbnails/($thumbnail_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific custom uploaded album thumbnail
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: get_album_custom_thumbnail
export def "users-albums-custom-thumbnails thumbnail-by-album_id-thumbnail_id-user_id-1" [
  album_id: float
  thumbnail_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/custom_thumbnails/($thumbnail_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace a custom uploaded album thumbnail
#
# PATCH /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: replace_album_custom_thumb
export def "users-albums-custom-thumbnails thumb-by-album_id-thumbnail_id-user_id" [
  album_id: float
  thumbnail_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/custom_thumbnails/($thumbnail_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the custom logos of an album
#
# GET /users/{user_id}/albums/{album_id}/logos
# operationId: get_album_logos
export def "users-albums-logos logos" [
  album_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/logos" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a custom album logo
#
# POST /users/{user_id}/albums/{album_id}/logos
# operationId: create_album_logo
export def "users-albums-logos logo-by-album_id-user_id" [
  album_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/logos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a custom album logo
#
# DELETE /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: delete_album_logo
export def "users-albums-logos logo-by-album_id-logo_id-user_id" [
  album_id: float
  logo_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/logos/($logo_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific custom album logo
#
# GET /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: get_album_logo
export def "users-albums-logos logo-by-album_id-logo_id-user_id-1" [
  album_id: float
  logo_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/logos/($logo_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace a custom album logo
#
# PATCH /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: replace_album_logo
export def "users-albums-logos logo-by-album_id-logo_id-user_id-2" [
  album_id: float
  logo_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/logos/($logo_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the videos in an album
#
# GET /users/{user_id}/albums/{album_id}/videos
# operationId: get_album_videos
export def "users-albums-videos videos" [
  album_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-9 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "weak_search" $weak_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace all the videos in an album
#
# PUT /users/{user_id}/albums/{album_id}/videos
# operationId: replace_videos_in_album
export def "users-albums-videos album-by-album_id-user_id" [
  album_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos")
  let body = {videos: $videos} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a video from an album
#
# DELETE /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album
export def "users-albums-videos album-by-album_id-user_id-video_id" [
  album_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in an album
#
# GET /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: get_album_video
export def "users-albums-videos video" [
  album_id: float
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos/($video_id)" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific video to an album
#
# PUT /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album
export def "users-albums-videos album-by-album_id-user_id-video_id-1" [
  album_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a video as the album thumbnail
#
# POST /users/{user_id}/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# operationId: set_video_as_album_thumbnail
export def "users-albums-videos-set-album-thumbnail thumbnail" [
  album_id: float
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/albums/($album_id)/videos/($video_id)/set_album_thumbnail")
  let body = {time_code: $time_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the videos in which a user appears
#
# GET /users/{user_id}/appearances
# operationId: get_appearances
export def "users-appearances appearances" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/appearances" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the categories that a user follows
#
# GET /users/{user_id}/categories
# operationId: get_category_subscriptions
export def "users-categories subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-10 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/categories" $qp)
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe a user from a category
#
# DELETE /users/{user_id}/categories/{category}
# operationId: unsubscribe_from_category
export def "users-categories category-by-category-user_id" [
  category: string
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user follows a category
#
# GET /users/{user_id}/categories/{category}
# operationId: check_if_user_subscribed_to_category
export def "users-categories category-by-category-user_id-1" [
  category: string
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe a user to a single category
#
# PUT /users/{user_id}/categories/{category}
# operationId: subscribe_to_category
export def "users-categories category-by-category-user_id-2" [
  category: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/categories/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the channels to which a user subscribes
#
# GET /users/{user_id}/channels
# operationId: get_channel_subscriptions
export def "users-channels subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe a user from a specific channel
#
# DELETE /users/{user_id}/channels/{channel_id}
# operationId: unsubscribe_from_channel
export def "users-channels channel-by-channel_id-user_id" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user follows a channel
#
# GET /users/{user_id}/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel
export def "users-channels channel-by-channel_id-user_id-1" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe a user to a specific channel
#
# PUT /users/{user_id}/channels/{channel_id}
# operationId: subscribe_to_channel
export def "users-channels channel-by-channel_id-user_id-2" [
  channel_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the custom logos that belong to a user
#
# GET /users/{user_id}/customlogos
# operationId: get_custom_logos
export def "users-customlogos logos" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a custom logo
#
# POST /users/{user_id}/customlogos
# operationId: create_custom_logo
export def "users-customlogos logo-by-user_id" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific custom logo
#
# GET /users/{user_id}/customlogos/{logo_id}
# operationId: get_custom_logo
export def "users-customlogos logo-by-logo_id-user_id" [
  logo_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/customlogos/($logo_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all videos in a user's feed
#
# GET /users/{user_id}/feed
# operationId: get_feed
export def "users-feed feed" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Necessary for proper pagination. You shouldn't provide this value yourself, and instead use the pagination links in the feed response. Please see our [pagination documentation](https://developer.vimeo.com/api/common-formats#using-the-pagination-parameter) for more information. (e.g. 280)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --type: string@type-completer # The feed type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/feed" $qp)
  let accept_val = "application/vnd.vimeo.activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the followers of a user
#
# GET /users/{user_id}/followers
# operationId: get_followers
export def "users-followers followers" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/followers" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the users that a user is following
#
# GET /users/{user_id}/following
# operationId: get_user_following
export def "users-following list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/following" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow a list of users
#
# POST /users/{user_id}/following
# operationId: follow_users
export def "users-following users" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list # An array of user URIs for the list of users to follow.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/following")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unfollow a user
#
# DELETE /users/{user_id}/following/{follow_user_id}
# operationId: unfollow_user
export def "users-following user-by-follow_user_id-user_id" [
  follow_user_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user is following another user
#
# GET /users/{user_id}/following/{follow_user_id}
# operationId: check_if_user_is_following
export def "users-following following" [
  follow_user_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow a specific user
#
# PUT /users/{user_id}/following/{follow_user_id}
# operationId: follow_user
export def "users-following user-by-follow_user_id-user_id-1" [
  follow_user_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/following/($follow_user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the groups that a user has joined
#
# GET /users/{user_id}/groups
# operationId: get_user_groups
export def "users-groups groups" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a user from a group
#
# DELETE /users/{user_id}/groups/{group_id}
# operationId: leave_group
export def "users-groups group-by-group_id-user_id" [
  group_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has joined a group
#
# GET /users/{user_id}/groups/{group_id}
# operationId: check_if_user_joined_group
export def "users-groups group-by-group_id-user_id-1" [
  group_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user to a group
#
# PUT /users/{user_id}/groups/{group_id}
# operationId: join_group
export def "users-groups group-by-group_id-user_id-2" [
  group_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/groups/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos that a user has liked
#
# GET /users/{user_id}/likes
# operationId: get_likes
export def "users-likes likes" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/likes" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cause a user to unlike a video
#
# DELETE /users/{user_id}/likes/{video_id}
# operationId: unlike_video
export def "users-likes video-by-user_id-video_id" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has liked a video
#
# GET /users/{user_id}/likes/{video_id}
# operationId: check_if_user_liked_video
export def "users-likes video-by-user_id-video_id-1" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cause a user to like a video
#
# PUT /users/{user_id}/likes/{video_id}
# operationId: like_video
export def "users-likes video-by-user_id-video_id-2" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/likes/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the On Demand pages of a user
#
# GET /users/{user_id}/ondemand/pages
# operationId: get_user_vods
export def "users-ondemand-pages vods" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-7 # The type of On Demand pages to return.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-11 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/ondemand/pages" $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an On Demand page
#
# POST /users/{user_id}/ondemand/pages
# operationId: create_vod
# --buy shape: {active?: bool, download?: bool, price?: record}
# --episodes shape: {buy?: record, rent?: record}
# --rent shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
# --subscription shape: {monthly?: record}
export def "users-ondemand-pages vod" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies.  Option descriptions:  * `AUD` - Australian Dollar  * `CAD` - Canadian Dollar  * `CHF` - Swiss Franc  * `DKK` - Danish Krone  * `EUR` - Euro  * `GBP` - British Pound  * `JPY` - Japanese Yen  * `KRW` - South Korean Won  * `NOK` - Norwegian Krone  * `PLN` - Polish Zloty  * `SEK` - Swedish Krona  * `USD` - US Dollar
  --buy: record # shape: {active?: bool, download?: bool, price?: record}
  content_rating: string@content-rating-completer # One or more ratings, either as a comma-separated list or as a JSON array depending on the request format.
  description: string # The description of the On Demand page. (e.g. DARBY FOREVER follows the fantasies of Darby, a shopgirl at "Bobbins & Notions".)
  --domain-link: string # The custom domain of the On Demand page. (e.g. https://example.com)
  --episodes: record # shape: {buy?: record, rent?: record}
  --link: string # The custom string to use in this On Demand page's Vimeo URL. (e.g. darbyforever)
  name: string # The name of the On Demand page. (e.g. Darby Forever)
  --rent: record # shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
  --subscription: record # shape: {monthly?: record}
  type: string@type-completer-1 # The type of On Demand page.
]: any -> record<background: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, colors: record<primary: string, secondary: string>, content_rating: list<string>, created_time: string, description: string, domain_link: string, episodes: record<buy: record<active: bool, price: float>, rent: record<active: bool, period: string, price: float>>, film: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, genres: table<canonical: string, interactions: record, link: string, metadata: record, name: string, uri: string>, link: string, metadata: record<connections: record<metadata: record>, interactions: record<buy: record, rent: record, subscribe: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, preorder: record<active: bool, cancel_time: string, publish_time: string, time: string>, published: record<enabled: bool, time: string>, rating: float, resource_key: string, sku: string, subscription: record<active: bool, link: string, period: string, price: record>, theme: string, thumbnail: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, trailer: record<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float>, type: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/ondemand/pages")
  let body = {accepted_currencies: $accepted_currencies, buy: $buy, content_rating: $content_rating, description: $description, domain_link: $domain_link, episodes: $episodes, link: $link, name: $name, rent: $rent, subscription: $subscription, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /users/{user_id}/ondemand/purchases
# operationId: check_if_vod_was_purchased
export def "users-ondemand-purchases purchased" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/ondemand/purchases")
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the pictures that belong to a user
#
# GET /users/{user_id}/pictures
# operationId: get_pictures
export def "users-pictures pictures" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/pictures" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a user picture
#
# POST /users/{user_id}/pictures
# operationId: create_picture
export def "users-pictures picture-by-user_id" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/pictures")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a user picture
#
# DELETE /users/{user_id}/pictures/{portraitset_id}
# operationId: delete_picture
export def "users-pictures picture-by-portraitset_id-user_id" [
  portraitset_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/pictures/($portraitset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific user picture
#
# GET /users/{user_id}/pictures/{portraitset_id}
# operationId: get_picture
export def "users-pictures picture-by-portraitset_id-user_id-1" [
  portraitset_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/pictures/($portraitset_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a user picture
#
# PATCH /users/{user_id}/pictures/{portraitset_id}
# operationId: edit_picture
export def "users-pictures picture-by-portraitset_id-user_id-2" [
  portraitset_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/pictures/($portraitset_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Get all the portfolios that belong to a user
#
# GET /users/{user_id}/portfolios
# operationId: get_portfolios
export def "users-portfolios portfolios" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/portfolios" $qp)
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}
# operationId: get_portfolio
export def "users-portfolios portfolio" [
  portfolio_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/portfolios/($portfolio_id)")
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos
# operationId: get_portfolio_videos
export def "users-portfolios-videos videos" [
  portfolio_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-13 # The way to sort the results.  Option descriptions:  * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/portfolios/($portfolio_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from a portfolio
#
# DELETE /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio
export def "users-portfolios-videos portfolio-by-portfolio_id-user_id-video_id" [
  portfolio_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: get_portfolio_video
export def "users-portfolios-videos video" [
  portfolio_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to a portfolio
#
# PUT /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio
export def "users-portfolios-videos portfolio-by-portfolio_id-user_id-video_id-1" [
  portfolio_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/portfolios/($portfolio_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the embed presets that a user has created
#
# GET /users/{user_id}/presets
# operationId: get_embed_presets
export def "users-presets presets" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/presets" $qp)
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific embed preset
#
# GET /users/{user_id}/presets/{preset_id}
# operationId: get_embed_preset
export def "users-presets preset-by-preset_id-user_id" [
  preset_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/presets/($preset_id)")
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit an embed preset
#
# PATCH /users/{user_id}/presets/{preset_id}
# operationId: edit_embed_preset
export def "users-presets preset-by-preset_id-user_id-1" [
  preset_id: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/presets/($preset_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.preset+json" $body
}

# Get all the videos that have been added to an embed preset
#
# GET /users/{user_id}/presets/{preset_id}/videos
# operationId: get_embed_preset_videos
export def "users-presets-videos videos" [
  preset_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/presets/($preset_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the projects that belong to a user
#
# GET /users/{user_id}/projects
# operationId: get_projects
export def "users-projects projects" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-14 # The way to sort the results.
]: nothing -> table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a project
#
# POST /users/{user_id}/projects
# operationId: create_project
export def "users-projects project-by-user_id" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/projects")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a project
#
# DELETE /users/{user_id}/projects/{project_id}
# operationId: delete_project
export def "users-projects project-by-project_id-user_id" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific project
#
# GET /users/{user_id}/projects/{project_id}
# operationId: get_project
export def "users-projects project-by-project_id-user_id-1" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a project
#
# PATCH /users/{user_id}/projects/{project_id}
# operationId: edit_project
export def "users-projects project-by-project_id-user_id-2" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a list of videos from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos
# operationId: remove_videos_from_project
export def "users-projects-videos project-by-project_id-user_id" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a project
#
# GET /users/{user_id}/projects/{project_id}/videos
# operationId: get_project_videos
export def "users-projects-videos videos" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of videos to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos
# operationId: add_videos_to_project
export def "users-projects-videos project-by-project_id-user_id-1" [
  project_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a specific video from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project
export def "users-projects-videos project-by-project_id-user_id-video_id" [
  project_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific video to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project
export def "users-projects-videos project-by-project_id-user_id-video_id-1" [
  project_id: float
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/projects/($project_id)/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete a user's streaming upload
#
# DELETE /users/{user_id}/uploads/{upload}
# operationId: complete_streaming_upload
export def "users-uploads upload" [
  upload: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --signature: string # The crypto signature of the completed upload. (e.g. cd89a20adde7a608f3331e71c37bdfa087bacbf3)
  --video-file-id: float # The ID of the uploaded file. (e.g. 1234)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signature" $signature "scalar") (serialize-qp "video_file_id" $video_file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/uploads/($upload)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's upload attempt
#
# GET /users/{user_id}/uploads/{upload}
# operationId: get_upload_attempt
export def "users-uploads attempt" [
  upload: float
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/uploads/($upload)")
  let accept_val = "application/vnd.vimeo.uploadattempt+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos that a user has uploaded
#
# GET /users/{user_id}/videos
# operationId: get_videos
export def "users-videos videos" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not  playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "filter_playable" $filter_playable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a video
#
# POST /users/{user_id}/videos
# operationId: upload_video
export def "users-videos video-by-user_id" [
  user_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/videos")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video+json" $body
}

# Check if a user owns a video
#
# GET /users/{user_id}/videos/{video_id}
# operationId: check_if_user_owns_video
export def "users-videos video-by-user_id-video_id" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the videos in a user's Watch Later queue
#
# GET /users/{user_id}/watchlater
# operationId: get_watch_later_queue
export def "users-watchlater list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($user_id)/watchlater" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a video from a user's Watch Later queue
#
# DELETE /users/{user_id}/watchlater/{video_id}
# operationId: delete_video_from_watch_later
export def "users-watchlater later-by-user_id-video_id" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/watchlater/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /users/{user_id}/watchlater/{video_id}
# operationId: check_watch_later_queue
export def "users-watchlater queue" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/watchlater/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video to a user's Watch Later queue
#
# PUT /users/{user_id}/watchlater/{video_id}
# operationId: add_video_to_watch_later
export def "users-watchlater later-by-user_id-video_id-1" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/users/($user_id)/watchlater/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for videos
#
# GET /videos
# operationId: search_videos
export def "videos videos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-15 # The attribute by which to filter the results. `CC` and related filters target videos with the corresponding Creative Commons licenses. For more information, see our [Creative Commons](https://vimeo.com/creativecommons) page.
  --links: string # A comma-separated list of video URLs to find. (e.g. https://vimeo.com/122375452,https://vimeo.com/273576296)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # Search query. (e.g. staff picks)
  --qp-sort: string@sort-completer-22 # The way to sort the results.
  --uris: string # The comma-separated list of videos to find. (e.g. /videos/122375452,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "links" $links "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a video
#
# DELETE /videos/{video_id}
# operationId: delete_video
export def "videos video-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video
#
# GET /videos/{video_id}
# operationId: get_video
export def "videos video-by-video_id-1" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)")
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a video
#
# PATCH /videos/{video_id}
# operationId: edit_video
export def "videos video-by-video_id-2" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video+json" $body
}

# Get all the channels to which a user can add or remove a specific video
#
# GET /videos/{video_id}/available_channels
# operationId: get_available_video_channels
export def "videos-available-channels channels" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/available_channels")
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the categories to which a video belongs
#
# GET /videos/{video_id}/categories
# operationId: get_video_categories
export def "videos-categories categories" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/categories")
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggest categories for a video
#
# PUT /videos/{video_id}/categories
# operationId: suggest_video_category
export def "videos-categories category" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/categories")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.category+json" $body
}

# Get all the comments on a video
#
# GET /videos/{video_id}/comments
# operationId: get_comments
export def "videos-comments comments" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/comments" $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a comment to a video
#
# POST /videos/{video_id}/comments
# operationId: create_comment
export def "videos-comments comment-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/comments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.comment+json" $body
}

# Delete a video comment
#
# DELETE /videos/{video_id}/comments/{comment_id}
# operationId: delete_comment
export def "videos-comments comment-by-comment_id-video_id" [
  comment_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific video comment
#
# GET /videos/{video_id}/comments/{comment_id}
# operationId: get_comment
export def "videos-comments comment-by-comment_id-video_id-1" [
  comment_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/comments/($comment_id)")
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a video comment
#
# PATCH /videos/{video_id}/comments/{comment_id}
# operationId: edit_comment
export def "videos-comments comment-by-comment_id-video_id-2" [
  comment_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/comments/($comment_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.comment+json" $body
}

# Get all the replies to a video comment
#
# GET /videos/{video_id}/comments/{comment_id}/replies
# operationId: get_comment_replies
export def "videos-comments-replies replies" [
  comment_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/comments/($comment_id)/replies" $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a reply to a video comment
#
# POST /videos/{video_id}/comments/{comment_id}/replies
# operationId: create_comment_reply
export def "videos-comments-replies reply" [
  comment_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/comments/($comment_id)/replies")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.comment+json" $body
}

# Get all the credited users in a video
#
# GET /videos/{video_id}/credits
# operationId: get_video_credits
export def "videos-credits credits" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/credits" $qp)
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Credit a user in a video
#
# POST /videos/{video_id}/credits
# operationId: add_video_credit
export def "videos-credits credit-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/credits")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.credit+json" $body
}

# Delete a credit for a user in a video
#
# DELETE /videos/{video_id}/credits/{credit_id}
# operationId: delete_video_credit
export def "videos-credits credit-by-credit_id-video_id" [
  credit_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/credits/($credit_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific credited user in a video
#
# GET /videos/{video_id}/credits/{credit_id}
# operationId: get_video_credit
export def "videos-credits credit-by-credit_id-video_id-1" [
  credit_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/credits/($credit_id)")
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a credit for a user in a video
#
# PATCH /videos/{video_id}/credits/{credit_id}
# operationId: edit_video_credit
export def "videos-credits credit-by-credit_id-video_id-2" [
  credit_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/credits/($credit_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.credit+json" $body
}

# Get all the users who have liked a video
#
# GET /videos/{video_id}/likes
# operationId: get_video_likes
export def "videos-likes likes" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/likes" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the thumbnails of a video
#
# GET /videos/{video_id}/pictures
# operationId: get_video_thumbnails
export def "videos-pictures thumbnails" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/pictures" $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a video thumbnail
#
# POST /videos/{video_id}/pictures
# operationId: create_video_thumbnail
export def "videos-pictures thumbnail-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/pictures")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Delete a video thumbnail
#
# DELETE /videos/{video_id}/pictures/{picture_id}
# operationId: delete_video_thumbnail
export def "videos-pictures thumbnail-by-picture_id-video_id" [
  picture_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/pictures/($picture_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a video thumbnail
#
# GET /videos/{video_id}/pictures/{picture_id}
# operationId: get_video_thumbnail
export def "videos-pictures thumbnail-by-picture_id-video_id-1" [
  picture_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/pictures/($picture_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a video thumbnail
#
# PATCH /videos/{video_id}/pictures/{picture_id}
# operationId: edit_video_thumbnail
export def "videos-pictures thumbnail-by-picture_id-video_id-2" [
  picture_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/pictures/($picture_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.picture+json" $body
}

# Remove an embed preset from a video
#
# DELETE /videos/{video_id}/presets/{preset_id}
# operationId: delete_video_embed_preset
export def "videos-presets preset-by-preset_id-video_id" [
  preset_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/presets/($preset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if an embed preset has been added to a video
#
# GET /videos/{video_id}/presets/{preset_id}
# operationId: get_video_embed_preset
export def "videos-presets preset-by-preset_id-video_id-1" [
  preset_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/presets/($preset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an embed preset to a video
#
# PUT /videos/{video_id}/presets/{preset_id}
# operationId: add_video_embed_preset
export def "videos-presets preset-by-preset_id-video_id-2" [
  preset_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/presets/($preset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the domains on which a video can be embedded
#
# GET /videos/{video_id}/privacy/domains
# operationId: get_video_privacy_domains
export def "videos-privacy-domains domains" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/privacy/domains" $qp)
  let accept_val = "application/vnd.vimeo.domain+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restrict a video from being embedded on a domain
#
# DELETE /videos/{video_id}/privacy/domains/{domain}
# operationId: delete_video_privacy_domain
export def "videos-privacy-domains domain-by-domain-video_id" [
  domain: string
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/privacy/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a video to be embedded on a domain
#
# PUT /videos/{video_id}/privacy/domains/{domain}
# operationId: add_video_privacy_domain
export def "videos-privacy-domains domain-by-domain-video_id-1" [
  domain: string
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/privacy/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the users who can view a user's private videos by default
#
# GET /videos/{video_id}/privacy/users
# operationId: get_video_privacy_users
export def "videos-privacy-users users-by-video_id" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/privacy/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a list of users to view a private video
#
# PUT /videos/{video_id}/privacy/users
# operationId: add_video_privacy_users
export def "videos-privacy-users users-by-video_id-1" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/privacy/users")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restrict a user from viewing a private video
#
# DELETE /videos/{video_id}/privacy/users/{user_id}
# operationId: delete_video_privacy_user
export def "videos-privacy-users user-by-user_id-video_id" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/privacy/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permit a specific user to view a private video
#
# PUT /videos/{video_id}/privacy/users/{user_id}
# operationId: add_video_privacy_user
export def "videos-privacy-users user-by-user_id-video_id-1" [
  user_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/privacy/users/($user_id)")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the tags of a video
#
# GET /videos/{video_id}/tags
# operationId: get_video_tags
export def "videos-tags tags-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/tags")
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a list of tags to a video
#
# PUT /videos/{video_id}/tags
# operationId: add_video_tags
export def "videos-tags tags-by-video_id-1" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/tags")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.tag+json" $body
}

# Remove a tag from a video
#
# DELETE /videos/{video_id}/tags/{word}
# operationId: delete_video_tag
export def "videos-tags tag-by-video_id-word" [
  video_id: float
  word: string
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
  let full_url = (build-url $base $"/videos/($video_id)/tags/($word)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a tag has been added to a video
#
# GET /videos/{video_id}/tags/{word}
# operationId: check_video_for_tag
export def "videos-tags tag-by-video_id-word-1" [
  video_id: float
  word: string
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
  let full_url = (build-url $base $"/videos/($video_id)/tags/($word)")
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a specific tag to a video
#
# PUT /videos/{video_id}/tags/{word}
# operationId: add_video_tag
export def "videos-tags tag-by-video_id-word-2" [
  video_id: float
  word: string
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
  let full_url = (build-url $base $"/videos/($video_id)/tags/($word)")
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the text tracks of a video
#
# GET /videos/{video_id}/texttracks
# operationId: get_text_tracks
export def "videos-texttracks tracks" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/texttracks")
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a text track to a video
#
# POST /videos/{video_id}/texttracks
# operationId: create_text_track
export def "videos-texttracks track-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/texttracks")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video.texttrack+json" $body
}

# Delete a text track
#
# DELETE /videos/{video_id}/texttracks/{texttrack_id}
# operationId: delete_text_track
export def "videos-texttracks track-by-texttrack_id-video_id" [
  texttrack_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/texttracks/($texttrack_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific text track
#
# GET /videos/{video_id}/texttracks/{texttrack_id}
# operationId: get_text_track
export def "videos-texttracks track-by-texttrack_id-video_id-1" [
  texttrack_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/texttracks/($texttrack_id)")
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a text track
#
# PATCH /videos/{video_id}/texttracks/{texttrack_id}
# operationId: edit_text_track
export def "videos-texttracks track-by-texttrack_id-video_id-2" [
  texttrack_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/texttracks/($texttrack_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video.texttrack+json" $body
}

# Add a new custom logo to a video
#
# POST /videos/{video_id}/timelinethumbnails
# operationId: create_video_custom_logo
export def "videos-timelinethumbnails logo-by-video_id" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/timelinethumbnails")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a custom video logo
#
# GET /videos/{video_id}/timelinethumbnails/{thumbnail_id}
# operationId: get_video_custom_logo
export def "videos-timelinethumbnails logo-by-thumbnail_id-video_id" [
  thumbnail_id: float
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/timelinethumbnails/($thumbnail_id)")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a version to a video
#
# POST /videos/{video_id}/versions
# operationId: create_video_version
export def "videos-versions version" [
  video_id: float
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
  let full_url = (build-url $base $"/videos/($video_id)/versions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.vimeo.video.version+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.vimeo.video.version+json" $body
}

# Get all the related videos of a video
#
# GET /videos/{video_id}/videos
# operationId: get_related_videos
export def "videos-videos videos" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-16 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/videos/($video_id)/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
