# Auto-generated client for Vimeo v3.4
# Source: https://api.apis.guru/v2/specs/vimeo.com/3.4/openapi.json
# Auth: --token flag or $env.VIMEO_TOKEN

const BASE_URL = "https://api.vimeo.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VIMEO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api-information get-endpoints" } } | get name | first)
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
export def "api-information get-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --openapi: oneof<nothing, bool> # Return an OpenAPI specification. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "openapi" $openapi "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/vnd.vimeo.endpoint+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"openapi": $openapi} | compact), body: null}
}

# Get all categories
#
# GET /categories
# operationId: get_categories
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get a specific category
#
# GET /categories/{category}
# operationId: get_category
export def "categories get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}"))
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the channels in a category
#
# GET /categories/{category}/channels
# operationId: get_category_channels
export def "categories-channels get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/channels") $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the groups in a category
#
# GET /categories/{category}/groups
# operationId: get_category_groups
export def "categories-groups get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/groups") $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the videos in a category
#
# GET /categories/{category}/videos
# operationId: get_category_videos
export def "categories-videos get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer # The attribute by which to filter the results. Option descriptions: * `conditional_featured` - Featured (promoted) videos
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-3 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Check for a video in a category
#
# GET /categories/{category}/videos/{video_id}
# operationId: check_category_for_video
export def "categories-videos check" [
  category: string
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category), video_id: (encode-path-segment $video_id)} | format pattern "/categories/{category}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all channels
#
# GET /channels
# operationId: get_channels
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results. Option descriptions: * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Create a channel
#
# POST /channels
# operationId: create_channel
export def "channels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.channel+json" $req_body {query: {}, body: $req_body}
}

# Delete a channel
#
# DELETE /channels/{channel_id}
# operationId: delete_channel
export def "channels delete" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific channel
#
# GET /channels/{channel_id}
# operationId: get_channel
export def "channels get" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}"))
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a channel
#
# PATCH /channels/{channel_id}
# operationId: edit_channel
export def "channels update-edit" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.channel+json" $req_body {query: {}, body: $req_body}
}

# Get all the categories in a channel
#
# GET /channels/{channel_id}/categories
# operationId: get_channel_categories
export def "channels-categories get" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/categories"))
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a list of categories to a channel
#
# PUT /channels/{channel_id}/categories
# operationId: add_channel_categories
export def "channels-categories create" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: list<string> # The array of category URIs to add.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/categories"))
  let req_body = {"channels": $channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a category from a channel
#
# DELETE /channels/{channel_id}/categories/{category}
# operationId: delete_channel_category
export def "channels-categories delete" [
  channel_id: float
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), category: (encode-path-segment $category)} | format pattern "/channels/{channel_id}/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Categorize a channel
#
# PUT /channels/{channel_id}/categories/{category}
# operationId: categorize_channel
export def "channels-categories update-categorize" [
  channel_id: float
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), category: (encode-path-segment $category)} | format pattern "/channels/{channel_id}/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a list of channel moderators
#
# DELETE /channels/{channel_id}/moderators
# operationId: remove_channel_moderators
export def "channels-moderators delete-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/moderators"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.user+json" $req_body {query: {}, body: $req_body}
}

# Get all the moderators in a channel
#
# GET /channels/{channel_id}/moderators
# operationId: get_channel_moderators
export def "channels-moderators list" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/moderators") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Replace the moderators of a channel
#
# PATCH /channels/{channel_id}/moderators
# operationId: replace_channel_moderators
export def "channels-moderators update" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of the user to add as a moderator. (e.g. /users/152184)
]: any -> table<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/moderators"))
  let req_body = {"user_uri": $user_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add a list of channel moderators
#
# PUT /channels/{channel_id}/moderators
# operationId: add_channel_moderators
export def "channels-moderators create-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_uri: string # The URI of a user to add as a moderator. (e.g. /users/152184)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/moderators"))
  let req_body = {"user_uri": $user_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a specific channel moderator
#
# DELETE /channels/{channel_id}/moderators/{user_id}
# operationId: remove_channel_moderator
export def "channels-moderators delete-by-channel-id-user-id" [
  channel_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), user_id: (encode-path-segment $user_id)} | format pattern "/channels/{channel_id}/moderators/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific channel moderator
#
# GET /channels/{channel_id}/moderators/{user_id}
# operationId: get_channel_moderator
export def "channels-moderators get" [
  channel_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), user_id: (encode-path-segment $user_id)} | format pattern "/channels/{channel_id}/moderators/{user_id}"))
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific channel moderator
#
# PUT /channels/{channel_id}/moderators/{user_id}
# operationId: add_channel_moderator
export def "channels-moderators create-by-channel-id-user-id" [
  channel_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), user_id: (encode-path-segment $user_id)} | format pattern "/channels/{channel_id}/moderators/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the users who can view a private channel
#
# GET /channels/{channel_id}/privacy/users
# operationId: get_channel_privacy_users
export def "channels-privacy-users get" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/privacy/users") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Permit a list of users to view a private channel
#
# PUT /channels/{channel_id}/privacy/users
# operationId: set_channel_privacy_users
export def "channels-privacy-users update-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/privacy/users"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.user+json" $req_body {query: {}, body: $req_body}
}

# Restrict a user from viewing a private channel
#
# DELETE /channels/{channel_id}/privacy/users/{user_id}
# operationId: delete_channel_privacy_user
export def "channels-privacy-users delete" [
  channel_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), user_id: (encode-path-segment $user_id)} | format pattern "/channels/{channel_id}/privacy/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Permit a specific user to view a private channel
#
# PUT /channels/{channel_id}/privacy/users/{user_id}
# operationId: set_channel_privacy_user
export def "channels-privacy-users update-by-channel-id-user-id" [
  channel_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), user_id: (encode-path-segment $user_id)} | format pattern "/channels/{channel_id}/privacy/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the tags that have been added to a channel
#
# GET /channels/{channel_id}/tags
# operationId: get_channel_tags
export def "channels-tags get" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/tags"))
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a list of tags to a channel
#
# PUT /channels/{channel_id}/tags
# operationId: add_tags_to_channel
export def "channels-tags create-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/tags"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.tag+json" $req_body {query: {}, body: $req_body}
}

# Remove a tag from a channel
#
# DELETE /channels/{channel_id}/tags/{word}
# operationId: delete_tag_from_channel
export def "channels-tags delete" [
  channel_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), word: (encode-path-segment $word)} | format pattern "/channels/{channel_id}/tags/{word}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a tag has been added to a channel
#
# GET /channels/{channel_id}/tags/{word}
# operationId: check_if_channel_has_tag
export def "channels-tags check-if-has" [
  channel_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), word: (encode-path-segment $word)} | format pattern "/channels/{channel_id}/tags/{word}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific tag to a channel
#
# PUT /channels/{channel_id}/tags/{word}
# operationId: add_channel_tag
export def "channels-tags create-by-channel-id-word" [
  channel_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), word: (encode-path-segment $word)} | format pattern "/channels/{channel_id}/tags/{word}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the followers of a channel
#
# GET /channels/{channel_id}/users
# operationId: get_channel_subscribers
export def "channels-users get-subscribers" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/users") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a list of videos from a channel
#
# DELETE /channels/{channel_id}/videos
# operationId: remove_videos_from_channel
export def "channels-videos delete-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to remove. (e.g. /videos/258684937)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/videos"))
  let req_body = {"video_uri": $video_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the videos in a channel
#
# GET /channels/{channel_id}/videos
# operationId: get_channel_videos
export def "channels-videos list" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-6 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Add a list of videos to a channel
#
# PUT /channels/{channel_id}/videos
# operationId: add_videos_to_channel
export def "channels-videos create-by-channel-id" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_uri: string # The URI of a video to add. (e.g. /videos/258684937)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/videos"))
  let req_body = {"video_uri": $video_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a specific video from a channel
#
# DELETE /channels/{channel_id}/videos/{video_id}
# operationId: delete_video_from_channel
export def "channels-videos delete-by-channel-id-video-id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in a channel
#
# GET /channels/{channel_id}/videos/{video_id}
# operationId: get_channel_video
export def "channels-videos get" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific video to a channel
#
# PUT /channels/{channel_id}/videos/{video_id}
# operationId: add_video_to_channel
export def "channels-videos create-by-channel-id-video-id" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the comments on a video
#
# GET /channels/{channel_id}/videos/{video_id}/comments
# operationId: get_comments_alt1
export def "channels-videos-comments get-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/comments") $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a comment to a video
#
# POST /channels/{channel_id}/videos/{video_id}/comments
# operationId: create_comment_alt1
export def "channels-videos-comments create-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/comments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.comment+json" $req_body {query: {}, body: $req_body}
}

# Get all the credited users in a video
#
# GET /channels/{channel_id}/videos/{video_id}/credits
# operationId: get_video_credits_alt1
export def "channels-videos-credits get-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/credits") $qp)
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Credit a user in a video
#
# POST /channels/{channel_id}/videos/{video_id}/credits
# operationId: add_video_credit_alt1
export def "channels-videos-credits create-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/credits"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.credit+json" $req_body {query: {}, body: $req_body}
}

