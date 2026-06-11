# Auto-generated client for Streaming Availability API v4.1.0
# Source: https://raw.githubusercontent.com/movieofthenight/streaming-availability-api/main/openapi.yaml
# Auth: --token flag or $env.STREAMING_AVAILABILITY_API_TOKEN

const BASE_URL = "https://api.movieofthenight.com/v4"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STREAMING_AVAILABILITY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "x-rapidapi-key" => { {headers: {X-RapidAPI-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api.movieofthenight.com/v4" "https://streaming-availability.p.rapidapi.com"] }
def auth-scheme-completer [] { ["x-api-key" "x-rapidapi-key"] }

# Completers for enum parameters
def output-language-completer [] { ["en" "es" "fr" "tr"] }
def series-granularity-completer [] { ["episode" "season" "show"] }
def show-type-completer [] { ["movie" "series"] }
def genres-relation-completer [] { ["and" "or"] }
def order-by-completer [] { ["original_title" "popularity_1month" "popularity_1week" "popularity_1year" "popularity_alltime" "rating" "release_date"] }
def order-direction-completer [] { ["asc" "desc"] }
def change-type-completer [] { ["expiring" "new" "removed" "upcoming" "updated"] }
def item-type-completer [] { ["episode" "season" "show"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "countries list" } } | get name | first)
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

# Get all Countries
#
# GET /countries
# Docs: https://docs.movieofthenight.com/resource/countries#get-all-countries — Official Documentation
# operationId: getCountries
export def "countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Country
#
# GET /countries/{country-code}
# Docs: https://docs.movieofthenight.com/resource/countries#get-a-country — Official Documentation
# operationId: getCountry
export def "countries get" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/countries/($country_code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Genres
#
# GET /genres
# Docs: https://docs.movieofthenight.com/resource/genres#get-all-genres — Official Documentation
# operationId: getGenres
export def "genres get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/genres" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Show
#
# GET /shows/{id}
# Docs: https://docs.movieofthenight.com/resource/shows#get-a-show — Official Documentation
# operationId: getShow
export def "shows get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the optional target country. If this parameter is not supplied, global streaming availability across all the countries will be returned. If it is supplied, only the streaming availability info from the given country will be returned. If you are only interested in the streaming availability in a single country, then it is recommended to use this parameter to reduce the size of the response and increase the performance of the endpoint. See /countries endpoint to get the list of supported countries.
  --series-granularity: string@series-granularity-completer # series_granularity determines the level of detail for series. It does not affect movies.  If series_granularity is show, then the output will not include season and episode info.  If series_granularity is season, then the output will include season info but not episode info.  If series_granularity is episode, then the output will include season and episode info.  If you do not need season and episode info, then it is recommended to set series_granularity as show to reduce the size of the response and increase the performance of the endpoint.  If you need deep links for individual seasons and episodes, then you should set series_granularity as episode. In this case response will include full streaming info for seasons and episodes, similar to the streaming info for movies and series; including deep links into seasons and episodes, individual subtitle/audio and video quality info etc.  (default: episode)
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "series_granularity" $series_granularity "scalar") (serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shows/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Shows by filters
#
# GET /shows/search/filters
# Docs: https://docs.movieofthenight.com/resource/shows#search-shows-by-filters — Official Documentation
# operationId: searchShowsByFilters
export def "shows-search-filters searchShowsByFilters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the target country. See /countries endpoint to get the list of supported countries.
  --catalogs: list # A comma separated list of up to 32 catalogs to search in. See /countries endpoint to get the supported services in each country and their ids.  When multiple catalogs are passed as a comma separated list, any show that is in at least one of the catalogs will be included in the result.  If no catalogs are passed, the endpoint will search in all the available catalogs in the country.  Syntax of the catalogs supplied in the list can be as the followings:  - <sevice_id>: Searches in the entire catalog of that service, including (if applicable) rentable, buyable shows or shows available through addons e.g. netflix, prime, apple  - <sevice_id>.<streaming_option_type>: Only returns the shows that are available in that service with the given streaming option type. Valid streaming option types are subscription, free, rent, buy and addon e.g. peacock.free only returns the shows on Peacock that are free to watch, prime.subscription only returns the shows on Prime Video that are available to watch with a Prime subscription. hulu.addon only returns the shows on Hulu that are available via an addon, prime.rent only returns the shows on Prime Video that are rentable.  - <sevice_id>.addon.<addon_id>: Only returns the shows that are available in that service with the given addon. Check /countries endpoint to fetch the available addons for a service in each country. Some sample values are: hulu.addon.hbo, prime.addon.hbomaxus.
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
  --show-type: string@show-type-completer # Type of shows to search in. If not supplied, both movies and series will be included in the search results.
  --genres: list # A comma seperated list of genre ids to only search within the shows in those genre. See /genres endpoint to see the available genres and their ids. Use genres_relation parameter to specify between returning shows that have at least one of the given genres or returning shows that have all of the given genres.
  --genres-relation: string@genres-relation-completer # Only used when there are multiple genres supplied in genres parameter.  When or, the endpoint returns any show that has at least one of the given genres. When and, it only returns the shows that have all of the given genres.  (default: and)
  --show-original-language: string # [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1) language code to only search within the shows whose original language matches with the provided language.
  --year-min: int # Minimum release/air year of the shows.
  --year-max: int # Maximum release/air year of the shows.
  --rating-min: int # Minimum rating of the shows.
  --rating-max: int # Maximum rating of the shows.
  --keyword: string # A keyword to only search within the shows have that keyword in their overview or title.
  --series-granularity: string@series-granularity-completer # series_granularity determines the level of detail for series. It does not affect movies.  If series_granularity is show, then the output will not include season and episode info.  If series_granularity is season, then the output will include season info but not episode info.  If series_granularity is episode, then the output will include season and episode info.  If you do not need season and episode info, then it is recommended to set series_granularity as show to reduce the size of the response and increase the performance of the endpoint.  If you need deep links for individual seasons and episodes, then you should set series_granularity as episode. In this case response will include full streaming info for seasons and episodes, similar to the streaming info for movies and series; including deep links into seasons and episodes, individual subtitle/audio and video quality info etc.  (default: show)
  --order-by: string@order-by-completer # Determines the ordering of the shows.  You can switch between ascending and descending order by using the order_direction parameter.  (default: original_title)
  --order-direction: string@order-direction-completer # Determines whether to order the results in ascending or descending order.  Default value when ordering alphabetically or based on dates/times is asc.  Default value when ordering by rating or popularity is desc.
  --cursor: string # Cursor is used for pagination. After each request, the response includes a hasMore boolean field to tell if there are more results that did not fit into the returned list. If it is set as true, to get the rest of the result set, send a new request (with the same parameters for other fields), and set the cursor parameter as the nextCursor value of the response of the previous request. Do not forget to escape the cursor value before putting it into a query as it might contain characters such as ?and &.  The first request naturally does not require a cursor parameter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "catalogs" $catalogs "csv") (serialize-qp "output_language" $output_language "scalar") (serialize-qp "show_type" $show_type "scalar") (serialize-qp "genres" $genres "csv") (serialize-qp "genres_relation" $genres_relation "scalar") (serialize-qp "show_original_language" $show_original_language "scalar") (serialize-qp "year_min" $year_min "scalar") (serialize-qp "year_max" $year_max "scalar") (serialize-qp "rating_min" $rating_min "scalar") (serialize-qp "rating_max" $rating_max "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "series_granularity" $series_granularity "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shows/search/filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Shows by title
#
# GET /shows/search/title
# Docs: https://docs.movieofthenight.com/resource/shows#search-shows-by-title — Official Documentation
# operationId: searchShowsByTitle
export def "shows-search-title searchShowsByTitle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # Title phrase to search for.
  --show-type: string@show-type-completer # Type of shows to search in. If not supplied, both movies and series will be included in the search results.
  --country: string # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the target country. See /countries endpoint to get the list of supported countries.
  --series-granularity: string@series-granularity-completer # series_granularity determines the level of detail for series. It does not affect movies.  If series_granularity is show, then the output will not include season and episode info.  If series_granularity is season, then the output will include season info but not episode info.  If series_granularity is episode, then the output will include season and episode info.  If you do not need season and episode info, then it is recommended to set series_granularity as show to reduce the size of the response and increase the performance of the endpoint.  If you need deep links for individual seasons and episodes, then you should set series_granularity as episode. In this case response will include full streaming info for seasons and episodes, similar to the streaming info for movies and series; including deep links into seasons and episodes, individual subtitle/audio and video quality info etc.  (default: show)
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "show_type" $show_type "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "series_granularity" $series_granularity "scalar") (serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shows/search/title" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Top Shows
#
# GET /shows/top
# Docs: https://docs.movieofthenight.com/resource/shows#get-top-shows — Official Documentation
# operationId: getTopShows
export def "shows-top get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the target country. See /countries endpoint to get the list of supported countries.
  --service: string # Id of the target service.
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
  --show-type: string@show-type-completer # Type of shows to search in. If not supplied, both movies and series will be included in the search results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "output_language" $output_language "scalar") (serialize-qp "show_type" $show_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shows/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Changes
#
# GET /changes
# Docs: https://docs.movieofthenight.com/resource/shows#search-shows-by-title — Official Documentation
# operationId: getChanges
export def "changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the target country. See /countries endpoint to get the list of supported countries.
  --catalogs: list # A comma separated list of up to 32 catalogs to search in. See /countries endpoint to get the supported services in each country and their ids.  When multiple catalogs are passed as a comma separated list, any show that is in at least one of the catalogs will be included in the result.  If no catalogs are passed, the endpoint will search in all the available catalogs in the country.  Syntax of the catalogs supplied in the list can be as the followings:  - <sevice_id>: Searches in the entire catalog of that service, including (if applicable) rentable, buyable shows or shows available through addons e.g. netflix, prime, apple  - <sevice_id>.<streaming_option_type>: Only returns the shows that are available in that service with the given streaming option type. Valid streaming option types are subscription, free, rent, buy and addon e.g. peacock.free only returns the shows on Peacock that are free to watch, prime.subscription only returns the shows on Prime Video that are available to watch with a Prime subscription. hulu.addon only returns the shows on Hulu that are available via an addon, prime.rent only returns the shows on Prime Video that are rentable.  - <sevice_id>.addon.<addon_id>: Only returns the shows that are available in that service with the given addon. Check /countries endpoint to fetch the available addons for a service in each country. Some sample values are: hulu.addon.hbo, prime.addon.hbomaxus.
  --change-type: string@change-type-completer # Type of changes to query.
  --item-type: string@item-type-completer # Type of items to search in. If item_type is show, you can use show_type parameter to only search for movies or series.
  --show-type: string@show-type-completer # Type of shows to search in. If not supplied, both movies and series will be included in the search results.
  --qp-from: int # [Unix Time Stamp](https://www.unixtimestamp.com/) to only query the changes happened/happening after this date (inclusive). For past changes such as new, removed or updated, the timestamp must be between today and 31 days ago. For future changes such as expiring or upcoming, the timestamp must be between today and 31 days from now in the future.  If not supplied, the default value for past changes is 31 days ago, and for future changes is today.  (format: int64)
  --qp-to: int # [Unix Time Stamp](https://www.unixtimestamp.com/) to only query the changes happened/happening before this date (inclusive). For past changes such as new, removed or updated, the timestamp must be between today and 31 days ago. For future changes such as expiring or upcoming, the timestamp must be between today and 31 days from now in the future.  If not supplied, the default value for past changes is today, and for future changes is 31 days from now.  (format: int64)
  --include-unknown-dates: string@bool-completer # Whether to include the changes with unknown dates. past changes such as new, removed or updated will always have a timestamp thus this parameter does not affect them. future changes such as expiring or upcoming may not have a timestamp if the exact date is not known (e.g. some services do not explicitly state the exact date of some of the upcoming/expiring shows). If set as true, the changes with unknown dates will be included in the response. If set as false, the changes with unknown dates will be excluded from the response.  When ordering, the changes with unknown dates will be treated as if their timestamp is 0. Thus, they will appear first in the ascending order and last in the descending order.  (default: false)
  --cursor: string # Cursor is used for pagination. After each request, the response includes a hasMore boolean field to tell if there are more results that did not fit into the returned list. If it is set as true, to get the rest of the result set, send a new request (with the same parameters for other fields), and set the cursor parameter as the nextCursor value of the response of the previous request. Do not forget to escape the cursor value before putting it into a query as it might contain characters such as ?and &.  The first request naturally does not require a cursor parameter.
  --order-direction: string@order-direction-completer # Determines whether to order the results in ascending or descending order.
  --output-language: string@output-language-completer # [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1) of the output language. Determines in which language the output  will be in.  (default: en)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "catalogs" $catalogs "csv") (serialize-qp "change_type" $change_type "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "show_type" $show_type "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "include_unknown_dates" $include_unknown_dates "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "order_direction" $order_direction "scalar") (serialize-qp "output_language" $output_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
