# Auto-generated client for Listen API: Podcast Search, Directory, and Insights API v2.0
# Source: https://api.apis.guru/v2/specs/listennotes.com/2.0/openapi.json
# Auth: --token flag or $env.LISTEN_API_PODCAST_SEARCH_DIRECTORY_AND_INSIGHTS_API_TOKEN

const BASE_URL = "https://listen-api.listennotes.com/api/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LISTEN_API_PODCAST_SEARCH_DIRECTORY_AND_INSIGHTS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://listen-api.listennotes.com/api/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["listen_score" "oldest_added_first" "oldest_published_first" "recent_added_first" "recent_published_first"] }
def safe-mode-completer [] { ["0" "1"] }
def top-level-only-completer [] { ["0" "1"] }
def sort-completer-1 [] { ["name_a_to_z" "name_z_to_a" "oldest_added_first" "recent_added_first"] }
def type-completer [] { ["episode_list" "podcast_list"] }
def sort-completer-2 [] { ["oldest_added_first" "oldest_published_first" "recent_added_first" "recent_published_first"] }
def show-latest-episodes-completer [] { ["0" "1"] }
def sort-completer-3 [] { ["oldest_first" "recent_first"] }
def sort-by-date-completer [] { ["0" "1"] }
def type-completer-1 [] { ["curated" "episode" "podcast"] }
def unique-podcasts-completer [] { ["0" "1"] }
def show-podcasts-completer [] { ["0" "1"] }
def show-genres-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "best-podcasts get" } } | get name | first)
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

# Fetch a list of best podcasts by genre
#
# GET /best_podcasts
# operationId: getBestPodcasts
export def "best-podcasts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --genre-id: string # You can get the id from `GET /genres`. If not specified, it'll be the overall best podcasts, which can be considered as a special genre.
  --page: int # Page number of those podcasts in this genre.
  --region: string # Filter best podcasts by country/region. Please note that podcasts that are "best" in a country/region may not be produced in that country/region. For example, a podcast from the US may be very popular in Canada. You can get the supported country codes (e.g., us, jp, gb...) from `GET /regions`. If not specified, you'll get "best podcasts" in United States. (default: us)
  --publisher-region: string # Filter best podcasts by the publisher's country/region. This is to narrow down the results to include "best podcasts" produced in a specific country/region. You can get the supported country codes (e.g., us, jp, gb...) from `GET /regions`. If not specified, you'll get "best podcasts" produced in any country/region. If you want to get a country/region's "best podcasts" that are also produced in that country/region, then you need to specify both **region** and **publisher_region**, e.g., `region=jp` and `publisher_region=jp`.
  --language: string # Filter best podcasts by language. You can get a list of supported languages (e.g., English, Chinese, Japanese...) from `GET /languages`. If not specified, you'll get "best podcasts" in any language.
  --qp-sort: string@sort-completer # How do you want to sort these podcasts? If you'd like to sort by popularity, please use **listen_score**. (default: recent_added_first, e.g. listen_score)
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<has_next: bool, has_previous: bool, id: int, listennotes_url: string, name: string, next_page_number: int, page_number: int, parent_id: int, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, previous_page_number: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "genre_id" $genre_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "publisher_region" $publisher_region "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "safe_mode" $safe_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/best_podcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"genre_id": $genre_id, "page": $page, "region": $region, "publisher_region": $publisher_region, "language": $language, "sort": $qp_sort, "safe_mode": $safe_mode} | compact), body: null}
}

# Fetch curated lists of podcasts
#
# GET /curated_podcasts
# operationId: getCuratedPodcasts
export def "curated-podcasts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number of curated lists. (default: 1, e.g. 2)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<curated_lists: table<description: string, id: string, listennotes_url: string, podcasts: list, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int>, has_next: bool, has_previous: bool, next_page_number: int, page_number: int, previous_page_number: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/curated_podcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page} | compact), body: null}
}

