# Auto-generated client for TMDB API v0.32.0
# Source: https://raw.githubusercontent.com/ckatle/oas-tmdb/master/openapi.yml
# Auth: --token flag or $env.TMDB_API_TOKEN

const BASE_URL = "https://api.themoviedb.org/3"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TMDB_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.themoviedb.org/3"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "collection CollectionDetails" } } | get name | first)
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

# Details
#
# GET /collection/{collection_id}
# operationId: CollectionDetails
export def "collection CollectionDetails" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> record<overview: string, parts: table<media_type: string, id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collection/($collection_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /company/{company_id}
# operationId: CompanyDetails
export def "company CompanyDetails" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, parent_company: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/company/($company_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Images
#
# GET /company/{company_id}/images
# operationId: CompanyImages
export def "company-images CompanyImages" [
  company_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, logos: table<aspect_ratio: float, file_path: string, height: int, id: string, file_type: string, vote_average: float, vote_count: int, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/company/($company_id)/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /configuration
# operationId: ConfigurationDetails
export def "configuration ConfigurationDetails" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<images: record<base_url: string, secure_base_url: string, backdrop_sizes: list<string>, logo_sizes: list<string>, poster_sizes: list<string>, profile_sizes: list<string>, still_sizes: list<string>>, change_keys: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Countries
#
# GET /configuration/countries
# operationId: ConfigurationCountries
export def "configuration-countries ConfigurationCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> table<iso_3166_1: string, english_name: string, native_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configuration/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Jobs
#
# GET /configuration/jobs
# operationId: ConfigurationJobs
export def "configuration-jobs ConfigurationJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<department: string, jobs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/jobs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Languages
#
# GET /configuration/languages
# operationId: ConfigurationLanguages
export def "configuration-languages ConfigurationLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<iso_639_1: string, english_name: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Primary Translations
#
# GET /configuration/primary_translations
# operationId: ConfigurationPrimaryTranslations
export def "configuration-primary-translations ConfigurationPrimaryTranslations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/primary_translations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Timezones
#
# GET /configuration/timezones
# operationId: ConfigurationTimezones
export def "configuration-timezones ConfigurationTimezones" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<iso_3166_1: string, zones: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration/timezones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Movie List
#
# GET /genre/movie/list
# operationId: GenreMovieList
export def "genre-movie-list GenreMovieList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> record<genres: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/genre/movie/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TV List
#
# GET /genre/tv/list
# operationId: GenreTvList
export def "genre-tv-list GenreTvList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> record<genres: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/genre/tv/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /keyword/{keyword_id}
# operationId: KeywordDetails
export def "keyword KeywordDetails" [
  keyword_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keyword/($keyword_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Movies
#
# GET /keyword/{keyword_id}/movies
# DEPRECATED
# operationId: KeywordMovies
@deprecated
export def "keyword-movies KeywordMovies" [
  keyword_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/keyword/($keyword_id)/movies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /network/{network_id}
# operationId: NetworkDetails
export def "network NetworkDetails" [
  network_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<headquarters: string, homepage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($network_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Images
#
# GET /network/{network_id}/images
# operationId: NetworkImages
export def "network-images NetworkImages" [
  network_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, logos: table<aspect_ratio: float, file_path: string, height: int, id: string, file_type: string, vote_average: float, vote_count: int, width: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($network_id)/images")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Now Playing
#
# GET /movie/now_playing
# operationId: MovieNowPlayingList
export def "movie-now-playing MovieNowPlayingList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
]: nothing -> record<dates: record<maximum: string, minimum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/movie/now_playing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Popular
#
# GET /movie/popular
# operationId: MoviePopularList
export def "movie-popular MoviePopularList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/movie/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Rated
#
# GET /movie/top_rated
# operationId: MovieTopRatedList
export def "movie-top-rated MovieTopRatedList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/movie/top_rated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upcoming
#
# GET /movie/upcoming
# operationId: MovieUpcomingList
export def "movie-upcoming MovieUpcomingList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
]: nothing -> record<dates: record<maximum: string, minimum: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/movie/upcoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /movie/{movie_id}
# operationId: MovieDetails
export def "movie MovieDetails" [
  movie_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --append-to-response: list # comma separated list of endpoints within this namespace, 20 items max
]: nothing -> record<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, belongs_to_collection: record<id: int, name: string, poster_path: string, backdrop_path: string>, budget: int, genres: table<id: int, name: string>, homepage: string, imdb_id: string, origin_country: list<string>, overview: string, popularity: float, poster_path: string, production_companies: table<id: int, name: string, origin_country: string, logo_path: string>, production_countries: table<iso_3166_1: string, name: string>, release_date: string, revenue: int, runtime: int, spoken_languages: table<iso_639_1: string, english_name: string, name: string>, status: string, tagline: string, video: bool, vote_average: float, vote_count: int, credits: record<id: int, cast: list<record>, crew: list<record>>, keywords: record<id: int, keywords: list<record>>, recommendations: record<page: int, total_pages: int, total_results: int, results: list<any>>, similar: record<page: int, total_pages: int, total_results: int, results: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "append_to_response" $append_to_response "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/movie/($movie_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Credits
#
# GET /movie/{movie_id}/credits
# operationId: MovieCredits
export def "movie-credits MovieCredits" [
  movie_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> record<id: int, cast: table<cast_id: int, character: string, order: int>, crew: table<department: string, job: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/movie/($movie_id)/credits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Keywords
#
# GET /movie/{movie_id}/keywords
# operationId: MovieKeywords
export def "movie-keywords MovieKeywords" [
  movie_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, keywords: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movie/($movie_id)/keywords")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recommendations
#
# GET /movie/{movie_id}/recommendations
# operationId: MovieRecommendations
export def "movie-recommendations MovieRecommendations" [
  movie_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/movie/($movie_id)/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Similar
#
# GET /movie/{movie_id}/similar
# operationId: MovieSimilar
export def "movie-similar MovieSimilar" [
  movie_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/movie/($movie_id)/similar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Collection
#
# GET /search/collection
# operationId: SearchCollection
export def "search-collection SearchCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<adult: bool, original_language: string, original_name: string, overview: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Keyword
#
# GET /search/keyword
# operationId: SearchKeyword
export def "search-keyword SearchKeyword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/keyword" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Movie
#
# GET /search/movie
# operationId: SearchMovie
export def "search-movie SearchMovie" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --primary-release-year: int # format: int32
  --page: int # format: int32, default: 1
  --region: string # `ISO-3166-1` code
  --year: string
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, title: string, original_language: string, original_title: string, adult: bool, backdrop_path: string, genre_ids: list, overview: string, popularity: float, poster_path: string, release_date: string, video: bool, vote_average: float, vote_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "primary_release_year" $primary_release_year "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/movie" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Multi
#
# GET /search/multi
# operationId: SearchMulti
export def "search-multi SearchMulti" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/multi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Person
#
# GET /search/person
# operationId: SearchPerson
export def "search-person SearchPerson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<id: int, name: string, original_name: string, adult: bool, gender: int, known_for_department: string, popularity: float, profile_path: string, known_for: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/person" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TV
#
# GET /search/tv
# operationId: SearchTV
export def "search-tv SearchTV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --first-air-date-year: string
  --include-adult: string@bool-completer # default: false
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --page: int # format: int32, default: 1
  --year: string
]: nothing -> record<page: int, total_pages: int, total_results: int, results: table<genre_ids: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "first_air_date_year" $first_air_date_year "scalar") (serialize-qp "include_adult" $include_adult "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/tv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details
#
# GET /tv/{series_id}
# operationId: TvSeriesDetails
export def "tv TvSeriesDetails" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
  --append-to-response: list # comma separated list of endpoints within this namespace, 20 items max
]: nothing -> record<created_by: table<id: int, name: string, credit_id: string, original_name: string, gender: int, profile_path: string>, episode_run_time: list<int>, genres: table<id: int, name: string>, homepage: string, in_production: bool, languages: list<string>, last_air_date: string, last_episode_to_air: record<episode_type: string, show_id: int>, next_episode_to_air: record<episode_type: string, show_id: int>, networks: table<id: int, name: string, origin_country: string, logo_path: string>, number_of_episodes: int, number_of_seasons: int, production_companies: table<id: int, name: string, origin_country: string, logo_path: string>, production_countries: table<iso_3166_1: string, name: string>, seasons: table<episode_count: int>, spoken_languages: table<iso_639_1: string, english_name: string, name: string>, status: string, tagline: string, type: string, recommendations: record<page: int, total_pages: int, total_results: int, results: list<any>>, similar: record<page: int, total_pages: int, total_results: int, results: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "append_to_response" $append_to_response "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/tv/($series_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Credits
#
# GET /tv/{series_id}/credits
# operationId: TvSeriesCredits
export def "tv-credits TvSeriesCredits" [
  series_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --language: string # `ISO-639-1`-`ISO-3166-1` code (default: en-US)
]: nothing -> record<id: int, cast: table<cast_id: int, character: string, order: int>, crew: table<department: string, job: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tv/($series_id)/credits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
