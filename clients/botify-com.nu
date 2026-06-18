# Auto-generated client for Botify API v1.0.0
# Source: https://api.apis.guru/v2/specs/botify.com/1.0.0/openapi.json
# Auth: --token flag or $env.BOTIFY_API_TOKEN

const BASE_URL = "https://api.botify.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOTIFY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.botify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def frequency-completer [] { ["1mn" "5mn" "60mn"] }
def area-completer [] { ["current" "disappeared" "new" "search_engines_orphans"] }
def area-completer-1 [] { ["current" "new"] }
def area-completer-2 [] { ["current" "disappeared" "new"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "analyses get" } } | get name | first)
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

# List all analyses for a project
#
# GET /analyses/{username}/{project_slug}
# operationId: getProjectAnalyses
export def "analyses get" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<config: string, date_created: string, date_finished: string, date_last_modified: string, date_launched: string, features: string, id: int, name: string, slug: string, status: string, url: string, urls_done: string, urls_in_queue: string, user: record>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/analyses/{username}/{project_slug}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Analysis detail
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}
# operationId: getAnalysisSummary
export def "analyses get-summary" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: string, date_finished: string, date_last_modified: string, date_launched: string, failures: string, features: string, id: int, name: string, red_button_domain: string, slug: string, url: string, urls_done: string, urls_in_queue: string, user: record<company_name: string, date_joined: string, email: string, first_name: string, is_organization: string, last_name: string, login: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return global statistics for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics
# operationId: getCrawlStatistics
export def "analyses-crawl-statistics get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<depth_current: int, last_upd_dt: string, pages_dones: int, pages_dones_2xx: int, pages_dones_3xx: int, pages_dones_4xx: int, pages_dones_5xx: int, pages_dones_networkerror: int, pages_dones_xxx: int, pages_known: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return crawl statistics grouped by time frequency (1 min, 5 mins or 60 min)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time
# operationId: getCrawlStatisticsByFrequency
export def "analyses-crawl-statistics-time get-by-frequency" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # max number of elements to retrieve (format: int32)
  --frequency: string@frequency-completer # Aggregation frequency
]: nothing -> record<avg_delay: table<count: int, datetime: string>, avg_size: table<count: int, datetime: string>, frequency: string, http_code_2xx: table<count: int, datetime: string>, http_code_3xx: table<count: int, datetime: string>, http_code_4xx: table<count: int, datetime: string>, http_code_5xx: table<count: int, datetime: string>, http_code_xxx: table<count: int, datetime: string>, last_update_date: string, new_urls: table<count: int, datetime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "frequency" $frequency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a list of 1000 latest URLs crawled (all crawled URLs or only URLS with HTTP errors)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}
# operationId: getCrawlStatisticsUrls
export def "analyses-crawl-statistics-urls get" [
  username: string
  project_slug: string
  analysis_slug: string
  list_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), list_type: (encode-path-segment $list_type)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of Orphan URLs
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}
# operationId: getGanalyticsOrphanURLs
export def "analyses-features-ganalytics-orphan-urls get-ur-ls" [
  username: string
  project_slug: string
  analysis_slug: string
  medium: string
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<url: string, visits: int>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), medium: (encode-path-segment $medium), source: (encode-path-segment $source)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get inlinks percentiles
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles
# operationId: getLinksPercentiles
export def "analyses-features-links-percentiles get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, percentiles: table<avg: int, id: int, max: int, metric_total: int, min: int, url_total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lost pagerank
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost
# operationId: getPageRankLost
export def "analyses-features-pagerank-lost get-page-rank" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<external: float, non_crawled: float, robots_txt: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global information of the sitemaps found (sitemaps indexes, invalid sitemaps urls, etc
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report
# operationId: getSitemapsReport
export def "analyses-features-sitemaps-report get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int, errors: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_indexes: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_only: record<in_configuration: int, out_of_configuration: int>, sitemaps: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sample list of URLs which were found in your sitemaps but outside of the
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config
# operationId: getSitemapsSamplesOutOfConfig
export def "analyses-features-sitemaps-samples-out-of-config get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: list<string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sample list of URLs which were found in your sitemaps, within the project
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only
# operationId: getSitemapsSamplesSitemapsOnly
export def "analyses-features-sitemaps-samples-sitemap-only get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: list<string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top domains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains
# operationId: getLinksTopDomains
export def "analyses-features-top-domains-domains get-links" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Top subddomains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains
# operationId: getLinksTopSubdomains
export def "analyses-features-top-domains-subdomains get-links" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Executes a query and returns a paginated response
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls
# operationId: getUrls
export def "analyses-urls get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # Analysis context to execute the query (default: current)
  --page: int # Page Number (format: int32)
  --size: int # Page Size (format: int32)
  --fields: list<string>
  --filters: record
  --body-sort: list
]: any -> record<count: int, next: string, page: int, previous: string, results: list<record>, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls") $qp)
  let req_body = {"fields": $fields, "filters": $filters, "sort": $body_sort} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Query aggregator
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs
# operationId: getUrlsAggs
export def "analyses-urls-aggs get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets an Analysis datamodel
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel
# operationId: getUrlsDatamodel
export def "analyses-urls-datamodel get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
]: nothing -> record<fields: table<group: string, id: string, multiple: bool, name: string, permissions: list, subtype: string, type: string>, groups: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A list of the CSV Exports requests and their current status
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# operationId: getUrlsExports
export def "analyses-urls-export get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record, results: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new UrlExport object and starts a task that will export the results into a csv
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# operationId: createUrlsExport
export def "analyses-urls-export create" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --fields: list<string>
  --filters: record
  --body-sort: list
]: any -> record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export") $qp)
  let req_body = {"fields": $fields, "filters": $filters, "sort": $body_sort} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Checks the status of an CSVUrlExportJob object
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}
# operationId: getUrlsExportStatus
export def "analyses-urls-export get-status" [
  username: string
  project_slug: string
  analysis_slug: string
  url_export_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), url_export_id: (encode-path-segment $url_export_id)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return most frequent segments (= suggested patterns in the previous version)
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters
# operationId: getUrlsSuggestedFilters
export def "analyses-urls-suggested-filters get" [
  username: string
  project_slug: string
  analysis_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-1 # default: current
  --aggs: list
  --filters: record
]: any -> record<aggs: list<record>, filters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters") $qp)
  let req_body = {"aggs": $aggs, "filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the detail of an URL for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}
# operationId: getUrlDetail
export def "analyses-urls get-detail" [
  username: string
  project_slug: string
  analysis_slug: string
  url: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # comma separated list of fields to return (c.f. URLs Datamodel)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), url: (encode-path-segment $url)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all active projects for the user
#
# GET /projects/{username}
# operationId: getUserProjects
export def "projects get-user" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<active: bool, current_settings: record, date_created: string, name: string, slug: string, user: record>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/projects/{username}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Match and replace parts of a URL based on rules passed in POST data
#
# POST /projects/{username}/{project_slug}/features/url_rewriting/rules_validator
# operationId: testUrlRewritingRules
export def "projects-features-url-rewriting-rules-validator test" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rules: table<ignore_case: bool, regex: string, replace: string>, urls: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/features/url_rewriting/rules_validator"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the project's saved filters (each filter's name, ID and filter value)
#
# GET /projects/{username}/{project_slug}/filters
# operationId: getSavedFilters
export def "projects-filters list" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> record<count: int, next: string, page: int, previous: string, results: table<filters: record, identifier: string, name: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/filters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific saved filter's name, ID and filter value
#
# GET /projects/{username}/{project_slug}/filters/{identifier}
# operationId: getSavedFilter
export def "projects-filters get-saved" [
  username: string
  project_slug: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filters: record, identifier: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), identifier: (encode-path-segment $identifier)} | format pattern "/projects/{username}/{project_slug}/filters/{identifier}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Project Query aggregator
#
# POST /projects/{username}/{project_slug}/urls/aggs
# operationId: getProjectUrlsAggs
export def "projects-urls-aggs get" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-2 # Analysis context to execute the queries (default: current)
  --last-analysis-slug: string # Last analysis on the trend
  --nb-analyses: int # Max number of analysis to return (format: int32, default: 20)
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "area" $area "scalar") (serialize-qp "last_analysis_slug" $last_analysis_slug "scalar") (serialize-qp "nb_analyses" $nb_analyses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/urls/aggs") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
