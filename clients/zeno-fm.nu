# Auto-generated client for Aggregators API Service v0.6-99cfdac
# Source: https://api.apis.guru/v2/specs/zeno.fm/0.6-99cfdac/openapi.json
# Auth: --token flag or $env.AGGREGATORS_API_SERVICE_TOKEN

const BASE_URL = "https://api.zeno.fm"
const DEFAULT_AUTH = "x-zeno-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AGGREGATORS_API_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-zeno-api-key" => { {headers: {x-zeno-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.zeno.fm"] }
def auth-scheme-completer [] { ["x-zeno-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "podcasts-categories get" } } | get name | first)
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

# Get the list of Categories that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/categories
# operationId: getPodcastCategories
export def "podcasts-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/categories")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of Countries that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/countries
# operationId: getPodcastCountries
export def "podcasts-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/countries")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create podcast
#
# POST /api/v2/podcasts/create
# operationId: createPodcast
# --podcast shape: {author?: string, block?: bool, categories: list, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
export def "podcasts-create createPodcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_logo: string # format: binary
  podcast: record # Podcast model — shape: {author?: string, block?: bool, categories: list, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/create")
  let body = {file_logo: $file_logo, podcast: $podcast} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get the list of Languages that can be used to filter podcasts in the search podcasts request
#
# GET /api/v2/podcasts/languages
# operationId: getPodcastLanguages
export def "podcasts-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search podcasts
#
# POST /api/v2/podcasts/search
# operationId: searchPodcasts
# --filters shape: {category?: list, country?: list, language?: list, podcastType?: "podcasts"|"shows"}
export def "podcasts-search searchPodcasts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # Filters for podcast search — shape: {category?: list, country?: list, language?: list, podcastType?: "podcasts"|"shows"}
  --hitsPerPage: int # format: int32, default: 10
  --page: int # format: int32, default: 1
  --query: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/podcasts/search")
  let body = {filters: $filters, hitsPerPage: $hitsPerPage, page: $page, query: $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete podcast
#
# DELETE /api/v2/podcasts/{podcastKey}
# operationId: deletePodcast
export def "podcasts delete" [
  podcastKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get podcast
#
# GET /api/v2/podcasts/{podcastKey}
# operationId: getPodcast
export def "podcasts get" [
  podcastKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update podcast
#
# PUT /api/v2/podcasts/{podcastKey}
# operationId: updatePodcast
# --podcast shape: {author?: string, block?: bool, categories: list, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
export def "podcasts updatePodcast" [
  podcastKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-logo: string # format: binary
  podcast: record # Podcast model — shape: {author?: string, block?: bool, categories: list, copyright?: string, country?: string, description: string, explicit?: bool, image?: string, key?: string, keywords?: list, language: string, link?: string, ownerEmail?: string, ownerName?: string, showType?: string, subtitle?: string, summary: string, title: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)")
  let body = {file_logo: $file_logo, podcast: $podcast} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get podcast episodes
#
# GET /api/v2/podcasts/{podcastKey}/episodes
# operationId: getPodcastEpisodes
export def "podcasts-episodes list" [
  podcastKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # default: 10
  --offset: string # default: 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)/episodes" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create podcast episode
#
# POST /api/v2/podcasts/{podcastKey}/episodes/create
# operationId: createPodcastEpisode
# --episode shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list, title: string}
export def "podcasts-episodes-create createPodcastEpisode" [
  podcastKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  episode: record # PodcastEpisode model — shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list, title: string}
  file_logo: string # format: binary
  file_media: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)/episodes/create")
  let body = {episode: $episode, file_logo: $file_logo, file_media: $file_media} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Delete podcast episode
#
# DELETE /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: deletePodcast_1
export def "podcasts-episodes delete-by-podcastKey-episodeKey" [
  podcastKey: string
  episodeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)/episodes/($episodeKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get podcast episode
#
# GET /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: getPodcastEpisode
export def "podcasts-episodes get" [
  podcastKey: string
  episodeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)/episodes/($episodeKey)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update podcast episode
#
# PUT /api/v2/podcasts/{podcastKey}/episodes/{episodeKey}
# operationId: updatePodcastEpisode
# --episode shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list, title: string}
export def "podcasts-episodes updatePodcastEpisode" [
  podcastKey: string
  episodeKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  episode: record # PodcastEpisode model — shape: {author?: string, block?: bool, description: string, duration?: int, episode?: int, episodeType?: string, explicit?: bool, fileUrl?: string, image?: string, key?: string, link?: string, publishDate: string, season?: int, size?: int, subtitle?: string, summary: string, tags?: list, title: string}
  --file-logo: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/podcasts/($podcastKey)/episodes/($episodeKey)")
  let body = {episode: $episode, file_logo: $file_logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get the list of Countries that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/countries
# operationId: getStationCountries
export def "stations-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/countries")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of Genres that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/genres
# operationId: getStationGenres
export def "stations-genres get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/genres")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of Languages that can be used to filter stations in the search stations request
#
# GET /api/v2/stations/languages
# operationId: getStationLanguages
export def "stations-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/languages")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List stations
#
# GET /api/v2/stations/list
# operationId: getPartnerAggregatorStations
export def "stations-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # default: 1
  --hitsPerPage: string # default: 10
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "hitsPerPage" $hitsPerPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/stations/list" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search stations
#
# POST /api/v2/stations/search
# operationId: searchStations
# --filters shape: {country?: list, genre?: list, language?: list}
export def "stations-search searchStations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: record # Filters for station search — shape: {country?: list, genre?: list, language?: list}
  --hitsPerPage: int # format: int32, default: 10
  --page: int # format: int32, default: 1
  --query: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-zeno-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/stations/search")
  let body = {filters: $filters, hitsPerPage: $hitsPerPage, page: $page, query: $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