# Fetch a curated list of podcasts by id
#
# GET /curated_podcasts/{id}
# operationId: getCuratedPodcastById
export def "curated-podcasts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<description: string, id: string, listennotes_url: string, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, source_domain: string, source_url: string, title: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/curated_podcasts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Batch fetch basic meta data for episodes
#
# POST /episodes
# operationId: getEpisodesInBatch
export def "episodes get-in-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
  ids: string # Comma-separated list of episode ids.
]: any -> record<episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/episodes")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Fetch detailed meta data for an episode by id
#
# GET /episodes/{id}
# operationId: getEpisodeById
export def "episodes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-transcript: int # To include the transcript of this episode or not? If it is 1, then include the transcript in the **transcript** field. The default value is 0 - we don't include transcript by default, because 1) it would make the response data very big, thus slow response time; 2) less than 1% of episodes have transcripts. The transcript field is available only in the PRO/ENTERPRISE plan. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>, pub_date_ms: int, thumbnail: string, title: string, transcript: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "show_transcript" $show_transcript "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"show_transcript": $show_transcript} | compact), body: null}
}

# Fetch recommendations for an episode
#
# GET /episodes/{id}/recommendations
# operationId: getEpisodeRecommendations
export def "episodes-recommendations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<recommendations: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "safe_mode" $safe_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}/recommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"safe_mode": $safe_mode} | compact), body: null}
}

# Fetch a list of podcast genres
#
# GET /genres
# operationId: getGenres
export def "genres get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --top-level-only: int@top-level-only-completer # Just show top level genres? If 1, yes, just show top level genres. If 0, no, show all genres. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<genres: table<id: int, name: string, parent_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top_level_only" $top_level_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/genres" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"top_level_only": $top_level_only} | compact), body: null}
}

# Fetch a random podcast episode
#
# GET /just_listen
# operationId: justListen
export def "just-listen get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, pub_date_ms: int, thumbnail: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/just_listen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a list of supported languages for podcasts
#
# GET /languages
# operationId: getLanguages
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
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<languages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a list of your playlists.
#
# GET /playlists
# operationId: getPlaylists
export def "playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-1 # How do you want to sort playlists? (default: recent_added_first)
  --page: int # Page number of playlists. (default: 1)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<has_next: bool, has_previous: bool, next_page_number: int, page_number: int, playlists: table<description: string, episode_count: int, id: string, image: string, last_timestamp_ms: int, listennotes_url: string, name: string, podcast_count: int, thumbnail: string, total_audio_length_sec: int, visibility: string>, previous_page_number: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "page": $page} | compact), body: null}
}

# Fetch a playlist's info and items (i.e., episodes or podcasts).
#
# GET /playlists/{id}
# operationId: getPlaylistById
export def "playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # The type of this playlist, which should be either **episode_list** or **podcast_list**. (default: episode_list)
  --last-timestamp-ms: int # For playlist items pagination. It's the value of **last_timestamp_ms** from the response of last request. If it's 0 or not specified, just return the latest or the oldest 20 items, depending on the value of the **sort** parameter. (default: 0)
  --qp-sort: string@sort-completer-2 # How do you want to sort playlist items? (default: recent_added_first)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<description: string, id: string, image: string, items: table<added_at_ms: int, data: any, id: int, notes: string, type: string>, last_timestamp_ms: int, listennotes_url: string, name: string, thumbnail: string, total: int, total_audio_length_sec: int, type: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "last_timestamp_ms" $last_timestamp_ms "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/playlists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "last_timestamp_ms": $last_timestamp_ms, "sort": $qp_sort} | compact), body: null}
}

