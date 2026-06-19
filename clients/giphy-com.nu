# Auto-generated client for Giphy API v1.0
# Source: https://api.apis.guru/v2/specs/giphy.com/1.0/openapi.json
# Auth: --token flag or $env.GIPHY_API_TOKEN

const BASE_URL = "https://api.giphy.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GIPHY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.giphy.com/v1"] }
def auth-scheme-completer [] { ["query-api_key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "gifs list" } } | get name | first)
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

# Get GIFs by ID
#
# GET /gifs
# operationId: getGifsById
export def "gifs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string # Filters results by specified GIF IDs, separated by commas.
]: nothing -> record<data: table<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list, id: string, images: record, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list, trending_datetime: string, type: string, update_datetime: string, url: string, user: record, username: string>, meta: record<msg: string, response_id: string, status: int>, pagination: record<count: int, offset: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gifs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ids": $ids} | compact), body: null}
}

# Random GIF
#
# GET /gifs/random
# operationId: randomGif
export def "gifs-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filters results by specified tag.
  --rating: string # Filters results by specified rating.
]: nothing -> record<data: record<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list<string>, id: string, images: record<downsized: record, downsized_large: record, downsized_medium: record, downsized_small: record, downsized_still: record, fixed_height: record, fixed_height_downsampled: record, fixed_height_small: record, fixed_height_small_still: record, fixed_height_still: record, fixed_width: record, fixed_width_downsampled: record, fixed_width_small: record, fixed_width_small_still: record, fixed_width_still: record, looping: record, original: record, original_still: record, preview: record, preview_gif: record>, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list<string>, trending_datetime: string, type: string, update_datetime: string, url: string, user: record<avatar_url: string, banner_url: string, display_name: string, profile_url: string, twitter: string, username: string>, username: string>, meta: record<msg: string, response_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gifs/random" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tag": $tag, "rating": $rating} | compact), body: null}
}

# Search GIFs
#
# GET /gifs/search
# operationId: searchGifs
export def "gifs-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query term or prhase.
  --limit: int # The maximum number of records to return. (format: int32, default: 25)
  --offset: int # An optional results offset. (format: int32, default: 0)
  --rating: string # Filters results by specified rating.
  --lang: string # Specify default language for regional content; use a 2-letter ISO 639-1 language code.
]: nothing -> record<data: table<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list, id: string, images: record, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list, trending_datetime: string, type: string, update_datetime: string, url: string, user: record, username: string>, meta: record<msg: string, response_id: string, status: int>, pagination: record<count: int, offset: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gifs/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "limit": $limit, "offset": $offset, "rating": $rating, "lang": $lang} | compact), body: null}
}

# Translate phrase to GIF
#
# GET /gifs/translate
# operationId: translateGif
export def "gifs-translate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --s: string # Search term.
]: nothing -> record<data: record<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list<string>, id: string, images: record<downsized: record, downsized_large: record, downsized_medium: record, downsized_small: record, downsized_still: record, fixed_height: record, fixed_height_downsampled: record, fixed_height_small: record, fixed_height_small_still: record, fixed_height_still: record, fixed_width: record, fixed_width_downsampled: record, fixed_width_small: record, fixed_width_small_still: record, fixed_width_still: record, looping: record, original: record, original_still: record, preview: record, preview_gif: record>, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list<string>, trending_datetime: string, type: string, update_datetime: string, url: string, user: record<avatar_url: string, banner_url: string, display_name: string, profile_url: string, twitter: string, username: string>, username: string>, meta: record<msg: string, response_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gifs/translate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"s": $s} | compact), body: null}
}

# Trending GIFs
#
# GET /gifs/trending
# operationId: trendingGifs
export def "gifs-trending get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of records to return. (format: int32, default: 25)
  --offset: int # An optional results offset. (format: int32, default: 0)
  --rating: string # Filters results by specified rating.
]: nothing -> record<data: table<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list, id: string, images: record, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list, trending_datetime: string, type: string, update_datetime: string, url: string, user: record, username: string>, meta: record<msg: string, response_id: string, status: int>, pagination: record<count: int, offset: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gifs/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "rating": $rating} | compact), body: null}
}

