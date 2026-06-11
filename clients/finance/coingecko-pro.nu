# Auto-generated client for CoinGecko Pro API v3.0.0
# Source: https://raw.githubusercontent.com/coingecko/coingecko-api-oas/main/pro-api.json
# Auth: --token flag or $env.COINGECKO_PRO_API_TOKEN

const BASE_URL = "https://pro-api.coingecko.com/api/v3"
const DEFAULT_AUTH = "x-cg-pro-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COINGECKO_PRO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-cg-pro-api-key" => { {headers: {x-cg-pro-api-key: $token_val}, query: ""} }
    "query-x_cg_pro_api_key" => { {headers: {}, query: $"x_cg_pro_api_key=($token_val)"} }
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
def base-url-completer [] { ["https://pro-api.coingecko.com/api/v3"] }
def auth-scheme-completer [] { ["x-cg-pro-api-key" "query-x_cg_pro_api_key"] }

# Completers for enum parameters
def include-tokens-completer [] { ["all" "top"] }
def precision-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "2" "3" "4" "5" "6" "7" "8" "9" "full"] }
def duration-completer [] { ["14d" "1h" "1y" "24h" "30d" "60d" "7d"] }
def top-coins-completer [] { ["1000" "300" "500" "all"] }
def dex-pair-format-completer [] { ["contract_address" "symbol"] }
def order-completer [] { ["id_asc" "id_desc" "market_cap_asc" "market_cap_desc" "volume_asc" "volume_desc"] }
def locale-completer [] { ["ar" "bg" "cs" "da" "de" "el" "en" "es" "fi" "fr" "he" "hi" "hr" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "ro" "ru" "sk" "sl" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw"] }
def order-completer-1 [] { ["trust_score_asc" "trust_score_desc" "volume_asc" "volume_desc"] }
def interval-completer [] { ["5m" "daily" "hourly"] }
def days-completer [] { ["1" "14" "180" "30" "365" "7" "90" "max"] }
def interval-completer-1 [] { ["daily" "hourly"] }
def interval-completer-2 [] { ["daily"] }
def status-completer [] { ["active" "inactive"] }
def filter-completer [] { ["nft"] }
def order-completer-2 [] { ["market_cap_asc" "market_cap_change_24h_asc" "market_cap_change_24h_desc" "market_cap_desc" "name_asc" "name_desc"] }
def order-completer-3 [] { ["base_target" "market_cap_asc" "market_cap_desc" "trust_score_asc" "trust_score_desc" "volume_asc" "volume_desc"] }
def days-completer-1 [] { ["1" "14" "180" "30" "365" "7" "90"] }
def order-completer-4 [] { ["name_asc" "name_desc" "open_interest_btc_asc" "open_interest_btc_desc" "trade_volume_24h_btc_asc" "trade_volume_24h_btc_desc"] }
def include-tickers-completer [] { ["all" "unexpired"] }
def entity-type-completer [] { ["company" "government"] }
def order-completer-5 [] { ["total_holdings_usd_asc" "total_holdings_usd_desc"] }
def order-completer-6 [] { ["average_cost_asc" "average_cost_desc" "date_asc" "date_desc" "holding_net_change_asc" "holding_net_change_desc" "transaction_value_usd_asc" "transaction_value_usd_desc"] }
def order-completer-7 [] { ["floor_price_native_asc" "floor_price_native_desc" "h24_volume_native_asc" "h24_volume_native_desc" "h24_volume_usd_asc" "h24_volume_usd_desc" "market_cap_native_asc" "market_cap_native_desc" "market_cap_usd_asc" "market_cap_usd_desc"] }
def order-completer-8 [] { ["h24_volume_native_asc" "h24_volume_native_desc" "h24_volume_usd_asc" "h24_volume_usd_desc" "market_cap_usd_asc" "market_cap_usd_desc"] }
def language-completer [] { ["ar" "bg" "cs" "da" "de" "el" "en" "es" "fi" "fr" "he" "hi" "hr" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt-br" "ro" "ru" "sk" "sl" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw"] }
def type-completer [] { ["all" "guides" "news"] }
def duration-completer-1 [] { ["1h" "24h" "5m" "6h"] }
def sort-completer [] { ["h24_tx_count_desc" "h24_volume_usd_desc"] }
def sort-completer-1 [] { ["fdv_usd_asc" "fdv_usd_desc" "h1_price_change_percentage_asc" "h1_price_change_percentage_desc" "h1_trending" "h24_price_change_percentage_asc" "h24_price_change_percentage_desc" "h24_trending" "h24_tx_count_asc" "h24_tx_count_desc" "h24_volume_usd_asc" "h24_volume_usd_desc" "h6_price_change_percentage_asc" "h6_price_change_percentage_desc" "h6_trending" "m5_price_change_percentage_asc" "m5_price_change_percentage_desc" "m5_trending" "pool_created_at_desc" "price_asc" "price_desc" "reserve_in_usd_asc" "reserve_in_usd_desc"] }
def tx-count-duration-completer [] { ["1h" "24h" "5m" "6h"] }
def buys-duration-completer [] { ["1h" "24h" "5m" "6h"] }
def sells-duration-completer [] { ["1h" "24h" "5m" "6h"] }
def price-change-percentage-duration-completer [] { ["1h" "24h" "5m" "6h"] }
def sort-completer-2 [] { ["h24_tx_count_desc" "h24_volume_usd_desc" "h24_volume_usd_liquidity_desc"] }
def include-completer [] { ["top_pools"] }
def include-completer-1 [] { ["pool"] }
def include-completer-2 [] { ["network"] }
def sort-completer-3 [] { ["realized_pnl_usd_desc" "total_buy_usd_desc" "total_sell_usd_desc" "unrealized_pnl_usd_desc"] }
def days-completer-2 [] { ["30" "7" "max"] }
def currency-completer [] { ["token" "usd"] }
def sort-completer-4 [] { ["fdv_usd_desc" "h12_volume_percentage_desc" "h1_volume_percentage_desc" "h24_tx_count_desc" "h24_volume_usd_desc" "h6_volume_percentage_desc" "reserve_in_usd_desc"] }
def sort-completer-5 [] { ["h1_trending" "h24_price_change_percentage_desc" "h24_trending" "h24_tx_count_desc" "h24_volume_usd_desc" "h6_trending" "m5_trending" "pool_created_at_desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ping ping-server" } } | get name | first)
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

# API Server Status
#
# GET /ping
# operationId: ping-server
export def "ping ping-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gecko_says: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API Usage
#
# GET /key
# operationId: api-usage
export def "key api-usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<plan: string, rate_limit_request_per_minute: int, monthly_call_credit: int, current_total_monthly_calls: int, current_remaining_monthly_calls: int, api_key_rate_limit_request_per_minute: int, api_key_monthly_call_credit: int, api_key_current_total_monthly_calls: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Price by IDs, Symbols, or Names
#
# GET /simple/price
# operationId: simple-price
export def "simple-price simple-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currencies: string # Target currency of coins, comma-separated if querying more than 1 currency.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies) (default: usd)
  --ids: string # Coins' IDs, comma-separated if querying more than 1 coin.  *refers to [`/coins/list`](/reference/coins-list) (default: bitcoin)
  --names: string # Coins' names, comma-separated if querying more than 1 coin. (default: Bitcoin)
  --symbols: string # Coins' symbols, comma-separated if querying more than 1 coin. (default: btc)
  --include-tokens: string@include-tokens-completer # For `symbols` lookups, specify `all` to include all matching tokens.  Default `top` returns top-ranked tokens by market cap or volume.
  --include-market-cap: string@bool-completer # Include market capitalization.  Default: false
  --include-24hr-vol: string@bool-completer # Include 24-hour trading volume.  Default: false
  --include-24hr-change: string@bool-completer # Include 24-hour change percentage.  Default: false
  --include-last-updated-at: string@bool-completer # Include last updated price time as a UNIX timestamp.  Default: false
  --precision: string@precision-completer # Decimal places for currency price value
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currencies" $vs_currencies "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "names" $names "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "include_market_cap" $include_market_cap "scalar") (serialize-qp "include_24hr_vol" $include_24hr_vol "scalar") (serialize-qp "include_24hr_change" $include_24hr_change "scalar") (serialize-qp "include_last_updated_at" $include_last_updated_at "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/simple/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Queries
#
# GET /search
# operationId: search-data
export def "search search-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query
]: nothing -> record<coins: table<id: string, name: string, api_symbol: string, symbol: string, market_cap_rank: int, thumb: string, large: string>, exchanges: table<id: string, name: string, market_type: string, thumb: string, large: string>, icos: list<record>, categories: table<id: string, name: string>, nfts: table<id: string, name: string, symbol: string, thumb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Currencies List
#
# GET /simple/supported_vs_currencies
# operationId: simple-supported-currencies
export def "simple-supported-vs-currencies simple-supported-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simple/supported_vs_currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Price by Token Addresses
#
# GET /simple/token_price/{id}
# operationId: simple-token-price
export def "simple-token-price simple-token-price" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contract-addresses: string # Token contract addresses, comma-separated if querying more than 1 token (default: 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599)
  --vs-currencies: string # Target currency of coins, comma-separated if querying more than 1 currency.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies) (default: usd)
  --include-market-cap: string@bool-completer # Include market capitalization.  Default: false
  --include-24hr-vol: string@bool-completer # Include 24-hour trading volume.  Default: false
  --include-24hr-change: string@bool-completer # Include 24-hour change percentage.  Default: false
  --include-last-updated-at: string@bool-completer # Include last updated price time as a UNIX timestamp.  Default: false
  --precision: string@precision-completer # Decimal places for currency price value
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contract_addresses" $contract_addresses "scalar") (serialize-qp "vs_currencies" $vs_currencies "scalar") (serialize-qp "include_market_cap" $include_market_cap "scalar") (serialize-qp "include_24hr_vol" $include_24hr_vol "scalar") (serialize-qp "include_24hr_change" $include_24hr_change "scalar") (serialize-qp "include_last_updated_at" $include_last_updated_at "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/simple/token_price/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Gainers & Losers
#
# GET /coins/top_gainers_losers
# operationId: coins-top-gainers-losers
export def "coins-top-gainers-losers coins-top-gainers-losers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of coins.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies) (default: usd)
  --duration: string@duration-completer # Filter result by time range.  Default: `24h`
  --price-change-percentage: string # Include price change percentage timeframe, comma-separated if querying more than 1 timeframe.  Valid values: `1h`, `24h`, `7d`, `14d`, `30d`, `60d`, `200d`, `1y`
  --top-coins: string@top-coins-completer # Filter result by market cap ranking (top 300 to 1000) or all coins (including coins that do not have market cap).  Default: `1000`
]: nothing -> record<top_gainers: table<id: string, symbol: string, name: string, image: string, market_cap_rank: int, usd: float, usd_24h_vol: float, usd_24h_change: float, usd_1h_change: float, usd_7d_change: float, usd_14d_change: float, usd_30d_change: float, usd_60d_change: float, usd_200d_change: float, usd_1y_change: float>, top_losers: table<id: string, symbol: string, name: string, image: string, market_cap_rank: int, usd: float, usd_24h_vol: float, usd_24h_change: float, usd_1h_change: float, usd_7d_change: float, usd_14d_change: float, usd_30d_change: float, usd_60d_change: float, usd_200d_change: float, usd_1y_change: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "price_change_percentage" $price_change_percentage "scalar") (serialize-qp "top_coins" $top_coins "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coins/top_gainers_losers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Data by ID
#
# GET /coins/{id}
# operationId: coins-id
export def "coins coins-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --localization: string@bool-completer # Include all localized languages in the response.  Default: true
  --tickers: string@bool-completer # Include tickers data.  Default: true
  --market-data: string@bool-completer # Include market data.  Default: true
  --community-data: string@bool-completer # Include community data.  Default: true
  --developer-data: string@bool-completer # Include developer data.  Default: true
  --sparkline: string@bool-completer # Include sparkline 7-day data.  Default: false
  --include-categories-details: string@bool-completer # Include categories details.  Default: false
  --dex-pair-format: string@dex-pair-format-completer # Set to `symbol` to display DEX pair base and target as symbols.  Default: `contract_address`
]: nothing -> record<id: string, symbol: string, name: string, web_slug: string, asset_platform_id: string, platforms: record, detail_platforms: record, block_time_in_minutes: float, hashing_algorithm: string, categories: list<string>, categories_details: table<id: string, name: string>, preview_listing: bool, public_notice: string, additional_notices: list<string>, localization: record, description: record, links: record<homepage: list<string>, whitepaper: string, blockchain_site: list<string>, official_forum_url: list<string>, chat_url: list<string>, announcement_url: list<string>, snapshot_url: string, twitter_screen_name: string, facebook_username: string, bitcointalk_thread_identifier: int, telegram_channel_identifier: string, subreddit_url: string, repos_url: record<github: list, bitbucket: list>>, image: record<thumb: string, small: string, large: string>, country_origin: string, genesis_date: string, sentiment_votes_up_percentage: float, sentiment_votes_down_percentage: float, ico_data: record<ico_start_date: string, ico_end_date: string, short_desc: string, description: string, links: record, softcap_currency: string, hardcap_currency: string, total_raised_currency: string, softcap_amount: float, hardcap_amount: float, total_raised: float, quote_pre_sale_currency: string, base_pre_sale_amount: float, quote_pre_sale_amount: float, quote_public_sale_currency: string, base_public_sale_amount: float, quote_public_sale_amount: float, accepting_currencies: string, country_origin: string, pre_sale_start_date: string, pre_sale_end_date: string, whitelist_url: string, whitelist_start_date: string, whitelist_end_date: string, bounty_detail_url: string, amount_for_sale: float, kyc_required: bool, whitelist_available: bool, pre_sale_available: bool, pre_sale_ended: bool>, watchlist_portfolio_users: float, market_cap_rank: int, market_cap_rank_with_rehypothecated: int, market_data: record<current_price: record, total_value_locked: float, mcap_to_tvl_ratio: float, fdv_to_tvl_ratio: float, roi: record<times: float, currency: string, percentage: float>, ath: record, ath_change_percentage: record, ath_date: record, atl: record, atl_change_percentage: record, atl_date: record, market_cap: record, fully_diluted_valuation: record, market_cap_fdv_ratio: float, market_cap_rank: int, outstanding_token_value_usd: float, market_cap_rank_with_rehypothecated: int, total_volume: record, high_24h: record, low_24h: record, price_change_24h: float, price_change_percentage_24h: float, price_change_percentage_7d: float, price_change_percentage_14d: float, price_change_percentage_30d: float, price_change_percentage_60d: float, price_change_percentage_200d: float, price_change_percentage_1y: float, market_cap_change_24h: float, market_cap_change_percentage_24h: float, price_change_24h_in_currency: record, price_change_percentage_1h_in_currency: record, price_change_percentage_24h_in_currency: record, price_change_percentage_7d_in_currency: record, price_change_percentage_14d_in_currency: record, price_change_percentage_30d_in_currency: record, price_change_percentage_60d_in_currency: record, price_change_percentage_200d_in_currency: record, price_change_percentage_1y_in_currency: record, market_cap_change_24h_in_currency: record, market_cap_change_percentage_24h_in_currency: record, total_supply: float, max_supply: float, max_supply_infinite: bool, circulating_supply: float, outstanding_supply: float, last_updated: string, sparkline_7d: list<float>>, community_data: record<facebook_likes: float, reddit_average_posts_48h: float, reddit_average_comments_48h: float, reddit_subscribers: float, reddit_accounts_active_48h: float, telegram_channel_user_count: float>, developer_data: record<forks: float, stars: float, subscribers: float, total_issues: float, closed_issues: float, pull_requests_merged: float, pull_request_contributors: float, code_additions_deletions_4_weeks: record<additions: float, deletions: float>, commit_count_4_weeks: float, last_4_weeks_commit_activity_series: list<float>>, status_updates: table<description: string, category: string, created_at: string, user: string, user_title: string>, last_updated: string, tickers: table<base: string, target: string, market: record, last: float, volume: float, converted_last: record, converted_volume: record, trust_score: string, bid_ask_spread_percentage: float, timestamp: string, last_traded_at: string, last_fetch_at: string, is_anomaly: bool, is_stale: bool, trade_url: string, token_info_url: string, coin_id: string, target_coin_id: string, coin_mcap_usd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "localization" $localization "scalar") (serialize-qp "tickers" $tickers "scalar") (serialize-qp "market_data" $market_data "scalar") (serialize-qp "community_data" $community_data "scalar") (serialize-qp "developer_data" $developer_data "scalar") (serialize-qp "sparkline" $sparkline "scalar") (serialize-qp "include_categories_details" $include_categories_details "scalar") (serialize-qp "dex_pair_format" $dex_pair_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coins List with Market Data
#
# GET /coins/markets
# operationId: coins-markets
export def "coins-markets coins-markets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of coins and market data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies) (default: usd)
  --ids: string # Coins' IDs, comma-separated if querying more than 1 coin.  *refers to [`/coins/list`](/reference/coins-list) (default: bitcoin)
  --names: string # Coins' names, comma-separated if querying more than 1 coin. (default: Bitcoin)
  --symbols: string # Coins' symbols, comma-separated if querying more than 1 coin. (default: btc)
  --include-tokens: string@include-tokens-completer # For `symbols` lookups, specify `all` to include all matching tokens.  Default `top` returns top-ranked tokens by market cap or volume.
  --category: string # Filter based on coins' category.  *refers to [`/coins/categories/list`](/reference/coins-categories-list)
  --order: string@order-completer # Sort result by field.  Default: market_cap_desc
  --per-page: int # Total results per page.  Default: 100  Valid values: 1...250
  --page: int # Page through results.  Default: 1
  --sparkline: string@bool-completer # Include sparkline 7-day data.  Default: false
  --price-change-percentage: string # Include price change percentage timeframe, comma-separated if querying more than 1 timeframe.  Valid values: `1h`, `24h`, `7d`, `14d`, `30d`, `200d`, `1y`
  --locale: string@locale-completer # Language background.  Default: en
  --precision: string@precision-completer # Decimal places for currency price value
  --include-rehypothecated: string@bool-completer # Include rehypothecated tokens in results. When true, returns `market_cap_rank_with_rehypothecated` field.  Default: false
]: nothing -> table<id: string, symbol: string, name: string, image: string, current_price: float, market_cap: float, market_cap_rank: int, fully_diluted_valuation: float, total_volume: float, high_24h: float, low_24h: float, price_change_24h: float, price_change_percentage_24h: float, market_cap_change_24h: float, market_cap_change_percentage_24h: float, circulating_supply: float, total_supply: float, max_supply: float, ath: float, ath_change_percentage: float, ath_date: string, atl: float, atl_change_percentage: float, atl_date: string, roi: record<times: float, currency: string, percentage: float>, last_updated: string, market_cap_rank_with_rehypothecated: int, sparkline_in_7d: record<price: list>, price_change_percentage_1h_in_currency: float, price_change_percentage_24h_in_currency: float, price_change_percentage_7d_in_currency: float, price_change_percentage_14d_in_currency: float, price_change_percentage_30d_in_currency: float, price_change_percentage_200d_in_currency: float, price_change_percentage_1y_in_currency: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "ids" $ids "scalar") (serialize-qp "names" $names "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "include_tokens" $include_tokens "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sparkline" $sparkline "scalar") (serialize-qp "price_change_percentage" $price_change_percentage "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "include_rehypothecated" $include_rehypothecated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coins/markets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Tickers by ID
#
# GET /coins/{id}/tickers
# operationId: coins-id-tickers
export def "coins-tickers coins-id-tickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exchange-ids: string # Exchange ID.  *refers to [`/exchanges/list`](/reference/exchanges-list)
  --include-exchange-logo: string@bool-completer # Include exchange logo.  Default: false
  --page: int # Page through results
  --order: string@order-completer-1 # Sort the order of responses.  Default: trust_score_desc
  --depth: string@bool-completer # Include 2% orderbook depth, i.e. `cost_to_move_up_usd` and `cost_to_move_down_usd`.  Default: false
  --dex-pair-format: string@dex-pair-format-completer # Set to `symbol` to display DEX pair base and target as symbols.  Default: `contract_address`
]: nothing -> record<name: string, tickers: table<base: string, target: string, market: record, last: float, volume: float, cost_to_move_up_usd: float, cost_to_move_down_usd: float, converted_last: record, converted_volume: record, trust_score: string, bid_ask_spread_percentage: float, timestamp: string, last_traded_at: string, last_fetch_at: string, is_anomaly: bool, is_stale: bool, trade_url: string, token_info_url: string, coin_id: string, target_coin_id: string, coin_mcap_usd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exchange_ids" $exchange_ids "scalar") (serialize-qp "include_exchange_logo" $include_exchange_logo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "dex_pair_format" $dex_pair_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/tickers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Historical Data by ID
#
# GET /coins/{id}/history
# operationId: coins-id-history
export def "coins-history coins-id-history" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # The date of data snapshot.  Format: `YYYY-MM-DD` (default: 2025-12-30)
  --localization: string@bool-completer # Include all the localized languages in response.  Default: true
]: nothing -> record<id: string, symbol: string, name: string, localization: record, image: record<thumb: string, small: string>, market_data: record<current_price: record, market_cap: record, total_volume: record>, community_data: record<facebook_likes: float, reddit_average_posts_48h: float, reddit_average_comments_48h: float, reddit_subscribers: float, reddit_accounts_active_48h: float>, developer_data: record<forks: float, stars: float, subscribers: float, total_issues: float, closed_issues: float, pull_requests_merged: float, pull_request_contributors: float, code_additions_deletions_4_weeks: record<additions: float, deletions: float>, commit_count_4_weeks: float>, public_interest_stats: record<alexa_rank: float, bing_matches: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "localization" $localization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Historical Chart Data by ID
#
# GET /coins/{id}/market_chart
# operationId: coins-id-market-chart
export def "coins-market-chart coins-id-market-chart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of market data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --days: string # Data up to number of days ago.  You may use any integer or `max` for number of days. (default: 1)
  --interval: string@interval-completer # Data interval, leave empty for auto granularity.
  --precision: string@precision-completer # Decimal place for currency price value.
]: nothing -> record<prices: list<list<float>>, market_caps: list<list<float>>, total_volumes: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/market_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Historical Chart Data within Time Range by ID
#
# GET /coins/{id}/market_chart/range
# operationId: coins-id-market-chart-range
export def "coins-market-chart-range coins-id-market-chart-range" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of market data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --qp-from: string # Starting date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-01-01)
  --qp-to: string # Ending date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-31)
  --interval: string@interval-completer # Data interval, leave empty for auto granularity.
  --precision: string@precision-completer # Decimal place for currency price value.
]: nothing -> record<prices: list<list<float>>, market_caps: list<list<float>>, total_volumes: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/market_chart/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin OHLC Chart by ID
#
# GET /coins/{id}/ohlc
# operationId: coins-id-ohlc
export def "coins-ohlc coins-id-ohlc" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of price data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --days: string@days-completer # Data up to number of days ago. (default: 1)
  --interval: string@interval-completer-1 # Data interval, leave empty for auto granularity.
  --precision: string@precision-completer # Decimal place for currency price value.
]: nothing -> list<list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/ohlc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin OHLC Chart within Time Range by ID
#
# GET /coins/{id}/ohlc/range
# operationId: coins-id-ohlc-range
export def "coins-ohlc-range coins-id-ohlc-range" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of price data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --qp-from: string # Starting date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-01)
  --qp-to: string # Ending date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-31)
  --interval: string@interval-completer-1 # Data interval. (default: daily)
]: nothing -> list<list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/ohlc/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Data by Token Address
#
# GET /coins/{id}/contract/{contract_address}
# operationId: coins-contract-address
export def "coins-contract coins-contract-address" [
  id: string
  contract_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, symbol: string, name: string, web_slug: string, asset_platform_id: string, platforms: record, detail_platforms: record, block_time_in_minutes: float, hashing_algorithm: string, categories: list<string>, preview_listing: bool, public_notice: string, additional_notices: list<string>, localization: record, description: record, links: record<homepage: list<string>, whitepaper: string, blockchain_site: list<string>, official_forum_url: list<string>, chat_url: list<string>, announcement_url: list<string>, snapshot_url: string, twitter_screen_name: string, facebook_username: string, bitcointalk_thread_identifier: int, telegram_channel_identifier: string, subreddit_url: string, repos_url: record<github: list, bitbucket: list>>, image: record<thumb: string, small: string, large: string>, country_origin: string, genesis_date: string, contract_address: string, sentiment_votes_up_percentage: float, sentiment_votes_down_percentage: float, watchlist_portfolio_users: float, market_cap_rank: int, market_cap_rank_with_rehypothecated: int, market_data: record<current_price: record, total_value_locked: float, mcap_to_tvl_ratio: float, fdv_to_tvl_ratio: float, roi: record<times: float, currency: string, percentage: float>, ath: record, ath_change_percentage: record, ath_date: record, atl: record, atl_change_percentage: record, atl_date: record, market_cap: record, fully_diluted_valuation: record, market_cap_fdv_ratio: float, market_cap_rank: int, outstanding_token_value_usd: float, market_cap_rank_with_rehypothecated: int, total_volume: record, high_24h: record, low_24h: record, price_change_24h: float, price_change_percentage_24h: float, price_change_percentage_7d: float, price_change_percentage_14d: float, price_change_percentage_30d: float, price_change_percentage_60d: float, price_change_percentage_200d: float, price_change_percentage_1y: float, market_cap_change_24h: float, market_cap_change_percentage_24h: float, price_change_24h_in_currency: record, price_change_percentage_1h_in_currency: record, price_change_percentage_24h_in_currency: record, price_change_percentage_7d_in_currency: record, price_change_percentage_14d_in_currency: record, price_change_percentage_30d_in_currency: record, price_change_percentage_60d_in_currency: record, price_change_percentage_200d_in_currency: record, price_change_percentage_1y_in_currency: record, market_cap_change_24h_in_currency: record, market_cap_change_percentage_24h_in_currency: record, total_supply: float, max_supply: float, max_supply_infinite: bool, circulating_supply: float, outstanding_supply: float, last_updated: string, sparkline_7d: list<float>>, community_data: record<facebook_likes: float, reddit_average_posts_48h: float, reddit_average_comments_48h: float, reddit_subscribers: float, reddit_accounts_active_48h: float, telegram_channel_user_count: float>, developer_data: record<forks: float, stars: float, subscribers: float, total_issues: float, closed_issues: float, pull_requests_merged: float, pull_request_contributors: float, code_additions_deletions_4_weeks: record<additions: float, deletions: float>, commit_count_4_weeks: float, last_4_weeks_commit_activity_series: list<float>>, status_updates: table<description: string, category: string, created_at: string, user: string, user_title: string>, last_updated: string, tickers: table<base: string, target: string, market: record, last: float, volume: float, converted_last: record, converted_volume: record, trust_score: string, bid_ask_spread_percentage: float, timestamp: string, last_traded_at: string, last_fetch_at: string, is_anomaly: bool, is_stale: bool, trade_url: string, token_info_url: string, coin_id: string, target_coin_id: string, coin_mcap_usd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/coins/($id)/contract/($contract_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Historical Chart Data by Token Address
#
# GET /coins/{id}/contract/{contract_address}/market_chart
# operationId: contract-address-market-chart
export def "coins-contract-market-chart contract-address-market-chart" [
  id: string
  contract_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of market data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --days: string # Data up to number of days ago.  You may use any integer or `max` for number of days. (default: 1)
  --interval: string@interval-completer # Data interval, leave empty for auto granularity.
  --precision: string@precision-completer # Decimal place for currency price value.
]: nothing -> record<prices: list<list<float>>, market_caps: list<list<float>>, total_volumes: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/contract/($contract_address)/market_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coin Historical Chart Data within Time Range by Token Address
#
# GET /coins/{id}/contract/{contract_address}/market_chart/range
# operationId: contract-address-market-chart-range
export def "coins-contract-market-chart-range contract-address-market-chart-range" [
  id: string
  contract_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vs-currency: string # Target currency of market data.  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies). (default: usd)
  --qp-from: string # Starting date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-01-01)
  --qp-to: string # Ending date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-31)
  --interval: string@interval-completer # Data interval, leave empty for auto granularity.
  --precision: string@precision-completer # Decimal place for currency price value.
]: nothing -> record<prices: list<list<float>>, market_caps: list<list<float>>, total_volumes: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vs_currency" $vs_currency "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "precision" $precision "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/contract/($contract_address)/market_chart/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Circulating Supply Chart by ID
#
# GET /coins/{id}/circulating_supply_chart
# operationId: coins-id-circulating-supply-chart
export def "coins-circulating-supply-chart coins-id-circulating-supply-chart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Data up to number of days ago.  Valid values: any integer or `max`. (default: 1)
  --interval: string@interval-completer # Data interval.
]: nothing -> record<circulating_supply: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/circulating_supply_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Circulating Supply Chart within Time Range by ID
#
# GET /coins/{id}/circulating_supply_chart/range
# operationId: coins-id-circulating-supply-chart-range
export def "coins-circulating-supply-chart-range coins-id-circulating-supply-chart-range" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Starting date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-01-01)
  --qp-to: string # Ending date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-31)
]: nothing -> record<circulating_supply: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/circulating_supply_chart/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Total Supply Chart by ID
#
# GET /coins/{id}/total_supply_chart
# operationId: coins-id-total-supply-chart
export def "coins-total-supply-chart coins-id-total-supply-chart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Data up to number of days ago.  Valid values: any integer or `max`. (default: 1)
  --interval: string@interval-completer-2 # Data interval.
]: nothing -> record<total_supply: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/total_supply_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Total Supply Chart within Time Range by ID
#
# GET /coins/{id}/total_supply_chart/range
# operationId: coins-id-total-supply-chart-range
export def "coins-total-supply-chart-range coins-id-total-supply-chart-range" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Starting date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-01-01)
  --qp-to: string # Ending date in ISO date string (`YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`) or UNIX timestamp.  **Use ISO date string for best compatibility.** (default: 2025-12-31)
]: nothing -> record<total_supply: list<list<any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/coins/($id)/total_supply_chart/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recently Added Coins
#
# GET /coins/list/new
# operationId: coins-list-new
export def "coins-list-new coins-list-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, symbol: string, name: string, activated_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coins/list/new")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coins List
#
# GET /coins/list
# operationId: coins-list
export def "coins-list coins-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-platform: string@bool-completer # Include platform and token's contract addresses.  Default: false
  --status: string@status-completer # Filter by status of coins.  Default: active
]: nothing -> table<id: string, symbol: string, name: string, platforms: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_platform" $include_platform "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coins/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Asset Platforms List
#
# GET /asset_platforms
# operationId: asset-platforms-list
export def "asset-platforms asset-platforms-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string@filter-completer # Apply relevant filters to results.
]: nothing -> table<id: string, chain_identifier: float, name: string, shortname: string, native_coin_id: string, image: record<thumb: string, small: string, large: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/asset_platforms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Token Lists by Asset Platform ID
#
# GET /token_lists/{asset_platform_id}/all.json
# operationId: token-lists
export def "token-lists-alljson token-lists" [
  asset_platform_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, logoURI: string, keywords: list<string>, timestamp: string, tokens: table<chainId: float, address: string, name: string, symbol: string, decimals: float, logoURI: string>, version: record<major: float, minor: float, patch: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/token_lists/($asset_platform_id)/all.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coins Categories List
#
# GET /coins/categories/list
# operationId: coins-categories-list
export def "coins-categories-list coins-categories-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<category_id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coins/categories/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Coins Categories List with Market Data
#
# GET /coins/categories
# operationId: coins-categories
export def "coins-categories coins-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer-2 # Sort results by field.  Default: `market_cap_desc`
]: nothing -> table<id: string, name: string, market_cap: float, market_cap_change_24h: float, content: string, top_3_coins_id: list<string>, top_3_coins: list<string>, volume_24h: float, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coins/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchanges List with Data
#
# GET /exchanges
# operationId: exchanges
export def "exchanges exchanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: float # Total results per page.  Default: 100.  Valid values: 1...250
  --page: float # Page through results.  Default: 1
]: nothing -> table<id: string, name: string, year_established: float, country: string, description: string, url: string, image: string, has_trading_incentive: bool, trust_score: float, trust_score_rank: float, trade_volume_24h_btc: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exchanges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchanges List
#
# GET /exchanges/list
# operationId: exchanges-list
export def "exchanges-list exchanges-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Filter by status of exchanges.  Default: `active`
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/exchanges/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Data by ID
#
# GET /exchanges/{id}
# operationId: exchanges-id
export def "exchanges exchanges-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dex-pair-format: string@dex-pair-format-completer # Set to `symbol` to display DEX pair base and target as symbols.  Default: `contract_address`
]: nothing -> record<name: string, year_established: float, country: string, description: string, url: string, image: string, facebook_url: string, reddit_url: string, telegram_url: string, slack_url: string, other_url_1: string, other_url_2: string, twitter_handle: string, has_trading_incentive: bool, centralized: bool, public_notice: string, alert_notice: string, trust_score: float, trust_score_rank: float, coins: float, pairs: float, trade_volume_24h_btc: float, tickers: table<base: string, target: string, market: record, last: float, volume: float, converted_last: record, converted_volume: record, trust_score: string, bid_ask_spread_percentage: float, timestamp: string, last_traded_at: string, last_fetch_at: string, is_anomaly: bool, is_stale: bool, trade_url: string, token_info_url: string, coin_id: string, target_coin_id: string, coin_mcap_usd: float>, status_updates: table<description: string, category: string, created_at: string, user: string, user_title: string, pin: bool, project: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dex_pair_format" $dex_pair_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exchanges/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Tickers by ID
#
# GET /exchanges/{id}/tickers
# operationId: exchanges-id-tickers
export def "exchanges-tickers exchanges-id-tickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin-ids: string # Filter tickers by coin IDs, comma-separated if querying more than 1 coin.  *refers to [`/coins/list`](/reference/coins-list).
  --include-exchange-logo: string@bool-completer # Include exchange logo.  Default: false
  --page: float # Page through results.
  --depth: string@bool-completer # Include 2% orderbook depth (cost_to_move_up_usd and cost_to_move_down_usd).  Default: false
  --order: string@order-completer-3 # Sort the order of responses.  Default: `trust_score_desc`
  --dex-pair-format: string@dex-pair-format-completer # Set to `symbol` to display DEX pair base and target as symbols.  Default: `contract_address`
]: nothing -> record<name: string, tickers: table<base: string, target: string, market: record, last: float, volume: float, cost_to_move_up_usd: float, cost_to_move_down_usd: float, converted_last: record, converted_volume: record, trust_score: string, bid_ask_spread_percentage: float, timestamp: string, last_traded_at: string, last_fetch_at: string, is_anomaly: bool, is_stale: bool, trade_url: string, token_info_url: string, coin_id: string, target_coin_id: string, coin_mcap_usd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin_ids" $coin_ids "scalar") (serialize-qp "include_exchange_logo" $include_exchange_logo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "dex_pair_format" $dex_pair_format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exchanges/($id)/tickers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Volume Chart by ID
#
# GET /exchanges/{id}/volume_chart
# operationId: exchanges-id-volume-chart
export def "exchanges-volume-chart exchanges-id-volume-chart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string@days-completer-1 # Data up to number of days ago. (default: 1)
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exchanges/($id)/volume_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Volume Chart within Time Range by ID
#
# GET /exchanges/{id}/volume_chart/range
# operationId: exchanges-id-volume-chart-range
export def "exchanges-volume-chart-range exchanges-id-volume-chart-range" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: float # Starting date in UNIX timestamp. (default: 1767196800)
  --qp-to: float # Ending date in UNIX timestamp. (default: 1769702400)
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exchanges/($id)/volume_chart/range" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Derivatives Tickers List
#
# GET /derivatives
# operationId: derivatives-tickers
export def "derivatives derivatives-tickers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<market: string, symbol: string, index_id: string, price: string, price_percentage_change_24h: float, contract_type: string, index: float, basis: float, spread: float, funding_rate: float, open_interest: float, volume_24h: float, last_traded_at: float, expired_at: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/derivatives")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Derivatives Exchanges List with Data
#
# GET /derivatives/exchanges
# operationId: derivatives-exchanges
export def "derivatives-exchanges derivatives-exchanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer-4 # Sort order of responses.  Default: `open_interest_btc_desc`
  --per-page: int # Total results per page.
  --page: int # Page through results.  Default value: 1
]: nothing -> table<name: string, id: string, open_interest_btc: float, trade_volume_24h_btc: string, number_of_perpetual_pairs: int, number_of_futures_pairs: int, image: string, year_established: int, country: string, description: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derivatives/exchanges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Derivatives Exchange Data by ID
#
# GET /derivatives/exchanges/{id}
# operationId: derivatives-exchanges-id
export def "derivatives-exchanges derivatives-exchanges-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-tickers: string@include-tickers-completer # Include tickers data.  Default: tickers data is not included.
]: nothing -> record<name: string, open_interest_btc: float, trade_volume_24h_btc: string, number_of_perpetual_pairs: int, number_of_futures_pairs: int, image: string, year_established: int, country: string, description: string, url: string, tickers: table<symbol: string, base: string, target: string, coin_id: string, target_coin_id: string, trade_url: string, contract_type: string, last: float, h24_percentage_change: float, index: float, index_basis_percentage: float, bid_ask_spread: float, funding_rate: float, open_interest_usd: float, h24_volume: float, converted_volume: record, converted_last: record, last_traded: float, expired_at: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_tickers" $include_tickers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivatives/exchanges/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Derivatives Exchanges List
#
# GET /derivatives/exchanges/list
# operationId: derivatives-exchanges-list
export def "derivatives-exchanges-list derivatives-exchanges-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/derivatives/exchanges/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Entities List
#
# GET /entities/list
# operationId: entities-list
export def "entities-list entities-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entity-type: string@entity-type-completer # Filter by entity type.
  --per-page: int # Total results per page.  Default value: 100  Valid values: 1...250
  --page: int # Page through results.  Default value: 1
]: nothing -> table<id: string, symbol: string, name: string, country: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity_type" $entity_type "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entities/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Treasury Holdings by Coin ID
#
# GET /{entity}/public_treasury/{coin_id}
# operationId: companies-public-treasury
export def "public-treasury companies-public-treasury" [
  entity: string
  coin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Total results per page.  Default value: 250  Valid values: 1...250
  --page: int # Page through results.  Default value: 1
  --order: string@order-completer-5 # Sort order for results.  Default: `total_holdings_usd_desc`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($entity)/public_treasury/($coin_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Treasury Holdings by Entity ID
#
# GET /public_treasury/{entity_id}
# operationId: public-treasury-entity
export def "public-treasury public-treasury-entity" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --holding-amount-change: string # Include holding amount change for specified timeframes, comma-separated if querying more than 1 timeframe.  Valid values: `7d`, `14d`, `30d`, `90d`, `1y`, `ytd`
  --holding-change-percentage: string # Include holding change percentage for specified timeframes, comma-separated if querying more than 1 timeframe.  Valid values: `7d`, `14d`, `30d`, `90d`, `1y`, `ytd`
]: nothing -> record<name: string, id: string, type: string, symbol: string, country: string, website_url: string, twitter_screen_name: string, total_treasury_value_usd: float, unrealized_pnl: float, m_nav: float, total_asset_value_per_share_usd: float, holdings: table<coin_id: string, amount: float, percentage_of_total_supply: float, amount_per_share: float, entity_value_usd_percentage: float, current_value_usd: float, total_entry_value_usd: float, average_entry_value_usd: float, unrealized_pnl: float, holding_amount_change: record, holding_change_percentage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "holding_amount_change" $holding_amount_change "scalar") (serialize-qp "holding_change_percentage" $holding_change_percentage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public_treasury/($entity_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Treasury Holdings Historical Chart Data by ID
#
# GET /public_treasury/{entity_id}/{coin_id}/holding_chart
# operationId: public-treasury-entity-chart
export def "public-treasury-holding-chart public-treasury-entity-chart" [
  entity_id: string
  coin_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Data up to number of days ago.  Valid values: `7`, `14`, `30`, `90`, `180`, `365`, `730`, `max` (default: 365)
  --include-empty-intervals: string@bool-completer # Include empty intervals with no transaction data.  Default: `false`
]: nothing -> record<holdings: list<list<float>>, holding_value_in_usd: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "include_empty_intervals" $include_empty_intervals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public_treasury/($entity_id)/($coin_id)/holding_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Treasury Transaction History by Entity ID
#
# GET /public_treasury/{entity_id}/transaction_history
# operationId: public-treasury-transaction-history
export def "public-treasury-transaction-history public-treasury-transaction-history" [
  entity_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Total results per page.  Default value: 100  Valid values: 1...250
  --page: int # Page through results.  Default value: 1
  --order: string@order-completer-6 # Sort order of transactions.  Default: `date_desc`
  --coin-ids: string # Filter transactions by coin IDs, comma-separated if querying more than 1 coin.  *refers to [`/coins/list`](/reference/coins-list).
]: nothing -> record<transactions: table<date: float, source_url: string, coin_id: string, type: string, holding_net_change: float, transaction_value_usd: float, holding_balance: float, average_entry_value_usd: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "coin_ids" $coin_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public_treasury/($entity_id)/transaction_history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs List
#
# GET /nfts/list
# operationId: nfts-list
export def "nfts-list nfts-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: string@order-completer-7 # Sort order of responses.
  --per-page: int # Total results per page.  Valid values: 1...250
  --page: int # Page through results.
]: nothing -> table<id: string, contract_address: string, name: string, asset_platform_id: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order" $order "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nfts/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs Collection Data by ID
#
# GET /nfts/{id}
# operationId: nfts-id
export def "nfts nfts-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, web_slug: string, contract_address: string, asset_platform_id: string, name: string, symbol: string, image: record<small: string, small_2x: string>, banner_image: string, description: string, native_currency: string, native_currency_symbol: string, market_cap_rank: int, floor_price: record<native_currency: float, usd: float>, market_cap: record<native_currency: float, usd: float>, volume_24h: record<native_currency: float, usd: float>, floor_price_in_usd_24h_percentage_change: float, floor_price_24h_percentage_change: record<usd: float, native_currency: float>, market_cap_24h_percentage_change: record<usd: float, native_currency: float>, volume_24h_percentage_change: record<usd: float, native_currency: float>, number_of_unique_addresses: float, number_of_unique_addresses_24h_percentage_change: float, volume_in_usd_24h_percentage_change: float, total_supply: float, one_day_sales: float, one_day_sales_24h_percentage_change: float, one_day_average_sale_price: float, one_day_average_sale_price_24h_percentage_change: float, links: record<homepage: string, twitter: string, discord: string>, floor_price_7d_percentage_change: record<usd: float, native_currency: float>, floor_price_14d_percentage_change: record<usd: float, native_currency: float>, floor_price_30d_percentage_change: record<usd: float, native_currency: float>, floor_price_60d_percentage_change: record<usd: float, native_currency: float>, floor_price_1y_percentage_change: record<usd: float, native_currency: float>, explorers: table<name: string, link: string>, user_favorites_count: int, ath: record<native_currency: float, usd: float>, ath_change_percentage: record<native_currency: float, usd: float>, ath_date: record<native_currency: string, usd: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nfts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs Collection Data by Contract Address
#
# GET /nfts/{asset_platform_id}/contract/{contract_address}
# operationId: nfts-contract-address
export def "nfts-contract nfts-contract-address" [
  asset_platform_id: string
  contract_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, web_slug: string, contract_address: string, asset_platform_id: string, name: string, symbol: string, image: record<small: string, small_2x: string>, banner_image: string, description: string, native_currency: string, native_currency_symbol: string, market_cap_rank: int, floor_price: record<native_currency: float, usd: float>, market_cap: record<native_currency: float, usd: float>, volume_24h: record<native_currency: float, usd: float>, floor_price_in_usd_24h_percentage_change: float, floor_price_24h_percentage_change: record<usd: float, native_currency: float>, market_cap_24h_percentage_change: record<usd: float, native_currency: float>, volume_24h_percentage_change: record<usd: float, native_currency: float>, number_of_unique_addresses: float, number_of_unique_addresses_24h_percentage_change: float, volume_in_usd_24h_percentage_change: float, total_supply: float, one_day_sales: float, one_day_sales_24h_percentage_change: float, one_day_average_sale_price: float, one_day_average_sale_price_24h_percentage_change: float, links: record<homepage: string, twitter: string, discord: string>, floor_price_7d_percentage_change: record<usd: float, native_currency: float>, floor_price_14d_percentage_change: record<usd: float, native_currency: float>, floor_price_30d_percentage_change: record<usd: float, native_currency: float>, floor_price_60d_percentage_change: record<usd: float, native_currency: float>, floor_price_1y_percentage_change: record<usd: float, native_currency: float>, explorers: table<name: string, link: string>, user_favorites_count: int, ath: record<native_currency: float, usd: float>, ath_change_percentage: record<native_currency: float, usd: float>, ath_date: record<native_currency: string, usd: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nfts/($asset_platform_id)/contract/($contract_address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs List with Market Data
#
# GET /nfts/markets
# operationId: nfts-markets
export def "nfts-markets nfts-markets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset-platform-id: string # Filter result by asset platform (blockchain network).  *refers to [`/asset_platforms`](/reference/asset-platforms-list) filter=`nft`.
  --order: string@order-completer-8 # Sort results by field.  Default: `market_cap_usd_desc`
  --per-page: int # Total results per page.  Default value: 100  Valid values: 1...250
  --page: int # Page through results.  Default value: 1
]: nothing -> table<id: string, contract_address: string, asset_platform_id: string, name: string, symbol: string, image: record<small: string, small_2x: string>, description: string, native_currency: string, native_currency_symbol: string, floor_price: record<native_currency: float, usd: float>, market_cap: record<native_currency: float, usd: float>, volume_24h: record<native_currency: float, usd: float>, floor_price_in_usd_24h_percentage_change: float, floor_price_24h_percentage_change: record<usd: float, native_currency: float>, market_cap_24h_percentage_change: record<usd: float, native_currency: float>, volume_24h_percentage_change: record<usd: float, native_currency: float>, number_of_unique_addresses: float, number_of_unique_addresses_24h_percentage_change: float, volume_in_usd_24h_percentage_change: float, total_supply: float, one_day_sales: float, one_day_sales_24h_percentage_change: float, one_day_average_sale_price: float, one_day_average_sale_price_24h_percentage_change: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_platform_id" $asset_platform_id "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nfts/markets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs Collection Historical Chart Data by ID
#
# GET /nfts/{id}/market_chart
# operationId: nfts-id-market-chart
export def "nfts-market-chart nfts-id-market-chart" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Data up to number of days ago.  Valid values: any integer or `max` (default: 1)
]: nothing -> record<floor_price_usd: list<list<float>>, floor_price_native: list<list<float>>, h24_volume_usd: list<list<float>>, h24_volume_native: list<list<float>>, market_cap_usd: list<list<float>>, market_cap_native: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nfts/($id)/market_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs Collection Historical Chart Data by Contract Address
#
# GET /nfts/{asset_platform_id}/contract/{contract_address}/market_chart
# operationId: nfts-contract-address-market-chart
export def "nfts-contract-market-chart nfts-contract-address-market-chart" [
  asset_platform_id: string
  contract_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string # Data up to number of days ago.  Valid values: any integer or `max` (default: 1)
]: nothing -> record<floor_price_usd: list<list<float>>, floor_price_native: list<list<float>>, h24_volume_usd: list<list<float>>, h24_volume_native: list<list<float>>, market_cap_usd: list<list<float>>, market_cap_native: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/nfts/($asset_platform_id)/contract/($contract_address)/market_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# NFTs Collection Tickers by ID
#
# GET /nfts/{id}/tickers
# operationId: nfts-id-tickers
export def "nfts-tickers nfts-id-tickers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<tickers: table<floor_price_in_native_currency: float, h24_volume_in_native_currency: float, native_currency: string, native_currency_symbol: string, updated_at: string, nft_marketplace_id: string, name: string, image: string, nft_collection_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nfts/($id)/tickers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BTC-to-Currency Exchange Rates
#
# GET /exchange_rates
# operationId: exchange-rates
export def "exchange-rates exchange-rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rates: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exchange_rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trending Search List
#
# GET /search/trending
# operationId: trending-search
export def "search-trending trending-search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-max: string # Show max number of results available for the given type.  Available values: `coins`, `nfts`, `categories`  e.g. `coins` or `coins,nfts,categories`
]: nothing -> record<coins: table<item: record>, nfts: table<id: string, name: string, symbol: string, thumb: string, nft_contract_id: int, native_currency_symbol: string, floor_price_in_native_currency: float, floor_price_24h_percentage_change: float, data: record>, categories: table<id: int, name: string, top_3_coins_images: list, market_cap_1h_change: float, slug: string, coins_count: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_max" $show_max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto News
#
# GET /news
# operationId: news
export def "news news" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page through results.  Default value: 1  Valid values: 1...20
  --per-page: int # Total results per page.  Default value: 10  Valid values: 1...20
  --coin-id: string # Filter news by coin ID.  *refers to [`/coins/list`](/reference/coins-list).
  --language: string@language-completer # Filter news by language.  Default: `en`
  --type: string@type-completer # Filter news by type.  Default: `all`  Note: `guides` filter is only applicable if `coin_id` is specified and valid.
]: nothing -> table<title: string, url: string, image: string, author: string, posted_at: string, type: string, source_name: string, related_coin_ids: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "coin_id" $coin_id "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Global Market Data
#
# GET /global
# operationId: crypto-global
export def "global crypto-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<active_cryptocurrencies: int, upcoming_icos: int, ongoing_icos: int, ended_icos: int, markets: int, total_market_cap: record, total_volume: record, market_cap_percentage: record, market_cap_change_percentage_24h_usd: float, volume_change_percentage_24h_usd: float, updated_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/global")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Global DeFi Market Data
#
# GET /global/decentralized_finance_defi
# operationId: global-defi
export def "global-decentralized-finance-defi global-defi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<defi_market_cap: string, eth_market_cap: string, defi_to_eth_ratio: string, trading_volume_24h: string, defi_dominance: string, top_coin_name: string, top_coin_defi_dominance: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/global/decentralized_finance_defi")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Global Market Cap Chart Data
#
# GET /global/market_cap_chart
# operationId: global-market-cap-chart
export def "global-market-cap-chart global-market-cap-chart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string@days-completer # Data up to number of days ago. (default: 1)
  --vs-currency: string # Target currency of market cap.  Default: `usd`  *refers to [`/simple/supported_vs_currencies`](/reference/simple-supported-currencies).
]: nothing -> record<market_cap_chart: record<market_cap: list<list>, volume: list<list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "vs_currency" $vs_currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/global/market_cap_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Specific Pool Data by Pool Address
#
# GET /onchain/networks/{network}/pools/{address}
# operationId: pool-address
export def "onchain-networks-pools pool-address" [
  network: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --include-volume-breakdown: string@bool-completer # Include volume breakdown.  Default: `false`
  --include-composition: string@bool-completer # Include pool composition.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<base_token_price_usd: string, base_token_price_native_currency: string, base_token_balance: string, base_token_liquidity_usd: string, quote_token_price_usd: string, quote_token_price_native_currency: string, quote_token_balance: string, quote_token_liquidity_usd: string, base_token_price_quote_token: string, quote_token_price_base_token: string, address: string, name: string, pool_name: string, pool_fee_percentage: string, pool_created_at: string, fdv_usd: string, market_cap_usd: string, price_change_percentage: record, transactions: record, volume_usd: record, net_buy_volume_usd: record, buy_volume_usd: record, sell_volume_usd: record, reserve_in_usd: string, locked_liquidity_percentage: string>, relationships: record<base_token: record, quote_token: record, dex: record>>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_volume_breakdown" $include_volume_breakdown "scalar") (serialize-qp "include_composition" $include_composition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools/($address)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trending Pools List
#
# GET /onchain/networks/trending_pools
# operationId: trending-pools-list
export def "onchain-networks-trending-pools trending-pools-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`, `network`
  --page: int # Page through results.  Default value: 1
  --duration: string@duration-completer-1 # Duration to sort trending list by.  Default: `24h`
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/networks/trending_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trending Pools by Network
#
# GET /onchain/networks/{network}/trending_pools
# operationId: trending-pools-network
export def "onchain-networks-trending-pools trending-pools-network" [
  network: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --page: int # Page through results.  Default value: 1
  --duration: string@duration-completer-1 # Duration to sort trending list by.  Default: `24h`
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/trending_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Pools by Network
#
# GET /onchain/networks/{network}/pools
# operationId: top-pools-network
export def "onchain-networks-pools top-pools-network" [
  network: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer # Sort the pools by field.  Default: `h24_tx_count_desc`
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Pools by DEX
#
# GET /onchain/networks/{network}/dexes/{dex}/pools
# operationId: top-pools-dex
export def "onchain-networks-dexes-pools top-pools-dex" [
  network: string
  dex: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer # Sort the pools by field.  Default: `h24_tx_count_desc`
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/dexes/($dex)/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Megafilter for Pools
#
# GET /onchain/pools/megafilter
# operationId: pools-megafilter
export def "onchain-pools-megafilter pools-megafilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --networks: string # Filter pools by networks, comma-separated if more than one.  *refers to [`/onchain/networks`](/reference/networks-list).
  --dexes: string # Filter pools by DEXes, comma-separated if more than one.  *refers to [`/onchain/networks/{network}/dexes`](/reference/dexes-list).
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`, `network`
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer-1 # Sort the pools by field.  Default: `h6_trending`
  --fdv-usd-min: float # Minimum fully diluted value in USD.
  --fdv-usd-max: float # Maximum fully diluted value in USD.
  --reserve-in-usd-min: float # Minimum reserve in USD.
  --reserve-in-usd-max: float # Maximum reserve in USD.
  --h24-volume-usd-min: float # Minimum 24hr volume in USD.
  --h24-volume-usd-max: float # Maximum 24hr volume in USD.
  --pool-created-hour-min: float # Minimum pool age in hours.
  --pool-created-hour-max: float # Maximum pool age in hours.
  --tx-count-min: int # Minimum transaction count.
  --tx-count-max: int # Maximum transaction count.
  --tx-count-duration: string@tx-count-duration-completer # Duration for transaction count metric.  Default: `24h`
  --buys-min: int # Minimum number of buy transactions.
  --buys-max: int # Maximum number of buy transactions.
  --buys-duration: string@buys-duration-completer # Duration for buy transactions metric.  Default: `24h`
  --sells-min: int # Minimum number of sell transactions.
  --sells-max: int # Maximum number of sell transactions.
  --sells-duration: string@sells-duration-completer # Duration for sell transactions metric.  Default: `24h`
  --price-change-percentage-min: float # Minimum price change percentage.
  --price-change-percentage-max: float # Maximum price change percentage.
  --price-change-percentage-duration: string@price-change-percentage-duration-completer # Duration for price change percentage metric.  Default: `24h`
  --buy-tax-percentage-min: float # Minimum buy tax percentage.
  --buy-tax-percentage-max: float # Maximum buy tax percentage.
  --sell-tax-percentage-min: float # Minimum sell tax percentage.
  --sell-tax-percentage-max: float # Maximum sell tax percentage.
  --checks: string # Filter options for various checks, comma-separated if more than one.  Available values: `no_honeypot`, `good_gt_score`, `on_coingecko`, `has_social`
  --include-unknown-honeypot-tokens: string@bool-completer # When `checks` includes `no_honeypot`, set to `true` to also include unknown honeypot tokens.  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "networks" $networks "scalar") (serialize-qp "dexes" $dexes "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fdv_usd_min" $fdv_usd_min "scalar") (serialize-qp "fdv_usd_max" $fdv_usd_max "scalar") (serialize-qp "reserve_in_usd_min" $reserve_in_usd_min "scalar") (serialize-qp "reserve_in_usd_max" $reserve_in_usd_max "scalar") (serialize-qp "h24_volume_usd_min" $h24_volume_usd_min "scalar") (serialize-qp "h24_volume_usd_max" $h24_volume_usd_max "scalar") (serialize-qp "pool_created_hour_min" $pool_created_hour_min "scalar") (serialize-qp "pool_created_hour_max" $pool_created_hour_max "scalar") (serialize-qp "tx_count_min" $tx_count_min "scalar") (serialize-qp "tx_count_max" $tx_count_max "scalar") (serialize-qp "tx_count_duration" $tx_count_duration "scalar") (serialize-qp "buys_min" $buys_min "scalar") (serialize-qp "buys_max" $buys_max "scalar") (serialize-qp "buys_duration" $buys_duration "scalar") (serialize-qp "sells_min" $sells_min "scalar") (serialize-qp "sells_max" $sells_max "scalar") (serialize-qp "sells_duration" $sells_duration "scalar") (serialize-qp "price_change_percentage_min" $price_change_percentage_min "scalar") (serialize-qp "price_change_percentage_max" $price_change_percentage_max "scalar") (serialize-qp "price_change_percentage_duration" $price_change_percentage_duration "scalar") (serialize-qp "buy_tax_percentage_min" $buy_tax_percentage_min "scalar") (serialize-qp "buy_tax_percentage_max" $buy_tax_percentage_max "scalar") (serialize-qp "sell_tax_percentage_min" $sell_tax_percentage_min "scalar") (serialize-qp "sell_tax_percentage_max" $sell_tax_percentage_max "scalar") (serialize-qp "checks" $checks "scalar") (serialize-qp "include_unknown_honeypot_tokens" $include_unknown_honeypot_tokens "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/pools/megafilter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trending Search Pools
#
# GET /onchain/pools/trending_search
# operationId: trending-search-pools
export def "onchain-pools-trending-search trending-search-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`, `network`
  --pools: int # Number of pools to return, maximum 10.  Default value: 4
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "pools" $pools "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/pools/trending_search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Pools by Token Address
#
# GET /onchain/networks/{network}/tokens/{token_address}/pools
# operationId: top-pools-contract-address
export def "onchain-networks-tokens-pools top-pools-contract-address" [
  network: string
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --include-inactive-source: string@bool-completer # Include tokens from inactive pools using the most recent swap.  Default: `false`
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer-2 # Sort the pools by field.  Default: `h24_volume_usd_liquidity_desc`
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_inactive_source" $include_inactive_source "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($token_address)/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Token Data by Token Address
#
# GET /onchain/networks/{network}/tokens/{address}
# operationId: token-data-contract-address
export def "onchain-networks-tokens token-data-contract-address" [
  network: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer # Attributes to include.
  --include-composition: string@bool-completer # Include pool composition.  Default: `false`
  --include-inactive-source: string@bool-completer # Include token data from inactive pools using the most recent swap.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<address: string, name: string, symbol: string, decimals: int, image_url: string, coingecko_coin_id: string, total_supply: string, normalized_total_supply: string, price_usd: string, fdv_usd: string, total_reserve_in_usd: string, volume_usd: record, market_cap_usd: string, last_trade_timestamp: string, launchpad_details: record>, relationships: record<top_pools: record>>, included: table<id: string, type: string, attributes: record, relationships: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_composition" $include_composition "scalar") (serialize-qp "include_inactive_source" $include_inactive_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($address)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tokens Data by Token Addresses
#
# GET /onchain/networks/{network}/tokens/multi/{addresses}
# operationId: tokens-data-contract-addresses
export def "onchain-networks-tokens-multi tokens-data-contract-addresses" [
  network: string
  addresses: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer # Attributes to include.
  --include-composition: string@bool-completer # Include pool composition.  Default: `false`
  --include-inactive-source: string@bool-completer # Include tokens from inactive pools using the most recent swap.  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record, relationships: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_composition" $include_composition "scalar") (serialize-qp "include_inactive_source" $include_inactive_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/multi/($addresses)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Token Info by Token Address
#
# GET /onchain/networks/{network}/tokens/{address}/info
# operationId: token-info-contract-address
export def "onchain-networks-tokens-info token-info-contract-address" [
  network: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, type: string, attributes: record<address: string, name: string, symbol: string, decimals: int, image_url: string, image: record, coingecko_coin_id: string, websites: list, discord_url: string, farcaster_url: string, zora_url: string, telegram_handle: string, twitter_handle: string, description: string, gt_score: float, gt_score_details: record, gt_verified: bool, categories: list, gt_category_ids: list, holders: record, mint_authority: string, freeze_authority: string, is_honeypot: any>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($address)/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pool Tokens Info by Pool Address
#
# GET /onchain/networks/{network}/pools/{pool_address}/info
# operationId: pool-token-info-contract-address
export def "onchain-networks-pools-info pool-token-info-contract-address" [
  network: string
  pool_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-1 # Attributes to include.
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools/($pool_address)/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Most Recently Updated Tokens List
#
# GET /onchain/tokens/info_recently_updated
# operationId: tokens-info-recent-updated
export def "onchain-tokens-info-recently-updated tokens-info-recent-updated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string@include-completer-2 # Attributes for related resources to include.
  --network: string # Filter tokens by provided network.  *refers to [`/onchain/networks`](/reference/networks-list).
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "network" $network "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/tokens/info_recently_updated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Token Traders by Token Address
#
# GET /onchain/networks/{network_id}/tokens/{token_address}/top_traders
# operationId: top-token-traders-token-address
export def "onchain-networks-tokens-top-traders top-token-traders-token-address" [
  network_id: string
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --traders: string # Number of top token traders to return, any integer or `max`.  Default value: 10
  --qp-sort: string@sort-completer-3 # Sort the traders by field.  Default: `realized_pnl_usd_desc`
  --include-address-label: string@bool-completer # Include address label data.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<traders: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "traders" $traders "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_address_label" $include_address_label "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network_id)/tokens/($token_address)/top_traders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top Token Holders by Token Address
#
# GET /onchain/networks/{network}/tokens/{address}/top_holders
# operationId: top-token-holders-token-address
export def "onchain-networks-tokens-top-holders top-token-holders-token-address" [
  network: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --holders: string # Number of top token holders to return, any integer or `max`.  Default value: 10
  --include-pnl-details: string@bool-completer # Include PnL details for token holders.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<last_updated_at: string, holders: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "holders" $holders "scalar") (serialize-qp "include_pnl_details" $include_pnl_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($address)/top_holders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Historical Token Holders Chart by Token Address
#
# GET /onchain/networks/{network}/tokens/{token_address}/holders_chart
# operationId: token-holders-chart-token-address
export def "onchain-networks-tokens-holders-chart token-holders-chart-token-address" [
  network: string
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: string@days-completer-2 # Number of days to return the historical token holders chart.  Default value: 7
]: nothing -> record<data: record<id: string, type: string, attributes: record<token_holders_list: list>>, meta: record<token: record<name: string, symbol: string, coingecko_coin_id: string, address: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($token_address)/holders_chart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pool OHLCV Chart by Pool Address
#
# GET /onchain/networks/{network}/pools/{pool_address}/ohlcv/{timeframe}
# operationId: pool-ohlcv-contract-address
export def "onchain-networks-pools-ohlcv pool-ohlcv-contract-address" [
  network: string
  pool_address: string
  timeframe: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aggregate: string # Time period to aggregate each OHLCV.  Available values (day): `1`  Available values (hour): `1`, `4`, `12`  Available values (minute): `1`, `5`, `15`  Available values (second): `1`, `15`, `30`  Default value: 1
  --before-timestamp: int # Return OHLCV data before this timestamp (integer seconds since epoch).
  --limit: int # Number of OHLCV results to return, maximum 1000.  Default value: 100
  --currency: string@currency-completer # Return OHLCV in USD or quote token.  Default: `usd`
  --qp-token: string # Return OHLCV for token, use this to invert the chart.  Available values: `base`, `quote`, or token address.  Default: `base`
  --include-empty-intervals: string@bool-completer # Include empty intervals with no trade data.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<ohlcv_list: list>>, meta: record<base: record<name: string, symbol: string, coingecko_coin_id: string, address: string>, quote: record<name: string, symbol: string, coingecko_coin_id: string, address: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aggregate" $aggregate "scalar") (serialize-qp "before_timestamp" $before_timestamp "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "include_empty_intervals" $include_empty_intervals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools/($pool_address)/ohlcv/($timeframe)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Token OHLCV Chart by Token Address
#
# GET /onchain/networks/{network}/tokens/{token_address}/ohlcv/{timeframe}
# operationId: token-ohlcv-token-address
export def "onchain-networks-tokens-ohlcv token-ohlcv-token-address" [
  network: string
  token_address: string
  timeframe: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --aggregate: string # Time period to aggregate each OHLCV.  Available values (day): `1`  Available values (hour): `1`, `4`, `12`  Available values (minute): `1`, `5`, `15`  Available values (second): `1`, `15`, `30`  Default value: 1
  --before-timestamp: int # Return OHLCV data before this timestamp (integer seconds since epoch).
  --limit: int # Number of OHLCV results to return, maximum 1000.  Default value: 100
  --currency: string@currency-completer # Return OHLCV in USD or quote token.  Default: `usd`
  --include-empty-intervals: string@bool-completer # Include empty intervals with no trade data.  Default: `false`
  --include-inactive-source: string@bool-completer # Include token data from inactive pools using the most recent swap.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<ohlcv_list: list>>, meta: record<base: record<name: string, symbol: string, coingecko_coin_id: string, address: string>, quote: record<name: string, symbol: string, coingecko_coin_id: string, address: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "aggregate" $aggregate "scalar") (serialize-qp "before_timestamp" $before_timestamp "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "include_empty_intervals" $include_empty_intervals "scalar") (serialize-qp "include_inactive_source" $include_inactive_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($token_address)/ohlcv/($timeframe)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Past 24 Hour Trades by Pool Address
#
# GET /onchain/networks/{network}/pools/{pool_address}/trades
# operationId: pool-trades-contract-address
export def "onchain-networks-pools-trades pool-trades-contract-address" [
  network: string
  pool_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trade-volume-in-usd-greater-than: float # Filter trades by trade volume in USD greater than this value.  Default value: 0
  --qp-token: string # Return trades for token, use this to invert the chart.  Available values: `base`, `quote`, or token address.  Default: `base`
]: nothing -> record<data: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trade_volume_in_usd_greater_than" $trade_volume_in_usd_greater_than "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools/($pool_address)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Past 24 Hour Trades by Token Address
#
# GET /onchain/networks/{network}/tokens/{token_address}/trades
# operationId: token-trades-contract-address
export def "onchain-networks-tokens-trades token-trades-contract-address" [
  network: string
  token_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trade-volume-in-usd-greater-than: float # Filter trades by trade volume in USD greater than this value.  Default value: 0
]: nothing -> record<data: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trade_volume_in_usd_greater_than" $trade_volume_in_usd_greater_than "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/tokens/($token_address)/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Categories List
#
# GET /onchain/categories
# operationId: categories-list
export def "onchain-categories categories-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer-4 # Sort the categories by field.  Default: `h6_volume_percentage_desc`
]: nothing -> record<data: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pools by Category ID
#
# GET /onchain/categories/{category_id}/pools
# operationId: pools-category
export def "onchain-categories-pools pools-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`, `network`
  --page: int # Page through results.  Default value: 1
  --qp-sort: string@sort-completer-5 # Sort the pools by field.  Default: `pool_created_at_desc`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/categories/($category_id)/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Pools List
#
# GET /onchain/networks/new_pools
# operationId: latest-pools-list
export def "onchain-networks-new-pools latest-pools-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`, `network`
  --page: int # Page through results.  Default value: 1
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/networks/new_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Pools by Network
#
# GET /onchain/networks/{network}/new_pools
# operationId: latest-pools-network
export def "onchain-networks-new-pools latest-pools-network" [
  network: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --page: int # Page through results.  Default value: 1
  --include-gt-community-data: string@bool-completer # Include GeckoTerminal community data (sentiment votes, suspicious reports).  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "include_gt_community_data" $include_gt_community_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/new_pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Multiple Pools Data by Pool Addresses
#
# GET /onchain/networks/{network}/pools/multi/{addresses}
# operationId: pools-addresses
export def "onchain-networks-pools-multi pools-addresses" [
  network: string
  addresses: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --include-volume-breakdown: string@bool-completer # Include volume breakdown.  Default: `false`
  --include-composition: string@bool-completer # Include pool composition.  Default: `false`
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "include_volume_breakdown" $include_volume_breakdown "scalar") (serialize-qp "include_composition" $include_composition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/pools/multi/($addresses)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Pools & Tokens
#
# GET /onchain/search/pools
# operationId: search-pools
export def "onchain-search-pools search-pools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Search query: pool contract address, token name, token symbol, or token contract address. (default: weth)
  --network: string # Network ID.  *refers to [`/onchain/networks`](/reference/networks-list).
  --include: string # Attributes to include, comma-separated if more than one.  Available values: `base_token`, `quote_token`, `dex`
  --page: int # Page through results.  Default value: 1
]: nothing -> record<data: table<id: string, type: string, attributes: record, relationships: record>, included: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/search/pools" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Token Price by Token Addresses
#
# GET /onchain/simple/networks/{network}/token_price/{addresses}
# operationId: onchain-simple-price
export def "onchain-simple-networks-token-price onchain-simple-price" [
  network: string
  addresses: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-market-cap: string@bool-completer # Include market capitalization.  Default: `false`
  --mcap-fdv-fallback: string@bool-completer # Return FDV if market cap is not available.  Default: `false`
  --include-24hr-vol: string@bool-completer # Include 24hr volume.  Default: `false`
  --include-24hr-price-change: string@bool-completer # Include 24hr price change.  Default: `false`
  --include-total-reserve-in-usd: string@bool-completer # Include total reserve in USD.  Default: `false`
  --include-inactive-source: string@bool-completer # Include token price data from inactive pools using the most recent swap.  Default: `false`
]: nothing -> record<data: record<id: string, type: string, attributes: record<token_prices: record, market_cap_usd: record, h24_volume_usd: record, h24_price_change_percentage: record, total_reserve_in_usd: record, last_trade_timestamp: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_market_cap" $include_market_cap "scalar") (serialize-qp "mcap_fdv_fallback" $mcap_fdv_fallback "scalar") (serialize-qp "include_24hr_vol" $include_24hr_vol "scalar") (serialize-qp "include_24hr_price_change" $include_24hr_price_change "scalar") (serialize-qp "include_total_reserve_in_usd" $include_total_reserve_in_usd "scalar") (serialize-qp "include_inactive_source" $include_inactive_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/simple/networks/($network)/token_price/($addresses)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Networks List
#
# GET /onchain/networks
# operationId: networks-list
export def "onchain-networks networks-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page through results.  Default value: 1
]: nothing -> record<data: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/onchain/networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DEXs List by Network
#
# GET /onchain/networks/{network}/dexes
# operationId: dexes-list
export def "onchain-networks-dexes dexes-list" [
  network: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page through results.  Default value: 1
]: nothing -> record<data: table<id: string, type: string, attributes: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-cg-pro-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/onchain/networks/($network)/dexes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