# Batch fetch basic meta data for podcasts
#
# POST /podcasts
# operationId: getPodcastsInBatch
export def "podcasts get-in-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
  --ids: string # Comma-separated list of podcast ids.
  --itunes-ids: string # Comma-separated Apple Podcasts (iTunes) ids, e.g., 659155419
  --next-episode-pub-date: int # For latest episodes pagination. It's the value of **next_episode_pub_date** from the response of last request. If not specified, just return latest 15 episodes.
  --rsses: string # Comma-separated rss urls.
  --show-latest-episodes: int@show-latest-episodes-completer # Whether or not to fetch up to 15 latest episodes from these podcasts, sorted by pub_date. 1 is yes, and 0 is no. (default: 0)
  --spotify-ids: string # Comma-separated Spotify ids, e.g., 3DDfEsKDIDrTlnPOiG4ZF4
]: any -> record<latest_episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, podcast: record, pub_date_ms: int, thumbnail: string, title: string>, podcasts: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/podcasts")
  let req_body = {"ids": $ids, "itunes_ids": $itunes_ids, "next_episode_pub_date": $next_episode_pub_date, "rsses": $rsses, "show_latest_episodes": $show_latest_episodes, "spotify_ids": $spotify_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Submit a podcast to Listen Notes database
#
# POST /podcasts/submit
# operationId: submitPodcast
export def "podcasts-submit submit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
  --email: string # A valid email address. If **email** is specified, then we'll notify this email address once the podcast is accepted.
  rss: string # A valid podcast rss url.
]: any -> record<podcast: record<id: string, image: string, listen_score: int, listen_score_global_rank: string, listennotes_url: string, publisher: string, thumbnail: string, title: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/podcasts/submit")
  let req_body = {"email": $email, "rss": $rss} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Request to delete a podcast
#
# DELETE /podcasts/{id}
# operationId: deletePodcastById
export def "podcasts delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # The reason why this podcast should be deleted, e.g., copyright violation, the podcaster wants to delete it... You can put "testing" here to indicate that you are testing this endpoint, so we will not actually delete the podcast. (e.g. the podcaster wants to delete it)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/podcasts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reason": $reason} | compact), body: null}
}

# Fetch detailed meta data and episodes for a podcast by id
#
# GET /podcasts/{id}
# operationId: getPodcastById
export def "podcasts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --next-episode-pub-date: int # For episodes pagination. It's the value of **next_episode_pub_date** from the response of last request. If not specified, just return latest 10 episodes or oldest 10 episodes, depending on the value of the **sort** parameter. (e.g. 1479154463000)
  --qp-sort: string@sort-completer-3 # How do you want to sort the episodes of this podcast? (default: recent_first, e.g. recent_first)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, episodes: table<audio: string, audio_length_sec: int, description: string, explicit_content: bool, id: string, image: string, link: string, listennotes_edit_url: string, listennotes_url: string, maybe_audio_invalid: bool, pub_date_ms: int, thumbnail: string, title: string>, explicit_content: bool, extra: record<amazon_music_url: string, facebook_handle: string, google_url: string, instagram_handle: string, linkedin_url: string, patreon_handle: string, spotify_url: string, twitter_handle: string, url1: string, url2: string, url3: string, wechat_handle: string, youtube_url: string>, genre_ids: list<int>, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record<cohosts: bool, cross_promotion: bool, guests: bool, sponsors: bool>, next_episode_pub_date: int, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "next_episode_pub_date" $next_episode_pub_date "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/podcasts/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"next_episode_pub_date": $next_episode_pub_date, "sort": $qp_sort} | compact), body: null}
}

# Fetch audience demographics for a podcast
#
# GET /podcasts/{id}/audience
# operationId: getPodcastAudience
export def "podcasts-audience get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<by_regions: table<ratio: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/podcasts/{id}/audience"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch recommendations for a podcast
#
# GET /podcasts/{id}/recommendations
# operationId: getPodcastRecommendations
export def "podcasts-recommendations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts with explicit language. 1 is yes, and 0 is no. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<recommendations: table<audio_length_sec: int, country: string, description: string, earliest_pub_date_ms: int, email: string, explicit_content: bool, extra: record, genre_ids: list, id: string, image: string, is_claimed: bool, itunes_id: int, language: string, latest_episode_id: string, latest_pub_date_ms: int, listen_score: int, listen_score_global_rank: string, listennotes_url: string, looking_for: record, publisher: string, rss: string, thumbnail: string, title: string, total_episodes: int, type: string, update_frequency_hours: int, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "safe_mode" $safe_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/podcasts/{id}/recommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"safe_mode": $safe_mode} | compact), body: null}
}

