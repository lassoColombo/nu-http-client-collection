# Auto-generated client for TheTVDB API v3 v3.0.0
# Source: https://api.apis.guru/v2/specs/thetvdb.com/3.0.0/swagger.json
# Auth: --token flag or $env.THETVDB_API_V3_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THETVDB_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "jwt" => { {headers: {Authorization: $"JWT ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://localhost" "http://localhost"] }
def auth-scheme-completer [] { ["jwt"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "episodes get" } } | get name | first)
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

# Returns the full information for a given episode id. __Deprecation Warning:__ The _director_ key will be deprecated in favor of the new _directors_ key in a future release.
#
# GET /episodes/{id}
export def "episodes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: record<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list<string>, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list<string>, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/episodes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All available languages. These language abbreviations can be used in the `Accept-Language` header for routes that return translation records.
#
# GET /languages
export def "languages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<abbreviation: string, englishName: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a particular language, given the language ID.
#
# GET /languages/{id}
export def "languages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<abbreviation: string, englishName: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/languages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a session token to be included in the rest of the requests. Note that API key authentication is required for all subsequent requests and user auth is required for routes in the `User` section
#
# POST /login
export def "login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string
  --userkey: string
  --username: string
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/login")
  let req_body = {"apikey": $apikey, "userkey": $userkey, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a movies records that contains all information known about a particular movies id.
#
# GET /movies/{id}
export def "movies get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<artworks: table<artwork_type: string, height: int, id: string, is_primary: bool, tags: string, thumb_url: string, url: string, width: int>, genres: table<id: int, name: string, url: string>, id: int, people: record<actors: list<record>, directors: list<record>, producers: list<record>, writers: list<record>>, release_dates: table<country: string, date: string, type: string>, remoteids: table<id: string, source_id: int, source_name: string, source_url: string, url: string>, runtime: int, trailers: table<name: string, url: string>, translations: table<is_primary: bool, language_code: string, name: string, overview: string, tagline: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/movies/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all movies ids updated since a given timestamp.
#
# GET /movieupdates
export def "movieupdates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # Epoch time to start your date range.
]: nothing -> record<movies: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/movieupdates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refreshes your current, valid JWT token and returns a new token. Hit this route so that you do not have to post to `/login` with your API key and credentials once you have already been authenticated.
#
# GET /refresh_token
export def "refresh-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refresh_token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows the user to search for a series based on the following parameters.
#
# GET /search/series
export def "search-series get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the series to search for.
  --imdb-id: string # IMDB id of the series
  --zap2it-id: string # Zap2it ID of the series to search for.
  --slug: string # Slug from site URL of series (https://www.thetvdb.com/series/$SLUG)
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: table<aliases: list, banner: string, firstAired: string, id: int, image: string, network: string, overview: string, poster: string, seriesName: string, slug: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "imdbId" $imdb_id "scalar") (serialize-qp "zap2itId" $zap2it_id "scalar") (serialize-qp "slug" $slug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of parameters to query by in the `/search/series` route.
#
# GET /search/series/params
export def "search-series-params get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/series/params")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a series records that contains all information known about a particular series id.
#
# GET /series/{id}
export def "series get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns header information only about the given series ID.
#
# HEAD /series/{id}
export def "series head-head" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns actors for the given series id
#
# GET /series/{id}/actors
export def "series-actors get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<id: int, image: string, imageAdded: string, imageAuthor: int, lastUpdated: string, name: string, role: string, seriesId: int, sortOrder: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/actors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All episodes for a given series. Paginated with 100 results per page.
#
# GET /series/{id}/episodes
export def "series-episodes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Page of results to fetch. Defaults to page 1 if not provided.
]: nothing -> record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/episodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This route allows the user to query against episodes for the given series. The response is a paginated array of episode records.
#
# GET /series/{id}/episodes/query
export def "series-episodes-query get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --absolute-number: string # Absolute number of the episode
  --aired-season: string # Aired season number
  --aired-episode: string # Aired episode number
  --dvd-season: string # DVD season number
  --dvd-episode: string # DVD episode number
  --imdb-id: string # IMDB id of the series
  --page: string # Page of results to fetch. Defaults to page 1 if not provided.
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: table<absoluteNumber: int, airedEpisodeNumber: int, airedSeason: int, airsAfterSeason: int, airsBeforeEpisode: int, airsBeforeSeason: int, director: string, directors: list, dvdChapter: float, dvdDiscid: string, dvdEpisodeNumber: float, dvdSeason: int, episodeName: string, filename: string, firstAired: string, guestStars: list, id: int, imdbId: string, lastUpdated: int, lastUpdatedBy: string, overview: string, productionCode: string, seriesId: string, showUrl: string, siteRating: float, siteRatingCount: int, thumbAdded: string, thumbAuthor: int, thumbHeight: string, thumbWidth: string, writers: list>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "absoluteNumber" $absolute_number "scalar") (serialize-qp "airedSeason" $aired_season "scalar") (serialize-qp "airedEpisode" $aired_episode "scalar") (serialize-qp "dvdSeason" $dvd_season "scalar") (serialize-qp "dvdEpisode" $dvd_episode "scalar") (serialize-qp "imdbId" $imdb_id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/episodes/query") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the allowed query keys for the `/series/{id}/episodes/query` route
#
# GET /series/{id}/episodes/query/params
export def "series-episodes-query-params get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/episodes/query/params"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a summary of the episodes and seasons available for the series. __Note__: Season "0" is for all episodes that are considered to be specials.
#
# GET /series/{id}/episodes/summary
export def "series-episodes-summary get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<airedEpisodes: string, airedSeasons: list<string>, dvdEpisodes: string, dvdSeasons: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/episodes/summary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a series records, filtered by the supplied comma-separated list of keys. Query keys can be found at the `/series/{id}/filter/params` route.
#
# GET /series/{id}/filter
export def "series-filter get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keys: string # Comma-separated list of keys to filter by
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: record<added: string, airsDayOfWeek: string, airsTime: string, aliases: list<string>, banner: string, firstAired: string, genre: list<string>, id: int, imdbId: string, lastUpdated: int, network: string, networkId: string, overview: string, rating: string, runtime: string, seriesId: string, seriesName: string, siteRating: float, siteRatingCount: int, slug: string, status: string, zap2itId: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/filter") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of keys available for the `/series/{id}/filter` route
#
# GET /series/{id}/filter/params
export def "series-filter-params get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/filter/params"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a summary of the images for a particular series
#
# GET /series/{id}/images
export def "series-images get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: record<fanart: int, poster: int, season: int, seasonwide: int, series: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/images"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query images for the given series ID.
#
# GET /series/{id}/images/query
export def "series-images-query get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key-type: string # Type of image you're querying for (fanart, poster, etc. See ../images/query/params for more details).
  --resolution: string # Resolution to filter by (1280x1024, for example)
  --sub-key: string # Subkey for the above query keys. See /series/{id}/images/query/params for more information
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: table<fileName: string, id: int, keyType: string, languageId: int, ratingsInfo: record, resolution: string, subKey: string, thumbnail: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyType" $key_type "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "subKey" $sub_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/images/query") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the allowed query keys for the `/series/{id}/images/query` route. Contains a parameter record for each unique `keyType`, listing values that will return results.
#
# GET /series/{id}/images/query/params
export def "series-images-query-params get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: table<keyType: string, languageId: string, resolution: list, subKey: list>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/series/{id}/images/query/params"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of series that have changed in a maximum of one week blocks since the provided `fromTime`. The user may specify a `toTime` to grab results for less than a week. Any timespan larger than a week will be reduced down to one week automatically.
#
# GET /updated/query
export def "updated-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-time: string # Epoch time to start your date range.
  --to-time: string # Epoch time to end your date range. Must be one week from `fromTime`.
  --accept-language: string # Records are returned with the some fields in the desired language, if it exists. If there is no translation for the given language, then the record is still returned but with empty values for the translated fields.
]: nothing -> record<data: table<id: int, lastUpdated: int>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromTime" $from_time "scalar") (serialize-qp "toTime" $to_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/updated/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of valid query keys for the `/updated/query/params` route.
#
# GET /updated/query/params
export def "updated-query-params get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updated/query/params")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns basic information about the currently authenticated user.
#
# GET /user
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<favoritesDisplaymode: string, language: string, userName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of favorite series for a given user, will be a blank array if no favorites exist.
#
# GET /user/favorites
export def "user-favorites get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/favorites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the given series ID from the user’s favorite’s list and returns the updated list.
#
# DELETE /user/favorites/{id}
export def "user-favorites delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/favorites/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds the supplied series ID to the user’s favorite’s list and returns the updated list.
#
# PUT /user/favorites/{id}
export def "user-favorites update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<favorites: list<string>>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/user/favorites/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of ratings for the given user.
#
# GET /user/ratings
export def "user-ratings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/ratings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an array of ratings for a given user that match the query.
#
# GET /user/ratings/query
export def "user-ratings-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-type: string # Item to query. Can be either 'series', 'episode', or 'banner' (format: string)
]: nothing -> record<data: table<rating: int, ratingItemId: int, ratingType: string>, errors: record<invalidFilters: list<string>, invalidLanguage: string, invalidQueryParams: list<string>>, links: record<first: int, last: int, next: int, previous: int>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "itemType" $item_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/ratings/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of query params for use in the `/user/ratings/query` route.
#
# GET /user/ratings/query/params
export def "user-ratings-query-params get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/ratings/query/params")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This route deletes a given rating of a given type.
#
# DELETE /user/ratings/{itemType}/{itemId}
export def "user-ratings delete" [
  item_type: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_type: (encode-path-segment $item_type), item_id: (encode-path-segment $item_id)} | format pattern "/user/ratings/{item_type}/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This route updates a given rating of a given type.
#
# PUT /user/ratings/{itemType}/{itemId}/{itemRating}
export def "user-ratings update" [
  item_type: string
  item_id: int
  item_rating: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<rating: int, ratingItemId: int, ratingType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_type: (encode-path-segment $item_type), item_id: (encode-path-segment $item_id), item_rating: (encode-path-segment $item_rating)} | format pattern "/user/ratings/{item_type}/{item_id}/{item_rating}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
