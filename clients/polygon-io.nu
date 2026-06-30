# Auto-generated client for Polygon v1.0.0
# Source: https://api.apis.guru/v2/specs/polygon.io/1.0.0/swagger.json
# Auth: --token flag or $env.POLYGON_TOKEN

const BASE_URL = "https://api.polygon.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o POLYGON_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apiKey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apiKey")=(encode-path-segment $token_val)", location: "query"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.polygon.io"] }
def auth-scheme-completer [] { ["query-apiKey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies get" } } | get name | first)
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

# Available Companies
#
# GET /v1/companies
export def "companies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Which field to sort by. For desc place a `-` in front of the field name. eg `?sort=-marketcap`
  --perpage: float # How many items to be on each page during pagination
  --page: float # Which page of results to return (default: 1)
]: nothing -> table<country: string, exchange: string, industry: string, marketcap: float, name: string, sector: string, symbol: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "perpage" $perpage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/companies" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort, "perpage": $perpage, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Available Currencies
#
# GET /v1/currencies
export def "currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/currencies" $auth.query)
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

# Historic Aggregates
#
# GET /v1/historic/agg/{size}/{symbol}/{date}
export def "historic-agg get" [
  size: string
  symbol: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Timestamp offset, used for pagination
  --limit: int # Limit the size of response, max: 10000 (default: 100)
]: nothing -> record<day: string, msLatency: int, status: string, symbol: string, ticks: table<c: int, h: int, k: int, l: int, o: int, t: int, v: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({size: (encode-path-segment $size), symbol: (encode-path-segment $symbol), date: (encode-path-segment $date)} | format pattern "/v1/historic/agg/{size}/{symbol}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Historic Forex Ticks
#
# GET /v1/historic/forex/{from}/{to}/{date}
export def "historic-forex get" [
  from: string
  to: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Timestamp offset, used for pagination
  --limit: int # Limit the size of response, max: 10000 (default: 100)
]: nothing -> record<day: string, msLatency: int, status: string, symbol: string, ticks: table<a: int, b: int, t: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  if ($to | is-empty) { error make --unspanned { msg: "path parameter 'to' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to), date: (encode-path-segment $date)} | format pattern "/v1/historic/forex/{from}/{to}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Historic Quotes
#
# GET /v1/historic/quotes/{symbol}/{date}
export def "historic-quotes get" [
  symbol: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Timestamp offset, used for pagination
  --limit: int # Limit the size of response, max: 10000 (default: 100)
]: nothing -> record<day: string, msLatency: int, status: string, symbol: string, ticks: table<aE: string, aP: float, aS: int, bE: string, bP: float, bS: int, c: int, t: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol), date: (encode-path-segment $date)} | format pattern "/v1/historic/quotes/{symbol}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Historic Trades
#
# GET /v1/historic/trades/{symbol}/{date}
export def "historic-trades get" [
  symbol: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Timestamp offset, used for pagination
  --limit: int # Limit the size of response, max: 10000 (default: 100)
]: nothing -> record<day: string, msLatency: int, status: string, symbol: string, ticks: table<c1: int, c2: int, c3: int, c4: int, e: string, p: float, s: int, t: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol), date: (encode-path-segment $date)} | format pattern "/v1/historic/trades/{symbol}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Last Trade for a Currency Pair
#
# GET /v1/last/currencies/{from}/{to}
export def "last-currencies get" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<last: record<exchange: int, price: float, timestamp: int>, status: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  if ($to | is-empty) { error make --unspanned { msg: "path parameter 'to' must be non-empty" } }
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/v1/last/currencies/{from}/{to}") $auth.query)
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

# Last Trade for a Symbol
#
# GET /v1/last/stocks/{symbol}
export def "last-stocks get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<last: record<cond1: int, cond2: int, cond3: int, cond4: int, exchange: int, price: float, size: int, timestamp: int>, status: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol)} | format pattern "/v1/last/stocks/{symbol}") $auth.query)
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

# Last Quote for a Currency Pair
#
# GET /v1/last_quote/currencies/{from}/{to}
export def "last-quote-currencies get" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<last: record<askprice: float, bidprice: float, timestamp: int>, status: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($from | is-empty) { error make --unspanned { msg: "path parameter 'from' must be non-empty" } }
  if ($to | is-empty) { error make --unspanned { msg: "path parameter 'to' must be non-empty" } }
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/v1/last_quote/currencies/{from}/{to}") $auth.query)
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

# Last Quote for a Symbol
#
# GET /v1/last_quote/stocks/{symbol}
export def "last-quote-stocks get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<last: record<askexchange: int, askprice: float, asksize: int, bidexchange: int, bidprice: float, bidsize: int, cond: int, timestamp: int>, status: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($symbol | is-empty) { error make --unspanned { msg: "path parameter 'symbol' must be non-empty" } }
  let full_url = (build-url $base ({symbol: (encode-path-segment $symbol)} | format pattern "/v1/last_quote/stocks/{symbol}") $auth.query)
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