# Fetch a list of supported countries/regions for best podcasts
#
# GET /regions
# operationId: getRegions
export def "regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<regions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch related search terms
#
# GET /related_searches
# operationId: getRelatedSearches
export def "related-searches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic...
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/related_searches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Full-text search
#
# GET /search
# operationId: search
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic... You can use double quotes to do verbatim match, e.g., "game of thrones". Otherwise, it's fuzzy search.
  --sort-by-date: int@sort-by-date-completer # Sort by date or not? If 0, then sort by relevance. If 1, then sort by date. (default: 0)
  --type: string@type-completer-1 # What type of contents do you want to search for? (default: episode)
  --offset: int # Offset for search results, for pagination. You'll use **next_offset** from response for this parameter. (default: 0)
  --len-min: int # Minimum audio length in minutes. Applicable only when **type** parameter is **episode** or **podcast**. If **type** parameter is **episode**, it's for audio length of an episode. If **type** parameter is **podcast**, it's for average audio length of all episodes in a podcast. (default: 0)
  --len-max: int # Maximum audio length in minutes. Applicable only when **type** parameter is **episode** or **podcast**. If **type** parameter is **episode**, it's for audio length of an episode. If **type** parameter is **podcast**, it's for average audio length of all episodes in a podcast.
  --episode-count-min: int # Minimum number of episodes. Applicable only when type parameter is **podcast**.
  --episode-count-max: int # Maximum number of episodes. Applicable only when type parameter is **podcast**.
  --update-freq-min: int # Minimum update frequency in hours (how frequently does a podcast release a new episode). For example, if you want to find "weekly" podcasts, then you can set **update_freq_min**=144 hours (or 6 days) and **update_freq_max**=192 hours (or 8 days). Applicable only when type parameter is **podcast**.
  --update-freq-max: int # Maximum update frequency in hours (how frequently does a podcast release a new episode). For example, if you want to find "weekly" podcasts, then you can set **update_freq_min**=144 hours (or 6 days) and **update_freq_max**=192 hours (or 8 days). Applicable only when type parameter is **podcast**.
  --genre-ids: string # A comma-delimited string of a list of genre ids. If not specified, then all genres are included. You can find the id and the name of all genres from `GET /genres`. It works only when **type** is *episode* or *podcast*.
  --published-before: int # Only show episodes/podcasts/curated lists published before this timestamp (in milliseconds). If **published_before** & **published_after** are used at the same time, **published_before** should be bigger than **published_after**.
  --published-after: int # Only show episodes/podcasts/curated lists published after this timestamp (in milliseconds). If **published_before** & **published_after** are used at the same time, **published_before** should be bigger than **published_after**. (default: 0)
  --only-in: string # A comma-delimited string to search only in specific fields. Allowed values are title, description, author, and audio. If not specified, then search every fields. (default: title,description,author,audio)
  --language: string # Limit search results to a specific language. If not specified, it'll be any language. You can get a list of supported languages from `GET /languages`. It works only when **type** is *episode* or *podcast*.
  --region: string # Limit search results to a specific region (e.g., us, gb, in...). If not specified, it'll be any region. You can get the supported country codes from `GET /regions`. It works only when **type** is *episode* or *podcast*.
  --ocid: string # A comma-delimited string of podcast ids (up to 5 podcasts) - you can get a podcast id from the **podcast_id** field in response. This parameter is to limit search results from only a few specific podcasts. It works only when **type** is *episode*.
  --ncid: string # A comma-delimited string of podcast ids (up to 5 podcasts) - you can get a podcast id from the **podcast_id** field in response. This parameter is to exclude search results of a few specific podcasts. It works only when **type** is *episode*.
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts/episodes with explicit language. 1 is yes and 0 is no. It works only when **type** is *episode* or *podcast*. (default: 0)
  --unique-podcasts: int@unique-podcasts-completer # Whether or not to keep only one episode per podcast in search results. 1 is yes and 0 is no. It works only when **type** is *episode*. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<count: int, next_offset: int, results: list<any>, took: float, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort_by_date" $sort_by_date "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "len_min" $len_min "scalar") (serialize-qp "len_max" $len_max "scalar") (serialize-qp "episode_count_min" $episode_count_min "scalar") (serialize-qp "episode_count_max" $episode_count_max "scalar") (serialize-qp "update_freq_min" $update_freq_min "scalar") (serialize-qp "update_freq_max" $update_freq_max "scalar") (serialize-qp "genre_ids" $genre_ids "scalar") (serialize-qp "published_before" $published_before "scalar") (serialize-qp "published_after" $published_after "scalar") (serialize-qp "only_in" $only_in "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "ocid" $ocid "scalar") (serialize-qp "ncid" $ncid "scalar") (serialize-qp "safe_mode" $safe_mode "scalar") (serialize-qp "unique_podcasts" $unique_podcasts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "sort_by_date": $sort_by_date, "type": $type, "offset": $offset, "len_min": $len_min, "len_max": $len_max, "episode_count_min": $episode_count_min, "episode_count_max": $episode_count_max, "update_freq_min": $update_freq_min, "update_freq_max": $update_freq_max, "genre_ids": $genre_ids, "published_before": $published_before, "published_after": $published_after, "only_in": $only_in, "language": $language, "region": $region, "ocid": $ocid, "ncid": $ncid, "safe_mode": $safe_mode, "unique_podcasts": $unique_podcasts} | compact), body: null}
}

