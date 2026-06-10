# Auto-generated client for Spaceflight News API v4.30.2 (v4)
# Source: https://api.spaceflightnewsapi.net/v4/schema/
# Auth: --token flag or $env.SPACEFLIGHT_NEWS_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPACEFLIGHT_NEWS_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "articles list" } } | get name | first)
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

# GET /v4/articles/
#
# operationId: articles_list
export def "articles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: list # Search for all documents related to a specific event using its Launch Library 2 ID.
  --has-event: string@bool-completer # Get all documents that have a related event.
  --has-launch: string@bool-completer # Get all documents that have a related launch.
  --is-featured: string@bool-completer # Get all documents that are featured.
  --launch: list # Search for all documents related to a specific launch using its Launch Library 2 ID.
  --limit: int # Number of results to return per page.
  --news-site: string # Search for documents with a news_site__name present in a list of comma-separated values. Case insensitive.
  --news-site-exclude: string # Search for documents with a news_site__name not present in a list of comma-separated values. Case insensitive.
  --offset: int # The initial index from which to return the results.
  --ordering: list # Order the result on `published_at, -published_at, updated_at, -updated_at`.  * `published_at` - Published at * `-published_at` - Published at (descending) * `updated_at` - Updated at * `-updated_at` - Updated at (descending)
  --published-at-gt: string # Get all documents published after a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-gte: string # Get all documents published after a given ISO8601 timestamp (included). (format: date-time)
  --published-at-lt: string # Get all documents published before a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-lte: string # Get all documents published before a given ISO8601 timestamp (included). (format: date-time)
  --search: string # Search for documents with a specific phrase in the title or summary.
  --summary-contains: string # Search for all documents with a specific phrase in the summary.
  --summary-contains-all: string # Search for documents with a summary containing all keywords from comma-separated values.
  --summary-contains-one: string # Search for documents with a summary containing at least one keyword from comma-separated values.
  --title-contains: string # Search for all documents with a specific phrase in the title.
  --title-contains-all: string # Search for documents with a title containing all keywords from comma-separated values.
  --title-contains-one: string # Search for documents with a title containing at least one keyword from comma-separated values.
  --updated-at-gt: string # Get all documents updated after a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-gte: string # Get all documents updated after a given ISO8601 timestamp (included). (format: date-time)
  --updated-at-lt: string # Get all documents updated before a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-lte: string # Get all documents updated before a given ISO8601 timestamp (included). (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, title: string, authors: list, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string, featured: bool, launches: list, events: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "csv") (serialize-qp "has_event" $has_event "scalar") (serialize-qp "has_launch" $has_launch "scalar") (serialize-qp "is_featured" $is_featured "scalar") (serialize-qp "launch" $launch "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "news_site" $news_site "scalar") (serialize-qp "news_site_exclude" $news_site_exclude "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "csv") (serialize-qp "published_at_gt" $published_at_gt "scalar") (serialize-qp "published_at_gte" $published_at_gte "scalar") (serialize-qp "published_at_lt" $published_at_lt "scalar") (serialize-qp "published_at_lte" $published_at_lte "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "summary_contains" $summary_contains "scalar") (serialize-qp "summary_contains_all" $summary_contains_all "scalar") (serialize-qp "summary_contains_one" $summary_contains_one "scalar") (serialize-qp "title_contains" $title_contains "scalar") (serialize-qp "title_contains_all" $title_contains_all "scalar") (serialize-qp "title_contains_one" $title_contains_one "scalar") (serialize-qp "updated_at_gt" $updated_at_gt "scalar") (serialize-qp "updated_at_gte" $updated_at_gte "scalar") (serialize-qp "updated_at_lt" $updated_at_lt "scalar") (serialize-qp "updated_at_lte" $updated_at_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/articles/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/articles/{id}/
