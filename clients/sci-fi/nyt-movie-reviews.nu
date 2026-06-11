# Auto-generated client for Movie Reviews API v2.0.0
# Source: https://api.apis.guru/v2/specs/nytimes.com/movie_reviews/2.0.0/openapi.json
# Auth: --token flag or $env.MOVIE_REVIEWS_API_TOKEN

const BASE_URL = "http://api.nytimes.com/svc/movies/v2"
const DEFAULT_AUTH = "query-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MOVIE_REVIEWS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api-key" => { {headers: {}, query: $"api-key=($token_val)"} }
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
def base-url-completer [] { ["http://api.nytimes.com/svc/movies/v2" "https://api.nytimes.com/svc/movies/v2"] }
def auth-scheme-completer [] { ["query-api-key"] }

# Completers for enum parameters
def critics-pick-completer [] { ["N" "Y"] }
def order-completer [] { ["by-opening-date" "by-publication-date" "by-title"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "critics get" } } | get name | first)
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

# GET /critics/{resource-type}.json
export def "critics get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<copyright: string, num_results: int, results: table<bio: string, display_name: string, multimedia: record, seo_name: string, sort_name: string, status: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/critics/($resource_type).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /reviews/search.json
export def "reviews-searchjson get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search keywords; matches movie title and indexed terms  To limit your search to exact matches only, surround your search string with single quotation marks (e.g., query='28+days+later'). Otherwise, responses will include partial matches ("head words") as well as exact matches (e.g., president will match president, presidents and presidential).      If you specify multiple terms without quotation marks, they will be combined in an OR search.      If you omit the query parameter, your request will be equivalent to a reviews and NYT Critics' Picks request.
  --critics-pick: string@critics-pick-completer # Set this parameter to Y to limit the results to NYT Critics' Picks. To get only those movies that have not been highlighted by Times critics, specify critics-pick=N. (To get all reviews regardless of critics-pick status, simply omit this parameter.)
  --reviewer: string # Include this parameter to limit your results to reviews by a specific critic. Reviewer names should be formatted like this: Manohla Dargis.
  --publication-date: string # Single date: YYYY-MM-DD  Start and end date: YYYY-MM-DD;YYYY-MM-DD  The publication-date is the date the review was first published in The Times.
  --opening-date: string # Single date: YYYY-MM-DD  Start and end date: YYYY-MM-DD;YYYY-MM-DD  The opening-date is the date the movie's opening date in the New York region.
  --offset: int # Positive integer, multiple of 20 (default: 20)
  --order: string # Sets the sort order of the results.  Results ordered by-title are in ascending alphabetical order. Results ordered by one of the date parameters are in reverse chronological order.  If you do not specify a sort order, the results will be ordered by publication-date.
]: nothing -> record<copyright: string, num_results: int, results: table<byline: string, critics_pick: int, date_updated: string, display_title: string, headline: string, link: record, mpaa_rating: string, multimedia: record, opening_date: string, publication_date: string, summary_short: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "critics-pick" $critics_pick "scalar") (serialize-qp "reviewer" $reviewer "scalar") (serialize-qp "publication-date" $publication_date "scalar") (serialize-qp "opening-date" $opening_date "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reviews/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /reviews/{resource-type}.json
export def "reviews get" [
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # Positive integer, multiple of 20 (default: 20)
  --order: string@order-completer # Sets the sort order of the results.  Results ordered by-title are in ascending alphabetical order. Results ordered by one of the date parameters are in reverse chronological order.  If you do not specify a sort order, the results will be ordered by publication-date.  (default: by-publication-date)
]: nothing -> record<copyright: string, num_results: int, results: table<byline: string, critics_pick: int, date_updated: string, display_title: string, headline: string, link: record, mpaa_rating: string, multimedia: record, opening_date: string, publication_date: string, summary_short: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reviews/($resource_type).json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
