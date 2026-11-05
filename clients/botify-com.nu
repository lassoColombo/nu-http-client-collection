# Auto-generated client for Botify API v1.0.0
# Source: https://api.apis.guru/v2/specs/botify.com/1.0.0/openapi.json
# Auth: --token flag or $env.BOTIFY_API_TOKEN

const BASE_URL = "https://api.botify.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BOTIFY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.botify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def frequency-completer [] { ["1mn" "5mn" "60mn"] }
def list-type-completer [] { ["crawled" "errors"] }
def medium-completer [] { ["organic" "social"] }
def source-completer [] { ["all" "aol" "ask" "baidu" "bing" "facebook" "google" "google+" "linkedin" "naver" "pinterest" "reddit" "tumblr" "twitter" "yahoo" "yandex"] }
def area-completer [] { ["current" "disappeared" "new" "search_engines_orphans"] }
def area-completer-1 [] { ["current" "new"] }
def area-completer-2 [] { ["current" "disappeared" "new"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-project-analyses" "get-analysis-summary" "get-crawl-statistics" "get-crawl-statistics-by-frequency" "get-crawl-statistics-urls" "get-ganalytics-orphan-ur-ls" "get-links-percentiles" "get-page-rank-lost" "get-sitemaps-report" "get-sitemaps-samples-out-of-config" "get-sitemaps-samples-sitemaps-only" "get-links-top-domains" "get-links-top-subdomains" "get-urls" "get-urls-aggs" "get-urls-datamodel" "get-urls-exports" "create-urls-export" "get-urls-export-status" "get-urls-suggested-filters" "get-url-detail" "get-user-projects" "test-url-rewriting-rules" "get-saved-filters" "get-saved-filter" "get-project-urls-aggs" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "get-project-analyses" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<config: string, date_created: string, date_finished: string, date_last_modified: string, date_launched: string, features: string, id: int, name: string, slug: string, status: string, url: string, urls_done: string, urls_in_queue: string, user: record>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/analyses/{username}/{project_slug}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an Analysis detail
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}
# operationId: getAnalysisSummary
export def "get-analysis-summary" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<config: string, date_finished: string, date_last_modified: string, date_launched: string, failures: string, features: string, id: int, name: string, red_button_domain: string, slug: string, url: string, urls_done: string, urls_in_queue: string, user: record<company_name: string, date_joined: string, email: string, first_name: string, is_organization: string, last_name: string, login: string, status: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return global statistics for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics
# operationId: getCrawlStatistics
export def "get-crawl-statistics" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<depth_current: int, last_upd_dt: string, pages_dones: int, pages_dones_2xx: int, pages_dones_3xx: int, pages_dones_4xx: int, pages_dones_5xx: int, pages_dones_networkerror: int, pages_dones_xxx: int, pages_known: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return crawl statistics grouped by time frequency (1 min, 5 mins or 60 min)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time
# operationId: getCrawlStatisticsByFrequency
export def "get-crawl-statistics-by-frequency" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # max number of elements to retrieve (format: int32)
  --frequency: string@frequency-completer # Aggregation frequency (required)
]: nothing -> oneof<record<avg_delay: table<count: int, datetime: string>, avg_size: table<count: int, datetime: string>, frequency: string, http_code_2xx: table<count: int, datetime: string>, http_code_3xx: table<count: int, datetime: string>, http_code_4xx: table<count: int, datetime: string>, http_code_5xx: table<count: int, datetime: string>, http_code_xxx: table<count: int, datetime: string>, last_update_date: string, new_urls: table<count: int, datetime: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  if ($frequency == null) { error make --unspanned { msg: "required query parameter 'frequency' missing: pass --frequency" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "frequency" $frequency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/time") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "frequency": $frequency} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return a list of 1000 latest URLs crawled (all crawled URLs or only URLS with HTTP errors)
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}
# operationId: getCrawlStatisticsUrls
export def "get-crawl-statistics-urls" [
  username: string
  project_slug: string
  analysis_slug: string
  list_type: string@list-type-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<list<any>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  if ($list_type | is-empty) { error make --unspanned { msg: "path parameter 'list_type' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), list_type: (encode-path-segment $list_type)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/crawl_statistics/urls/{list_type}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List of Orphan URLs
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}
# operationId: getGanalyticsOrphanURLs
export def "get-ganalytics-orphan-ur-ls" [
  username: string
  project_slug: string
  analysis_slug: string
  medium: string@medium-completer
  source: string@source-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<url: string, visits: int>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  if ($medium | is-empty) { error make --unspanned { msg: "path parameter 'medium' must be non-empty" } }
  if ($source | is-empty) { error make --unspanned { msg: "path parameter 'source' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), medium: (encode-path-segment $medium), source: (encode-path-segment $source)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/ganalytics/orphan_urls/{medium}/{source}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get inlinks percentiles
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles
# operationId: getLinksPercentiles
export def "get-links-percentiles" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<domain: string, percentiles: table<avg: int, id: int, max: int, metric_total: int, min: int, url_total: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/links/percentiles") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lost pagerank
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost
# operationId: getPageRankLost
export def "get-page-rank-lost" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<external: float, non_crawled: float, robots_txt: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/pagerank/lost") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get global information of the sitemaps found (sitemaps indexes, invalid sitemaps urls, etc
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report
# operationId: getSitemapsReport
export def "get-sitemaps-report" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: int, errors: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_indexes: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>, sitemap_only: record<in_configuration: int, out_of_configuration: int>, sitemaps: table<error: record, file_type: string, invalid_urls: int, sitemap_indexes: list, url: string, valid_urls: int>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/report") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sample list of URLs which were found in your sitemaps but outside of the
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config
# operationId: getSitemapsSamplesOutOfConfig
export def "get-sitemaps-samples-out-of-config" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/out_of_config") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sample list of URLs which were found in your sitemaps, within the project
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only
# operationId: getSitemapsSamplesSitemapsOnly
export def "get-sitemaps-samples-sitemaps-only" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: list<string>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/sitemaps/samples/sitemap_only") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Top domains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains
# operationId: getLinksTopDomains
export def "get-links-top-domains" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/domains") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Top subddomains
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains
# operationId: getLinksTopSubdomains
export def "get-links-top-subdomains" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<domain: string, follow_links: int, follow_samples: list, nofollow_links: int, nofollow_samples: list, unique_follow_links: int, unique_nofollow_links: int>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/features/top_domains/subdomains") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Executes a query and returns a paginated response
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls
# operationId: getUrls
export def "get-urls" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # Analysis context to execute the query (default: current)
  --page: int # Page Number (format: int32)
  --size: int # Page Size (format: int32)
  --fields: list<string>
  --filters: record
  --sort: list
]: any -> oneof<record<count: int, next: string, page: int, previous: string, results: list<record>, size: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls") $qp $auth.query)
  let req_body = {"fields": $fields, "filters": $filters, "sort": $sort} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"area": $area, "page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Query aggregator
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs
# operationId: getUrlsAggs
export def "get-urls-aggs" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --body: list
]: any -> oneof<list<any>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/aggs") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"area": $area} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets an Analysis datamodel
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel
# operationId: getUrlsDatamodel
export def "get-urls-datamodel" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
]: nothing -> oneof<record<fields: table<group: string, id: string, multiple: bool, name: string, permissions: list, subtype: string, type: string>, groups: table<id: string, name: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/datamodel") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"area": $area} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# A list of the CSV Exports requests and their current status
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# operationId: getUrlsExports
export def "get-urls-exports" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record, results: string>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new UrlExport object and starts a task that will export the results into a csv
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/export
# operationId: createUrlsExport
export def "create-urls-export" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer # default: current
  --fields: list<string>
  --filters: record
  --sort: list
]: any -> oneof<record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export") $qp $auth.query)
  let req_body = {"fields": $fields, "filters": $filters, "sort": $sort} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"area": $area} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Checks the status of an CSVUrlExportJob object
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}
# operationId: getUrlsExportStatus
export def "get-urls-export-status" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<area: int, date_created: string, job_id: string, job_status: string, job_url: string, nb_results: int, query: record<fields: list<string>, filters: record, sort: list<record>>, results: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  if ($url_export_id | is-empty) { error make --unspanned { msg: "path parameter 'url_export_id' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), url_export_id: (encode-path-segment $url_export_id)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/export/{url_export_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Return most frequent segments (= suggested patterns in the previous version)
#
# POST /analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters
# operationId: getUrlsSuggestedFilters
export def "get-urls-suggested-filters" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-1 # default: current
  --aggs: list
  --filters: record
]: any -> oneof<record<aggs: list<record>, filters: record>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/suggested_filters") $qp $auth.query)
  let req_body = {"aggs": $aggs, "filters": $filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"area": $area} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Gets the detail of an URL for an analysis
#
# GET /analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}
# operationId: getUrlDetail
export def "get-url-detail" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: list<string> # comma separated list of fields to return (c.f. URLs Datamodel)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($analysis_slug | is-empty) { error make --unspanned { msg: "path parameter 'analysis_slug' must be non-empty" } }
  if ($url | is-empty) { error make --unspanned { msg: "path parameter 'url' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), analysis_slug: (encode-path-segment $analysis_slug), url: (encode-path-segment $url)} | format pattern "/analyses/{username}/{project_slug}/{analysis_slug}/urls/{url}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all active projects for the user
#
# GET /projects/{username}
# operationId: getUserProjects
export def "get-user-projects" [
  username: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<active: bool, current_settings: record, date_created: string, name: string, slug: string, user: record>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username)} | format pattern "/projects/{username}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Match and replace parts of a URL based on rules passed in POST data
#
# POST /projects/{username}/{project_slug}/features/url_rewriting/rules_validator
# operationId: testUrlRewritingRules
export def "test-url-rewriting-rules" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<rules: table<ignore_case: bool, regex: string, replace: string>, urls: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/features/url_rewriting/rules_validator") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [201]
}

# List all the project's saved filters (each filter's name, ID and filter value)
#
# GET /projects/{username}/{project_slug}/filters
# operationId: getSavedFilters
export def "get-saved-filters" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page Number
  --size: int # Page Size
]: nothing -> oneof<record<count: int, next: string, page: int, previous: string, results: table<filters: record, identifier: string, name: string>, size: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/filters") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves a specific saved filter's name, ID and filter value
#
# GET /projects/{username}/{project_slug}/filters/{identifier}
# operationId: getSavedFilter
export def "get-saved-filter" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<filters: record, identifier: string, name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug), identifier: (encode-path-segment $identifier)} | format pattern "/projects/{username}/{project_slug}/filters/{identifier}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Project Query aggregator
#
# POST /projects/{username}/{project_slug}/urls/aggs
# operationId: getProjectUrlsAggs
export def "get-project-urls-aggs" [
  username: string
  project_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --area: string@area-completer-2 # Analysis context to execute the queries (default: current)
  --last-analysis-slug: string # Last analysis on the trend
  --nb-analyses: int # Max number of analysis to return (format: int32, default: 20)
  --body: list
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($username | is-empty) { error make --unspanned { msg: "path parameter 'username' must be non-empty" } }
  if ($project_slug | is-empty) { error make --unspanned { msg: "path parameter 'project_slug' must be non-empty" } }
  let qp = [(serialize-qp "area" $area "scalar") (serialize-qp "last_analysis_slug" $last_analysis_slug "scalar") (serialize-qp "nb_analyses" $nb_analyses "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({username: (encode-path-segment $username), project_slug: (encode-path-segment $project_slug)} | format pattern "/projects/{username}/{project_slug}/urls/aggs") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"area": $area, "last_analysis_slug": $last_analysis_slug, "nb_analyses": $nb_analyses} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}