# Get all the users who have liked a video
#
# GET /channels/{channel_id}/videos/{video_id}/likes
# operationId: get_video_likes_alt1
export def "channels-videos-likes get-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/likes") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get all the thumbnails of a video
#
# GET /channels/{channel_id}/videos/{video_id}/pictures
# operationId: get_video_thumbnails_alt1
export def "channels-videos-pictures get-thumbnails-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/pictures") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a video thumbnail
#
# POST /channels/{channel_id}/videos/{video_id}/pictures
# operationId: create_video_thumbnail_alt1
export def "channels-videos-pictures create-thumbnail-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/pictures"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Get all the users who can view a user's private videos by default
#
# GET /channels/{channel_id}/videos/{video_id}/privacy/users
# operationId: get_video_privacy_users_alt1
export def "channels-videos-privacy-users get-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/privacy/users") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Permit a list of users to view a private video
#
# PUT /channels/{channel_id}/videos/{video_id}/privacy/users
# operationId: add_video_privacy_users_alt1
export def "channels-videos-privacy-users create-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/privacy/users"))
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the text tracks of a video
#
# GET /channels/{channel_id}/videos/{video_id}/texttracks
# operationId: get_text_tracks_alt1
export def "channels-videos-texttracks get-text-tracks-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/texttracks"))
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a text track to a video
#
# POST /channels/{channel_id}/videos/{video_id}/texttracks
# operationId: create_text_track_alt1
export def "channels-videos-texttracks create-text-track-alt1" [
  channel_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id), video_id: (encode-path-segment $video_id)} | format pattern "/channels/{channel_id}/videos/{video_id}/texttracks"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video.texttrack+json" $req_body {query: {}, body: $req_body}
}

# Get all content ratings
#
# GET /contentratings
# operationId: get_content_ratings
export def "contentratings get-content-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contentratings")
  let accept_val = "application/vnd.vimeo.contentrating+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all Creative Commons licenses
#
# GET /creativecommons
# operationId: get_cc_licenses
export def "creativecommons get-cc-licenses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/creativecommons")
  let accept_val = "application/vnd.vimeo.creativecommons+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all groups
#
# GET /groups
# operationId: get_groups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-1 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results. Option descriptions: * `relevant` - Relevant sorting is available only for search queries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Create a group
#
# POST /groups
# operationId: create_group
export def "groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.group+json" $req_body {query: {}, body: $req_body}
}

# Delete a group
#
# DELETE /groups/{group_id}
# operationId: delete_group
export def "groups delete" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific group
#
# GET /groups/{group_id}
# operationId: get_group
export def "groups get" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}"))
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the members of a group
#
# GET /groups/{group_id}/users
# operationId: get_group_members
export def "groups-users get-members" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-2 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/users") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the videos in a group
#
# GET /groups/{group_id}/videos
# operationId: get_group_videos
export def "groups-videos list" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/groups/{group_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from a group
#
# DELETE /groups/{group_id}/videos/{video_id}
# operationId: delete_video_from_group
export def "groups-videos delete" [
  group_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), video_id: (encode-path-segment $video_id)} | format pattern "/groups/{group_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in a group
#
# GET /groups/{group_id}/videos/{video_id}
# operationId: get_group_video
export def "groups-videos get" [
  group_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), video_id: (encode-path-segment $video_id)} | format pattern "/groups/{group_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to a group
#
# PUT /groups/{group_id}/videos/{video_id}
# operationId: add_video_to_group
export def "groups-videos create" [
  group_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), video_id: (encode-path-segment $video_id)} | format pattern "/groups/{group_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all languages
#
# GET /languages
# operationId: get_languages
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-4 # The attribute by which to filter the results. Option descriptions: * `texttracks` - Only return text track supported languages
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/languages" $qp)
  let accept_val = "application/vnd.vimeo.language+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter} | compact), body: null}
}

# Get a user
#
# GET /me
# operationId: get_user_alt1
export def "me get-user-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a user
#
# PATCH /me
# operationId: edit_user_alt1
export def "me update-edit-user-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.user+json" $req_body {query: {}, body: $req_body}
}

# Get all the albums that belong to a user
#
# GET /me/albums
# operationId: get_albums_alt1
export def "me-albums list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/albums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Create an album
#
# POST /me/albums
# operationId: create_album_alt1
export def "me-albums create-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/albums")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.album+json" $req_body {query: {}, body: $req_body}
}

# Delete an album
#
# DELETE /me/albums/{album_id}
# operationId: delete_album_alt1
export def "me-albums delete-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/me/albums/{album_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific album
#
# GET /me/albums/{album_id}
# operationId: get_album_alt1
export def "me-albums get-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/me/albums/{album_id}"))
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an album
#
# PATCH /me/albums/{album_id}
# operationId: edit_album_alt1
export def "me-albums update-edit-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/me/albums/{album_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.album+json" $req_body {query: {}, body: $req_body}
}

# Get all the videos in an album
#
# GET /me/albums/{album_id}/videos
# operationId: get_album_videos_alt1
export def "me-albums-videos list" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-9 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "weak_search" $weak_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/me/albums/{album_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "password": $password, "per_page": $per_page, "query": $query, "sort": $qp_sort, "weak_search": $weak_search} | compact), body: null}
}

# Replace all the videos in an album
#
# PUT /me/albums/{album_id}/videos
# operationId: replace_videos_in_album_alt1
export def "me-albums-videos update-in-alt1" [
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/me/albums/{album_id}/videos"))
  let req_body = {"videos": $videos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a video from an album
#
# DELETE /me/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album_alt1
export def "me-albums-videos delete-from-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/albums/{album_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in an album
#
# GET /me/albums/{album_id}/videos/{video_id}
# operationId: get_album_video_alt1
export def "me-albums-videos get-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/albums/{album_id}/videos/{video_id}") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"password": $password} | compact), body: null}
}