#
# operationId: articles_retrieve
export def "articles get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authors: table<name: string, socials: record>, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string, featured: bool, launches: table<launch_id: string, provider: string>, events: table<event_id: int, provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/articles/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/blogs/
#
# operationId: blogs_list
export def "blogs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --event: list # Search for all documents related to a specific event using its Launch Library 2 ID.
  --has-event: string@bool-completer # Get all documents that have a related event.
  --has-launch: string@bool-completer # Get all documents that have a related launch.
  --is-featured: string@bool-completer # Get all documents that are featured.
  --launch: list # Search for all documents related to a specific launch using its Launch Library 2 ID.
  --limit: int # Number of results to return per page.
  --news-site: string # Search for documents with a news_site__name present in a list of comma-separated values. Case insensitive.
  --news-site-exclude: string # Search for documents with a news_site__name not present in a list of comma-separated values. Case insensitive.
  --offset: int # The initial index from which to return the results.
  --ordering: list # Order the result on `published_at, -published_at, updated_at, -updated_at`.  * `published_at` - Published at * `-published_at` - Published at (descending) * `updated_at` - Updated at * `-updated_at` - Updated at (descending)
  --published-at-gt: string # Get all documents published after a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-gte: string # Get all documents published after a given ISO8601 timestamp (included). (format: date-time)
  --published-at-lt: string # Get all documents published before a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-lte: string # Get all documents published before a given ISO8601 timestamp (included). (format: date-time)
  --search: string # Search for documents with a specific phrase in the title or summary.
  --summary-contains: string # Search for all documents with a specific phrase in the summary.
  --summary-contains-all: string # Search for documents with a summary containing all keywords from comma-separated values.
  --summary-contains-one: string # Search for documents with a summary containing at least one keyword from comma-separated values.
  --title-contains: string # Search for all documents with a specific phrase in the title.
  --title-contains-all: string # Search for documents with a title containing all keywords from comma-separated values.
  --title-contains-one: string # Search for documents with a title containing at least one keyword from comma-separated values.
  --updated-at-gt: string # Get all documents updated after a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-gte: string # Get all documents updated after a given ISO8601 timestamp (included). (format: date-time)
  --updated-at-lt: string # Get all documents updated before a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-lte: string # Get all documents updated before a given ISO8601 timestamp (included). (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, title: string, authors: list, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string, featured: bool, launches: list, events: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "event" $event "csv") (serialize-qp "has_event" $has_event "scalar") (serialize-qp "has_launch" $has_launch "scalar") (serialize-qp "is_featured" $is_featured "scalar") (serialize-qp "launch" $launch "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "news_site" $news_site "scalar") (serialize-qp "news_site_exclude" $news_site_exclude "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "csv") (serialize-qp "published_at_gt" $published_at_gt "scalar") (serialize-qp "published_at_gte" $published_at_gte "scalar") (serialize-qp "published_at_lt" $published_at_lt "scalar") (serialize-qp "published_at_lte" $published_at_lte "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "summary_contains" $summary_contains "scalar") (serialize-qp "summary_contains_all" $summary_contains_all "scalar") (serialize-qp "summary_contains_one" $summary_contains_one "scalar") (serialize-qp "title_contains" $title_contains "scalar") (serialize-qp "title_contains_all" $title_contains_all "scalar") (serialize-qp "title_contains_one" $title_contains_one "scalar") (serialize-qp "updated_at_gt" $updated_at_gt "scalar") (serialize-qp "updated_at_gte" $updated_at_gte "scalar") (serialize-qp "updated_at_lt" $updated_at_lt "scalar") (serialize-qp "updated_at_lte" $updated_at_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/blogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/blogs/{id}/
#
# operationId: blogs_retrieve
export def "blogs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authors: table<name: string, socials: record>, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string, featured: bool, launches: table<launch_id: string, provider: string>, events: table<event_id: int, provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/blogs/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/info/
#
# operationId: info_retrieve
export def "info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string, news_sites: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/info/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/reports/
#
# operationId: reports_list
export def "reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Number of results to return per page.
  --news-site: string # Search for documents with a news_site__name present in a list of comma-separated values. Case insensitive.
  --news-site-exclude: string # Search for documents with a news_site__name not present in a list of comma-separated values. Case insensitive.
  --offset: int # The initial index from which to return the results.
  --ordering: list # Order the result on `published_at, -published_at, updated_at, -updated_at`.  * `published_at` - Published at * `-published_at` - Published at (descending) * `updated_at` - Updated at * `-updated_at` - Updated at (descending)
  --published-at-gt: string # Get all documents published after a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-gte: string # Get all documents published after a given ISO8601 timestamp (included). (format: date-time)
  --published-at-lt: string # Get all documents published before a given ISO8601 timestamp (excluded). (format: date-time)
  --published-at-lte: string # Get all documents published before a given ISO8601 timestamp (included). (format: date-time)
  --search: string # Search for documents with a specific phrase in the title or summary.
  --summary-contains: string # Search for all documents with a specific phrase in the summary.
  --summary-contains-all: string # Search for documents with a summary containing all keywords from comma-separated values.
  --summary-contains-one: string # Search for documents with a summary containing at least one keyword from comma-separated values.
  --title-contains: string # Search for all documents with a specific phrase in the title.
  --title-contains-all: string # Search for documents with a title containing all keywords from comma-separated values.
  --title-contains-one: string # Search for documents with a title containing at least one keyword from comma-separated values.
  --updated-at-gt: string # Get all documents updated after a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-gte: string # Get all documents updated after a given ISO8601 timestamp (included). (format: date-time)
  --updated-at-lt: string # Get all documents updated before a given ISO8601 timestamp (excluded). (format: date-time)
  --updated-at-lte: string # Get all documents updated before a given ISO8601 timestamp (included). (format: date-time)
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, title: string, authors: list, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "news_site" $news_site "scalar") (serialize-qp "news_site_exclude" $news_site_exclude "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "csv") (serialize-qp "published_at_gt" $published_at_gt "scalar") (serialize-qp "published_at_gte" $published_at_gte "scalar") (serialize-qp "published_at_lt" $published_at_lt "scalar") (serialize-qp "published_at_lte" $published_at_lte "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "summary_contains" $summary_contains "scalar") (serialize-qp "summary_contains_all" $summary_contains_all "scalar") (serialize-qp "summary_contains_one" $summary_contains_one "scalar") (serialize-qp "title_contains" $title_contains "scalar") (serialize-qp "title_contains_all" $title_contains_all "scalar") (serialize-qp "title_contains_one" $title_contains_one "scalar") (serialize-qp "updated_at_gt" $updated_at_gt "scalar") (serialize-qp "updated_at_gte" $updated_at_gte "scalar") (serialize-qp "updated_at_lt" $updated_at_lt "scalar") (serialize-qp "updated_at_lte" $updated_at_lte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/reports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v4/reports/{id}/
#
# operationId: reports_retrieve
export def "reports get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, title: string, authors: table<name: string, socials: record>, url: string, image_url: string, news_site: string, summary: string, published_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/reports/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