# Spell check on a search term
#
# GET /spellcheck
# operationId: spellcheck
export def "spellcheck get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic...
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<corrected_text_html: string, tokens: table<offset: int, suggestion: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/spellcheck" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q} | compact), body: null}
}

# Fetch trending search terms
#
# GET /trending_searches
# operationId: getTrendingSearches
export def "trending-searches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trending_searches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Typeahead search
#
# GET /typeahead
# operationId: typeahead
export def "typeahead get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term, e.g., person, place, topic... You can use double quotes to do verbatim match, e.g., "game of thrones". Otherwise, it's fuzzy search.
  --show-podcasts: int@show-podcasts-completer # Autosuggest podcasts. This only searches podcast title and publisher and returns very limited info of 5 podcasts. 1 is yes, 0 is no. It's a bit slow to autosuggest podcasts, so we turn it off by default. If show_podcasts=1, you can also pass iTunes id (e.g., 474722933) to the q parameter to fetch podcast meta data. (default: 0)
  --show-genres: int@show-genres-completer # Whether or not to autosuggest genres. 1 is yes, 0 is no. (default: 0)
  --safe-mode: int@safe-mode-completer # Whether or not to exclude podcasts/episodes with explicit language. 1 is yes and 0 is no. It works only when **show_podcasts** is *1*. (default: 0)
  --x-listen-api-key: string # Get API Key on listennotes.com/api
]: nothing -> record<genres: table<id: int, name: string, parent_id: int>, podcasts: table<explicit_content: bool, id: string, image: string, publisher_highlighted: string, publisher_original: string, thumbnail: string, title_highlighted: string, title_original: string>, terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "show_podcasts" $show_podcasts "scalar") (serialize-qp "show_genres" $show_genres "scalar") (serialize-qp "safe_mode" $safe_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/typeahead" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-ListenAPI-Key": $x_listen_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "show_podcasts": $show_podcasts, "show_genres": $show_genres, "safe_mode": $safe_mode} | compact), body: null}
}