# Add a specific video to an album
#
# PUT /me/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album_alt1
export def "me-albums-videos create-to-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/albums/{album_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set a video as the album thumbnail
#
# POST /me/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# operationId: set_video_as_album_thumbnail_alt1
export def "me-albums-videos-set-album-thumbnail update-as-alt1" [
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/albums/{album_id}/videos/{video_id}/set_album_thumbnail"))
  let req_body = {"time_code": $time_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the videos in which a user appears
#
# GET /me/appearances
# operationId: get_appearances_alt1
export def "me-appearances get-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/appearances" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the categories that a user follows
#
# GET /me/categories
# operationId: get_category_subscriptions_alt1
export def "me-categories get-category-subscriptions-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Unsubscribe a user from a category
#
# DELETE /me/categories/{category}
# operationId: unsubscribe_from_category_alt1
export def "me-categories unsubscribe-from-alt1" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/me/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user follows a category
#
# GET /me/categories/{category}
# operationId: check_if_user_subscribed_to_category_alt1
export def "me-categories check-if-user-subscribed-to-alt1" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/me/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Subscribe a user to a single category
#
# PUT /me/categories/{category}
# operationId: subscribe_to_category_alt1
export def "me-categories subscribe-to-alt1" [
  category: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/me/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the channels to which a user subscribes
#
# GET /me/channels
# operationId: get_channel_subscriptions_alt1
export def "me-channels get-subscriptions-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/channels" $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Unsubscribe a user from a specific channel
#
# DELETE /me/channels/{channel_id}
# operationId: unsubscribe_from_channel_alt1
export def "me-channels unsubscribe-from-alt1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/me/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user follows a channel
#
# GET /me/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel_alt1
export def "me-channels check-if-user-subscribed-to-alt1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/me/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Subscribe a user to a specific channel
#
# PUT /me/channels/{channel_id}
# operationId: subscribe_to_channel_alt1
export def "me-channels subscribe-to-alt1" [
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/me/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the custom logos that belong to a user
#
# GET /me/customlogos
# operationId: get_custom_logos_alt1
export def "me-customlogos get-custom-logos-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a custom logo
#
# POST /me/customlogos
# operationId: create_custom_logo_alt1
export def "me-customlogos create-custom-logo-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/customlogos")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific custom logo
#
# GET /me/customlogos/{logo_id}
# operationId: get_custom_logo_alt1
export def "me-customlogos get-custom-alt1" [
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($logo_id | is-empty) { error make --unspanned { msg: "path parameter 'logo_id' must be non-empty" } }
  let full_url = (build-url $base ({logo_id: (encode-path-segment $logo_id)} | format pattern "/me/customlogos/{logo_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all videos in a user's feed
#
# GET /me/feed
# operationId: get_feed_alt1
export def "me-feed get-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "page": $page, "per_page": $per_page, "type": $type} | compact), body: null}
}

# Get all the followers of a user
#
# GET /me/followers
# operationId: get_followers_alt1
export def "me-followers get-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/followers" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the users that a user is following
#
# GET /me/following
# operationId: get_user_following_alt1
export def "me-following get-user-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/following" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Follow a list of users
#
# POST /me/following
# operationId: follow_users_alt1
export def "me-following create-follow-users-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string> # An array of user URIs for the list of users to follow.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/following")
  let req_body = {"users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unfollow a user
#
# DELETE /me/following/{follow_user_id}
# operationId: unfollow_user_alt1
export def "me-following delete-unfollow-alt1" [
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/me/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user is following another user
#
# GET /me/following/{follow_user_id}
# operationId: check_if_user_is_following_alt1
export def "me-following check-if-is-alt1" [
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/me/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Follow a specific user
#
# PUT /me/following/{follow_user_id}
# operationId: follow_user_alt1
export def "me-following update-alt1" [
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/me/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the groups that a user has joined
#
# GET /me/groups
# operationId: get_user_groups_alt1
export def "me-groups get-user-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/groups" $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a user from a group
#
# DELETE /me/groups/{group_id}
# operationId: leave_group_alt1
export def "me-groups delete-leave-alt1" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/me/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has joined a group
#
# GET /me/groups/{group_id}
# operationId: check_if_user_joined_group_alt1
export def "me-groups check-if-user-joined-alt1" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/me/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a user to a group
#
# PUT /me/groups/{group_id}
# operationId: join_group_alt1
export def "me-groups update-join-alt1" [
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/me/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos that a user has liked
#
# GET /me/likes
# operationId: get_likes_alt1
export def "me-likes get-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/likes" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Cause a user to unlike a video
#
# DELETE /me/likes/{video_id}
# operationId: unlike_video_alt1
export def "me-likes delete-unlike-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has liked a video
#
# GET /me/likes/{video_id}
# operationId: check_if_user_liked_video_alt1
export def "me-likes check-if-user-liked-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cause a user to like a video
#
# PUT /me/likes/{video_id}
# operationId: like_video_alt1
export def "me-likes update-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the On Demand pages of a user
#
# GET /me/ondemand/pages
# operationId: get_user_vods_alt1
export def "me-ondemand-pages get-user-vods-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Create an On Demand page
#
# POST /me/ondemand/pages
# operationId: create_vod_alt1
# --buy shape: {active?: bool, download?: bool, price?: record}
# --episodes shape: {buy?: record, rent?: record}
# --rent shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
# --subscription shape: {monthly?: record}
export def "me-ondemand-pages create-vod-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies. Option descriptions: * `AUD` - Australian Dollar * `CAD` - Canadian Dollar * `CHF` - Swiss Franc * `DKK` - Danish Krone * `EUR` - Euro * `GBP` - British Pound * `JPY` - Japanese Yen * `KRW` - South Korean Won * `NOK` - Norwegian Krone * `PLN` - Polish Zloty * `SEK` - Swedish Krona * `USD` - US Dollar
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
  let req_body = {"accepted_currencies": $accepted_currencies, "buy": $buy, "content_rating": $content_rating, "description": $description, "domain_link": $domain_link, "episodes": $episodes, "link": $link, "name": $name, "rent": $rent, "subscription": $subscription, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the On Demand purchases and rentals that a user has made
#
# GET /me/ondemand/purchases
# operationId: get_vod_purchases
export def "me-ondemand-purchases get-vod" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-8 # The type of On Demand videos to show. Option descriptions: * `important` - Will show all pages which are about to expire.
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /me/ondemand/purchases/{ondemand_id}
# operationId: check_if_vod_was_purchased_alt1
export def "me-ondemand-purchases check-if-vod-was-purchased-alt1" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/me/ondemand/purchases/{ondemand_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the pictures that belong to a user
#
# GET /me/pictures
# operationId: get_pictures_alt1
export def "me-pictures list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a user picture
#
# POST /me/pictures
# operationId: create_picture_alt1
export def "me-pictures create-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/pictures")
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a user picture
#
# DELETE /me/pictures/{portraitset_id}
# operationId: delete_picture_alt1
export def "me-pictures delete-alt1" [
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/me/pictures/{portraitset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific user picture
#
# GET /me/pictures/{portraitset_id}
# operationId: get_picture_alt1
export def "me-pictures get-alt1" [
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/me/pictures/{portraitset_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a user picture
#
# PATCH /me/pictures/{portraitset_id}
# operationId: edit_picture_alt1
export def "me-pictures update-edit-alt1" [
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/me/pictures/{portraitset_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/portfolios" $qp)
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get a specific portfolio
#
# GET /me/portfolios/{portfolio_id}
# operationId: get_portfolio_alt1
export def "me-portfolios get-alt1" [
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  let full_url = (build-url $base ({portfolio_id: (encode-path-segment $portfolio_id)} | format pattern "/me/portfolios/{portfolio_id}"))
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos
# operationId: get_portfolio_videos_alt1
export def "me-portfolios-videos list" [
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-13 # The way to sort the results. Option descriptions: * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({portfolio_id: (encode-path-segment $portfolio_id)} | format pattern "/me/portfolios/{portfolio_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from a portfolio
#
# DELETE /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio_alt1
export def "me-portfolios-videos delete-from-alt1" [
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in a portfolio
#
# GET /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: get_portfolio_video_alt1
export def "me-portfolios-videos get-alt1" [
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to a portfolio
#
# PUT /me/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio_alt1
export def "me-portfolios-videos create-to-alt1" [
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the embed presets that a user has created
#
# GET /me/presets
# operationId: get_embed_presets_alt1
export def "me-presets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a specific embed preset
#
# GET /me/presets/{preset_id}
# operationId: get_embed_preset_alt1
export def "me-presets get-embed-alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({preset_id: (encode-path-segment $preset_id)} | format pattern "/me/presets/{preset_id}"))
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an embed preset
#
# PATCH /me/presets/{preset_id}
# operationId: edit_embed_preset_alt1
export def "me-presets update-edit-embed-alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({preset_id: (encode-path-segment $preset_id)} | format pattern "/me/presets/{preset_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.preset+json" $req_body {query: {}, body: $req_body}
}

# Get all the videos that have been added to an embed preset
#
# GET /me/presets/{preset_id}/videos
# operationId: get_embed_preset_videos_alt1
export def "me-presets-videos get-embed-alt1" [
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({preset_id: (encode-path-segment $preset_id)} | format pattern "/me/presets/{preset_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get all the projects that belong to a user
#
# GET /me/projects
# operationId: get_projects_alt1
export def "me-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Create a project
#
# POST /me/projects
# operationId: create_project_alt1
export def "me-projects create-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/projects")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project
#
# DELETE /me/projects/{project_id}
# operationId: delete_project_alt1
export def "me-projects delete-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"should_delete_clips": $should_delete_clips} | compact), body: null}
}

# Get a specific project
#
# GET /me/projects/{project_id}
# operationId: get_project_alt1
export def "me-projects get-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a project
#
# PATCH /me/projects/{project_id}
# operationId: edit_project_alt1
export def "me-projects update-edit-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a list of videos from a project
#
# DELETE /me/projects/{project_id}/videos
# operationId: remove_videos_from_project_alt1
export def "me-projects-videos delete-from-alt1-by-project-id" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"should_delete_clips": $should_delete_clips, "uris": $uris} | compact), body: null}
}

# Get all the videos in a project
#
# GET /me/projects/{project_id}/videos
# operationId: get_project_videos_alt1
export def "me-projects-videos get-alt1" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Add a list of videos to a project
#
# PUT /me/projects/{project_id}/videos
# operationId: add_videos_to_project_alt1
export def "me-projects-videos create-to-alt1-by-project-id" [
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/me/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"uris": $uris} | compact), body: null}
}

# Remove a specific video from a project
#
# DELETE /me/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project_alt1
export def "me-projects-videos delete-from-alt1-by-project-id-video-id" [
  project_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/projects/{project_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific video to a project
#
# PUT /me/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project_alt1
export def "me-projects-videos create-to-alt1-by-project-id-video-id" [
  project_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), video_id: (encode-path-segment $video_id)} | format pattern "/me/projects/{project_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos that a user has uploaded
#
# GET /me/videos
# operationId: get_videos_alt1
export def "me-videos get-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "filter_playable" $filter_playable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "filter_playable": $filter_playable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Upload a video
#
# POST /me/videos
# operationId: upload_video_alt1
export def "me-videos upload-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/videos")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video+json" $req_body {query: {}, body: $req_body}
}

# Check if a user owns a video
#
# GET /me/videos/{video_id}
# operationId: check_if_user_owns_video_alt1
export def "me-videos check-if-user-owns-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a user's watch history
#
# DELETE /me/watched/videos
# operationId: delete_watch_history
export def "me-watched-videos delete-watch-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/watched/videos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos that a user has watched
#
# GET /me/watched/videos
# operationId: get_watch_history
export def "me-watched-videos get-watch-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Delete a specific video from a user's watch history
#
# DELETE /me/watched/videos/{video_id}
# operationId: delete_from_watch_history
export def "me-watched-videos delete-from-watch-history" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/watched/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos in a user's Watch Later queue
#
# GET /me/watchlater
# operationId: get_watch_later_queue_alt1
export def "me-watchlater get-watch-later-queue-alt1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/me/watchlater" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from a user's Watch Later queue
#
# DELETE /me/watchlater/{video_id}
# operationId: delete_video_from_watch_later_alt1
export def "me-watchlater delete-from-watch-later-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/watchlater/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /me/watchlater/{video_id}
# operationId: check_watch_later_queue_alt1
export def "me-watchlater check-watch-later-queue-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/watchlater/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to a user's Watch Later queue
#
# PUT /me/watchlater/{video_id}
# operationId: add_video_to_watch_later_alt1
export def "me-watchlater create-to-watch-later-alt1" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/me/watchlater/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Exchange an authorization code for an access token
#
# POST /oauth/access_token
# operationId: exchange_auth_code
export def "oauth-access-token create-exchange-auth-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/access_token")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.auth+json" $req_body {query: {}, body: $req_body}
}

# Authorize a client with OAuth
#
# POST /oauth/authorize/client
# operationId: client_auth
export def "oauth-authorize-client create-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/authorize/client")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.auth+json" $req_body {query: {}, body: $req_body}
}

# Convert OAuth 1 access tokens to OAuth 2 access tokens
#
# POST /oauth/authorize/vimeo_oauth1
# operationId: convert_access_token
export def "oauth-authorize-vimeo-oauth1 create-convert-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/authorize/vimeo_oauth1")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.auth+json" $req_body {query: {}, body: $req_body}
}

# Verify an OAuth 2 token
#
# GET /oauth/verify
# operationId: verify_token
export def "oauth-verify verify-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/verify")
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all On Demand genres
#
# GET /ondemand/genres
# operationId: get_vod_genres
export def "ondemand-genres list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ondemand/genres")
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific On Demand genre
#
# GET /ondemand/genres/{genre_id}
# operationId: get_vod_genre
export def "ondemand-genres get-vod" [
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  let full_url = (build-url $base ({genre_id: (encode-path-segment $genre_id)} | format pattern "/ondemand/genres/{genre_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the On Demand pages in a genre
#
# GET /ondemand/genres/{genre_id}/pages
# operationId: get_genre_vods
export def "ondemand-genres-pages get-vods" [
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-10 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-17 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({genre_id: (encode-path-segment $genre_id)} | format pattern "/ondemand/genres/{genre_id}/pages") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get a specific On Demand page in a genre
#
# GET /ondemand/genres/{genre_id}/pages/{ondemand_id}
# operationId: get_genre_vod
export def "ondemand-genres-pages get-vod" [
  genre_id: string
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({genre_id: (encode-path-segment $genre_id), ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/genres/{genre_id}/pages/{ondemand_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a draft of an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}
# operationId: delete_vod_draft
export def "ondemand-pages delete-vod-draft" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific On Demand page
#
# GET /ondemand/pages/{ondemand_id}
# operationId: get_vod
export def "ondemand-pages get-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}
# operationId: edit_vod
export def "ondemand-pages update-edit-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.ondemand.page+json" $req_body {query: {}, body: $req_body}
}

# Get all the backgrounds of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds
# operationId: get_vod_backgrounds
export def "ondemand-pages-backgrounds list" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/backgrounds") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a background to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/backgrounds
# operationId: create_vod_background
export def "ondemand-pages-backgrounds create-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/backgrounds"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a background from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: delete_vod_background
export def "ondemand-pages-backgrounds delete-vod" [
  ondemand_id: float
  background_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($background_id | is-empty) { error make --unspanned { msg: "path parameter 'background_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), background_id: (encode-path-segment $background_id)} | format pattern "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific background of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: get_vod_background
export def "ondemand-pages-backgrounds get-vod" [
  ondemand_id: float
  background_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($background_id | is-empty) { error make --unspanned { msg: "path parameter 'background_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), background_id: (encode-path-segment $background_id)} | format pattern "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a background of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/backgrounds/{background_id}
# operationId: edit_vod_background
export def "ondemand-pages-backgrounds update-edit-vod" [
  ondemand_id: float
  background_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($background_id | is-empty) { error make --unspanned { msg: "path parameter 'background_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), background_id: (encode-path-segment $background_id)} | format pattern "/ondemand/pages/{ondemand_id}/backgrounds/{background_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/genres"))
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a genre from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: delete_vod_genre
export def "ondemand-pages-genres delete-vod" [
  ondemand_id: float
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), genre_id: (encode-path-segment $genre_id)} | format pattern "/ondemand/pages/{ondemand_id}/genres/{genre_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check whether an On Demand page belongs to a genre
#
# GET /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: get_vod_genre_by_ondemand_id
export def "ondemand-pages-genres get-vod" [
  ondemand_id: float
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), genre_id: (encode-path-segment $genre_id)} | format pattern "/ondemand/pages/{ondemand_id}/genres/{genre_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a genre to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/genres/{genre_id}
# operationId: add_vod_genre
export def "ondemand-pages-genres create-vod" [
  ondemand_id: float
  genre_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($genre_id | is-empty) { error make --unspanned { msg: "path parameter 'genre_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), genre_id: (encode-path-segment $genre_id)} | format pattern "/ondemand/pages/{ondemand_id}/genres/{genre_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.genre+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the users who have liked a video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/likes
# operationId: get_vod_likes
export def "ondemand-pages-likes get-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-11 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/likes") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get all the posters of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures
# operationId: get_vod_posters
export def "ondemand-pages-pictures get-vod-posters" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/pictures") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a poster to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/pictures
# operationId: add_vod_poster
export def "ondemand-pages-pictures create-vod-poster" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/pictures"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific poster of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# operationId: get_vod_poster
export def "ondemand-pages-pictures get-vod" [
  ondemand_id: float
  poster_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($poster_id | is-empty) { error make --unspanned { msg: "path parameter 'poster_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), poster_id: (encode-path-segment $poster_id)} | format pattern "/ondemand/pages/{ondemand_id}/pictures/{poster_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a poster of an On Demand page
#
# PATCH /ondemand/pages/{ondemand_id}/pictures/{poster_id}
# operationId: edit_vod_poster
export def "ondemand-pages-pictures update-edit-vod" [
  ondemand_id: float
  poster_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($poster_id | is-empty) { error make --unspanned { msg: "path parameter 'poster_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), poster_id: (encode-path-segment $poster_id)} | format pattern "/ondemand/pages/{ondemand_id}/pictures/{poster_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Get all the promotions on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions
# operationId: get_vod_promotions
export def "ondemand-pages-promotions list" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-12 # The filter to apply to the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/promotions") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a promotion to an On Demand page
#
# POST /ondemand/pages/{ondemand_id}/promotions
# operationId: create_vod_promotion
export def "ondemand-pages-promotions create-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/promotions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.ondemand.promotion+json" $req_body {query: {}, body: $req_body}
}

# Remove a promotion from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# operationId: delete_vod_promotion
export def "ondemand-pages-promotions delete-vod" [
  ondemand_id: float
  promotion_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), promotion_id: (encode-path-segment $promotion_id)} | format pattern "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}
# operationId: get_vod_promotion
export def "ondemand-pages-promotions get-vod" [
  ondemand_id: float
  promotion_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), promotion_id: (encode-path-segment $promotion_id)} | format pattern "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.promotion+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the codes of a promotion on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/promotions/{promotion_id}/codes
# operationId: get_vod_promotion_codes
export def "ondemand-pages-promotions-codes get-vod" [
  ondemand_id: float
  promotion_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($promotion_id | is-empty) { error make --unspanned { msg: "path parameter 'promotion_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), promotion_id: (encode-path-segment $promotion_id)} | format pattern "/ondemand/pages/{ondemand_id}/promotions/{promotion_id}/codes") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.promocode+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Remove a list of regions from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions
# operationId: delete_vod_regions
export def "ondemand-pages-regions delete-vod-by-ondemand-id" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/regions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.ondemand.region+json" $req_body {query: {}, body: $req_body}
}

# Get all the regions of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions
# operationId: get_vod_regions
export def "ondemand-pages-regions list" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/regions"))
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a list of regions to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions
# operationId: set_vod_regions
export def "ondemand-pages-regions update-vod" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/regions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.ondemand.region+json" $req_body {query: {}, body: $req_body}
}

# Remove a specific region from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: delete_vod_region
export def "ondemand-pages-regions delete-vod-by-ondemand-id-country" [
  ondemand_id: float
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), country: (encode-path-segment $country)} | format pattern "/ondemand/pages/{ondemand_id}/regions/{country}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific region of an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: get_vod_region
export def "ondemand-pages-regions get-vod" [
  ondemand_id: float
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), country: (encode-path-segment $country)} | format pattern "/ondemand/pages/{ondemand_id}/regions/{country}"))
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific region to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/regions/{country}
# operationId: add_vod_region
export def "ondemand-pages-regions create-vod" [
  ondemand_id: float
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), country: (encode-path-segment $country)} | format pattern "/ondemand/pages/{ondemand_id}/regions/{country}"))
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the seasons on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons
# operationId: get_vod_seasons
export def "ondemand-pages-seasons list" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-18 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/seasons") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.season+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get a specific season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}
# operationId: get_vod_season
export def "ondemand-pages-seasons get-vod" [
  ondemand_id: float
  season_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($season_id | is-empty) { error make --unspanned { msg: "path parameter 'season_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), season_id: (encode-path-segment $season_id)} | format pattern "/ondemand/pages/{ondemand_id}/seasons/{season_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.season+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos in a season on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/seasons/{season_id}/videos
# operationId: get_vod_season_videos
export def "ondemand-pages-seasons-videos get-vod" [
  ondemand_id: float
  season_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-13 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-19 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($season_id | is-empty) { error make --unspanned { msg: "path parameter 'season_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), season_id: (encode-path-segment $season_id)} | format pattern "/ondemand/pages/{ondemand_id}/seasons/{season_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get all the videos on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos
# operationId: get_vod_videos
export def "ondemand-pages-videos list" [
  ondemand_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-14 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-20 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id)} | format pattern "/ondemand/pages/{ondemand_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from an On Demand page
#
# DELETE /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: delete_video_from_vod
export def "ondemand-pages-videos delete-from-vod" [
  ondemand_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), video_id: (encode-path-segment $video_id)} | format pattern "/ondemand/pages/{ondemand_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video on an On Demand page
#
# GET /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: get_vod_video
export def "ondemand-pages-videos get-vod" [
  ondemand_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), video_id: (encode-path-segment $video_id)} | format pattern "/ondemand/pages/{ondemand_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to an On Demand page
#
# PUT /ondemand/pages/{ondemand_id}/videos/{video_id}
# operationId: add_video_to_vod
export def "ondemand-pages-videos create-to-vod" [
  ondemand_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ondemand_id | is-empty) { error make --unspanned { msg: "path parameter 'ondemand_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({ondemand_id: (encode-path-segment $ondemand_id), video_id: (encode-path-segment $video_id)} | format pattern "/ondemand/pages/{ondemand_id}/videos/{video_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.ondemand.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.ondemand.video+json" $req_body {query: {}, body: $req_body}
}

# Get all the On Demand regions
#
# GET /ondemand/regions
# operationId: get_regions
export def "ondemand-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ondemand/regions")
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific On Demand region
#
# GET /ondemand/regions/{country}
# operationId: get_region
export def "ondemand-regions get" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($country | is-empty) { error make --unspanned { msg: "path parameter 'country' must be non-empty" } }
  let full_url = (build-url $base ({country: (encode-path-segment $country)} | format pattern "/ondemand/regions/{country}"))
  let accept_val = "application/vnd.vimeo.ondemand.region+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific tag
#
# GET /tags/{word}
# operationId: get_tag
export def "tags get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/tags/{word}"))
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos with a specific tag
#
# GET /tags/{word}/videos
# operationId: get_videos_with_tag
export def "tags-videos get" [
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-21 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({word: (encode-path-segment $word)} | format pattern "/tags/{word}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Revoke the current access token
#
# DELETE /tokens
# operationId: delete_token
export def "tokens delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tokens")
  let accept_val = "application/vnd.vimeo.auth+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for users
#
# GET /users
# operationId: search_users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-4 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get a user
#
# GET /users/{user_id}
# operationId: get_user
export def "users get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a user
#
# PATCH /users/{user_id}
# operationId: edit_user
export def "users update-edit" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.user+json" $req_body {query: {}, body: $req_body}
}

# Get all the albums that belong to a user
#
# GET /users/{user_id}/albums
# operationId: get_albums
export def "users-albums list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-8 # The way to sort the results.
]: nothing -> table<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, web_brand_color: bool, web_custom_logo: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/albums") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Create an album
#
# POST /users/{user_id}/albums
# operationId: create_album
export def "users-albums create" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/albums"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.album+json" $req_body {query: {}, body: $req_body}
}

# Delete an album
#
# DELETE /users/{user_id}/albums/{album_id}
# operationId: delete_album
export def "users-albums delete" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific album
#
# GET /users/{user_id}/albums/{album_id}
# operationId: get_album
export def "users-albums get" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}"))
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an album
#
# PATCH /users/{user_id}/albums/{album_id}
# operationId: edit_album
export def "users-albums update-edit" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.album+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.album+json" $req_body {query: {}, body: $req_body}
}

# Get all the custom upload thumbnails of an album
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails
# operationId: get_album_custom_thumbs
export def "users-albums-custom-thumbnails get-thumbs" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/custom_thumbnails") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a custom uploaded thumbnail
#
# POST /users/{user_id}/albums/{album_id}/custom_thumbnails
# operationId: create_album_custom_thumb
export def "users-albums-custom-thumbnails create-thumb" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/custom_thumbnails"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a custom uploaded album thumbnail
#
# DELETE /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: delete_album_custom_thumbnail
export def "users-albums-custom-thumbnails delete" [
  user_id: float
  album_id: float
  thumbnail_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($thumbnail_id | is-empty) { error make --unspanned { msg: "path parameter 'thumbnail_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), thumbnail_id: (encode-path-segment $thumbnail_id)} | format pattern "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific custom uploaded album thumbnail
#
# GET /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: get_album_custom_thumbnail
export def "users-albums-custom-thumbnails get" [
  user_id: float
  album_id: float
  thumbnail_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($thumbnail_id | is-empty) { error make --unspanned { msg: "path parameter 'thumbnail_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), thumbnail_id: (encode-path-segment $thumbnail_id)} | format pattern "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Replace a custom uploaded album thumbnail
#
# PATCH /users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}
# operationId: replace_album_custom_thumb
export def "users-albums-custom-thumbnails update-thumb" [
  user_id: float
  album_id: float
  thumbnail_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($thumbnail_id | is-empty) { error make --unspanned { msg: "path parameter 'thumbnail_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), thumbnail_id: (encode-path-segment $thumbnail_id)} | format pattern "/users/{user_id}/albums/{album_id}/custom_thumbnails/{thumbnail_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Get all the custom logos of an album
#
# GET /users/{user_id}/albums/{album_id}/logos
# operationId: get_album_logos
export def "users-albums-logos list" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/logos") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a custom album logo
#
# POST /users/{user_id}/albums/{album_id}/logos
# operationId: create_album_logo
export def "users-albums-logos create" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/logos"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a custom album logo
#
# DELETE /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: delete_album_logo
export def "users-albums-logos delete" [
  user_id: float
  album_id: float
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($logo_id | is-empty) { error make --unspanned { msg: "path parameter 'logo_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), logo_id: (encode-path-segment $logo_id)} | format pattern "/users/{user_id}/albums/{album_id}/logos/{logo_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific custom album logo
#
# GET /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: get_album_logo
export def "users-albums-logos get" [
  user_id: float
  album_id: float
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($logo_id | is-empty) { error make --unspanned { msg: "path parameter 'logo_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), logo_id: (encode-path-segment $logo_id)} | format pattern "/users/{user_id}/albums/{album_id}/logos/{logo_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Replace a custom album logo
#
# PATCH /users/{user_id}/albums/{album_id}/logos/{logo_id}
# operationId: replace_album_logo
export def "users-albums-logos update" [
  user_id: float
  album_id: float
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($logo_id | is-empty) { error make --unspanned { msg: "path parameter 'logo_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), logo_id: (encode-path-segment $logo_id)} | format pattern "/users/{user_id}/albums/{album_id}/logos/{logo_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Get all the videos in an album
#
# GET /users/{user_id}/albums/{album_id}/videos
# operationId: get_album_videos
export def "users-albums-videos list" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page containing the video URI. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --password: string # The password of the album. (e.g. hunter1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-9 # The way to sort the results.
  --weak-search: oneof<nothing, bool> # Whether to include private videos in the search. Please note that a separate search service provides this functionality. The service performs a partial text search on the video's name. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "password" $password "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "weak_search" $weak_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "password": $password, "per_page": $per_page, "query": $query, "sort": $qp_sort, "weak_search": $weak_search} | compact), body: null}
}

# Replace all the videos in an album
#
# PUT /users/{user_id}/albums/{album_id}/videos
# operationId: replace_videos_in_album
export def "users-albums-videos update" [
  user_id: float
  album_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  videos: string # A comma-separated list of video URIs. (e.g. /videos/258684937,/videos/273576296)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos"))
  let req_body = {"videos": $videos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a video from an album
#
# DELETE /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: remove_video_from_album
export def "users-albums-videos delete" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in an album
#
# GET /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: get_album_video
export def "users-albums-videos get" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password of the album. (e.g. hunter1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos/{video_id}") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"password": $password} | compact), body: null}
}

# Add a specific video to an album
#
# PUT /users/{user_id}/albums/{album_id}/videos/{video_id}
# operationId: add_video_to_album
export def "users-albums-videos create" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set a video as the album thumbnail
#
# POST /users/{user_id}/albums/{album_id}/videos/{video_id}/set_album_thumbnail
# operationId: set_video_as_album_thumbnail
export def "users-albums-videos-set-album-thumbnail update" [
  user_id: float
  album_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-code: float # The video frame time in seconds to use as the album thumbnail. (e.g. 300)
]: any -> record<allow_continuous_play: bool, allow_downloads: bool, allow_share: bool, brand_color: string, created_time: string, custom_logo: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, description: string, domain: string, duration: float, embed: record<html: string>, embed_brand_color: bool, embed_custom_logo: bool, hide_nav: bool, hide_vimeo_logo: bool, layout: string, link: string, metadata: record<connections: record<videos: record>, interactions: record<add_custom_thumbnails: record, add_logos: record, add_videos: record>>, modified_time: string, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list<record>, type: string, uri: string>, privacy: record<password: string, view: string>, resource_key: string, review_mode: bool, sort: string, theme: string, uri: string, url: string, use_custom_domain: bool, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>, web_brand_color: bool, web_custom_logo: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'album_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), album_id: (encode-path-segment $album_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/albums/{album_id}/videos/{video_id}/set_album_thumbnail"))
  let req_body = {"time_code": $time_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all the videos in which a user appears
#
# GET /users/{user_id}/appearances
# operationId: get_appearances
export def "users-appearances get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/appearances") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the categories that a user follows
#
# GET /users/{user_id}/categories
# operationId: get_category_subscriptions
export def "users-categories get-category-subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-10 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/categories") $qp)
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Unsubscribe a user from a category
#
# DELETE /users/{user_id}/categories/{category}
# operationId: unsubscribe_from_category
export def "users-categories unsubscribe" [
  user_id: float
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), category: (encode-path-segment $category)} | format pattern "/users/{user_id}/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user follows a category
#
# GET /users/{user_id}/categories/{category}
# operationId: check_if_user_subscribed_to_category
export def "users-categories check-if-subscribed" [
  user_id: float
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), category: (encode-path-segment $category)} | format pattern "/users/{user_id}/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Subscribe a user to a single category
#
# PUT /users/{user_id}/categories/{category}
# operationId: subscribe_to_category
export def "users-categories subscribe" [
  user_id: float
  category: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), category: (encode-path-segment $category)} | format pattern "/users/{user_id}/categories/{category}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the channels to which a user subscribes
#
# GET /users/{user_id}/channels
# operationId: get_channel_subscriptions
export def "users-channels get-subscriptions" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-1 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/channels") $qp)
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Unsubscribe a user from a specific channel
#
# DELETE /users/{user_id}/channels/{channel_id}
# operationId: unsubscribe_from_channel
export def "users-channels unsubscribe" [
  user_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/users/{user_id}/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user follows a channel
#
# GET /users/{user_id}/channels/{channel_id}
# operationId: check_if_user_subscribed_to_channel
export def "users-channels check-if-subscribed" [
  user_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/users/{user_id}/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Subscribe a user to a specific channel
#
# PUT /users/{user_id}/channels/{channel_id}
# operationId: subscribe_to_channel
export def "users-channels subscribe" [
  user_id: float
  channel_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), channel_id: (encode-path-segment $channel_id)} | format pattern "/users/{user_id}/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the custom logos that belong to a user
#
# GET /users/{user_id}/customlogos
# operationId: get_custom_logos
export def "users-customlogos get-custom-logos" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customlogos"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a custom logo
#
# POST /users/{user_id}/customlogos
# operationId: create_custom_logo
export def "users-customlogos create-custom-logo" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customlogos"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific custom logo
#
# GET /users/{user_id}/customlogos/{logo_id}
# operationId: get_custom_logo
export def "users-customlogos get-custom" [
  user_id: float
  logo_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($logo_id | is-empty) { error make --unspanned { msg: "path parameter 'logo_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), logo_id: (encode-path-segment $logo_id)} | format pattern "/users/{user_id}/customlogos/{logo_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all videos in a user's feed
#
# GET /users/{user_id}/feed
# operationId: get_feed
export def "users-feed get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: string # Necessary for proper pagination. You shouldn't provide this value yourself, and instead use the pagination links in the feed response. Please see our [pagination documentation](https://developer.vimeo.com/api/common-formats#using-the-pagination-parameter) for more information. (e.g. 280)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --type: string@type-completer # The feed type.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/feed") $qp)
  let accept_val = "application/vnd.vimeo.activity+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "page": $page, "per_page": $per_page, "type": $type} | compact), body: null}
}

# Get all the followers of a user
#
# GET /users/{user_id}/followers
# operationId: get_followers
export def "users-followers get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/followers") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get all the users that a user is following
#
# GET /users/{user_id}/following
# operationId: get_user_following
export def "users-following get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-6 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/following") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Follow a list of users
#
# POST /users/{user_id}/following
# operationId: follow_users
export def "users-following create-follow" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string> # An array of user URIs for the list of users to follow.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/following"))
  let req_body = {"users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unfollow a user
#
# DELETE /users/{user_id}/following/{follow_user_id}
# operationId: unfollow_user
export def "users-following delete-unfollow" [
  user_id: float
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/users/{user_id}/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user is following another user
#
# GET /users/{user_id}/following/{follow_user_id}
# operationId: check_if_user_is_following
export def "users-following check-if-is" [
  user_id: float
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/users/{user_id}/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Follow a specific user
#
# PUT /users/{user_id}/following/{follow_user_id}
# operationId: follow_user
export def "users-following update" [
  user_id: float
  follow_user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($follow_user_id | is-empty) { error make --unspanned { msg: "path parameter 'follow_user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), follow_user_id: (encode-path-segment $follow_user_id)} | format pattern "/users/{user_id}/following/{follow_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the groups that a user has joined
#
# GET /users/{user_id}/groups
# operationId: get_user_groups
export def "users-groups get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-5 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-2 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/groups") $qp)
  let accept_val = "application/vnd.vimeo.group+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a user from a group
#
# DELETE /users/{user_id}/groups/{group_id}
# operationId: leave_group
export def "users-groups delete-leave" [
  user_id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id)} | format pattern "/users/{user_id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has joined a group
#
# GET /users/{user_id}/groups/{group_id}
# operationId: check_if_user_joined_group
export def "users-groups check-if-joined" [
  user_id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id)} | format pattern "/users/{user_id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a user to a group
#
# PUT /users/{user_id}/groups/{group_id}
# operationId: join_group
export def "users-groups update-join" [
  user_id: float
  group_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'group_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), group_id: (encode-path-segment $group_id)} | format pattern "/users/{user_id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos that a user has liked
#
# GET /users/{user_id}/likes
# operationId: get_likes
export def "users-likes get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/likes") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Cause a user to unlike a video
#
# DELETE /users/{user_id}/likes/{video_id}
# operationId: unlike_video
export def "users-likes delete-unlike" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has liked a video
#
# GET /users/{user_id}/likes/{video_id}
# operationId: check_if_user_liked_video
export def "users-likes check-if-liked" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cause a user to like a video
#
# PUT /users/{user_id}/likes/{video_id}
# operationId: like_video
export def "users-likes update" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/likes/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the On Demand pages of a user
#
# GET /users/{user_id}/ondemand/pages
# operationId: get_user_vods
export def "users-ondemand-pages get-vods" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-7 # The type of On Demand pages to return.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-11 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/ondemand/pages") $qp)
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Create an On Demand page
#
# POST /users/{user_id}/ondemand/pages
# operationId: create_vod
# --buy shape: {active?: bool, download?: bool, price?: record}
# --episodes shape: {buy?: record, rent?: record}
# --rent shape: {active?: bool, period?: "1 week"|"1 year"|"24 hour"|"3 month"|"30 day"|"48 hour"|"6 month"|"72 hour", price?: record}
# --subscription shape: {monthly?: record}
export def "users-ondemand-pages create-vod" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-currencies: string@accepted-currencies-completer # An array of accepted currencies. Option descriptions: * `AUD` - Australian Dollar * `CAD` - Canadian Dollar * `CHF` - Swiss Franc * `DKK` - Danish Krone * `EUR` - Euro * `GBP` - British Pound * `JPY` - Japanese Yen * `KRW` - South Korean Won * `NOK` - Norwegian Krone * `PLN` - Polish Zloty * `SEK` - Swedish Krona * `USD` - US Dollar
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/ondemand/pages"))
  let req_body = {"accepted_currencies": $accepted_currencies, "buy": $buy, "content_rating": $content_rating, "description": $description, "domain_link": $domain_link, "episodes": $episodes, "link": $link, "name": $name, "rent": $rent, "subscription": $subscription, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Check if a user has made a purchase or rental from an On Demand page
#
# GET /users/{user_id}/ondemand/purchases
# operationId: check_if_vod_was_purchased
export def "users-ondemand-purchases check-if-vod-was-purchased" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/ondemand/purchases"))
  let accept_val = "application/vnd.vimeo.ondemand.page+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the pictures that belong to a user
#
# GET /users/{user_id}/pictures
# operationId: get_pictures
export def "users-pictures list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/pictures") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a user picture
#
# POST /users/{user_id}/pictures
# operationId: create_picture
export def "users-pictures create" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/pictures"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a user picture
#
# DELETE /users/{user_id}/pictures/{portraitset_id}
# operationId: delete_picture
export def "users-pictures delete" [
  user_id: float
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/users/{user_id}/pictures/{portraitset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific user picture
#
# GET /users/{user_id}/pictures/{portraitset_id}
# operationId: get_picture
export def "users-pictures get" [
  user_id: float
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/users/{user_id}/pictures/{portraitset_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a user picture
#
# PATCH /users/{user_id}/pictures/{portraitset_id}
# operationId: edit_picture
export def "users-pictures update-edit" [
  user_id: float
  portraitset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portraitset_id | is-empty) { error make --unspanned { msg: "path parameter 'portraitset_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portraitset_id: (encode-path-segment $portraitset_id)} | format pattern "/users/{user_id}/pictures/{portraitset_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Get all the portfolios that belong to a user
#
# GET /users/{user_id}/portfolios
# operationId: get_portfolios
export def "users-portfolios list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/portfolios") $qp)
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Get a specific portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}
# operationId: get_portfolio
export def "users-portfolios get" [
  user_id: float
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portfolio_id: (encode-path-segment $portfolio_id)} | format pattern "/users/{user_id}/portfolios/{portfolio_id}"))
  let accept_val = "application/vnd.vimeo.portfolio+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos
# operationId: get_portfolio_videos
export def "users-portfolios-videos list" [
  user_id: float
  portfolio_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. (e.g. /videos/258684937)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-13 # The way to sort the results. Option descriptions: * `default` - This will sort to the default sort set on the portfolio.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portfolio_id: (encode-path-segment $portfolio_id)} | format pattern "/users/{user_id}/portfolios/{portfolio_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from a portfolio
#
# DELETE /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: delete_video_from_portfolio
export def "users-portfolios-videos delete" [
  user_id: float
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video in a portfolio
#
# GET /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: get_portfolio_video
export def "users-portfolios-videos get" [
  user_id: float
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to a portfolio
#
# PUT /users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}
# operationId: add_video_to_portfolio
export def "users-portfolios-videos create" [
  user_id: float
  portfolio_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($portfolio_id | is-empty) { error make --unspanned { msg: "path parameter 'portfolio_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), portfolio_id: (encode-path-segment $portfolio_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/portfolios/{portfolio_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the embed presets that a user has created
#
# GET /users/{user_id}/presets
# operationId: get_embed_presets
export def "users-presets list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/presets") $qp)
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a specific embed preset
#
# GET /users/{user_id}/presets/{preset_id}
# operationId: get_embed_preset
export def "users-presets get-embed" [
  user_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/users/{user_id}/presets/{preset_id}"))
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an embed preset
#
# PATCH /users/{user_id}/presets/{preset_id}
# operationId: edit_embed_preset
export def "users-presets update-edit-embed" [
  user_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/users/{user_id}/presets/{preset_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.preset+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.preset+json" $req_body {query: {}, body: $req_body}
}

# Get all the videos that have been added to an embed preset
#
# GET /users/{user_id}/presets/{preset_id}/videos
# operationId: get_embed_preset_videos
export def "users-presets-videos get-embed" [
  user_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/users/{user_id}/presets/{preset_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get all the projects that belong to a user
#
# GET /users/{user_id}/projects
# operationId: get_projects
export def "users-projects list" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-14 # The way to sort the results.
]: nothing -> table<created_time: string, metadata: record<connections: record>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/projects") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Create a project
#
# POST /users/{user_id}/projects
# operationId: create_project
export def "users-projects create" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/projects"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a project
#
# DELETE /users/{user_id}/projects/{project_id}
# operationId: delete_project
export def "users-projects delete" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete all the videos in the project along with the project itself. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"should_delete_clips": $should_delete_clips} | compact), body: null}
}

# Get a specific project
#
# GET /users/{user_id}/projects/{project_id}
# operationId: get_project
export def "users-projects get" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a project
#
# PATCH /users/{user_id}/projects/{project_id}
# operationId: edit_project
export def "users-projects update-edit" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project. (e.g. Rough cuts)
]: any -> record<created_time: string, metadata: record<connections: record<videos: record>>, modified_time: string, name: string, resource_key: string, uri: string, user: record<account: string, bio: string, content_filter: list<string>, created_time: string, email: string, link: string, location: string, metadata: record<connections: record, interactions: record>, name: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, preferences: record<videos: record>, resource_key: string, upload_quota: record<lifetime: record, periodic: record, space: record>, uri: string, websites: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove a list of videos from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos
# operationId: remove_videos_from_project
export def "users-projects-videos delete-by-user-id-project-id" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --should-delete-clips: oneof<nothing, bool> # Whether to delete the videos when removing them from the project. (e.g. false)
  --uris: string # A comma-separated list of the video URIs to remove. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "should_delete_clips" $should_delete_clips "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"should_delete_clips": $should_delete_clips, "uris": $uris} | compact), body: null}
}

# Get all the videos in a project
#
# GET /users/{user_id}/projects/{project_id}/videos
# operationId: get_project_videos
export def "users-projects-videos get" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-15 # The way to sort the results.
]: nothing -> table<categories: list<record>, content_rating: list<string>, context: record<action: string, resource: record, resource_type: string>, created_time: string, description: string, duration: float, embed: record<buttons: record, color: string, logos: record, playbar: bool, speed: bool, title: record, uri: string, volume: bool>, height: float, language: string, last_user_action_event_date: string, license: string, link: string, metadata: record<connections: record, interactions: record>, modified_time: string, name: string, parent_folder: record<created_time: string, metadata: record, modified_time: string, name: string, resource_key: string, uri: string, user: record>, password: string, pictures: record<active: bool, link: string, resource_key: string, sizes: list, type: string, uri: string>, privacy: record<add: bool, comments: string, download: bool, embed: string, view: string>, release_time: string, resource_key: string, spatial: record<director_timeline: list, field_of_view: float, projection: string, stereo_format: string>, stats: record<plays: float>, status: string, tags: list<record>, transcode: record<status: string>, upload: record<approach: string, complete_uri: string, form: string, link: string, redirect_url: string, size: float, status: string, upload_link: string>, uri: string, user: record<account: string, bio: string, content_filter: list, created_time: string, email: string, link: string, location: string, metadata: record, name: string, pictures: record, preferences: record, resource_key: string, upload_quota: record, uri: string, websites: list>, width: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Add a list of videos to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos
# operationId: add_videos_to_project
export def "users-projects-videos create-by-user-id-project-id" [
  user_id: float
  project_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: string # A comma-separated list of video URIs to add. (e.g. /videos/258684937,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  let qp = [(serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id)} | format pattern "/users/{user_id}/projects/{project_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"uris": $uris} | compact), body: null}
}

# Remove a specific video from a project
#
# DELETE /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: remove_video_from_project
export def "users-projects-videos delete-by-user-id-project-id-video-id" [
  user_id: float
  project_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/projects/{project_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific video to a project
#
# PUT /users/{user_id}/projects/{project_id}/videos/{video_id}
# operationId: add_video_to_project
export def "users-projects-videos create-by-user-id-project-id-video-id" [
  user_id: float
  project_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'project_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), project_id: (encode-path-segment $project_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/projects/{project_id}/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Complete a user's streaming upload
#
# DELETE /users/{user_id}/uploads/{upload}
# operationId: complete_streaming_upload
export def "users-uploads complete-streaming" [
  user_id: float
  upload: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --signature: string # The crypto signature of the completed upload. (e.g. cd89a20adde7a608f3331e71c37bdfa087bacbf3)
  --video-file-id: float # The ID of the uploaded file. (e.g. 1234)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($upload | is-empty) { error make --unspanned { msg: "path parameter 'upload' must be non-empty" } }
  let qp = [(serialize-qp "signature" $signature "scalar") (serialize-qp "video_file_id" $video_file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), upload: (encode-path-segment $upload)} | format pattern "/users/{user_id}/uploads/{upload}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"signature": $signature, "video_file_id": $video_file_id} | compact), body: null}
}

# Get a user's upload attempt
#
# GET /users/{user_id}/uploads/{upload}
# operationId: get_upload_attempt
export def "users-uploads get-attempt" [
  user_id: float
  upload: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($upload | is-empty) { error make --unspanned { msg: "path parameter 'upload' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), upload: (encode-path-segment $upload)} | format pattern "/users/{user_id}/uploads/{upload}"))
  let accept_val = "application/vnd.vimeo.uploadattempt+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos that a user has uploaded
#
# GET /users/{user_id}/videos
# operationId: get_videos
export def "users-videos get" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --containing-uri: string # The page that contains the video URI. Only available when not paired with `query`. (e.g. /videos/258684937)
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-9 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --filter-playable: oneof<nothing, bool> # Whether to filter by all playable videos or by all videos that are not playable. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-16 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "containing_uri" $containing_uri "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "filter_playable" $filter_playable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"containing_uri": $containing_uri, "direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "filter_playable": $filter_playable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Upload a video
#
# POST /users/{user_id}/videos
# operationId: upload_video
export def "users-videos upload" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/videos"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video+json" $req_body {query: {}, body: $req_body}
}

# Check if a user owns a video
#
# GET /users/{user_id}/videos/{video_id}
# operationId: check_if_user_owns_video
export def "users-videos check-if-owns" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the videos in a user's Watch Later queue
#
# GET /users/{user_id}/watchlater
# operationId: get_watch_later_queue
export def "users-watchlater get-watch-later-queue" [
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-3 # The attribute by which to filter the results.
  --filter-embeddable: oneof<nothing, bool> # Whether to filter the results by embeddable videos (`true`) or non-embeddable videos (`false`). Required only if **filter** is `embeddable`. (e.g. true)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-7 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filter_embeddable" $filter_embeddable "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/watchlater") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "filter_embeddable": $filter_embeddable, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Remove a video from a user's Watch Later queue
#
# DELETE /users/{user_id}/watchlater/{video_id}
# operationId: delete_video_from_watch_later
export def "users-watchlater delete-from-watch-later" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/watchlater/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a user has added a specific video to their Watch Later queue
#
# GET /users/{user_id}/watchlater/{video_id}
# operationId: check_watch_later_queue
export def "users-watchlater check-watch-later-queue" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/watchlater/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a video to a user's Watch Later queue
#
# PUT /users/{user_id}/watchlater/{video_id}
# operationId: add_video_to_watch_later
export def "users-watchlater create-to-watch-later" [
  user_id: float
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), video_id: (encode-path-segment $video_id)} | format pattern "/users/{user_id}/watchlater/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for videos
#
# GET /videos
# operationId: search_videos
export def "videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --filter: string@filter-completer-15 # The attribute by which to filter the results. `CC` and related filters target videos with the corresponding Creative Commons licenses. For more information, see our [Creative Commons](https://vimeo.com/creativecommons) page.
  --links: string # A comma-separated list of video URLs to find. (e.g. https://vimeo.com/122375452,https://vimeo.com/273576296)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # Search query. (e.g. staff picks)
  --qp-sort: string@sort-completer-22 # The way to sort the results.
  --uris: string # The comma-separated list of videos to find. (e.g. /videos/122375452,/videos/273576296)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "links" $links "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "uris" $uris "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "filter": $filter, "links": $links, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort, "uris": $uris} | compact), body: null}
}

# Delete a video
#
# DELETE /videos/{video_id}
# operationId: delete_video
export def "videos delete" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video
#
# GET /videos/{video_id}
# operationId: get_video
export def "videos get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a video
#
# PATCH /videos/{video_id}
# operationId: edit_video
export def "videos update-edit" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video+json" $req_body {query: {}, body: $req_body}
}

# Get all the channels to which a user can add or remove a specific video
#
# GET /videos/{video_id}/available_channels
# operationId: get_available_video_channels
export def "videos-available-channels get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/available_channels"))
  let accept_val = "application/vnd.vimeo.channel+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the categories to which a video belongs
#
# GET /videos/{video_id}/categories
# operationId: get_video_categories
export def "videos-categories get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/categories"))
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Suggest categories for a video
#
# PUT /videos/{video_id}/categories
# operationId: suggest_video_category
export def "videos-categories update-suggest-category" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/categories"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.category+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.category+json" $req_body {query: {}, body: $req_body}
}

# Get all the comments on a video
#
# GET /videos/{video_id}/comments
# operationId: get_comments
export def "videos-comments list" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/comments") $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a comment to a video
#
# POST /videos/{video_id}/comments
# operationId: create_comment
export def "videos-comments create" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/comments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.comment+json" $req_body {query: {}, body: $req_body}
}

# Delete a video comment
#
# DELETE /videos/{video_id}/comments/{comment_id}
# operationId: delete_comment
export def "videos-comments delete" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/videos/{video_id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific video comment
#
# GET /videos/{video_id}/comments/{comment_id}
# operationId: get_comment
export def "videos-comments get" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/videos/{video_id}/comments/{comment_id}"))
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a video comment
#
# PATCH /videos/{video_id}/comments/{comment_id}
# operationId: edit_comment
export def "videos-comments update-edit" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/videos/{video_id}/comments/{comment_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.comment+json" $req_body {query: {}, body: $req_body}
}

# Get all the replies to a video comment
#
# GET /videos/{video_id}/comments/{comment_id}/replies
# operationId: get_comment_replies
export def "videos-comments-replies get" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/videos/{video_id}/comments/{comment_id}/replies") $qp)
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a reply to a video comment
#
# POST /videos/{video_id}/comments/{comment_id}/replies
# operationId: create_comment_reply
export def "videos-comments-replies create-reply" [
  video_id: float
  comment_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'comment_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), comment_id: (encode-path-segment $comment_id)} | format pattern "/videos/{video_id}/comments/{comment_id}/replies"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.comment+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.comment+json" $req_body {query: {}, body: $req_body}
}

# Get all the credited users in a video
#
# GET /videos/{video_id}/credits
# operationId: get_video_credits
export def "videos-credits list" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --query: string # The search query to use to filter the results. (e.g. Stop motion)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/credits") $qp)
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort} | compact), body: null}
}

# Credit a user in a video
#
# POST /videos/{video_id}/credits
# operationId: add_video_credit
export def "videos-credits create" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/credits"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.credit+json" $req_body {query: {}, body: $req_body}
}

# Delete a credit for a user in a video
#
# DELETE /videos/{video_id}/credits/{credit_id}
# operationId: delete_video_credit
export def "videos-credits delete" [
  video_id: float
  credit_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($credit_id | is-empty) { error make --unspanned { msg: "path parameter 'credit_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), credit_id: (encode-path-segment $credit_id)} | format pattern "/videos/{video_id}/credits/{credit_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific credited user in a video
#
# GET /videos/{video_id}/credits/{credit_id}
# operationId: get_video_credit
export def "videos-credits get" [
  video_id: float
  credit_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($credit_id | is-empty) { error make --unspanned { msg: "path parameter 'credit_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), credit_id: (encode-path-segment $credit_id)} | format pattern "/videos/{video_id}/credits/{credit_id}"))
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a credit for a user in a video
#
# PATCH /videos/{video_id}/credits/{credit_id}
# operationId: edit_video_credit
export def "videos-credits update-edit" [
  video_id: float
  credit_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($credit_id | is-empty) { error make --unspanned { msg: "path parameter 'credit_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), credit_id: (encode-path-segment $credit_id)} | format pattern "/videos/{video_id}/credits/{credit_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.credit+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.credit+json" $req_body {query: {}, body: $req_body}
}

# Get all the users who have liked a video
#
# GET /videos/{video_id}/likes
# operationId: get_video_likes
export def "videos-likes get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string@direction-completer # The sort direction of the results. (e.g. asc)
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
  --qp-sort: string@sort-completer-5 # The way to sort the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/likes") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# Get all the thumbnails of a video
#
# GET /videos/{video_id}/pictures
# operationId: get_video_thumbnails
export def "videos-pictures get-thumbnails" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/pictures") $qp)
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Add a video thumbnail
#
# POST /videos/{video_id}/pictures
# operationId: create_video_thumbnail
export def "videos-pictures create-thumbnail" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/pictures"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Delete a video thumbnail
#
# DELETE /videos/{video_id}/pictures/{picture_id}
# operationId: delete_video_thumbnail
export def "videos-pictures delete-thumbnail" [
  video_id: float
  picture_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($picture_id | is-empty) { error make --unspanned { msg: "path parameter 'picture_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), picture_id: (encode-path-segment $picture_id)} | format pattern "/videos/{video_id}/pictures/{picture_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a video thumbnail
#
# GET /videos/{video_id}/pictures/{picture_id}
# operationId: get_video_thumbnail
export def "videos-pictures get-thumbnail" [
  video_id: float
  picture_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($picture_id | is-empty) { error make --unspanned { msg: "path parameter 'picture_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), picture_id: (encode-path-segment $picture_id)} | format pattern "/videos/{video_id}/pictures/{picture_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a video thumbnail
#
# PATCH /videos/{video_id}/pictures/{picture_id}
# operationId: edit_video_thumbnail
export def "videos-pictures update-edit-thumbnail" [
  video_id: float
  picture_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($picture_id | is-empty) { error make --unspanned { msg: "path parameter 'picture_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), picture_id: (encode-path-segment $picture_id)} | format pattern "/videos/{video_id}/pictures/{picture_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.picture+json" $req_body {query: {}, body: $req_body}
}

# Remove an embed preset from a video
#
# DELETE /videos/{video_id}/presets/{preset_id}
# operationId: delete_video_embed_preset
export def "videos-presets delete-embed" [
  video_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/videos/{video_id}/presets/{preset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if an embed preset has been added to a video
#
# GET /videos/{video_id}/presets/{preset_id}
# operationId: get_video_embed_preset
export def "videos-presets get-embed" [
  video_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/videos/{video_id}/presets/{preset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add an embed preset to a video
#
# PUT /videos/{video_id}/presets/{preset_id}
# operationId: add_video_embed_preset
export def "videos-presets create-embed" [
  video_id: float
  preset_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($preset_id | is-empty) { error make --unspanned { msg: "path parameter 'preset_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), preset_id: (encode-path-segment $preset_id)} | format pattern "/videos/{video_id}/presets/{preset_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the domains on which a video can be embedded
#
# GET /videos/{video_id}/privacy/domains
# operationId: get_video_privacy_domains
export def "videos-privacy-domains get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/privacy/domains") $qp)
  let accept_val = "application/vnd.vimeo.domain+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Restrict a video from being embedded on a domain
#
# DELETE /videos/{video_id}/privacy/domains/{domain}
# operationId: delete_video_privacy_domain
export def "videos-privacy-domains delete" [
  video_id: float
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), domain: (encode-path-segment $domain)} | format pattern "/videos/{video_id}/privacy/domains/{domain}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Permit a video to be embedded on a domain
#
# PUT /videos/{video_id}/privacy/domains/{domain}
# operationId: add_video_privacy_domain
export def "videos-privacy-domains create" [
  video_id: float
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), domain: (encode-path-segment $domain)} | format pattern "/videos/{video_id}/privacy/domains/{domain}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the users who can view a user's private videos by default
#
# GET /videos/{video_id}/privacy/users
# operationId: get_video_privacy_users
export def "videos-privacy-users get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/privacy/users") $qp)
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Permit a list of users to view a private video
#
# PUT /videos/{video_id}/privacy/users
# operationId: add_video_privacy_users
export def "videos-privacy-users create-by-video-id" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/privacy/users"))
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Restrict a user from viewing a private video
#
# DELETE /videos/{video_id}/privacy/users/{user_id}
# operationId: delete_video_privacy_user
export def "videos-privacy-users delete" [
  video_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), user_id: (encode-path-segment $user_id)} | format pattern "/videos/{video_id}/privacy/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Permit a specific user to view a private video
#
# PUT /videos/{video_id}/privacy/users/{user_id}
# operationId: add_video_privacy_user
export def "videos-privacy-users create-by-video-id-user-id" [
  video_id: float
  user_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'user_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), user_id: (encode-path-segment $user_id)} | format pattern "/videos/{video_id}/privacy/users/{user_id}"))
  let accept_val = "application/vnd.vimeo.user+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the tags of a video
#
# GET /videos/{video_id}/tags
# operationId: get_video_tags
export def "videos-tags get" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/tags"))
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a list of tags to a video
#
# PUT /videos/{video_id}/tags
# operationId: add_video_tags
export def "videos-tags create-by-video-id" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/tags"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.tag+json" $req_body {query: {}, body: $req_body}
}

# Remove a tag from a video
#
# DELETE /videos/{video_id}/tags/{word}
# operationId: delete_video_tag
export def "videos-tags delete" [
  video_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), word: (encode-path-segment $word)} | format pattern "/videos/{video_id}/tags/{word}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check if a tag has been added to a video
#
# GET /videos/{video_id}/tags/{word}
# operationId: check_video_for_tag
export def "videos-tags check" [
  video_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), word: (encode-path-segment $word)} | format pattern "/videos/{video_id}/tags/{word}"))
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a specific tag to a video
#
# PUT /videos/{video_id}/tags/{word}
# operationId: add_video_tag
export def "videos-tags create-by-video-id-word" [
  video_id: float
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($word | is-empty) { error make --unspanned { msg: "path parameter 'word' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), word: (encode-path-segment $word)} | format pattern "/videos/{video_id}/tags/{word}"))
  let accept_val = "application/vnd.vimeo.tag+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all the text tracks of a video
#
# GET /videos/{video_id}/texttracks
# operationId: get_text_tracks
export def "videos-texttracks get-text-tracks" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/texttracks"))
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a text track to a video
#
# POST /videos/{video_id}/texttracks
# operationId: create_text_track
export def "videos-texttracks create-text-track" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/texttracks"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video.texttrack+json" $req_body {query: {}, body: $req_body}
}

# Delete a text track
#
# DELETE /videos/{video_id}/texttracks/{texttrack_id}
# operationId: delete_text_track
export def "videos-texttracks delete-text-track" [
  video_id: float
  texttrack_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($texttrack_id | is-empty) { error make --unspanned { msg: "path parameter 'texttrack_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), texttrack_id: (encode-path-segment $texttrack_id)} | format pattern "/videos/{video_id}/texttracks/{texttrack_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a specific text track
#
# GET /videos/{video_id}/texttracks/{texttrack_id}
# operationId: get_text_track
export def "videos-texttracks get-text-track" [
  video_id: float
  texttrack_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($texttrack_id | is-empty) { error make --unspanned { msg: "path parameter 'texttrack_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), texttrack_id: (encode-path-segment $texttrack_id)} | format pattern "/videos/{video_id}/texttracks/{texttrack_id}"))
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit a text track
#
# PATCH /videos/{video_id}/texttracks/{texttrack_id}
# operationId: edit_text_track
export def "videos-texttracks update-edit-text-track" [
  video_id: float
  texttrack_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($texttrack_id | is-empty) { error make --unspanned { msg: "path parameter 'texttrack_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), texttrack_id: (encode-path-segment $texttrack_id)} | format pattern "/videos/{video_id}/texttracks/{texttrack_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video.texttrack+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video.texttrack+json" $req_body {query: {}, body: $req_body}
}

# Add a new custom logo to a video
#
# POST /videos/{video_id}/timelinethumbnails
# operationId: create_video_custom_logo
export def "videos-timelinethumbnails create-custom-logo" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/timelinethumbnails"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a custom video logo
#
# GET /videos/{video_id}/timelinethumbnails/{thumbnail_id}
# operationId: get_video_custom_logo
export def "videos-timelinethumbnails get-custom-logo" [
  video_id: float
  thumbnail_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  if ($thumbnail_id | is-empty) { error make --unspanned { msg: "path parameter 'thumbnail_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), thumbnail_id: (encode-path-segment $thumbnail_id)} | format pattern "/videos/{video_id}/timelinethumbnails/{thumbnail_id}"))
  let accept_val = "application/vnd.vimeo.picture+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a version to a video
#
# POST /videos/{video_id}/versions
# operationId: create_video_version
export def "videos-versions create" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/versions"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.vimeo.video.version+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/vnd.vimeo.video.version+json" $req_body {query: {}, body: $req_body}
}

# Get all the related videos of a video
#
# GET /videos/{video_id}/videos
# operationId: get_related_videos
export def "videos-videos get-related" [
  video_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string@filter-completer-16 # The attribute by which to filter the results.
  --page: float # The page number of the results to show. (e.g. 1)
  --per-page: float # The number of items to show on each page of results, up to a maximum of 100. (e.g. 10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'video_id' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/videos") $qp)
  let accept_val = "application/vnd.vimeo.video+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}