# Get GIF by Id
#
# GET /gifs/{gifId}
# operationId: getGifById
export def "gifs get" [
  gif_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list<string>, id: string, images: record<downsized: record, downsized_large: record, downsized_medium: record, downsized_small: record, downsized_still: record, fixed_height: record, fixed_height_downsampled: record, fixed_height_small: record, fixed_height_small_still: record, fixed_height_still: record, fixed_width: record, fixed_width_downsampled: record, fixed_width_small: record, fixed_width_small_still: record, fixed_width_still: record, looping: record, original: record, original_still: record, preview: record, preview_gif: record>, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list<string>, trending_datetime: string, type: string, update_datetime: string, url: string, user: record<avatar_url: string, banner_url: string, display_name: string, profile_url: string, twitter: string, username: string>, username: string>, meta: record<msg: string, response_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  if ($gif_id | is-empty) { error make --unspanned { msg: "path parameter 'gifId' must be non-empty" } }
  let full_url = (build-url $base ({gif_id: (encode-path-segment $gif_id)} | format pattern "/gifs/{gif_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Random Sticker
#
# GET /stickers/random
# operationId: randomSticker
export def "stickers-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Filters results by specified tag.
  --rating: string # Filters results by specified rating.
]: nothing -> record<data: record<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list<string>, id: string, images: record<downsized: record, downsized_large: record, downsized_medium: record, downsized_small: record, downsized_still: record, fixed_height: record, fixed_height_downsampled: record, fixed_height_small: record, fixed_height_small_still: record, fixed_height_still: record, fixed_width: record, fixed_width_downsampled: record, fixed_width_small: record, fixed_width_small_still: record, fixed_width_still: record, looping: record, original: record, original_still: record, preview: record, preview_gif: record>, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list<string>, trending_datetime: string, type: string, update_datetime: string, url: string, user: record<avatar_url: string, banner_url: string, display_name: string, profile_url: string, twitter: string, username: string>, username: string>, meta: record<msg: string, response_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tag" $tag "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stickers/random" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tag": $tag, "rating": $rating} | compact), body: null}
}

# Search Stickers
#
# GET /stickers/search
# operationId: searchStickers
export def "stickers-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query term or prhase.
  --limit: int # The maximum number of records to return. (format: int32, default: 25)
  --offset: int # An optional results offset. (format: int32, default: 0)
  --rating: string # Filters results by specified rating.
  --lang: string # Specify default language for regional content; use a 2-letter ISO 639-1 language code.
]: nothing -> record<data: table<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list, id: string, images: record, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list, trending_datetime: string, type: string, update_datetime: string, url: string, user: record, username: string>, meta: record<msg: string, response_id: string, status: int>, pagination: record<count: int, offset: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stickers/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "limit": $limit, "offset": $offset, "rating": $rating, "lang": $lang} | compact), body: null}
}

# Translate phrase to Sticker
#
# GET /stickers/translate
# operationId: translateSticker
export def "stickers-translate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --s: string # Search term.
]: nothing -> record<data: record<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list<string>, id: string, images: record<downsized: record, downsized_large: record, downsized_medium: record, downsized_small: record, downsized_still: record, fixed_height: record, fixed_height_downsampled: record, fixed_height_small: record, fixed_height_small_still: record, fixed_height_still: record, fixed_width: record, fixed_width_downsampled: record, fixed_width_small: record, fixed_width_small_still: record, fixed_width_still: record, looping: record, original: record, original_still: record, preview: record, preview_gif: record>, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list<string>, trending_datetime: string, type: string, update_datetime: string, url: string, user: record<avatar_url: string, banner_url: string, display_name: string, profile_url: string, twitter: string, username: string>, username: string>, meta: record<msg: string, response_id: string, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "s" $s "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stickers/translate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"s": $s} | compact), body: null}
}

# Trending Stickers
#
# GET /stickers/trending
# operationId: trendingStickers
export def "stickers-trending get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of records to return. (format: int32, default: 25)
  --offset: int # An optional results offset. (format: int32, default: 0)
  --rating: string # Filters results by specified rating.
]: nothing -> record<data: table<bitly_url: string, content_url: string, create_datetime: string, embded_url: string, featured_tags: list, id: string, images: record, import_datetime: string, rating: string, slug: string, source: string, source_post_url: string, source_tld: string, tags: list, trending_datetime: string, type: string, update_datetime: string, url: string, user: record, username: string>, meta: record<msg: string, response_id: string, status: int>, pagination: record<count: int, offset: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stickers/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset, "rating": $rating} | compact), body: null}
}
