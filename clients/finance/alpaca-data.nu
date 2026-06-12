# Auto-generated client for Market Data API v2.0.0
# Source: https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/data/openapi.yaml
# Auth: --token flag or $env.MARKET_DATA_API_TOKEN

const BASE_URL = "https://data.alpaca.markets"
const DEFAULT_AUTH = "apca-api-key-id"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARKET_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apca-api-key-id" => { {headers: {APCA-API-KEY-ID: $token_val}, query: ""} }
    "apca-api-secret-key" => { {headers: {APCA-API-SECRET-KEY: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://data.alpaca.markets" "https://data.sandbox.alpaca.markets"] }
def auth-scheme-completer [] { ["apca-api-key-id" "apca-api-secret-key"] }

# Completers for enum parameters
def adjustment-completer [] { ["all" "dividend" "raw" "split"] }
def feed-completer [] { ["iex" "otc" "sip"] }
def exchange-completer [] { ["CBSE" "ERSX" "FTXU"] }
def accept-completer [] { ["application/json" "application/xml" "multipart/form-data"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def sort-completer [] { ["ASC" "DESC"] }
def tape-completer [] { ["A" "B" "C"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "stocks-bars list" } } | get name | first)
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

# Get Bar data for multiple stock symbols
#
# GET /v2/stocks/bars
# operationId: getBarsForMultipleStockSymbols
export def "stocks-bars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --timeframe: string # Timeframe for the aggregation. Values are customizeable, frequently used examples: 1Min, 15Min, 1Hour, 1Day. Limits: 1Min-59Min, 1Hour-23Hour.
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --adjustment: string@adjustment-completer # specifies the corporate action adjustment(s) for bars data
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<bars: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "adjustment" $adjustment "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/bars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Bar data for multiple stock symbols
#
# GET /v2/stocks/bars/latest
# operationId: getLatestBarsForMultipleStockSymbols
export def "stocks-bars-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<bars: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/bars/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bars
#
# GET /v2/stocks/{symbol}/bars
# operationId: getBarsForStockSymbol
export def "stocks-bars get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --timeframe: string # Timeframe for the aggregation. Values are customizeable, frequently used examples: 1Min, 15Min, 1Hour, 1Day. Limits: 1Min-59Min, 1Hour-23Hour.
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
  --adjustment: string@adjustment-completer # specifies the corporate action adjustment(s) for bars data
]: nothing -> record<bars: table<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "feed" $feed "scalar") (serialize-qp "adjustment" $adjustment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/bars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Bars for Symbol
#
# GET /v2/stocks/{symbol}/bars/latest
# operationId: getLatestBarForStockSymbol
export def "stocks-bars-latest get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<symbol: string, bar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/bars/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trade data for multiple stock symbols
#
# GET /v2/stocks/trades
# operationId: getTradesForMultipleStockSymbols
export def "stocks-trades list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<trades: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Trades data for multiple stock symbols
#
# GET /v2/stocks/trades/latest
# operationId: getLatestTradesForMultipleStockSymbols
export def "stocks-trades-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<trades: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/trades/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trades
#
# GET /v2/stocks/{symbol}/trades
# operationId: getTradesForStockSymbol
export def "stocks-trades get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<trades: table<t: string, x: string, p: float, s: float, c: list, i: int, z: string, tks: string>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Latest Trade
#
# GET /v2/stocks/{symbol}/trades/latest
# operationId: getLatestTradeForStockSymbol
export def "stocks-trades-latest get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<trade: record<t: string, x: string, p: float, s: float, c: list<string>, i: int, z: string, tks: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/trades/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Quotes for multiple stock symbols
#
# GET /v2/stocks/quotes
# operationId: getQuotesForMultipleStockSymbols
export def "stocks-quotes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<quotes: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Quotes for multiple stock symbols
#
# GET /v2/stocks/quotes/latest
# operationId: getLatestQuotesForMultipleStockSymbols
export def "stocks-quotes-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<quotes: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/quotes/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Quotes for stock symbol
#
# GET /v2/stocks/{symbol}/quotes
# operationId: getQuotesForStockSymbol
export def "stocks-quotes get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<quotes: table<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list, x: string, z: string>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Quote for stock symbol
#
# GET /v2/stocks/{symbol}/quotes/latest
# operationId: getLatestQuoteForStockSymbol
export def "stocks-quotes-latest get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<quote: record<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list<string>, x: string, z: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/quotes/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Snapshots for multiple stock symbols
#
# GET /v2/stocks/snapshots
# operationId: getSnapshotsForMultipleStockSymbols
export def "stocks-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of stock ticker symbols to query for. (e.g. AAPL,TSLA)
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/stocks/snapshots" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Snapshot for a stock symbol
#
# GET /v2/stocks/{symbol}/snapshot
# operationId: getSnapshotForStockSymbol
export def "stocks-snapshot get" [
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feed: string@feed-completer # Which feed to pull market data from. This is either `iex`, `otc`, or `sip`. `sip` and `otc` are only available to those with a subscription (e.g. sip)
]: nothing -> record<latestTrade: record<t: string, x: string, p: float, s: float, c: list<string>, i: int, z: string, tks: string>, latestQuote: record<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list<string>, x: string, z: string>, minuteBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, dailyBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, prevDailyBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "feed" $feed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/($symbol)/snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trade data for multiple crypto symbols
#
# GET /v1beta1/crypto/trades
# operationId: getTradesForMultipleCryptoSymbols
export def "v1beta1-crypto-trades list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
]: nothing -> record<trades: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "exchanges" $exchanges "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Trade data for multiple Crypto symbols
#
# GET /v1beta1/crypto/trades/latest
# operationId: getLatestTradesForMultipleCryptoSymbols
export def "v1beta1-crypto-trades-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<trades: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/trades/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trade data for a crypto symbol
#
# GET /v1beta1/crypto/{symbol}/trades
# operationId: getTradesForCryptoSymbol
export def "v1beta1-crypto-trades get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
]: nothing -> record<trades: table<t: string, x: string, p: float, s: float, c: list, i: int, z: string, tks: string>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "exchanges" $exchanges "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Latest Trades
#
# GET /v1beta1/crypto/{symbol}/trades/latest
# operationId: getLatestTradesForCryptoSymbol
export def "v1beta1-crypto-trades-latest get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<trade: record<t: string, x: string, p: float, s: float, c: list<string>, i: int, z: string, tks: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/trades/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bars for multiple Crypto symbols
#
# GET /v1beta1/crypto/bars
# operationId: getBarsForMultipleCryptoSymbols
export def "v1beta1-crypto-bars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --timeframe: string # Timeframe for the aggregation. Values are customizeable, frequently used examples: 1Min, 15Min, 1Hour, 1Day. Limits: 1Min-59Min, 1Hour-23Hour.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
]: nothing -> record<bars: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exchanges" $exchanges "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/bars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Bars for multiple Crypto symbols
#
# GET /v1beta1/crypto/bars/latest
# operationId: getLatestBarsForMultipleCryptoSymbols
export def "v1beta1-crypto-bars-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<bars: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/bars/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bar data for a crypto symbol
#
# GET /v1beta1/crypto/{symbol}/bars
# operationId: getBarsForCryptoSymbol
export def "v1beta1-crypto-bars get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --timeframe: string # Timeframe for the aggregation. Values are customizeable, frequently used examples: 1Min, 15Min, 1Hour, 1Day. Limits: 1Min-59Min, 1Hour-23Hour.
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
]: nothing -> record<bars: table<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "exchanges" $exchanges "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/bars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Bar data for a Crypto symbol
#
# GET /v1beta1/crypto/{symbol}/bars/latest
# operationId: getLatestBarsForCryptoSymbol
export def "v1beta1-crypto-bars-latest get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<symbol: string, bar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/bars/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Quotes for multiple crypto symbols
#
# GET /v1beta1/crypto/quotes
# operationId: getQuotesForMultipleCryptoSymbols
export def "v1beta1-crypto-quotes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
]: nothing -> record<quotes: record, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "exchanges" $exchanges "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest Quotes for multiple Crypto symbols
#
# GET /v1beta1/crypto/quotes/latest
# operationId: getLatestQuotesForMultipleCryptoSymbols
export def "v1beta1-crypto-quotes-latest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<quotes: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/quotes/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Quotes for crypto symbol
#
# GET /v1beta1/crypto/{symbol}/quotes
# operationId: getQuotesForCryptoSymbol
export def "v1beta1-crypto-quotes get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
]: nothing -> record<quotes: table<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list, x: string, z: string>, symbol: string, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "exchanges" $exchanges "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Latest Quote
#
# GET /v1beta1/crypto/{symbol}/quotes/latest
# operationId: getLatestQuoteForCryptoSymbol
export def "v1beta1-crypto-quotes-latest get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<quote: record<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list<string>, x: string, z: string>, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/quotes/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Snapshots for multiple crypto symbols
#
# GET /v1beta1/crypto/snapshots
# operationId: getSnapshotsForMultipleCryptoSymbols
export def "v1beta1-crypto-snapshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/snapshots" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Snapshot for a crypto symbol
#
# GET /v1beta1/crypto/{symbol}/snapshot
# operationId: getSnapshotForCryptoSymbol
export def "v1beta1-crypto-snapshot get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --exchange: string@exchange-completer # Which crypto exchange to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX)
]: nothing -> record<latestTrade: record<t: string, x: string, p: float, s: float, c: list<string>, i: int, z: string, tks: string>, latestQuote: record<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float, c: list<string>, x: string, z: string>, minuteBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, dailyBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>, prevDailyBar: record<t: string, x: string, o: float, h: float, l: float, c: float, v: float, n: int, vw: float>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange" $exchange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/snapshot" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest XBBO for multiple crypto symbols
#
# GET /v1beta1/crypto/xbbos/latest
# operationId: getLatestXBBOForMultipleCryptoSymbols
export def "v1beta1-crypto-xbbos-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
]: nothing -> record<xbbos: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "exchanges" $exchanges "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/crypto/xbbos/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Latest XBBO for a single crypto symbol
#
# GET /v1beta1/crypto/{symbol}/xbbo/latest
# operationId: getLatestXBBOForCryptoSymbol
export def "v1beta1-crypto-xbbo-latest get" [
  symbol: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exchanges: string # A comma separated list of which crypto exchanges to pull the data from. Alpaca currently supports `ERSX`, `CBSE`, and `FTXU` (e.g. ERSX,CBSE)
]: nothing -> record<symbol: string, xbbo: record<t: string, ax: string, ap: float, as: float, bx: string, bp: float, bs: float>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchanges" $exchanges "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/crypto/($symbol)/xbbo/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of crypto spreads per exchange
#
# GET /v1beta1/crypto/meta/spreads
# operationId: getCryptoMetaSpreads
export def "v1beta1-crypto-meta-spreads get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<spreads: record> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1beta1/crypto/meta/spreads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# News API
#
# GET /v1beta1/news
# operationId: getNews
export def "v1beta1-news get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # Filter data equal to or after this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --end: string # Filter data equal to or before this time in RFC-3339 format. Fractions of a second are not accepted. (format: date-time, e.g. 2021-01-01T00:00:00Z)
  --symbols: string # The comma-separated list of crypto symbols to query for. Note, currently all crypto symbols must be appended with "USD", ie "BTCUSD,ETHUSD" would get both BTC and ETH (e.g. BTCUSD,ETHUSD)
  --limit: int # Number of data points to return. Must be in range 1-10000, defaults to 1000.
  --qp-sort: string@sort-completer # Sort articles by updated date. Options: DESC, ASC (e.g. DESC)
  --include-content: oneof<nothing, bool> # Boolean indicator to include content for news articles (if available)
  --exclude-contentless: oneof<nothing, bool> # Boolean indicator to exclude news articles that do not contain content 
  --page-token: string # Pagination token to continue from. The value to pass here is returned in specific requests when more data is available than the request limit allows.
]: nothing -> record<news: table<id: int, headline: string, author: string, created_at: string, updated_at: string, summary: string, content: string, url: string, images: list, symbols: list, source: string>, next_page_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_content" $include_content "scalar") (serialize-qp "exclude_contentless" $exclude_contentless "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1beta1/news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Top Market Movers by Market type
#
# GET /v1beta1/screener/{market_type}/movers
# operationId: getTopMoversByMarketType
export def "v1beta1-screener-movers get" [
  market_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --top: int # Number of top market movers to fetch (gainers and losers). Will return number top for each. By default 10 gainers and 10 losers. (default: 10)
]: nothing -> record<gainers: table<symbol: string, percent_change: float, change: float, price: float>, losers: table<symbol: string, percent_change: float, change: float, price: float>, market_type: string, last_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/screener/($market_type)/movers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Logo for symbol
#
# GET /v1beta1/logos/{crypto_or_stock_symbol}
# operationId: getLogoForSymbol
export def "v1beta1-logos get" [
  crypto_or_stock_symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeholder: oneof<nothing, bool> # If true then the api will generate a placeholder image if no logo was found. Defaults to true (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeholder" $placeholder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/logos/($crypto_or_stock_symbol)" $qp)
  let accept_val = "image/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of supported exchanges
#
# GET /v2/stocks/meta/exchanges
# operationId: getExchanges
export def "stocks-meta-exchanges get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/stocks/meta/exchanges")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of Conditions
#
# GET /v2/stocks/meta/conditions/{type}
# operationId: getConditions
export def "stocks-meta-conditions get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tape: string@tape-completer # What kind of conditions to retrieve, "A" and "B" return CTS, where "C" will give you UTP  (e.g. A)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tape" $tape "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/stocks/meta/conditions/($type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
