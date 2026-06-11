# Auto-generated client for Binance Public Spot API v1.0
# Source: https://raw.githubusercontent.com/binance/binance-api-swagger/master/spot_api.yaml
# Auth: --token flag or $env.BINANCE_API_KEY

const BASE_URL = "https://api.binance.com"
const DEFAULT_AUTH = "x-mbx-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BINANCE_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-mbx-apikey" => { {headers: {X-MBX-APIKEY: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://api.binance.com" "https://testnet.binance.vision"] }
def auth-scheme-completer [] { ["x-mbx-apikey"] }

# Completers for enum parameters
def interval-completer [] { ["12h" "15m" "1M" "1d" "1h" "1m" "1s" "1w" "2h" "30m" "3d" "3m" "4h" "5m" "6h" "8h"] }
def type-completer [] { ["FULL" "MINI"] }
def side-completer [] { ["BUY" "SELL"] }
def type-completer-1 [] { ["LIMIT" "LIMIT_MAKER" "MARKET" "STOP_LOSS" "STOP_LOSS_LIMIT" "TAKE_PROFIT" "TAKE_PROFIT_LIMIT"] }
def timeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def newOrderRespType-completer [] { ["ACK" "FULL" "RESULT"] }
def selfTradePreventionMode-completer [] { ["EXPIRE_BOTH" "EXPIRE_MAKER" "EXPIRE_TAKER" "NONE"] }
def cancelRestrictions-completer [] { ["ONLY_NEW" "ONLY_PARTIALLY_FILLED"] }
def aboveTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def belowTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def workingType-completer [] { ["LIMIT" "LIMIT_MAKER"] }
def workingSide-completer [] { ["BUY" "SELL"] }
def workingTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def pendingType-completer [] { ["LIMIT" "LIMIT_MAKER" "MARKET" "STOP_LOSS" "STOP_LOSS_LIMIT" "TAKE_PROFIT" "TAKE_PROFIT_LIMIT"] }
def pendingSide-completer [] { ["BUY" "SELL"] }
def pendingTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def pendingAboveType-completer [] { ["LIMIT_MAKER" "STOP_LOSS" "STOP_LOSS_LIMIT"] }
def pendingAboveTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def pendingBelowType-completer [] { ["LIMIT_MAKER" "STOP_LOSS" "STOP_LOSS_LIMIT"] }
def pendingBelowTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def type-completer-2 [] { ["ROLL_IN" "ROLL_OUT"] }
def isIsolated-completer [] { ["FALSE" "TRUE"] }
def sideEffectType-completer [] { ["AUTO_REPAY" "MARGIN_BUY" "NO_SIDE_EFFECT"] }
def stopLimitTimeInForce-completer [] { ["FOK" "GTC" "IOC"] }
def spotBNBBurn-completer [] { ["false" "true"] }
def interestBNBBurn-completer [] { ["false" "true"] }
def type-completer-3 [] { ["BORROW" "BUY_EXPENSE" "BUY_INCOME" "BUY_LIQUIDATION" "COMMISSION_RETURN" "LIQUIDATION_FEE" "OTHER_LIQUIDATION" "REPAY" "REPAY_LIQUIDATION" "SELL_EXPENSE" "SELL_INCOME" "SELL_LIQUIDATION" "SMALL_BALANCE_CONVERT" "SMALL_CONVERT" "TRADING_COMMISSION" "TRANSFER"] }
def type-completer-4 [] { ["ISOLATED" "MARGIN"] }
def sideEffectType-completer-1 [] { ["MARGIN_BUY" "NO_SIDE_EFFECT"] }
def type-completer-5 [] { ["FUTURES" "MARGIN" "SPOT"] }
def accountType-completer [] { ["MARGIN" "SPOT"] }
def type-completer-6 [] { ["C2C_MAIN" "C2C_MARGIN" "C2C_MINING" "C2C_UMFUTURE" "CMFUTURE_MAIN" "CMFUTURE_MARGIN" "ISOLATEDMARGIN_ISOLATEDMARGIN" "ISOLATEDMARGIN_MARGIN" "MAIN_C2C" "MAIN_CMFUTURE" "MAIN_MARGIN" "MAIN_MINING" "MAIN_PAY" "MAIN_UMFUTURE" "MARGIN_C2C" "MARGIN_CMFUTURE" "MARGIN_ISOLATEDMARGIN" "MARGIN_MAIN" "MARGIN_MINING" "MARGIN_UMFUTURE" "MINING_C2C" "MINING_MAIN" "MINING_MARGIN" "MINING_UMFUTURE" "PAY_MAIN" "UMFUTURE_C2C" "UMFUTURE_MAIN" "UMFUTURE_MARGIN"] }
def needBtcValuation-completer [] { ["false" "true"] }
def accountType-completer-1 [] { ["CARD" "MAIN"] }
def isFreeze-completer [] { ["false" "true"] }
def fromAccountType-completer [] { ["COIN_FUTURE" "ISOLATED_MARGIN" "MARGIN" "SPOT" "USDT_FUTURE"] }
def toAccountType-completer [] { ["COIN_FUTURE" "ISOLATED_MARGIN" "MARGIN" "SPOT" "USDT_FUTURE"] }
def transfers-completer [] { ["FROM" "TO"] }
def transferFunctionAccountType-completer [] { ["COIN_FUTURE" "ISOLATED_MARGIN" "MARGIN" "SPOT" "USDT_FUTURE"] }
def type-completer-7 [] { ["ACTIVITY" "CUSTOMIZED_FIXED"] }
def status-completer [] { ["ALL" "SUBSCRIBABLE" "UNSUBSCRIBABLE"] }
def sortBy-completer [] { ["DURATION" "INTEREST_RATE" "LOT_SIZE" "START_TIME"] }
def dataType-completer [] { ["S_DEPTH" "T_DEPTH"] }
def positionSide-completer [] { ["BOTH" "LONG" "SHORT"] }
def urgency-completer [] { ["HIGH" "LOW" "MEDIUM"] }
def transferSide-completer [] { ["FROM_UM" "TO_UM"] }
def tradeType-completer [] { ["BUY" "SELL"] }
def isFlexibleRate-completer [] { ["FALSE" "TRUE"] }
def type-completer-8 [] { ["addCollateral" "borrowIn" "collateralReturn" "collateralReturnAfterLiquidation" "collateralSpent" "removeCollateral" "repayAmount"] }
def direction-completer [] { ["ADDITIONAL" "REDUCED"] }
def walletType-completer [] { ["FUNDING" "SPOT" "SPOT_FUNDING"] }
def expiredType-completer [] { ["1_D" "30_D" "3_D" "7_D"] }
def sourceType-completer [] { ["MAIN_SITE" "TR"] }
def planType-completer [] { ["INDEX" "PORTFOLIO" "SINGLE"] }
def subscriptionCycle-completer [] { ["BI_WEEKLY" "DAILY" "H1" "H12" "H4" "H8" "MONTHLY" "WEEKLY"] }
def subscriptionStartWeekday-completer [] { ["FRI" "MON" "SAT" "SUN" "THU" "TUE" "WED"] }
def status-completer-1 [] { ["ONGOING" "PAUSED" "REMOVED"] }
def planType-completer-1 [] { ["ALL" "INDEX" "PORTFOLIO" "SINGLE"] }
def redeemTo-completer [] { ["FLEXIBLE" "SPOT"] }
def optionType-completer [] { ["CALL" "PUT"] }
def autoCompoundPlan-completer [] { ["ADVANCE" "NONE" "STANDARD"] }
def status-completer-2 [] { ["PENDING" "PURCHASE_FAIL" "PURCHASE_SUCCESS" "REFUNDING" "REFUND_SUCCESS" "SETTLED" "SETTLING"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ping get" } } | get name | first)
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

# Test Connectivity
#
# GET /api/v3/ping
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Server Time
#
# GET /api/v3/time
export def "time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<serverTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Information
#
# GET /api/v3/exchangeInfo
export def "exchange-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
  --permissions: string # e.g. 'SPOT' or ['MARGIN','LEVERAGED']
]: nothing -> record<timezone: string, serverTime: int, rateLimits: table<rateLimitType: string, interval: string, intervalNum: int, limit: int>, exchangeFilters: list<record>, symbols: table<symbol: string, status: string, baseAsset: string, baseAssetPrecision: int, quoteAsset: string, quoteAssetPrecision: int, baseCommissionPrecision: int, quoteCommissionPrecision: int, orderTypes: list, icebergAllowed: bool, ocoAllowed: bool, otoAllowed: bool, quoteOrderQtyMarketAllowed: bool, allowTrailingStop: bool, cancelReplaceAllowed: bool, isSpotTradingAllowed: bool, isMarginTradingAllowed: bool, filters: list, permissions: list, permissionSets: list, defaultSelfTradePreventionMode: string, allowedSelfTradePreventionModes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "permissions" $permissions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/exchangeInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Order Book
#
# GET /api/v3/depth
export def "depth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --limit: int # If limit > 5000, then the response will truncate to 5000 (format: int32, default: 100, e.g. 100)
]: nothing -> record<lastUpdateId: int, bids: list<list<string>>, asks: list<list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/depth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Recent Trades List
#
# GET /api/v3/trades
export def "trades get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
]: nothing -> table<id: int, price: string, qty: string, quoteQty: string, time: int, isBuyerMaker: bool, isBestMatch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/trades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Old Trade Lookup
#
# GET /api/v3/historicalTrades
export def "historical-trades get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --fromId: int # Trade id to fetch from. Default gets most recent trades. (format: int64)
]: nothing -> table<id: int, price: string, qty: string, quoteQty: string, time: int, isBuyerMaker: bool, isBestMatch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fromId" $fromId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/historicalTrades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compressed/Aggregate Trades List
#
# GET /api/v3/aggTrades
export def "agg-trades get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --fromId: int # Trade id to fetch from. Default gets most recent trades. (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
]: nothing -> table<a: int, p: string, q: string, f: int, l: int, T: bool, m: bool, M: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/aggTrades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Kline/Candlestick Data
#
# GET /api/v3/klines
export def "klines get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --interval: string@interval-completer # kline intervals (e.g. "1m")
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --timeZone: string # Default: 0 (UTC)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/klines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# UIKlines
#
# GET /api/v3/uiKlines
export def "ui-klines get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --interval: string@interval-completer # kline intervals (e.g. "1m")
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --timeZone: string # Default: 0 (UTC)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
]: nothing -> list<list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/uiKlines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current Average Price
#
# GET /api/v3/avgPrice
export def "avg-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
]: nothing -> record<mins: int, price: string, closeTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/avgPrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# 24hr Ticker Price Change Statistics
#
# GET /api/v3/ticker/24hr
export def "ticker-24hr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
  --type: string@type-completer # Supported values: FULL or MINI. If none provided, the default is FULL (e.g. FULL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/ticker/24hr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trading Day Ticker
#
# GET /api/v3/ticker/tradingDay
export def "ticker-trading-day get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
  --timeZone: string # Default: 0 (UTC)
  --type: string@type-completer # Supported values: FULL or MINI. If none provided, the default is FULL (e.g. FULL)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "timeZone" $timeZone "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/ticker/tradingDay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Symbol Price Ticker
#
# GET /api/v3/ticker/price
export def "ticker-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/ticker/price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Symbol Order Book Ticker
#
# GET /api/v3/ticker/bookTicker
export def "ticker-book-ticker get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/ticker/bookTicker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rolling window price change statistics
#
# GET /api/v3/ticker
export def "ticker get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --symbols: string # e.g. ["BTCUSDT","BNBBTC"]
  --windowSize: string # Defaults to 1d if no parameter provided. Supported windowSize values: 1m,2m....59m for minutes 1h, 2h....23h - for hours 1d...7d - for days.  Units cannot be combined (e.g. 1d2h is not allowed)
  --type: string # Supported values: FULL or MINI. If none provided, the default is FULL
]: nothing -> record<symbol: string, priceChange: string, priceChangePercent: string, weightedAvgPrice: string, openPrice: string, highPrice: string, lowPrice: string, lastPrice: string, volume: string, quoteVolume: string, openTime: int, closeTime: int, firstId: int, lastId: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "symbols" $symbols "scalar") (serialize-qp "windowSize" $windowSize "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/ticker" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test New Order (TRADE)
#
# POST /api/v3/order/test
export def "order-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --quantity: float # Order quantity (format: double, e.g. 1)
  --quoteOrderQty: float # Quote quantity (format: double)
  --price: float # Order price (format: double, e.g. 219.0)
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --strategyId: int # format: int64
  --strategyType: int # The value cannot be less than 1000000. (format: int64)
  --stopPrice: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double, e.g. 221.01)
  --trailingDelta: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double)
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --computeCommissionRates: string@bool-completer # Default: false (e.g. false)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "quoteOrderQty" $quoteOrderQty "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "strategyId" $strategyId "scalar") (serialize-qp "strategyType" $strategyType "scalar") (serialize-qp "stopPrice" $stopPrice "scalar") (serialize-qp "trailingDelta" $trailingDelta "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "computeCommissionRates" $computeCommissionRates "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/order/test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Order (USER_DATA)
#
# GET /api/v3/order
export def "order get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --orderId: int # Order id (format: int64)
  --origClientOrderId: string # Order id from client
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<symbol: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string, icebergQty: string, time: int, updateTime: int, isWorking: bool, workingTime: int, origQuoteOrderQty: string, selfTradePreventionMode: string, preventedMatchId: int, preventedQuantity: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Order (TRADE)
#
# POST /api/v3/order
export def "order post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --quantity: float # Order quantity (format: double, e.g. 1)
  --quoteOrderQty: float # Quote quantity (format: double)
  --price: float # Order price (format: double, e.g. 219.0)
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --strategyId: int # format: int64
  --strategyType: int # The value cannot be less than 1000000. (format: int64)
  --stopPrice: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double, e.g. 221.01)
  --trailingDelta: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double)
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "quoteOrderQty" $quoteOrderQty "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "strategyId" $strategyId "scalar") (serialize-qp "strategyType" $strategyType "scalar") (serialize-qp "stopPrice" $stopPrice "scalar") (serialize-qp "trailingDelta" $trailingDelta "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Order (TRADE)
#
# DELETE /api/v3/order
export def "order delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --orderId: int # Order id (format: int64)
  --origClientOrderId: string # Order id from client
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --cancelRestrictions: string@cancelRestrictions-completer # e.g. ONLY_NEW
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<symbol: string, origClientOrderId: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, selfTradePreventionMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "cancelRestrictions" $cancelRestrictions "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel an Existing Order and Send a New Order (Trade)
#
# POST /api/v3/order/cancelReplace
export def "order-cancel-replace post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --cancelReplaceMode: string # - `STOP_ON_FAILURE` If the cancel request fails, the new order placement will not be attempted. - `ALLOW_FAILURES` If new order placement will be attempted even if cancel request fails. (e.g. STOP_ON_FAILURE)
  --cancelRestrictions: string@cancelRestrictions-completer # e.g. ONLY_NEW
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --quantity: float # Order quantity (format: double, e.g. 1)
  --quoteOrderQty: float # Quote quantity (format: double)
  --price: float # Order price (format: double, e.g. 219.0)
  --cancelNewClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --cancelOrigClientOrderId: string # Either the cancelOrigClientOrderId or cancelOrderId must be provided. If both are provided, cancelOrderId takes precedence.
  --cancelOrderId: int # Either the cancelOrigClientOrderId or cancelOrderId must be provided. If both are provided, cancelOrderId takes precedence. (format: int64, e.g. 12)
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --strategyId: int # format: int64
  --strategyType: int # The value cannot be less than 1000000. (format: int64)
  --stopPrice: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double, e.g. 221.01)
  --trailingDelta: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double)
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<cancelResult: string, newOrderResult: string, cancelResponse: record<symbol: string, origClientOrderId: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, selfTradePreventionMode: string, transactTime: int>, newOrderResponse: record<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, workingTime: int, fills: list<string>, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "cancelReplaceMode" $cancelReplaceMode "scalar") (serialize-qp "cancelRestrictions" $cancelRestrictions "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "quoteOrderQty" $quoteOrderQty "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "cancelNewClientOrderId" $cancelNewClientOrderId "scalar") (serialize-qp "cancelOrigClientOrderId" $cancelOrigClientOrderId "scalar") (serialize-qp "cancelOrderId" $cancelOrderId "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "strategyId" $strategyId "scalar") (serialize-qp "strategyType" $strategyType "scalar") (serialize-qp "stopPrice" $stopPrice "scalar") (serialize-qp "trailingDelta" $trailingDelta "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/order/cancelReplace" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current Open Orders (USER_DATA)
#
# GET /api/v3/openOrders
export def "open-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string, icebergQty: string, time: int, updateTime: int, isWorking: bool, workingTime: int, origQuoteOrderQty: string, selfTradePreventionMode: string, preventedMatchId: int, preventedQuantity: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel all Open Orders on a Symbol (TRADE)
#
# DELETE /api/v3/openOrders
export def "open-orders delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All Orders (USER_DATA)
#
# GET /api/v3/allOrders
export def "all-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --orderId: int # Order id (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string, icebergQty: string, time: int, updateTime: int, isWorking: bool, workingTime: int, origQuoteOrderQty: string, selfTradePreventionMode: string, preventedMatchId: int, preventedQuantity: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/allOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Order list - OCO (TRADE)
#
# POST /api/v3/orderList/oco
export def "order-list-oco post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --listClientOrderId: string # Arbitrary unique ID among open order lists. Automatically generated if not sent. A new order list with the same `listClientOrderId` is accepted only when the previous one is filled or completely expired. `listClientOrderId` is distinct from the `aboveClientOrderId` and the `belowCLientOrderId`.
  --side: string@side-completer # e.g. SELL
  --quantity: float # format: double, e.g. 1.0
  --aboveType: string # Supported values : `STOP_LOSS_LIMIT`, `STOP_LOSS`, `LIMIT_MAKER`
  --aboveClientOrderId: string # Arbitrary unique ID among open orders for the above order. Automatically generated if not sent
  --aboveIcebergQty: float # Note that this can only be used if `aboveTimeInForce` is `GTC`. (format: double)
  --abovePrice: float # format: double
  --aboveStopPrice: float # Can be used if `aboveType` is `STOP_LOSS` or `STOP_LOSS_LIMIT`. Either `aboveStopPrice` or `aboveTrailingDelta` or both, must be specified. (format: double)
  --aboveTrailingDelta: float # format: double
  --aboveTimeInForce: string@aboveTimeInForce-completer # Required if the `aboveType` is `STOP_LOSS_LIMIT`. (e.g. GTC)
  --aboveStrategyId: float # Arbitrary numeric value identifying the above order within an order strategy. (format: double)
  --aboveStrategyType: int # Arbitrary numeric value identifying the above order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --belowType: string # Supported values : `STOP_LOSS_LIMIT`, `STOP_LOSS`, `LIMIT_MAKER`
  --belowClientOrderId: string # Arbitrary unique ID among open orders for the below order. Automatically generated if not sent
  --belowIcebergQty: float # Note that this can only be used if `belowTimeInForce` is `GTC`. (format: double)
  --belowPrice: float # Can be used if `belowType` is `STOP_LOSS_LIMIT` or `LIMIT_MAKER` to specify the limit price. (format: double)
  --belowStopPrice: float # Can be used if `belowType` is `STOP_LOSS` or `STOP_LOSS_LIMIT`. Either `belowStopPrice` or `belowTrailingDelta` or both, must be specified. (format: double)
  --belowTrailingDelta: float # format: double
  --belowTimeInForce: string@belowTimeInForce-completer # Required if the `belowType` is `STOP_LOSS_LIMIT`. (e.g. GTC)
  --belowStrategyId: float # Arbitrary numeric value identifying the below order within an order strategy. (format: double)
  --belowStrategyType: int # Arbitrary numeric value identifying the below order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string, workingTime: int, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "aboveType" $aboveType "scalar") (serialize-qp "aboveClientOrderId" $aboveClientOrderId "scalar") (serialize-qp "aboveIcebergQty" $aboveIcebergQty "scalar") (serialize-qp "abovePrice" $abovePrice "scalar") (serialize-qp "aboveStopPrice" $aboveStopPrice "scalar") (serialize-qp "aboveTrailingDelta" $aboveTrailingDelta "scalar") (serialize-qp "aboveTimeInForce" $aboveTimeInForce "scalar") (serialize-qp "aboveStrategyId" $aboveStrategyId "scalar") (serialize-qp "aboveStrategyType" $aboveStrategyType "scalar") (serialize-qp "belowType" $belowType "scalar") (serialize-qp "belowClientOrderId" $belowClientOrderId "scalar") (serialize-qp "belowIcebergQty" $belowIcebergQty "scalar") (serialize-qp "belowPrice" $belowPrice "scalar") (serialize-qp "belowStopPrice" $belowStopPrice "scalar") (serialize-qp "belowTrailingDelta" $belowTrailingDelta "scalar") (serialize-qp "belowTimeInForce" $belowTimeInForce "scalar") (serialize-qp "belowStrategyId" $belowStrategyId "scalar") (serialize-qp "belowStrategyType" $belowStrategyType "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/orderList/oco" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Order List - OTO (TRADE)
#
# POST /api/v3/orderList/oto
export def "order-list-oto post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --listClientOrderId: string # Arbitrary unique ID among open order lists. Automatically generated if not sent. A new order list with the same `listClientOrderId` is accepted only when the previous one is filled or completely expired. `listClientOrderId` is distinct from the `workingClientOrderId` and the `pendingClientOrderId`.
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --workingType: string@workingType-completer # Supported values: LIMIT,LIMIT_MAKER
  --workingSide: string@workingSide-completer # BUY,SELL
  --workingClientOrderId: string # Arbitrary unique ID among open orders for the working order. Automatically generated if not sent.
  --workingPrice: float # format: double
  --workingQuantity: float # Sets the quantity for the working order. (format: double)
  --workingIcebergQty: float # This can only be used if workingTimeInForce is GTC. (format: double)
  --workingTimeInForce: string@workingTimeInForce-completer # GTC, IOC, FOK
  --workingStrategyId: float # Arbitrary numeric value identifying the working order within an order strategy. (format: double)
  --workingStrategyType: int # Arbitrary numeric value identifying the working order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --pendingType: string@pendingType-completer # Supported values: Order Types Note that MARKET orders using quoteOrderQty are not supported.
  --pendingSide: string@pendingSide-completer # BUY,SELL
  --pendingClientOrderId: string # Arbitrary unique ID among open orders for the pending order. Automatically generated if not sent.
  --pendingPrice: float # format: double
  --pendingStopPrice: float # format: double
  --pendingTrailingDelta: float # format: double
  --pendingQuantity: float # Sets the quantity for the pending order. (format: double)
  --pendingIcebergQty: float # This can only be used if pendingTimeInForce is GTC. (format: double)
  --pendingTimeInForce: string@pendingTimeInForce-completer # GTC, IOC, FOK
  --pendingStrategyId: float # Arbitrary numeric value identifying the pending order within an order strategy. (format: double)
  --pendingStrategyType: int # Arbitrary numeric value identifying the pending order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, workingTime: int, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "workingType" $workingType "scalar") (serialize-qp "workingSide" $workingSide "scalar") (serialize-qp "workingClientOrderId" $workingClientOrderId "scalar") (serialize-qp "workingPrice" $workingPrice "scalar") (serialize-qp "workingQuantity" $workingQuantity "scalar") (serialize-qp "workingIcebergQty" $workingIcebergQty "scalar") (serialize-qp "workingTimeInForce" $workingTimeInForce "scalar") (serialize-qp "workingStrategyId" $workingStrategyId "scalar") (serialize-qp "workingStrategyType" $workingStrategyType "scalar") (serialize-qp "pendingType" $pendingType "scalar") (serialize-qp "pendingSide" $pendingSide "scalar") (serialize-qp "pendingClientOrderId" $pendingClientOrderId "scalar") (serialize-qp "pendingPrice" $pendingPrice "scalar") (serialize-qp "pendingStopPrice" $pendingStopPrice "scalar") (serialize-qp "pendingTrailingDelta" $pendingTrailingDelta "scalar") (serialize-qp "pendingQuantity" $pendingQuantity "scalar") (serialize-qp "pendingIcebergQty" $pendingIcebergQty "scalar") (serialize-qp "pendingTimeInForce" $pendingTimeInForce "scalar") (serialize-qp "pendingStrategyId" $pendingStrategyId "scalar") (serialize-qp "pendingStrategyType" $pendingStrategyType "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/orderList/oto" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Order List - OTOCO (TRADE)
#
# POST /api/v3/orderList/otoco
export def "order-list-otoco post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --listClientOrderId: string # Arbitrary unique ID among open order lists. Automatically generated if not sent. A new order list with the same `listClientOrderId` is accepted only when the previous one is filled or completely expired. `listClientOrderId` is distinct from the `workingClientOrderId` and the `pendingClientOrderId`.
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --workingType: string@workingType-completer # Supported values: LIMIT,LIMIT_MAKER
  --workingSide: string@workingSide-completer # BUY,SELL
  --workingClientOrderId: string # Arbitrary unique ID among open orders for the working order. Automatically generated if not sent.
  --workingPrice: float # format: double
  --workingQuantity: float # Sets the quantity for the working order. (format: double)
  --workingIcebergQty: float # This can only be used if workingTimeInForce is GTC. (format: double)
  --workingTimeInForce: string@workingTimeInForce-completer # GTC, IOC, FOK
  --workingStrategyId: float # Arbitrary numeric value identifying the working order within an order strategy. (format: double)
  --workingStrategyType: int # Arbitrary numeric value identifying the working order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --pendingSide: string@pendingSide-completer # BUY,SELL
  --pendingQuantity: float # Sets the quantity for the pending order. (format: double)
  --pendingAboveType: string@pendingAboveType-completer # Supported values: LIMIT_MAKER, STOP_LOSS, and STOP_LOSS_LIMIT
  --pendingAboveClientOrderId: string # Arbitrary unique ID among open orders for the pending above order. Automatically generated if not sent.
  --pendingAbovePrice: float # format: double
  --pendingAboveStopPrice: float # format: double
  --pendingAboveTrailingDelta: float # format: double
  --pendingAboveIcebergQty: float # This can only be used if pendingAboveTimeInForce is GTC. (format: double)
  --pendingAboveTimeInForce: string@pendingAboveTimeInForce-completer
  --pendingAboveStrategyId: float # Arbitrary numeric value identifying the pending above order within an order strategy. (format: double)
  --pendingAboveStrategyType: int # Arbitrary numeric value identifying the pending above order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --pendingBelowType: string@pendingBelowType-completer # Supported values: LIMIT_MAKER, STOP_LOSS, and STOP_LOSS_LIMIT
  --pendingBelowClientOrderId: string # Arbitrary unique ID among open orders for the pending below order. Automatically generated if not sent.
  --pendingBelowPrice: float # format: double
  --pendingBelowStopPrice: float # format: double
  --pendingBelowTrailingDelta: float # format: double
  --pendingBelowIcebergQty: float # This can only be used if pendingBelowTimeInForce is GTC. (format: double)
  --pendingBelowTimeInForce: string@pendingBelowTimeInForce-completer
  --pendingBelowStrategyId: float # Arbitrary numeric value identifying the pending below order within an order strategy. (format: double)
  --pendingBelowStrategyType: int # Arbitrary numeric value identifying the pending below order strategy. Values smaller than 1000000 are reserved and cannot be used. (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, workingTime: int, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "workingType" $workingType "scalar") (serialize-qp "workingSide" $workingSide "scalar") (serialize-qp "workingClientOrderId" $workingClientOrderId "scalar") (serialize-qp "workingPrice" $workingPrice "scalar") (serialize-qp "workingQuantity" $workingQuantity "scalar") (serialize-qp "workingIcebergQty" $workingIcebergQty "scalar") (serialize-qp "workingTimeInForce" $workingTimeInForce "scalar") (serialize-qp "workingStrategyId" $workingStrategyId "scalar") (serialize-qp "workingStrategyType" $workingStrategyType "scalar") (serialize-qp "pendingSide" $pendingSide "scalar") (serialize-qp "pendingQuantity" $pendingQuantity "scalar") (serialize-qp "pendingAboveType" $pendingAboveType "scalar") (serialize-qp "pendingAboveClientOrderId" $pendingAboveClientOrderId "scalar") (serialize-qp "pendingAbovePrice" $pendingAbovePrice "scalar") (serialize-qp "pendingAboveStopPrice" $pendingAboveStopPrice "scalar") (serialize-qp "pendingAboveTrailingDelta" $pendingAboveTrailingDelta "scalar") (serialize-qp "pendingAboveIcebergQty" $pendingAboveIcebergQty "scalar") (serialize-qp "pendingAboveTimeInForce" $pendingAboveTimeInForce "scalar") (serialize-qp "pendingAboveStrategyId" $pendingAboveStrategyId "scalar") (serialize-qp "pendingAboveStrategyType" $pendingAboveStrategyType "scalar") (serialize-qp "pendingBelowType" $pendingBelowType "scalar") (serialize-qp "pendingBelowClientOrderId" $pendingBelowClientOrderId "scalar") (serialize-qp "pendingBelowPrice" $pendingBelowPrice "scalar") (serialize-qp "pendingBelowStopPrice" $pendingBelowStopPrice "scalar") (serialize-qp "pendingBelowTrailingDelta" $pendingBelowTrailingDelta "scalar") (serialize-qp "pendingBelowIcebergQty" $pendingBelowIcebergQty "scalar") (serialize-qp "pendingBelowTimeInForce" $pendingBelowTimeInForce "scalar") (serialize-qp "pendingBelowStrategyId" $pendingBelowStrategyId "scalar") (serialize-qp "pendingBelowStrategyType" $pendingBelowStrategyType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/orderList/otoco" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query OCO (USER_DATA)
#
# GET /api/v3/orderList
export def "order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderListId: int # Order list id (format: int64)
  --origClientOrderId: string # Order id from client
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: table<symbol: string, orderId: int, clientOrderId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderListId" $orderListId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/orderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel OCO (TRADE)
#
# DELETE /api/v3/orderList
export def "order-list delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --orderListId: int # Order list id (format: int64)
  --listClientOrderId: string # A unique Id for the entire orderList
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, origClientOrderId: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string, selfTradePreventionMode: string, transactTime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderListId" $orderListId "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/orderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query all OCO (USER_DATA)
#
# GET /api/v3/allOrderList
export def "all-order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromId: int # Trade id to fetch from. Default gets most recent trades. (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromId" $fromId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/allOrderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Open OCO (USER_DATA)
#
# GET /api/v3/openOrderList
export def "open-order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, orders: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/openOrderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New order using SOR (TRADE)
#
# POST /api/v3/sor/order
export def "sor-order post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --quantity: float # format: double, e.g. 1.0
  --price: float # format: double
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --strategyId: int # format: int64
  --strategyType: int # The value cannot be less than 1000000. (format: int64)
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, workingTime: int, fills: table<matchType: string, price: string, qty: string, commission: string, commissionAsset: string, tradeId: int, allocId: int>, workingFloor: string, selfTradePreventionMode: string, usedSor: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "strategyId" $strategyId "scalar") (serialize-qp "strategyType" $strategyType "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/sor/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test new order using SOR (TRADE)
#
# POST /api/v3/sor/order/test
export def "sor-order-test post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --quantity: float # format: double, e.g. 1.0
  --price: float # format: double
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --strategyId: int # format: int64
  --strategyType: int # The value cannot be less than 1000000. (format: int64)
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON. MARKET and LIMIT order types default to FULL, all other orders default to ACK.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --computeCommissionRates: string@bool-completer # Default: false (e.g. false)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "strategyId" $strategyId "scalar") (serialize-qp "strategyType" $strategyType "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "computeCommissionRates" $computeCommissionRates "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/sor/order/test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Information (USER_DATA)
#
# GET /api/v3/account
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<makerCommission: int, takerCommission: int, buyerCommission: int, sellerCommission: int, commissionRates: record<maker: string, taker: string, buyer: string, seller: string>, canTrade: bool, canWithdraw: bool, canDeposit: bool, brokered: bool, requireSelfTradePrevention: bool, preventSor: bool, updateTime: int, accountType: string, balances: table<asset: string, free: string, locked: string>, permissions: list<string>, uid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Trade List (USER_DATA)
#
# GET /api/v3/myTrades
export def "my-trades get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --orderId: int # This can only be used in combination with symbol. (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --fromId: int # Trade id to fetch from. Default gets most recent trades. (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, id: int, orderId: int, orderListId: int, price: string, qty: string, quoteQty: string, commission: string, commissionAsset: string, time: int, isBuyer: bool, isMaker: bool, isBestMatch: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/myTrades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Current Order Count Usage (TRADE)
#
# GET /api/v3/rateLimit/order
export def "rate-limit-order get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<rateLimitType: string, interval: string, intervalNum: int, limit: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/rateLimit/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Prevented Matches
#
# GET /api/v3/myPreventedMatches
export def "my-prevented-matches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --preventedMatchId: int # format: int64, e.g. 1
  --orderId: int # Order id (format: int64)
  --fromPreventedMatchId: int # format: int64, e.g. 1
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, preventedMatchId: int, takerOrderId: int, makerOrderId: int, tradeGroupId: int, selfTradePreventionMode: string, price: string, makerPreventedQuantity: string, transactTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "preventedMatchId" $preventedMatchId "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "fromPreventedMatchId" $fromPreventedMatchId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/myPreventedMatches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Allocations (USER_DATA)
#
# GET /api/v3/myAllocations
export def "my-allocations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --fromAllocationId: int # format: int64
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --orderId: int # Order id (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, allocationId: int, allocationType: string, orderId: int, orderListId: int, price: string, qty: string, quoteQty: string, commission: string, commissionAsset: string, time: int, isBuyer: bool, isMaker: bool, isAllocator: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "fromAllocationId" $fromAllocationId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/myAllocations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Commission Rates (USER_DATA)
#
# GET /api/v3/account/commission
export def "account-commission get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<symbol: string, standardCommission: record<maker: string, taker: string, buyer: string, seller: string>, taxCommission: record<maker: string, taker: string, buyer: string, seller: string>, discount: record<enabledForAccount: bool, enabledForSymbol: bool, discountAsset: string, discount: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/account/commission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin account borrow/repay(MARGIN)
#
# POST /sapi/v1/margin/borrow-repay
export def "sapi-margin-borrow-repay post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --isIsolated: string # TRUE for isolated margin, FALSE for crossed margin
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --amount: float # format: double, e.g. 1.01
  --type: string # BORROW or REPAY
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/borrow-repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query borrow/repay records in Margin account(USER_DATA)
#
# GET /sapi/v1/margin/borrow-repay
export def "sapi-margin-borrow-repay get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --isolatedSymbol: string # Isolated symbol
  --txId: int # tranId in POST /sapi/v1/margin/loan (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --type: string # BORROW or REPAY
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<isolatedSymbol: string, amount: string, asset: string, interest: string, principal: string, status: string, timestamp: int, txId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "txId" $txId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/borrow-repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Cross Margin Transfer History (USER_DATA)
#
# GET /sapi/v1/margin/transfer
export def "sapi-margin-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --type: string@type-completer-2
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --isolatedSymbol: string # Isolated symbol
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<amount: string, asset: string, status: string, timestamp: int, txId: int, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Margin Assets (MARKET_DATA)
#
# GET /sapi/v1/margin/allAssets
export def "sapi-margin-all-assets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
]: nothing -> table<assetFullName: string, assetName: string, isBorrowable: bool, isMortgageable: bool, userMinBorrow: string, userMinRepay: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/allAssets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Cross Margin Pairs (MARKET_DATA)
#
# GET /sapi/v1/margin/allPairs
export def "sapi-margin-all-pairs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
]: nothing -> table<base: string, id: int, isBuyAllowed: bool, isMarginTrade: bool, isSellAllowed: bool, quote: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/allPairs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin PriceIndex (MARKET_DATA)
#
# GET /sapi/v1/margin/priceIndex
export def "sapi-margin-price-index get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
]: nothing -> record<calcTime: int, price: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/priceIndex" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's Order (USER_DATA)
#
# GET /sapi/v1/margin/order
export def "sapi-margin-order get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --orderId: int # Order id (format: int64)
  --origClientOrderId: string # Order id from client
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<clientOrderId: string, cummulativeQuoteQty: string, executedQty: string, icebergQty: string, isWorking: bool, orderId: int, origQty: string, price: string, side: string, status: string, stopPrice: string, symbol: string, isIsolated: bool, time: int, timeInForce: string, type: string, updateTime: int, selfTradePreventionMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account New Order (TRADE)
#
# POST /sapi/v1/margin/order
export def "sapi-margin-order post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --side: string@side-completer # e.g. SELL
  --type: string@type-completer-1 # Order type (e.g. LIMIT)
  --quantity: float # format: double, e.g. 1.0
  --quoteOrderQty: float # Quote quantity (format: double)
  --price: float # Order price (format: double, e.g. 219.0)
  --stopPrice: float # Used with STOP_LOSS, STOP_LOSS_LIMIT, TAKE_PROFIT, and TAKE_PROFIT_LIMIT orders. (format: double, e.g. 221.01)
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --icebergQty: float # Used with LIMIT, STOP_LOSS_LIMIT, and TAKE_PROFIT_LIMIT to create an iceberg order. (format: double)
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --sideEffectType: string@sideEffectType-completer # Default `NO_SIDE_EFFECT`
  --timeInForce: string@timeInForce-completer # Order time in force (e.g. GTC)
  --autoRepayAtCancel: string@bool-completer # e.g. true
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "quoteOrderQty" $quoteOrderQty "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "stopPrice" $stopPrice "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "icebergQty" $icebergQty "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "sideEffectType" $sideEffectType "scalar") (serialize-qp "timeInForce" $timeInForce "scalar") (serialize-qp "autoRepayAtCancel" $autoRepayAtCancel "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account Cancel Order (TRADE)
#
# DELETE /sapi/v1/margin/order
export def "sapi-margin-order delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --orderId: int # Order id (format: int64)
  --origClientOrderId: string # Order id from client
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<symbol: string, orderId: int, origClientOrderId: string, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Interest History (USER_DATA)
#
# GET /sapi/v1/margin/interestHistory
export def "sapi-margin-interest-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --isolatedSymbol: string # Isolated symbol
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --archived: string # Default: false. Set to true for archived data from 6 months ago
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<isolatedSymbol: string, asset: string, interest: string, interestAccuredTime: int, interestRate: string, principal: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/interestHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Force Liquidation Record (USER_DATA)
#
# GET /sapi/v1/margin/forceLiquidationRec
export def "sapi-margin-force-liquidation-rec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --isolatedSymbol: string # Isolated symbol
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<avgPrice: string, executedQty: string, orderId: int, price: string, qty: string, side: string, symbol: string, timeInForce: string, isIsolated: bool, updatedTime: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/forceLiquidationRec" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Cross Margin Account Details (USER_DATA)
#
# GET /sapi/v1/margin/account
export def "sapi-margin-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<created: bool, borrowEnabled: bool, marginLevel: string, collateralMarginLevel: string, totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string, TotalCollateralValueInUSDT: string, tradeEnabled: bool, transferInEnabled: bool, transferOutEnabled: bool, accountType: string, userAssets: table<asset: string, borrowed: string, free: string, interest: string, locked: string, netAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's Open Orders (USER_DATA)
#
# GET /sapi/v1/margin/openOrders
export def "sapi-margin-open-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<clientOrderId: string, cummulativeQuoteQty: string, executedQty: string, icebergQty: string, isWorking: bool, orderId: int, origQty: string, price: string, side: string, status: string, stopPrice: string, symbol: string, isIsolated: bool, time: int, timeInForce: string, type: string, updateTime: int, selfTradePreventionMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account Cancel all Open Orders on a Symbol (TRADE)
#
# DELETE /sapi/v1/margin/openOrders
export def "sapi-margin-open-orders delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's All Orders (USER_DATA)
#
# GET /sapi/v1/margin/allOrders
export def "sapi-margin-all-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --orderId: int # Order id (format: int64)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<clientOrderId: string, cummulativeQuoteQty: string, executedQty: string, icebergQty: string, isWorking: bool, orderId: int, origQty: string, price: string, side: string, status: string, stopPrice: string, symbol: string, isIsolated: bool, time: int, timeInForce: string, type: string, updateTime: int, selfTradePreventionMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/allOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account New OCO (TRADE)
#
# POST /sapi/v1/margin/order/oco
export def "sapi-margin-order-oco post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --listClientOrderId: string # A unique Id for the entire orderList
  --side: string@side-completer # e.g. SELL
  --quantity: float # format: double, e.g. 1.0
  --limitClientOrderId: string # A unique Id for the limit order
  --price: float # Order price (format: double, e.g. 218.0)
  --limitIcebergQty: float # format: double
  --stopClientOrderId: string # A unique Id for the stop loss/stop loss limit leg
  --stopPrice: float # format: double, e.g. 220.0
  --stopLimitPrice: float # If provided, stopLimitTimeInForce is required. (format: double)
  --stopIcebergQty: float # format: double
  --stopLimitTimeInForce: string@stopLimitTimeInForce-completer
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --sideEffectType: string@sideEffectType-completer # Default `NO_SIDE_EFFECT`
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, marginBuyBorrowAmount: string, marginBuyBorrowAsset: string, isIsolated: bool, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "limitClientOrderId" $limitClientOrderId "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "limitIcebergQty" $limitIcebergQty "scalar") (serialize-qp "stopClientOrderId" $stopClientOrderId "scalar") (serialize-qp "stopPrice" $stopPrice "scalar") (serialize-qp "stopLimitPrice" $stopLimitPrice "scalar") (serialize-qp "stopIcebergQty" $stopIcebergQty "scalar") (serialize-qp "stopLimitTimeInForce" $stopLimitTimeInForce "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "sideEffectType" $sideEffectType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order/oco" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's OCO (USER_DATA)
#
# GET /sapi/v1/margin/orderList
export def "sapi-margin-order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --symbol: string # Mandatory for isolated margin, not supported for cross margin
  --orderListId: int # Order list id (format: int64)
  --origClientOrderId: string # Order id from client
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: table<symbol: string, orderId: int, clientOrderId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "orderListId" $orderListId "scalar") (serialize-qp "origClientOrderId" $origClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/orderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account Cancel OCO (TRADE)
#
# DELETE /sapi/v1/margin/orderList
export def "sapi-margin-order-list delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --orderListId: int # Order list id (format: int64)
  --listClientOrderId: string # A unique Id for the entire orderList
  --newClientOrderId: string # Used to uniquely identify this cancel. Automatically generated by default
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, origClientOrderId: string, orderId: int, orderListId: int, clientOrderId: string, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, stopPrice: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "orderListId" $orderListId "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newClientOrderId" $newClientOrderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/orderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's all OCO (USER_DATA)
#
# GET /sapi/v1/margin/allOrderList
export def "sapi-margin-all-order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --symbol: string # Mandatory for isolated margin, not supported for cross margin
  --fromId: string # If supplied, neither `startTime` or `endTime` can be provided
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default Value: 500; Max Value: 1000 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/allOrderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's Open OCO (USER_DATA)
#
# GET /sapi/v1/margin/openOrderList
export def "sapi-margin-open-order-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --symbol: string # Mandatory for isolated margin, not supported for cross margin
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/openOrderList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Account's Trade List (USER_DATA)
#
# GET /sapi/v1/margin/myTrades
export def "sapi-margin-my-trades get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --fromId: int # Trade id to fetch from. Default gets most recent trades. (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<commission: string, commissionAsset: string, id: int, isBestMatch: bool, isBuyer: bool, isMaker: bool, orderId: int, price: string, qty: string, symbol: string, isIsolated: bool, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/myTrades" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Max Borrow (USER_DATA)
#
# GET /sapi/v1/margin/maxBorrowable
export def "sapi-margin-max-borrowable get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --isolatedSymbol: string # Isolated symbol
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<amount: string, borrowLimit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/maxBorrowable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Max Transfer-Out Amount (USER_DATA)
#
# GET /sapi/v1/margin/maxTransferable
export def "sapi-margin-max-transferable get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --isolatedSymbol: string # Isolated symbol
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<amount: string, borrowLimit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "isolatedSymbol" $isolatedSymbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/maxTransferable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Summary of Margin account (USER_DATA)
#
# GET /sapi/v1/margin/tradeCoeff
export def "sapi-margin-trade-coeff get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Email Address (e.g. me@email.com)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<normalBar: string, marginCallBar: string, forceLiquidationBar: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/tradeCoeff" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Isolated Margin Account Info (USER_DATA)
#
# GET /sapi/v1/margin/isolated/account
export def "sapi-margin-isolated-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbols: string # Max 5 symbols can be sent; separated by ',' (e.g. BTCUSDT,BNBUSDT,ADAUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<assets: table<baseAsset: record, quoteAsset: record, symbol: string, isolatedCreated: bool, enabled: bool, marginLevel: string, marginLevelStatus: string, marginRatio: string, indexPrice: string, liquidatePrice: string, liquidateRate: string, tradeEnabled: bool>, totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbols" $symbols "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolated/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Isolated Margin Account (TRADE)
#
# DELETE /sapi/v1/margin/isolated/account
export def "sapi-margin-isolated-account delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolated/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Isolated Margin Account (TRADE)
#
# POST /sapi/v1/margin/isolated/account
export def "sapi-margin-isolated-account post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolated/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Enabled Isolated Margin Account Limit (USER_DATA)
#
# GET /sapi/v1/margin/isolated/accountLimit
export def "sapi-margin-isolated-account-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<enabledAccount: int, maxAccount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolated/accountLimit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Isolated Margin Symbol(USER_DATA)
#
# GET /sapi/v1/margin/isolated/allPairs
export def "sapi-margin-isolated-all-pairs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, base: string, quote: string, isMarginTrade: bool, isBuyAllowed: bool, isSellAllowed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolated/allPairs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle BNB Burn On Spot Trade And Margin Interest (USER_DATA)
#
# POST /sapi/v1/bnbBurn
export def "sapi-bnb-burn post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --spotBNBBurn: string@spotBNBBurn-completer # Determines whether to use BNB to pay for trading fees on SPOT (e.g. true)
  --interestBNBBurn: string@interestBNBBurn-completer # Determines whether to use BNB to pay for margin loan's interest (e.g. false)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<spotBNBBurn: bool, interestBNBBurn: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spotBNBBurn" $spotBNBBurn "scalar") (serialize-qp "interestBNBBurn" $interestBNBBurn "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/bnbBurn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get BNB Burn Status(USER_DATA)
#
# GET /sapi/v1/bnbBurn
export def "sapi-bnb-burn get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<spotBNBBurn: bool, interestBNBBurn: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/bnbBurn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Interest Rate History (USER_DATA)
#
# GET /sapi/v1/margin/interestRateHistory
export def "sapi-margin-interest-rate-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, dailyInterestRate: string, timestamp: int, vipLevel: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/interestRateHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Cross Margin Fee Data (USER_DATA)
#
# GET /sapi/v1/margin/crossMarginData
export def "sapi-margin-cross-margin-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --coin: string # Coin name (e.g. BNB)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<vipLevel: int, coin: string, transferIn: bool, borrowable: bool, dailyInterest: string, yearlyInterest: string, borrowLimit: string, marginablePairs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/crossMarginData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Isolated Margin Fee Data (USER_DATA)
#
# GET /sapi/v1/margin/isolatedMarginData
export def "sapi-margin-isolated-margin-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<vipLevel: int, symbol: string, leverage: string, data: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolatedMarginData" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Isolated Margin Tier Data (USER_DATA)
#
# GET /sapi/v1/margin/isolatedMarginTier
export def "sapi-margin-isolated-margin-tier get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --tier: string # All margin tier data will be returned if tier is omitted (e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, tier: int, effectiveMultiple: string, initialRiskRatio: string, liquidationRiskRatio: string, baseAssetMaxBorrowable: string, quoteAssetMaxBorrowable: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "tier" $tier "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/isolatedMarginTier" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Current Margin Order Count Usage (TRADE)
#
# GET /sapi/v1/margin/rateLimit/order
export def "sapi-margin-rate-limit-order get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isIsolated: string # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --symbol: string # isolated symbol, mandatory for isolated margin
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<rateLimitType: string, interval: string, intervalNum: int, limit: int, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/rateLimit/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cross margin collateral ratio (MARKET_DATA)
#
# GET /sapi/v1/margin/crossMarginCollateralRatio
export def "sapi-margin-cross-margin-collateral-ratio get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<collaterals: list<record>, assetNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/margin/crossMarginCollateralRatio")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Small Liability Exchange Coin List (USER_DATA)
#
# GET /sapi/v1/margin/exchange-small-liability
export def "sapi-margin-exchange-small-liability get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, interest: string, principal: string, liabilityAsset: string, liabilityQty: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/exchange-small-liability" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Small Liability Exchange History (USER_DATA)
#
# GET /sapi/v1/margin/exchange-small-liability-history
export def "sapi-margin-exchange-small-liability-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<asset: string, amount: string, targetAsset: string, targetAmount: string, bizType: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/exchange-small-liability-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a future hourly interest rate (USER_DATA)
#
# GET /sapi/v1/margin/next-hourly-interest-rate
export def "sapi-margin-next-hourly-interest-rate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assets: string # List of assets, separated by commas, up to 20 (e.g. BTC,ETH)
  --isIsolated: string@isIsolated-completer # for isolated margin or not, "TRUE", "FALSE" (e.g. TRUE)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, nextHourlyInterestRate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assets" $assets "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/next-hourly-interest-rate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get cross or isolated margin capital flow(USER_DATA)
#
# GET /sapi/v1/margin/capital-flow
export def "sapi-margin-capital-flow get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --symbol: string # Required when querying isolated data (e.g. BTCUSDT)
  --type: string@type-completer-3
  --startTime: int # Only supports querying the data of the last 90 days (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --fromId: int # If fromId is set, the data with id > fromId will be returned. Otherwise the latest data will be returned (format: int64)
  --limit: int # The number of data items returned each time is limited. Default 500; Max 1000. (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<id: int, tranId: int, timestamp: int, asset: string, symbol: string, type: string, amount: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "fromId" $fromId "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/capital-flow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tokens or symbols delist schedule for cross margin and isolated margin (MARKET_DATA)
#
# GET /sapi/v1/margin/delist-schedule
export def "sapi-margin-delist-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<delistTime: int, crossMarginAssets: list<string>, isolatedMarginSymbols: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/delist-schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Margin Available Inventory (USER_DATA)
#
# GET /sapi/v1/margin/available-inventory
export def "sapi-margin-available-inventory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<assets: record<MATIC: string, STPT: string, TVK: string, SHIB: string>, updateTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/available-inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin manual liquidation(MARGIN)
#
# POST /sapi/v1/margin/manual-liquidation
export def "sapi-margin-manual-liquidation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4
  --symbol: string # e.g. BTCUSDT
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, interest: string, principal: string, liabilityAsset: string, liabilityQty: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/manual-liquidation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account New OTO (TRADE)
#
# POST /sapi/v1/margin/order/oto
export def "sapi-margin-order-oto post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --listClientOrderId: string # Arbitrary unique ID among open order lists. Automatically generated if not sent. A new order list with the same `listClientOrderId` is accepted only when the previous one is filled or completely expired. `listClientOrderId` is distinct from the `workingClientOrderId` and the `pendingClientOrderId`.
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --sideEffectType: string@sideEffectType-completer-1 # Default `NO_SIDE_EFFECT`
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --autoRepayAtCancel: string@bool-completer # Only when MARGIN_BUY order takes effect, true means that the debt generated by the order needs to be repay after the order is cancelled. The default is true (e.g. true)
  --workingType: string@workingType-completer # Supported values: LIMIT,LIMIT_MAKER
  --workingSide: string@workingSide-completer # BUY,SELL
  --workingClientOrderId: string # Arbitrary unique ID among open orders for the working order. Automatically generated if not sent.
  --workingPrice: float # format: double
  --workingQuantity: float # Sets the quantity for the working order. (format: double)
  --workingIcebergQty: float # This can only be used if workingTimeInForce is GTC. (format: double)
  --workingTimeInForce: string@workingTimeInForce-completer # GTC, IOC, FOK
  --pendingType: string@pendingType-completer # Supported values: Order Types Note that MARKET orders using quoteOrderQty are not supported.
  --pendingSide: string@pendingSide-completer # BUY,SELL
  --pendingClientOrderId: string # Arbitrary unique ID among open orders for the pending order. Automatically generated if not sent.
  --pendingPrice: float # format: double
  --pendingStopPrice: float # format: double
  --pendingTrailingDelta: float # format: double
  --pendingQuantity: float # Sets the quantity for the pending order. (format: double)
  --pendingIcebergQty: float # This can only be used if pendingTimeInForce is GTC. (format: double)
  --pendingTimeInForce: string@pendingTimeInForce-completer # GTC, IOC, FOK
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "sideEffectType" $sideEffectType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "autoRepayAtCancel" $autoRepayAtCancel "scalar") (serialize-qp "workingType" $workingType "scalar") (serialize-qp "workingSide" $workingSide "scalar") (serialize-qp "workingClientOrderId" $workingClientOrderId "scalar") (serialize-qp "workingPrice" $workingPrice "scalar") (serialize-qp "workingQuantity" $workingQuantity "scalar") (serialize-qp "workingIcebergQty" $workingIcebergQty "scalar") (serialize-qp "workingTimeInForce" $workingTimeInForce "scalar") (serialize-qp "pendingType" $pendingType "scalar") (serialize-qp "pendingSide" $pendingSide "scalar") (serialize-qp "pendingClientOrderId" $pendingClientOrderId "scalar") (serialize-qp "pendingPrice" $pendingPrice "scalar") (serialize-qp "pendingStopPrice" $pendingStopPrice "scalar") (serialize-qp "pendingTrailingDelta" $pendingTrailingDelta "scalar") (serialize-qp "pendingQuantity" $pendingQuantity "scalar") (serialize-qp "pendingIcebergQty" $pendingIcebergQty "scalar") (serialize-qp "pendingTimeInForce" $pendingTimeInForce "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order/oto" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Account New OTOCO (TRADE)
#
# POST /sapi/v1/margin/order/otoco
export def "sapi-margin-order-otoco post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --isIsolated: string@isIsolated-completer # * `TRUE` - For isolated margin * `FALSE` - Default, not for isolated margin
  --sideEffectType: string@sideEffectType-completer-1 # Default `NO_SIDE_EFFECT`
  --autoRepayAtCancel: string@bool-completer # Only when MARGIN_BUY order takes effect, true means that the debt generated by the order needs to be repay after the order is cancelled. The default is true (e.g. true)
  --listClientOrderId: string # Arbitrary unique ID among open order lists. Automatically generated if not sent. A new order list with the same `listClientOrderId` is accepted only when the previous one is filled or completely expired. `listClientOrderId` is distinct from the `workingClientOrderId` and the `pendingClientOrderId`.
  --newOrderRespType: string@newOrderRespType-completer # Set the response JSON.
  --selfTradePreventionMode: string@selfTradePreventionMode-completer # The allowed enums is dependent on what is configured on the symbol. The possible supported values are EXPIRE_TAKER, EXPIRE_MAKER, EXPIRE_BOTH, NONE. (e.g. EXPIRE_TAKER)
  --workingType: string@workingType-completer # Supported values: LIMIT,LIMIT_MAKER
  --workingSide: string@workingSide-completer # BUY,SELL
  --workingClientOrderId: string # Arbitrary unique ID among open orders for the working order. Automatically generated if not sent.
  --workingPrice: float # format: double
  --workingQuantity: float # Sets the quantity for the working order. (format: double)
  --workingIcebergQty: float # This can only be used if workingTimeInForce is GTC. (format: double)
  --workingTimeInForce: string@workingTimeInForce-completer # GTC, IOC, FOK
  --pendingSide: string@pendingSide-completer # BUY,SELL
  --pendingQuantity: float # Sets the quantity for the pending order. (format: double)
  --pendingAboveType: string@pendingAboveType-completer # Supported values: LIMIT_MAKER, STOP_LOSS, and STOP_LOSS_LIMIT
  --pendingAboveClientOrderId: string # Arbitrary unique ID among open orders for the pending above order. Automatically generated if not sent.
  --pendingAbovePrice: float # format: double
  --pendingAboveStopPrice: float # format: double
  --pendingAboveTrailingDelta: float # format: double
  --pendingAboveIcebergQty: float # This can only be used if pendingAboveTimeInForce is GTC. (format: double)
  --pendingAboveTimeInForce: string@pendingAboveTimeInForce-completer
  --pendingBelowType: string@pendingBelowType-completer # Supported values: LIMIT_MAKER, STOP_LOSS, and STOP_LOSS_LIMIT
  --pendingBelowClientOrderId: string # Arbitrary unique ID among open orders for the pending below order. Automatically generated if not sent.
  --pendingBelowPrice: float # format: double
  --pendingBelowStopPrice: float # format: double
  --pendingBelowTrailingDelta: float # format: double
  --pendingBelowIcebergQty: float # This can only be used if pendingBelowTimeInForce is GTC. (format: double)
  --pendingBelowTimeInForce: string@pendingBelowTimeInForce-completer
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderListId: int, contingencyType: string, listStatusType: string, listOrderStatus: string, listClientOrderId: string, transactionTime: int, symbol: string, isIsolated: bool, orders: table<symbol: string, orderId: int, clientOrderId: string>, orderReports: table<symbol: string, orderId: int, orderListId: int, clientOrderId: string, transactTime: int, price: string, origQty: string, executedQty: string, cummulativeQuoteQty: string, status: string, timeInForce: string, type: string, side: string, selfTradePreventionMode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "isIsolated" $isIsolated "scalar") (serialize-qp "sideEffectType" $sideEffectType "scalar") (serialize-qp "autoRepayAtCancel" $autoRepayAtCancel "scalar") (serialize-qp "listClientOrderId" $listClientOrderId "scalar") (serialize-qp "newOrderRespType" $newOrderRespType "scalar") (serialize-qp "selfTradePreventionMode" $selfTradePreventionMode "scalar") (serialize-qp "workingType" $workingType "scalar") (serialize-qp "workingSide" $workingSide "scalar") (serialize-qp "workingClientOrderId" $workingClientOrderId "scalar") (serialize-qp "workingPrice" $workingPrice "scalar") (serialize-qp "workingQuantity" $workingQuantity "scalar") (serialize-qp "workingIcebergQty" $workingIcebergQty "scalar") (serialize-qp "workingTimeInForce" $workingTimeInForce "scalar") (serialize-qp "pendingSide" $pendingSide "scalar") (serialize-qp "pendingQuantity" $pendingQuantity "scalar") (serialize-qp "pendingAboveType" $pendingAboveType "scalar") (serialize-qp "pendingAboveClientOrderId" $pendingAboveClientOrderId "scalar") (serialize-qp "pendingAbovePrice" $pendingAbovePrice "scalar") (serialize-qp "pendingAboveStopPrice" $pendingAboveStopPrice "scalar") (serialize-qp "pendingAboveTrailingDelta" $pendingAboveTrailingDelta "scalar") (serialize-qp "pendingAboveIcebergQty" $pendingAboveIcebergQty "scalar") (serialize-qp "pendingAboveTimeInForce" $pendingAboveTimeInForce "scalar") (serialize-qp "pendingBelowType" $pendingBelowType "scalar") (serialize-qp "pendingBelowClientOrderId" $pendingBelowClientOrderId "scalar") (serialize-qp "pendingBelowPrice" $pendingBelowPrice "scalar") (serialize-qp "pendingBelowStopPrice" $pendingBelowStopPrice "scalar") (serialize-qp "pendingBelowTrailingDelta" $pendingBelowTrailingDelta "scalar") (serialize-qp "pendingBelowIcebergQty" $pendingBelowIcebergQty "scalar") (serialize-qp "pendingBelowTimeInForce" $pendingBelowTimeInForce "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/order/otoco" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adjust cross margin max leverage (USER_DATA)
#
# POST /sapi/v1/margin/max-leverage
export def "sapi-margin-max-leverage post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxLeverage: int # Can only adjust 3 or 5 (e.g. 3)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxLeverage" $maxLeverage "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/margin/max-leverage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Liability Coin Leverage Bracket in Cross Margin Pro Mode (MARKET_DATA)
#
# GET /sapi/v1/margin/leverageBracket
export def "sapi-margin-leverage-bracket get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<assetNames: list<string>, rank: int, brackets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/margin/leverageBracket")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# System Status (System)
#
# GET /sapi/v1/system/status
export def "sapi-system-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/system/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All Coins' Information (USER_DATA)
#
# GET /sapi/v1/capital/config/getall
export def "sapi-capital-config-getall get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<coin: string, depositAllEnable: bool, free: string, freeze: string, ipoable: string, ipoing: string, isLegalMoney: bool, locked: string, name: string, networkList: list<record>, storage: string, trading: bool, withdrawAllEnable: bool, withdrawing: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/config/getall" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Daily Account Snapshot (USER_DATA)
#
# GET /sapi/v1/accountSnapshot
export def "sapi-account-snapshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-5
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # format: int32, default: 7
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/accountSnapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Fast Withdraw Switch (USER_DATA)
#
# POST /sapi/v1/account/disableFastWithdrawSwitch
export def "sapi-account-disable-fast-withdraw-switch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/disableFastWithdrawSwitch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Fast Withdraw Switch (USER_DATA)
#
# POST /sapi/v1/account/enableFastWithdrawSwitch
export def "sapi-account-enable-fast-withdraw-switch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/enableFastWithdrawSwitch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Withdraw (USER_DATA)
#
# POST /sapi/v1/capital/withdraw/apply
export def "sapi-capital-withdraw-apply post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # Coin name (e.g. BNB)
  --withdrawOrderId: string # Client id for withdraw
  --network: string # e.g. BTC
  --address: string
  --addressTag: string # Secondary address identifier for coins like XRP,XMR etc.
  --amount: float # format: double, e.g. 1.01
  --transactionFeeFlag: string@bool-completer # When making internal transfer - `true` ->  returning the fee to the destination account; - `false` -> returning the fee back to the departure account. (default: false)
  --name: string
  --walletType: int # The wallet type for withdraw，0-Spot wallet, 1- Funding wallet. Default is Spot wallet (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "withdrawOrderId" $withdrawOrderId "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "address" $address "scalar") (serialize-qp "addressTag" $addressTag "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "transactionFeeFlag" $transactionFeeFlag "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "walletType" $walletType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/withdraw/apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deposit History(supporting network) (USER_DATA)
#
# GET /sapi/v1/capital/deposit/hisrec
export def "sapi-capital-deposit-hisrec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # Coin name (e.g. BNB)
  --status: int # * `0` - pending * `6` - credited but cannot withdraw * `1` - success (format: int32)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --offset: int # format: int32
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<amount: string, coin: string, network: string, status: int, address: string, addressTag: string, txId: string, insertTime: int, transferType: int, unlockConfirm: string, confirmTimes: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/hisrec" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Withdraw History (supporting network) (USER_DATA)
#
# GET /sapi/v1/capital/withdraw/history
export def "sapi-capital-withdraw-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # Coin name (e.g. BNB)
  --withdrawOrderId: string
  --status: int # * `0` - Email Sent * `1` - Cancelled * `2` - Awaiting Approval * `3` - Rejected * `4` - Processing * `5` - Failure * `6` - Completed (format: int32)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --offset: int # format: int32
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<address: string, amount: string, applyTime: string, coin: string, id: string, withdrawOrderId: string, network: string, transferType: int, status: int, transactionFee: string, confirmNo: int, info: string, txId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "withdrawOrderId" $withdrawOrderId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/withdraw/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deposit Address (supporting network) (USER_DATA)
#
# GET /sapi/v1/capital/deposit/address
export def "sapi-capital-deposit-address get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # Coin name (e.g. BNB)
  --network: string # e.g. BTC
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<address: string, coin: string, tag: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Status (USER_DATA)
#
# GET /sapi/v1/account/status
export def "sapi-account-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<data: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account API Trading Status (USER_DATA)
#
# GET /sapi/v1/account/apiTradingStatus
export def "sapi-account-api-trading-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<data: record<isLocked: bool, plannedRecoverTime: int, triggerCondition: record<GCR: int, IFER: int, UFR: int>, indicators: record<BTCUSDT: list>, updateTime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/apiTradingStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DustLog(USER_DATA)
#
# GET /sapi/v1/asset/dribblet
export def "sapi-asset-dribblet get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountType: string@accountType-completer # SPOT or MARGIN, default SPOT
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, userAssetDribblets: table<operateTime: int, totalTransferedAmount: string, totalServiceChargeAmount: string, transId: int, userAssetDribbletDetails: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountType" $accountType "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/dribblet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Assets That Can Be Converted Into BNB (USER_DATA)
#
# POST /sapi/v1/asset/dust-btc
export def "sapi-asset-dust-btc post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountType: string@accountType-completer # SPOT or MARGIN, default SPOT
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<details: table<asset: string, assetFullName: string, amountFree: string, toBTC: string, toBNB: string, toBNBOffExchange: string, exchange: string>, totalTransferBtc: string, totalTransferBNB: string, dribbletPercentage: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountType" $accountType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/dust-btc" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dust Transfer (USER_DATA)
#
# POST /sapi/v1/asset/dust
export def "sapi-asset-dust post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: list # The asset being converted. For example, asset=BTC&asset=USDT
  --accountType: string@accountType-completer # SPOT or MARGIN, default SPOT
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalServiceCharge: string, totalTransfered: string, transferResult: table<amount: string, fromAsset: string, operateTime: int, serviceChargeAmount: string, tranId: int, transferedAmount: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "multi") (serialize-qp "accountType" $accountType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/dust" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Asset Dividend Record (USER_DATA)
#
# GET /sapi/v1/asset/assetDividend
export def "sapi-asset-asset-dividend get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # format: int32, default: 20
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<id: int, amount: string, asset: string, divTime: int, enInfo: string, tranId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/assetDividend" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Asset Detail (USER_DATA)
#
# GET /sapi/v1/asset/assetDetail
export def "sapi-asset-asset-detail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<CTR: record<minWithdrawAmount: string, depositStatus: bool, withdrawFee: int, withdrawStatus: bool, depositTip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/assetDetail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trade Fee (USER_DATA)
#
# GET /sapi/v1/asset/tradeFee
export def "sapi-asset-trade-fee get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<symbol: string, makerCommission: string, takerCommission: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/tradeFee" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Universal Transfer History (USER_DATA)
#
# GET /sapi/v1/asset/transfer
export def "sapi-asset-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-6 # Universal transfer type (e.g. MAIN_C2C)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --fromSymbol: string # Must be sent when type are ISOLATEDMARGIN_MARGIN and ISOLATEDMARGIN_ISOLATEDMARGIN (e.g. BNBUSDT)
  --toSymbol: string # Must be sent when type are MARGIN_ISOLATEDMARGIN and ISOLATEDMARGIN_ISOLATEDMARGIN (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<asset: string, amount: string, type: string, status: string, tranId: int, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "fromSymbol" $fromSymbol "scalar") (serialize-qp "toSymbol" $toSymbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Universal Transfer (USER_DATA)
#
# POST /sapi/v1/asset/transfer
export def "sapi-asset-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-6 # Universal transfer type (e.g. MAIN_C2C)
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --fromSymbol: string # Must be sent when type are ISOLATEDMARGIN_MARGIN and ISOLATEDMARGIN_ISOLATEDMARGIN (e.g. BNBUSDT)
  --toSymbol: string # Must be sent when type are MARGIN_ISOLATEDMARGIN and ISOLATEDMARGIN_ISOLATEDMARGIN (e.g. BNBUSDT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "fromSymbol" $fromSymbol "scalar") (serialize-qp "toSymbol" $toSymbol "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Funding Wallet (USER_DATA)
#
# POST /sapi/v1/asset/get-funding-asset
export def "sapi-asset-get-funding-asset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --needBtcValuation: string@needBtcValuation-completer
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, free: string, locked: string, freeze: string, withdrawing: string, btcValuation: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "needBtcValuation" $needBtcValuation "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/get-funding-asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# User Asset (USER_DATA)
#
# POST /sapi/v3/asset/getUserAsset
export def "sapi-asset-get-user-asset post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --needBtcValuation: string@needBtcValuation-completer
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, free: string, locked: string, freeze: string, withdrawing: string, ipoable: string, btcValuation: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "needBtcValuation" $needBtcValuation "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v3/asset/getUserAsset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert Transfer (USER_DATA)
#
# POST /sapi/v1/asset/convert-transfer
export def "sapi-asset-convert-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientTranId: string # The unique flag, the min length is 20
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --targetAsset: string # Target asset you want to convert (e.g. BNB)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientTranId" $clientTranId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "targetAsset" $targetAsset "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/convert-transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Convert Transfer (USER_DATA)
#
# GET /sapi/v1/asset/convert-transfer/queryByPage
export def "sapi-asset-convert-transfer-query-by-page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tranId: int # The transaction id (format: int64, e.g. 118263615991)
  --asset: string # If it is blank, we will match deducted asset and target asset. (e.g. BTC)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --accountType: string@accountType-completer-1 # MAIN: main account. CARD: funding account. If it is blank, we will query spot and card wallet, otherwise, we just query the corresponding wallet
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<tranId: int, type: int, time: int, deductedAsset: string, deductedAmount: string, targetAsset: string, targetAmount: string, status: string, accountType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tranId" $tranId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "accountType" $accountType "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/convert-transfer/queryByPage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Cloud-Mining payment and refund history (USER_DATA)
#
# GET /sapi/v1/asset/ledger-transfer/cloud-mining/queryByPage
export def "sapi-asset-ledger-transfer-cloud-mining-query-by-page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tranId: int # The transaction id (format: int64, e.g. 118263615991)
  --clientTranId: string # The unique flag
  --asset: string # If it is blank, we will query all assets (e.g. BTC)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<createTime: int, tranId: int, type: int, asset: string, amount: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tranId" $tranId "scalar") (serialize-qp "clientTranId" $clientTranId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/ledger-transfer/cloud-mining/queryByPage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API Key Permission (USER_DATA)
#
# GET /sapi/v1/account/apiRestrictions
export def "sapi-account-api-restrictions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<ipRestrict: bool, createTime: int, enableInternalTransfer: bool, enableFutures: bool, enablePortfolioMarginTrading: bool, enableVanillaOptions: bool, permitsUniversalTransfer: bool, enableReading: bool, enableSpotAndMarginTrading: bool, enableWithdrawals: bool, enableMargin: bool, tradingAuthorityExpirationTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/apiRestrictions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query auto-converting stable coins (USER_DATA)
#
# GET /sapi/v1/capital/contract/convertible-coins
export def "sapi-capital-contract-convertible-coins get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<convertEnabled: bool, coins: list<string>, exchangeRates: record<USDC: string, TUSD: string, USDP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/capital/contract/convertible-coins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Switch on/off BUSD and stable coins conversion (USER_DATA) (USER_DATA)
#
# POST /sapi/v1/capital/contract/convertible-coins
export def "sapi-capital-contract-convertible-coins post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # Must be USDC, USDP or TUSD
  --enable: string@bool-completer # true: turn on the auto-conversion. false: turn off the auto-conversion
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "enable" $enable "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/contract/convertible-coins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Virtual Sub-account(For Master Account)
#
# POST /sapi/v1/sub-account/virtualSubAccount
export def "sapi-sub-account-virtual-sub-account post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subAccountString: string # Please input a string. We will create a virtual email using that string for you to register
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subAccountString" $subAccountString "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/virtualSubAccount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Sub-account List (For Master Account)
#
# GET /sapi/v1/sub-account/list
export def "sapi-sub-account-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --isFreeze: string@isFreeze-completer
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 1; max 200 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<subAccounts: table<email: string, isFreeze: bool, createTime: int, isManagedSubAccount: bool, isAssetManagementSubAccount: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "isFreeze" $isFreeze "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Spot Asset Transfer History (For Master Account)
#
# GET /sapi/v1/sub-account/sub/transfer/history
export def "sapi-sub-account-sub-transfer-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromEmail: string # Sub-account email
  --toEmail: string # Sub-account email
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<from: string, to: string, asset: string, qty: string, status: string, tranId: int, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromEmail" $fromEmail "scalar") (serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/sub/transfer/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Futures Asset Transfer History (For Master Account)
#
# GET /sapi/v1/sub-account/futures/internalTransfer
export def "sapi-sub-account-futures-internal-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --futuresType: int # 1:USDT-margined Futures, 2: Coin-margined Futures (format: int32, e.g. 2)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default value: 50, Max value: 500 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, futuresType: int, transfers: table<from: string, to: string, asset: string, qty: string, tranId: int, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "futuresType" $futuresType "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/internalTransfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Futures Asset Transfer (For Master Account)
#
# POST /sapi/v1/sub-account/futures/internalTransfer
export def "sapi-sub-account-futures-internal-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromEmail: string # Sender email
  --toEmail: string # Recipient email
  --futuresType: int # 1:USDT-margined Futures,2: Coin-margined Futures (format: int32, e.g. 2)
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromEmail" $fromEmail "scalar") (serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "futuresType" $futuresType "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/internalTransfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Assets (For Master Account)
#
# GET /sapi/v3/sub-account/assets
export def "sapi-sub-account-assets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<balances: table<asset: string, free: int, locked: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v3/sub-account/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Spot Assets Summary (For Master Account)
#
# GET /sapi/v1/sub-account/spotSummary
export def "sapi-sub-account-spot-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --page: int # Default 1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:20 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalCount: int, masterAccountTotalAsset: string, spotSubUserAssetBtcVoList: table<email: string, totalAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/spotSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Spot Assets Summary (For Master Account)
#
# GET /sapi/v1/capital/deposit/subAddress
export def "sapi-capital-deposit-sub-address get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --coin: string # Coin name (e.g. BNB)
  --network: string # e.g. BTC
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<address: string, coin: string, tag: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/subAddress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Deposit History (For Master Account)
#
# GET /sapi/v1/capital/deposit/subHisrec
export def "sapi-capital-deposit-sub-hisrec get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --coin: string # Coin name (e.g. BNB)
  --status: int # 0(0:pending,6: credited but cannot withdraw, 1:success) (format: int32)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # format: int64
  --offset: int # format: int32
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<amount: string, coin: string, network: string, status: int, address: string, addressTag: string, txId: string, insertTime: int, transferType: int, confirmTimes: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/subHisrec" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# One click arrival deposit apply (USER_DATA)
#
# POST /sapi/v1/capital/deposit/credit-apply
export def "sapi-capital-deposit-credit-apply post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --depositId: int # Deposit record Id, priority use (format: int64)
  --txId: string # Deposit txId, used when depositId is not specified
  --subAccountId: int # format: int64
  --subUserId: int # format: int64
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: bool, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depositId" $depositId "scalar") (serialize-qp "txId" $txId "scalar") (serialize-qp "subAccountId" $subAccountId "scalar") (serialize-qp "subUserId" $subUserId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/credit-apply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Wallet Balance (USER_DATA)
#
# GET /sapi/v1/asset/wallet/balance
export def "sapi-asset-wallet-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<activate: bool, balance: string, walletName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/wallet/balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query User Delegation History(For Master Account) (USER_DATA)
#
# GET /sapi/v1/asset/custody/transfer-history
export def "sapi-asset-custody-transfer-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # e.g. alice@test.com
  --startTime: int # format: int64, e.g. 1695205406000
  --endTime: int # format: int64, e.g. 1695205396000
  --type: string # e.g. Delegate
  --asset: string # e.g. BTC
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<clientTranId: string, transferType: string, asset: string, amount: string, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/asset/custody/transfer-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch deposit address list with network (USER_DATA)
#
# GET /sapi/v1/capital/deposit/address/list
export def "sapi-capital-deposit-address-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --coin: string # e.g. BTC
  --network: string # e.g. BTC
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<coin: string, address: string, isDefault: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coin" $coin "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/capital/deposit/address/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get symbols delist schedule for spot (MARKET_DATA)
#
# GET /sapi/v1/spot/delist-schedule
export def "sapi-spot-delist-schedule get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<delistTime: int, symbol: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/spot/delist-schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch withdraw address list (USER_DATA)
#
# GET /sapi/v1/capital/withdraw/address/list
export def "sapi-capital-withdraw-address-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<address: string, addressTag: string, coin: string, name: string, network: string, origin: string, originType: string, whiteStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/capital/withdraw/address/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account info (USER_DATA)
#
# GET /sapi/v1/account/info
export def "sapi-account-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<vipLevel: int, isMarginEnabled: bool, isFutureEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/account/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account's Status on Margin/Futures (For Master Account)
#
# GET /sapi/v1/sub-account/status
export def "sapi-sub-account-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<email: string, isSubUserEnabled: bool, isUserActive: bool, insertTime: int, isMarginEnabled: bool, isFutureEnabled: bool, mobile: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Margin for Sub-account (For Master Account)
#
# POST /sapi/v1/sub-account/margin/enable
export def "sapi-sub-account-margin-enable post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, isMarginEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/margin/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail on Sub-account's Margin Account (For Master Account)
#
# GET /sapi/v1/sub-account/margin/account
export def "sapi-sub-account-margin-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, marginLevel: string, totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string, marginTradeCoeffVo: record<forceLiquidationBar: string, marginCallBar: string, normalBar: string>, marginUserAssetVoList: table<asset: string, borrowed: string, free: string, interest: string, locked: string, netAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/margin/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summary of Sub-account's Margin Account (For Master Account)
#
# GET /sapi/v1/sub-account/margin/accountSummary
export def "sapi-sub-account-margin-account-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string, subAccountList: table<email: string, totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/margin/accountSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Futures for Sub-account (For Master Account)
#
# POST /sapi/v1/sub-account/futures/enable
export def "sapi-sub-account-futures-enable post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, isFuturesEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail on Sub-account's Futures Account (For Master Account)
#
# GET /sapi/v1/sub-account/futures/account
export def "sapi-sub-account-futures-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # e.g. alice@test.com
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, asset: string, assets: table<asset: string, initialMargin: string, maintenanceMargin: string, marginBalance: string, maxWithdrawAmount: string, openOrderInitialMargin: string, positionInitialMargin: string, unrealizedProfit: string, walletBalance: string>, canDeposit: bool, canTrade: bool, canWithdraw: bool, feeTier: int, maxWithdrawAmount: string, totalInitialMargin: string, totalMaintenanceMargin: string, totalMarginBalance: string, totalOpenOrderInitialMargin: string, totalPositionInitialMargin: string, totalUnrealizedProfit: string, totalWalletBalance: string, updateTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summary of Sub-account's Futures Account (For Master Account)
#
# GET /sapi/v1/sub-account/futures/accountSummary
export def "sapi-sub-account-futures-account-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalInitialMargin: string, totalMaintenanceMargin: string, totalMarginBalance: string, totalOpenOrderInitialMargin: string, totalPositionInitialMargin: string, totalUnrealizedProfit: string, totalWalletBalance: string, asset: string, subAccountList: table<email: string, totalInitialMargin: string, totalMaintenanceMargin: string, totalMarginBalance: string, totalOpenOrderInitialMargin: string, totalPositionInitialMargin: string, totalUnrealizedProfit: string, totalWalletBalance: string, asset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/accountSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Futures Position-Risk of Sub-account (For Master Account)
#
# GET /sapi/v1/sub-account/futures/positionRisk
export def "sapi-sub-account-futures-position-risk get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<entryPrice: string, leverage: string, maxNotional: string, liquidationPrice: string, markPrice: string, positionAmount: string, symbol: string, unrealizedProfit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/positionRisk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer for Sub-account (For Master Account)
#
# POST /sapi/v1/sub-account/futures/transfer
export def "sapi-sub-account-futures-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --type: int # * `1` - transfer from subaccount's spot account to its USDT-margined futures account * `2` - transfer from subaccount's USDT-margined futures account to its spot account * `3` - transfer from subaccount's spot account to its COIN-margined futures account * `4` - transfer from subaccount's COIN-margined futures account to its spot account (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/futures/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Margin Transfer for Sub-account (For Master Account)
#
# POST /sapi/v1/sub-account/margin/transfer
export def "sapi-sub-account-margin-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --type: int # * `1` - transfer from subaccount's spot account to margin account * `2` - transfer from subaccount's margin account to its spot account (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/margin/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer to Sub-account of Same Master (For Sub-account)
#
# POST /sapi/v1/sub-account/transfer/subToSub
export def "sapi-sub-account-transfer-sub-to-sub post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --toEmail: string # Recipient email
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/transfer/subToSub" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transfer to Master (For Sub-account)
#
# POST /sapi/v1/sub-account/transfer/subToMaster
export def "sapi-sub-account-transfer-sub-to-master post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<txnId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/transfer/subToMaster" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sub-account Transfer History (For Sub-account)
#
# GET /sapi/v1/sub-account/transfer/subUserHistory
export def "sapi-sub-account-transfer-sub-user-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --type: int # * `1` - transfer in * `2` - transfer out (format: int32)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<counterParty: string, email: string, type: int, asset: string, qty: string, fromAccountType: string, toAccountType: string, status: string, tranId: int, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/transfer/subUserHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Universal Transfer History (For Master Account)
#
# GET /sapi/v1/sub-account/universalTransfer
export def "sapi-sub-account-universal-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromEmail: string # Sub-account email
  --toEmail: string # Sub-account email
  --clientTranId: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 500, Max 500 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<tranId: int, fromEmail: string, toEmail: string, asset: string, amount: string, fromAccountType: string, toAccountType: string, status: string, createTimeStamp: int, clientTranId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromEmail" $fromEmail "scalar") (serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "clientTranId" $clientTranId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/universalTransfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Universal Transfer (For Master Account)
#
# POST /sapi/v1/sub-account/universalTransfer
export def "sapi-sub-account-universal-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromEmail: string # Sub-account email
  --toEmail: string # Sub-account email
  --fromAccountType: string@fromAccountType-completer
  --toAccountType: string@toAccountType-completer
  --clientTranId: string
  --symbol: string # Only supported under ISOLATED_MARGIN type (e.g. BNBUSDT)
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int, clientTranId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromEmail" $fromEmail "scalar") (serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "fromAccountType" $fromAccountType "scalar") (serialize-qp "toAccountType" $toAccountType "scalar") (serialize-qp "clientTranId" $clientTranId "scalar") (serialize-qp "symbol" $symbol "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/universalTransfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Detail on Sub-account's Futures Account V2 (For Master Account)
#
# GET /sapi/v2/sub-account/futures/account
export def "sapi-sub-account-futures-account get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --futuresType: int # * `1` - USDT Margined Futures * `2` - COIN Margined Futures (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "futuresType" $futuresType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/sub-account/futures/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summary of Sub-account's Futures Account V2 (For Master Account)
#
# GET /sapi/v2/sub-account/futures/accountSummary
export def "sapi-sub-account-futures-account-summary get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --futuresType: int # * `1` - USDT Margined Futures * `2` - COIN Margined Futures (format: int32, e.g. 1)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 10, Max 20 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "futuresType" $futuresType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/sub-account/futures/accountSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Futures Position-Risk of Sub-account V2 (For Master Account)
#
# GET /sapi/v2/sub-account/futures/positionRisk
export def "sapi-sub-account-futures-position-risk get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --futuresType: int # * `1` - USDT Margined Futures * `2` - COIN Margined Futures (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "futuresType" $futuresType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/sub-account/futures/positionRisk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Leverage Token for Sub-account (For Master Account)
#
# POST /sapi/v1/sub-account/blvt/enable
export def "sapi-sub-account-blvt-enable post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --enableBlvt: string@bool-completer # Only true for now
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, enableBlvt: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "enableBlvt" $enableBlvt "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/blvt/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deposit assets into the managed sub-account(For Investor Master Account)
#
# POST /sapi/v1/managed-subaccount/deposit
export def "sapi-managed-subaccount-deposit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --toEmail: string # Recipient email
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "toEmail" $toEmail "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/deposit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Managed sub-account asset details(For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/asset
export def "sapi-managed-subaccount-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<coin: string, name: string, totalBalance: string, availableBalance: string, inOrder: string, btcValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Withdrawl assets from the managed sub-account(For Investor Master Account)
#
# POST /sapi/v1/managed-subaccount/withdraw
export def "sapi-managed-subaccount-withdraw post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromEmail: string # Sender email
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --transferDate: int # Withdrawals is automatically occur on the transfer date(UTC0). If a date is not selected, the withdrawal occurs right now (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromEmail" $fromEmail "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "transferDate" $transferDate "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/withdraw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Managed sub-account snapshot (For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/accountSnapshot
export def "sapi-managed-subaccount-account-snapshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --type: string # "SPOT", "MARGIN"(cross), "FUTURES"(UM) (e.g. SPOT)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # min 7, max 30, default 7 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, snapshotVos: table<data: record, type: string, updateTime: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/accountSnapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub Account Transfer Log (For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/queryTransLogForInvestor
export def "sapi-managed-subaccount-query-trans-log-for-investor get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --transfers: string # Transfer Direction (FROM/TO) (e.g. FROM)
  --transferFunctionAccountType: string # Transfer function account type (SPOT/MARGIN/ISOLATED_MARGIN/USDT_FUTURE/COIN_FUTURE) (e.g. SPOT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<count: int, managerSubTransferHistoryVos: table<fromEmail: string, fromAccountType: string, toEmail: string, toAccountType: string, asset: string, amount: string, scheduledData: int, createTime: int, status: string, tranId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "transfers" $transfers "scalar") (serialize-qp "transferFunctionAccountType" $transferFunctionAccountType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/queryTransLogForInvestor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub Account Transfer Log (For Trading Team Master Account)
#
# GET /sapi/v1/managed-subaccount/queryTransLogForTradeParent
export def "sapi-managed-subaccount-query-trans-log-for-trade-parent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --transfers: string # Transfer Direction (FROM/TO) (e.g. FROM)
  --transferFunctionAccountType: string # Transfer function account type (SPOT/MARGIN/ISOLATED_MARGIN/USDT_FUTURE/COIN_FUTURE) (e.g. SPOT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<count: int, managerSubTransferHistoryVos: table<fromEmail: string, fromAccountType: string, toEmail: string, toAccountType: string, asset: string, amount: string, scheduledData: int, createTime: int, status: string, tranId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "transfers" $transfers "scalar") (serialize-qp "transferFunctionAccountType" $transferFunctionAccountType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/queryTransLogForTradeParent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub-account Futures Asset Details (For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/fetch-future-asset
export def "sapi-managed-subaccount-fetch-future-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, message: string, snapshotVos: table<type: string, updateTime: int, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/fetch-future-asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub-account Margin Asset Details (For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/marginAsset
export def "sapi-managed-subaccount-margin-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<marginLevel: string, totalAssetOfBtc: string, totalLiabilityOfBtc: string, totalNetAssetOfBtc: string, userAssets: table<asset: string, borrowed: string, free: string, interest: string, locked: string, netAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/marginAsset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub-account List (For Investor)
#
# GET /sapi/v1/managed-subaccount/info
export def "sapi-managed-subaccount-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, managerSubUserInfoVoList: table<rootUserId: int, managersubUserId: int, bindParentUserId: int, email: string, insertTimeStamp: int, bindParentEmail: string, isSubUserEnabled: bool, isUserActive: bool, isMarginEnabled: bool, isFutureEnabled: bool, isSignedLVTRiskAgreement: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Managed Sub-account Deposit Address (For Investor Master Account)
#
# GET /sapi/v1/managed-subaccount/deposit/address
export def "sapi-managed-subaccount-deposit-address get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --coin: string # Coin name (e.g. BNB)
  --network: string # e.g. BTC
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<coin: string, address: string, tag: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/deposit/address" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Managed Sub Account Transfer Log (For Trading Team Sub Account)(USER_DATA)
#
# GET /sapi/v1/managed-subaccount/query-trans-log
export def "sapi-managed-subaccount-query-trans-log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --transfers: string@transfers-completer # Transfer Direction
  --transferFunctionAccountType: string@transferFunctionAccountType-completer # Transfer function account type
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<count: int, managerSubTransferHistoryVos: table<fromEmail: string, fromAccountType: string, toEmail: string, toAccountType: string, asset: string, amount: string, scheduledData: int, createTime: int, status: string, tranId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "transfers" $transfers "scalar") (serialize-qp "transferFunctionAccountType" $transferFunctionAccountType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/managed-subaccount/query-trans-log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get IP Restriction for a Sub-account API Key (For Master Account)
#
# GET /sapi/v1/sub-account/subAccountApi/ipRestriction
export def "sapi-sub-account-sub-account-api-ip-restriction get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --subAccountApiKey: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<ipRestrict: string, ipList: list<string>, updateTime: int, apiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "subAccountApiKey" $subAccountApiKey "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/subAccountApi/ipRestriction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete IP List for a Sub-account API Key (For Master Account)
#
# DELETE /sapi/v1/sub-account/subAccountApi/ipRestriction/ipList
export def "sapi-sub-account-sub-account-api-ip-restriction-ip-list delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --subAccountApiKey: string
  --ipAddress: string # Can be added in batches, separated by commas
  --thirdPartyName: string # third party IP list name
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<ipRestrict: string, ipList: list<string>, updateTime: int, apiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "subAccountApiKey" $subAccountApiKey "scalar") (serialize-qp "ipAddress" $ipAddress "scalar") (serialize-qp "thirdPartyName" $thirdPartyName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/subAccountApi/ipRestriction/ipList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Sub-account Transaction Statistics (For Master Account)
#
# GET /sapi/v1/sub-account/transaction-statistics
export def "sapi-sub-account-transaction-statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<recent30BtcTotal: string, recent30BtcFuturesTotal: string, recent30BtcMarginTotal: string, recent30BusdTotal: string, recent30BusdFuturesTotal: string, recent30BusdMarginTotal: string, tradeInfoVos: table<userId: int, btc: float, btcFutures: float, btcMargin: float, busd: float, busdFutures: float, busdMargin: float, date: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/transaction-statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enable Options for Sub-account (For Master Account)(USER_DATA)
#
# POST /sapi/v1/sub-account/eoptions/enable
export def "sapi-sub-account-eoptions-enable post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<email: string, isEOptionsEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/sub-account/eoptions/enable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update IP Restriction for Sub-Account API key (For Master Account)
#
# POST /sapi/v2/sub-account/subAccountApi/ipRestriction
export def "sapi-sub-account-sub-account-api-ip-restriction post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Sub-account email
  --subAccountApiKey: string
  --status: string # IP Restriction status. 1 = IP Unrestricted. 2 = Restrict access to trusted IPs only. 3 = Restrict access to users' trusted third party IPs only (e.g. 1)
  --thirdPartyName: string # third party IP list name
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<status: string, ipList: list<string>, updateTime: int, apiKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "subAccountApiKey" $subAccountApiKey "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "thirdPartyName" $thirdPartyName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/sub-account/subAccountApi/ipRestriction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Sub-account Assets (For Master Account)
#
# GET /sapi/v4/sub-account/assets
export def "sapi-sub-account-assets get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<balances: table<asset: string, free: string, locked: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v4/sub-account/assets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ListenKey (USER_STREAM)
#
# POST /api/v3/userDataStream
export def "user-data-stream post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<listenKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v3/userDataStream")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping/Keep-alive a ListenKey (USER_STREAM)
#
# PUT /api/v3/userDataStream
export def "user-data-stream put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/userDataStream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close a ListenKey (USER_STREAM)
#
# DELETE /api/v3/userDataStream
export def "user-data-stream delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v3/userDataStream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a ListenKey (USER_STREAM)
#
# POST /sapi/v1/userDataStream
export def "sapi-user-data-stream post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<listenKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/userDataStream")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping/Keep-alive a ListenKey (USER_STREAM)
#
# PUT /sapi/v1/userDataStream
export def "sapi-user-data-stream put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/userDataStream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close a ListenKey (USER_STREAM)
#
# DELETE /sapi/v1/userDataStream
export def "sapi-user-data-stream delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/userDataStream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Listen Key (USER_STREAM)
#
# POST /sapi/v1/userDataStream/isolated
export def "sapi-user-data-stream-isolated post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<listenKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/userDataStream/isolated")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Ping/Keep-alive a Listen Key (USER_STREAM)
#
# PUT /sapi/v1/userDataStream/isolated
export def "sapi-user-data-stream-isolated put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/userDataStream/isolated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close a ListenKey (USER_STREAM)
#
# DELETE /sapi/v1/userDataStream/isolated
export def "sapi-user-data-stream-isolated delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --listenKey: string # User websocket listen key (e.g. pqia91ma19a5s61cv6a81va65sdf19v8a65a1a5s61cv6a81va65sdf19v8a65a1)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "listenKey" $listenKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/userDataStream/isolated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fiat Deposit/Withdraw History (USER_DATA)
#
# GET /sapi/v1/fiat/orders
export def "sapi-fiat-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transactionType: int # * `0` - deposit * `1` - withdraw (format: int32)
  --beginTime: int # format: int64, e.g. 1626144956000
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --rows: int # Default 100, max 500 (format: int32, e.g. 300)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: table<orderNo: string, fiatCurrency: string, indicatedAmount: string, amount: string, totalFee: string, method: string, status: string, createTime: int, updateTime: int>, total: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transactionType" $transactionType "scalar") (serialize-qp "beginTime" $beginTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/fiat/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fiat Payments History (USER_DATA)
#
# GET /sapi/v1/fiat/payments
export def "sapi-fiat-payments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transactionType: int # * `0` - deposit * `1` - withdraw (format: int32)
  --beginTime: int # format: int64, e.g. 1626144956000
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --rows: int # Default 100, max 500 (format: int32, e.g. 300)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: table<orderNo: string, sourceAmount: string, fiatCurrency: string, obtainAmount: string, cryptoCurrency: string, totalFee: string, price: string, status: string, createTime: int, updateTime: int>, total: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transactionType" $transactionType "scalar") (serialize-qp "beginTime" $beginTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/fiat/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Fixed/Activity Project List(USER_DATA)
#
# GET /sapi/v1/lending/project/list
export def "sapi-lending-project-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --type: string@type-completer-7
  --status: string@status-completer # Default `ALL`
  --isSortAsc: string@bool-completer # default "true"
  --sortBy: string@sortBy-completer # Default `START_TIME`
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, displayPriority: int, duration: int, interestPerLot: string, interestRate: string, lotSize: string, lotsLowLimit: int, lotsPurchased: int, lotsUpLimit: int, maxLotsPerUser: int, needKyc: bool, projectId: string, projectName: string, status: string, type: string, withAreaLimitation: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "isSortAsc" $isSortAsc "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/project/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Purchase Fixed/Activity Project (USER_DATA)
#
# POST /sapi/v1/lending/customizedFixed/purchase
export def "sapi-lending-customized-fixed-purchase post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --lot: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<purchaseId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "lot" $lot "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/customizedFixed/purchase" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Fixed/Activity Project Position (USER_DATA)
#
# GET /sapi/v1/lending/project/position/list
export def "sapi-lending-project-position-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --projectId: string
  --status: string@status-completer # Default `ALL`
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, canTransfer: bool, createTimestamp: int, duration: int, endTime: int, interest: string, interestRate: string, lot: int, positionId: int, principal: string, projectId: string, projectName: string, purchaseTime: int, redeemDate: string, startTime: int, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/project/position/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Fixed/Activity Position to Daily Position (USER_DATA)
#
# POST /sapi/v1/lending/positionChanged
export def "sapi-lending-position-changed post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --lot: string
  --positionId: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<dailyPurchaseId: int, success: bool, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "lot" $lot "scalar") (serialize-qp "positionId" $positionId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/positionChanged" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acquiring Algorithm (MARKET_DATA)
#
# GET /sapi/v1/mining/pub/algoList
export def "sapi-mining-pub-algo-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, msg: string, data: table<algoName: string, algoId: int, poolIndex: int, unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/mining/pub/algoList")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Acquiring CoinName (MARKET_DATA)
#
# GET /sapi/v1/mining/pub/coinList
export def "sapi-mining-pub-coin-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: int, msg: string, data: table<coinName: string, coinId: int, poolIndex: int, algoId: int, algoName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/mining/pub/coinList")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request for Detail Miner List (USER_DATA)
#
# GET /sapi/v1/mining/worker/detail
export def "sapi-mining-worker-detail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --workerName: string # Miner’s name
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: table<workerName: string, type: string, hashrateDatas: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "workerName" $workerName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/worker/detail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request for Miner List (USER_DATA)
#
# GET /sapi/v1/mining/worker/list
export def "sapi-mining-worker-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --qp-sort: int # sort sequence(default=0)0 positive sequence, 1 negative sequence (format: int32)
  --sortColumn: int # Sort by( default 1): 1: miner name, 2: real-time computing power, 3: daily average computing power, 4: real-time rejection rate, 5: last submission time (format: int32)
  --workerStatus: int # miners status(default=0)0 all, 1 valid, 2 invalid, 3 failure (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<workerDatas: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortColumn" $sortColumn "scalar") (serialize-qp "workerStatus" $workerStatus "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/worker/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Earnings List (USER_DATA)
#
# GET /sapi/v1/mining/payment/list
export def "sapi-mining-payment-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --coin: string # Coin name (e.g. BNB)
  --startDate: string # Search date, millisecond timestamp, while empty query all
  --endDate: string # Search date, millisecond timestamp, while empty query all
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --pageSize: string # Number of pages, minimum 10, maximum 200
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<accountProfits: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/payment/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extra Bonus List (USER_DATA)
#
# GET /sapi/v1/mining/payment/other
export def "sapi-mining-payment-other get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --coin: string # Coin name (e.g. BNB)
  --startDate: string # Search date, millisecond timestamp, while empty query all
  --endDate: string # Search date, millisecond timestamp, while empty query all
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --pageSize: string # Number of pages, minimum 10, maximum 200
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<otherProfits: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "coin" $coin "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/payment/other" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hashrate Resale List (USER_DATA)
#
# GET /sapi/v1/mining/hash-transfer/config/details/list
export def "sapi-mining-hash-transfer-config-details-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --pageSize: string # Number of pages, minimum 10, maximum 200
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<configDetails: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/hash-transfer/config/details/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hashrate Resale Details (USER_DATA)
#
# GET /sapi/v1/mining/hash-transfer/profit/details
export def "sapi-mining-hash-transfer-profit-details get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --configId: string # Mining ID
  --userName: string # Mining Account
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --pageSize: string # Number of pages, minimum 10, maximum 200
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<profitTransferDetails: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configId" $configId "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/hash-transfer/profit/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hashrate Resale Request (USER_DATA)
#
# POST /sapi/v1/mining/hash-transfer/config
export def "sapi-mining-hash-transfer-config post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userName: string # Mining Account
  --algo: string # Algorithm(sha256)
  --startDate: string # Search date, millisecond timestamp, while empty query all
  --endDate: string # Search date, millisecond timestamp, while empty query all
  --toPoolUser: string # Mining Account
  --hashRate: string # Resale hashrate h/s must be transferred (BTC is greater than 500000000000 ETH is greater than 500000)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "algo" $algo "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "toPoolUser" $toPoolUser "scalar") (serialize-qp "hashRate" $hashRate "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/hash-transfer/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Hashrate Resale configuration (USER_DATA)
#
# POST /sapi/v1/mining/hash-transfer/config/cancel
export def "sapi-mining-hash-transfer-config-cancel post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --configId: string # Mining ID
  --userName: string # Mining Account
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "configId" $configId "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/hash-transfer/config/cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Statistic List (USER_DATA)
#
# GET /sapi/v1/mining/statistics/user/status
export def "sapi-mining-statistics-user-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<fifteenMinHashRate: string, dayHashRate: string, validNum: int, invalidNum: int, profitToday: record<BTC: string, BSV: string, BCH: string>, profitYesterday: record<BTC: string, BSV: string, BCH: string>, userName: string, unit: string, algo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/statistics/user/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account List (USER_DATA)
#
# GET /sapi/v1/mining/statistics/user/list
export def "sapi-mining-statistics-user-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --userName: string # Mining Account
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: table<type: string, userName: string, list: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/statistics/user/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mining Account Earning (USER_DATA)
#
# GET /sapi/v1/mining/payment/uid
export def "sapi-mining-payment-uid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algo: string # Algorithm(sha256)
  --startDate: string # Search date, millisecond timestamp, while empty query all
  --endDate: string # Search date, millisecond timestamp, while empty query all
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --pageSize: string # Number of pages, minimum 10, maximum 200
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: int, msg: string, data: record<accountProfits: list<record>, totalNum: int, pageSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algo" $algo "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/mining/payment/uid" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# New Future Account Transfer (USER_DATA)
#
# POST /sapi/v1/futures/transfer
export def "sapi-futures-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --amount: float # format: double, e.g. 1.01
  --type: int # 1: transfer from spot account to USDT-Ⓜ futures account. 2: transfer from USDT-Ⓜ futures account to spot account. 3: transfer from spot account to COIN-Ⓜ futures account. 4: transfer from COIN-Ⓜ futures account to spot account. (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/futures/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Future Account Transaction History List (USER_DATA)
#
# GET /sapi/v1/futures/transfer
export def "sapi-futures-transfer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<asset: string, tranId: int, amount: string, type: string, timestamp: int, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/futures/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Future TickLevel Orderbook Historical Data Download Link (USER_DATA)
#
# GET /sapi/v1/futures/histDataLink
export def "sapi-futures-hist-data-link get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # e.g. BTCUSDT
  --dataType: string@dataType-completer # e.g. T_DEPTH
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<data: table<day: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "dataType" $dataType "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/futures/histDataLink" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Volume Participation(VP) New Order (TRADE)
#
# POST /sapi/v1/algo/futures/newOrderVp
export def "sapi-algo-futures-new-order-vp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --positionSide: string@positionSide-completer # Default BOTH for One-way Mode ; LONG or SHORT for Hedge Mode. It must be sent in Hedge Mode. (e.g. BOTH)
  --quantity: float # Quantity of base asset; The notional (quantity * mark price(base asset)) must be more than the equivalent of 10,000 USDT and less than the equivalent of 1,000,000 USDT (format: double)
  --urgency: string@urgency-completer # Represent the relative speed of the current execution; ENUM: LOW, MEDIUM, HIGH (e.g. LOW)
  --clientAlgoId: string # A unique id among Algo orders (length should be 32 characters)， If it is not sent, we will give default value (e.g. 00358ce6a268403398bd34eaa36dffe7)
  --reduceOnly: string@bool-completer # 'true' or 'false'. Default 'false'; Cannot be sent in Hedge Mode; Cannot be sent when you open a position
  --limitPrice: float # Limit price of the order; If it is not sent, will place order by market price by default (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<clientAlgoId: string, success: bool, code: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "positionSide" $positionSide "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "urgency" $urgency "scalar") (serialize-qp "clientAlgoId" $clientAlgoId "scalar") (serialize-qp "reduceOnly" $reduceOnly "scalar") (serialize-qp "limitPrice" $limitPrice "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/newOrderVp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Time-Weighted Average Price(Twap) New Order (TRADE)
#
# POST /sapi/v1/algo/futures/newOrderTwap
export def "sapi-algo-futures-new-order-twap post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --positionSide: string@positionSide-completer # Default BOTH for One-way Mode ; LONG or SHORT for Hedge Mode. It must be sent in Hedge Mode. (e.g. BOTH)
  --quantity: float # Quantity of base asset; The notional (quantity * mark price(base asset)) must be more than the equivalent of 10,000 USDT and less than the equivalent of 1,000,000 USDT (format: double)
  --duration: int # Duration for TWAP orders in seconds. [300, 86400];Less than 5min => defaults to 5 min; Greater than 24h => defaults to 24h (format: int64, e.g. 300)
  --clientAlgoId: string # A unique id among Algo orders (length should be 32 characters)， If it is not sent, we will give default value (e.g. 00358ce6a268403398bd34eaa36dffe7)
  --reduceOnly: string@bool-completer # 'true' or 'false'. Default 'false'; Cannot be sent in Hedge Mode; Cannot be sent when you open a position
  --limitPrice: float # Limit price of the order; If it is not sent, will place order by market price by default (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<clientAlgoId: string, success: bool, code: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "positionSide" $positionSide "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "clientAlgoId" $clientAlgoId "scalar") (serialize-qp "reduceOnly" $reduceOnly "scalar") (serialize-qp "limitPrice" $limitPrice "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/newOrderTwap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Algo Order(TRADE)
#
# DELETE /sapi/v1/algo/futures/order
export def "sapi-algo-futures-order delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algoId: int # Eg. 14511 (format: int64)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<algoId: int, success: bool, code: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algoId" $algoId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Current Algo Open Orders (USER_DATA)
#
# GET /sapi/v1/algo/futures/openOrders
export def "sapi-algo-futures-open-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, orders: table<algoId: int, symbol: string, side: string, positionSide: string, totalQty: string, executedQty: string, executedAmt: string, avgPrice: string, clientAlgoId: string, bookTime: int, endTime: int, algoStatus: string, algoType: string, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Historical Algo Orders (USER_DATA)
#
# GET /sapi/v1/algo/futures/historicalOrders
export def "sapi-algo-futures-historical-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --pageSize: string # MIN 1, MAX 100; Default 100
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, orders: table<algoId: int, symbol: string, side: string, positionSide: string, totalQty: string, executedQty: string, executedAmt: string, avgPrice: string, clientAlgoId: string, bookTime: int, endTime: int, algoStatus: string, algoType: string, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/historicalOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Sub Orders (USER_DATA)
#
# GET /sapi/v1/algo/futures/subOrders
export def "sapi-algo-futures-sub-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algoId: int # format: int64
  --page: int # Default 1 (format: int32, e.g. 1)
  --pageSize: string # MIN 1, MAX 100; Default 100
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, executedQty: string, executedAmt: string, subOrders: table<algoId: int, orderId: int, orderStatus: string, executedQty: string, executedAmt: string, feeAmt: string, feeAsset: string, bookTime: int, avgPrice: string, side: string, symbol: string, subId: int, timeInForce: string, origQty: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algoId" $algoId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/futures/subOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Time-Weighted Average Price (Twap) New Order
#
# POST /sapi/v1/algo/spot/newOrderTwap
export def "sapi-algo-spot-new-order-twap post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --quantity: float # format: double, e.g. 1.0
  --duration: int # format: int32, e.g. 300
  --clientAlgoId: string
  --limitPrice: float # format: float
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<clientAlgoId: string, success: bool, code: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "clientAlgoId" $clientAlgoId "scalar") (serialize-qp "limitPrice" $limitPrice "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/spot/newOrderTwap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Algo Order
#
# DELETE /sapi/v1/algo/spot/order
export def "sapi-algo-spot-order delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algoId: int # format: int64, e.g. 1
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<algoId: int, success: bool, code: int, msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algoId" $algoId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/spot/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Current Algo Open Orders
#
# GET /sapi/v1/algo/spot/openOrders
export def "sapi-algo-spot-open-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, orders: table<algoId: int, symbol: string, side: string, totalQty: string, executedQty: string, executedAmt: string, avgPrice: string, clientAlgoId: string, bookTime: int, endTime: int, algoStatus: string, algoType: string, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/spot/openOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Historical Algo Orders
#
# GET /sapi/v1/algo/spot/historicalOrders
export def "sapi-algo-spot-historical-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # Trading symbol, e.g. BNBUSDT (e.g. BNBUSDT)
  --side: string@side-completer # e.g. SELL
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --pageSize: string # MIN 1, MAX 100; Default 100
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, orders: table<algoId: int, symbol: string, side: string, totalQty: string, executedQty: string, executedAmt: string, avgPrice: string, clientAlgoId: string, bookTime: int, endTime: int, algoStatus: string, algoType: string, urgency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "symbol" $symbol "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/spot/historicalOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Sub Orders
#
# GET /sapi/v1/algo/spot/subOrders
export def "sapi-algo-spot-sub-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --algoId: int # format: int64
  --page: int # Default 1 (format: int32, e.g. 1)
  --pageSize: string # MIN 1, MAX 100; Default 100
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, executedQty: string, executedAmt: string, subOrders: table<algoId: int, orderId: int, orderStatus: string, executedQty: string, executedAmt: string, feeAmt: string, feeAsset: string, bookTime: int, avgPrice: string, side: string, symbol: string, subId: int, timeInForce: string, origQty: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "algoId" $algoId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/algo/spot/subOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Portfolio Margin Account (USER_DATA)
#
# GET /sapi/v1/portfolio/account
export def "sapi-portfolio-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<uniMMR: string, accountEquity: string, actualEquity: string, accountMaintMargin: string, accountStatus: string, accountType: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Portfolio Margin Collateral Rate (MARKET_DATA)
#
# GET /sapi/v1/portfolio/collateralRate
export def "sapi-portfolio-collateral-rate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<asset: string, collateralRate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/portfolio/collateralRate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Portfolio Margin Pro Tiered Collateral Rate(USER_DATA)
#
# GET /sapi/v2/portfolio/collateralRate
export def "sapi-portfolio-collateral-rate get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, collateralInfo: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/portfolio/collateralRate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Portfolio Margin Bankruptcy Loan Amount (USER_DATA)
#
# GET /sapi/v1/portfolio/pmLoan
export def "sapi-portfolio-pm-loan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<asset: string, amount: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/pmLoan" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Portfolio Margin Bankruptcy Loan Repay (USER_DATA)
#
# POST /sapi/v1/portfolio/repay
export def "sapi-portfolio-repay post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # e.g. SPOT
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Classic Portfolio Margin Negative Balance Interest History (USER_DATA)
#
# GET /sapi/v1/portfolio/interest-history
export def "sapi-portfolio-interest-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, interest: string, interestAccruedTime: int, interestRate: string, principal: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/interest-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Portfolio Margin Asset Index Price (MARKET_DATA)
#
# GET /sapi/v1/portfolio/asset-index-price
export def "sapi-portfolio-asset-index-price get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
]: nothing -> table<asset: string, assetIndexPrice: string, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/asset-index-price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fund Auto-collection (USER_DATA)
#
# POST /sapi/v1/portfolio/auto-collection
export def "sapi-portfolio-auto-collection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/auto-collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BNB Transfer (USER_DATA)
#
# POST /sapi/v1/portfolio/bnb-transfer
export def "sapi-portfolio-bnb-transfer post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transferSide: string@transferSide-completer # e.g. TO_UM
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<tranId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transferSide" $transferSide "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/bnb-transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Auto-repay-futures Status (USER_DATA)
#
# POST /sapi/v1/portfolio/repay-futures-switch
export def "sapi-portfolio-repay-futures-switch post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoRepay: string@bool-completer # e.g. true
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoRepay" $autoRepay "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/repay-futures-switch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Auto-repay-futures Status (USER_DATA)
#
# GET /sapi/v1/portfolio/repay-futures-switch
export def "sapi-portfolio-repay-futures-switch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<autoRepay: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/repay-futures-switch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repay futures Negative Balance (USER_DATA)
#
# POST /sapi/v1/portfolio/repay-futures-negative-balance
export def "sapi-portfolio-repay-futures-negative-balance post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/repay-futures-negative-balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Portfolio Margin Asset Leverage (USER_DATA)
#
# GET /sapi/v1/portfolio/margin-asset-leverage
export def "sapi-portfolio-margin-asset-leverage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<asset: string, collateralRate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sapi/v1/portfolio/margin-asset-leverage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fund Collection by Asset (USER_DATA)
#
# POST /sapi/v1/portfolio/asset-collection
export def "sapi-portfolio-asset-collection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<msg: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/portfolio/asset-collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BLVT Info (MARKET_DATA)
#
# GET /sapi/v1/blvt/tokenInfo
export def "sapi-blvt-token-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
]: nothing -> table<tokenName: string, description: string, underlying: string, tokenIssued: string, basket: string, currentBaskets: list<record>, nav: string, realLeverage: string, fundingRate: string, dailyManagementFee: string, purchaseFeePct: string, dailyPurchaseLimit: string, redeemFeePct: string, dailyRedeemLimit: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/tokenInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe BLVT (USER_DATA)
#
# POST /sapi/v1/blvt/subscribe
export def "sapi-blvt-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
  --cost: float # Spot balance (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<id: int, status: string, tokenName: string, amount: string, cost: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "cost" $cost "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/subscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Subscription Record (USER_DATA)
#
# GET /sapi/v1/blvt/subscribe/record
export def "sapi-blvt-subscribe-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
  --id: int # format: int64
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<id: int, tokenName: string, amount: string, nav: string, fee: string, totalCharge: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/subscribe/record" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem BLVT (USER_DATA)
#
# POST /sapi/v1/blvt/redeem
export def "sapi-blvt-redeem post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<id: int, status: string, tokenName: string, redeemAmount: string, amount: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/redeem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redemption Record (USER_DATA)
#
# GET /sapi/v1/blvt/redeem/record
export def "sapi-blvt-redeem-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
  --id: int # format: int64
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # default 1000, max 1000 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<id: int, tokenName: string, amount: string, nav: string, fee: string, netProceed: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/redeem/record" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# BLVT User Limit Info (USER_DATA)
#
# GET /sapi/v1/blvt/userLimit
export def "sapi-blvt-user-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenName: string # BTCDOWN, BTCUP
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<tokenName: string, userDailyTotalPurchaseLimit: string, userDailyTotalRedeemLimit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenName" $tokenName "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/blvt/userLimit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get C2C Trade History (USER_DATA)
#
# GET /sapi/v1/c2c/orderMatch/listUserOrderHistory
export def "sapi-c2c-order-match-list-user-order-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tradeType: string@tradeType-completer
  --startTimestamp: int # UTC timestamp in ms (format: int64)
  --endTimestamp: int # UTC timestamp in ms (format: int64)
  --page: int # Default 1 (format: int32, e.g. 1)
  --rows: int # default 100, max 100 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: table<orderNumber: string, advNo: string, tradeType: string, asset: string, fiat: string, fiatSymbol: string, amount: string, totalPrice: string, unitPrice: string, orderStatus: string, createTime: int, commission: string, counterPartNickName: string, advertisementRole: string>, total: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tradeType" $tradeType "scalar") (serialize-qp "startTimestamp" $startTimestamp "scalar") (serialize-qp "endTimestamp" $endTimestamp "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "rows" $rows "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/c2c/orderMatch/listUserOrderHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get VIP Loan Ongoing Orders (USER_DATA)
#
# GET /sapi/v1/loan/vip/ongoing/orders
export def "sapi-loan-vip-ongoing-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order id (format: int64)
  --collateralAccountId: int # format: int64
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 10; max 100. (format: int32, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<orderId: int, loanCoin: string, totalDebt: string, residualInterest: string, collateralAccountId: string, collateralCoin: string, collateralValue: string, totalCollateralValueAfterHaircut: string, lockedCollateralValue: string, currentLTV: string, expirationTime: int, loanDate: string, loanRate: string, loanTerm: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "collateralAccountId" $collateralAccountId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/ongoing/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# VIP Loan Repay (TRADE)
#
# POST /sapi/v1/loan/vip/repay
export def "sapi-loan-vip-repay post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order id (format: int64)
  --amount: float # format: double, e.g. 1.01
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, repayAmount: string, remainingPrincipal: string, remainingInterest: string, collateralCoin: string, currentLTV: string, repayStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get VIP Loan Repayment History (USER_DATA)
#
# GET /sapi/v1/loan/vip/repay/history
export def "sapi-loan-vip-repay-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order id (format: int64)
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 10; max 100. (format: int32, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, repayAmount: string, collateralCoin: string, repayStatus: string, repayTime: string, orderId: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/repay/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Locked Value of VIP Collateral Account (USER_DATA)
#
# GET /sapi/v1/loan/vip/collateral/account
export def "sapi-loan-vip-collateral-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order id (format: int64)
  --collateralAccountId: int # format: int64
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<collateralAccountId: string, collateralCoin: string, collateralValue: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "collateralAccountId" $collateralAccountId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/collateral/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# VIP Loan Borrow
#
# POST /sapi/v1/loan/vip/borrow
export def "sapi-loan-vip-borrow post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanAccountId: int # format: int64
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --loanAmount: float # format: float
  --collateralAccountId: string
  --collateralCoin: string
  --isFlexibleRate: string@isFlexibleRate-completer # e.g. TRUE
  --loanTerm: int
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanAccountId: string, requestId: string, loanCoin: string, isFlexibleRate: string, loanAmount: string, collateralAccountId: string, collateralCoin: string, loanTerm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanAccountId" $loanAccountId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "loanAmount" $loanAmount "scalar") (serialize-qp "collateralAccountId" $collateralAccountId "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "isFlexibleRate" $isFlexibleRate "scalar") (serialize-qp "loanTerm" $loanTerm "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/borrow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Loanable Assets Data
#
# GET /sapi/v1/loan/vip/loanable/data
export def "sapi-loan-vip-loanable-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<loanCoin: string, _flexibleDailyInterestRate: string, _flexibleYearlyInterestRate: string, _30dDailyInterestRate: string, _30dYearlyInterestRate: string, _60dDailyInterestRate: string, _60dYearlyInterestRate: string, minLimit: string, maxLimit: string, vipLevel: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/loanable/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Collateral Asset Data (USER_DATA)
#
# GET /sapi/v1/loan/vip/collateral/data
export def "sapi-loan-vip-collateral-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<collateralCoin: string, _1stCollateralRatio: string, _1stCollateralRange: string, _2ndCollateralRatio: string, _2ndCollateralRange: string, _3rdCollateralRatio: string, _3rdCollateralRange: string, _4thCollateralRatio: string, _4thCollateralRange: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/collateral/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Application Status (USER_DATA)
#
# GET /sapi/v1/loan/vip/request/data
export def "sapi-loan-vip-request-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<loanAccountId: string, orderId: string, requestId: string, loanCoin: string, loanAmount: string, collateralAccountId: string, collateralCoin: string, loanTerm: int, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/request/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Borrow Interest Rate (USER_DATA)
#
# GET /sapi/v1/loan/vip/request/interestRate
export def "sapi-loan-vip-request-interest-rate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Max 10 assets, Multiple split by "," (e.g. BUSD)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, flexibleDailyInterestRate: string, flexibleYearlyInterestRate: string, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/request/interestRate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# VIP Loan Renew
#
# POST /sapi/v1/loan/vip/renew
export def "sapi-loan-vip-renew post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order id (format: int64)
  --loanTerm: int # e.g. 30
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanAccountId: string, loanCoin: string, loanAmount: string, collateralAccountId: string, collateralCoin: string, loanTerm: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanTerm" $loanTerm "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/vip/renew" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Crypto Loans Income History (USER_DATA)
#
# GET /sapi/v1/loan/income
export def "sapi-loan-income get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --type: string@type-completer-8 # All types will be returned by default.   * `borrowIn`   * `collateralSpent`   * `repayAmount`   * `collateralReturn` - Collateral return after repayment   * `addCollateral`   * `removeCollateral`   * `collateralReturnAfterLiquidation`
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # default 20, max 100 (format: int32, e.g. 20)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, type: string, amount: string, timestamp: int, tranId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/income" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Loan Borrow (TRADE)
#
# POST /sapi/v1/loan/borrow
export def "sapi-loan-borrow post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --loanAmount: float # Loan amount (format: float, e.g. 100.1)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --collateralAmount: float # format: float, e.g. 50.5
  --loanTerm: int # 7/14/30/90/180 days (format: int32, e.g. 30)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, loanAmount: string, collateralCoin: string, collateralAmount: string, hourlyInterestRate: string, orderId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "loanAmount" $loanAmount "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "collateralAmount" $collateralAmount "scalar") (serialize-qp "loanTerm" $loanTerm "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/borrow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Crypto Loans Borrow History (USER_DATA)
#
# GET /sapi/v1/loan/borrow/history
export def "sapi-loan-borrow-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # orderId in POST /sapi/v1/loan/borrow (format: int64, e.g. 10)
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # default 10, max 100 (format: int64, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<orderId: int, loanCoin: string, initialLoanAmount: string, hourlyInterestRate: string, loanTerm: string, collateralCoin: string, initialCollateralAmount: string, borrowTime: int, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/borrow/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Loan Ongoing Orders (USER_DATA)
#
# GET /sapi/v1/loan/ongoing/orders
export def "sapi-loan-ongoing-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # orderId in POST /sapi/v1/loan/borrow (format: int64, e.g. 10)
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --current: int # Current querying page. Start from 1; default:1, max:1000 (format: int32, e.g. 1)
  --limit: int # default 10, max 100 (format: int64, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<orderId: int, loanCoin: string, totalDebt: string, residualInterest: string, collateralCoin: string, collateralAmount: string, currentLTV: string, expirationTime: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/ongoing/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Loan Repay (TRADE)
#
# POST /sapi/v1/loan/repay
export def "sapi-loan-repay post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order ID (format: int64, e.g. 123456789)
  --amount: float # Repayment Amount (format: double, e.g. 100.5)
  --type: int # Default: 1. 1 for 'repay with borrowed coin'; 2 for 'repay with collateral'. (format: int32, e.g. 1)
  --collateralReturn: string@bool-completer # Default: TRUE. TRUE: Return extra collateral to spot account; FALSE: Keep extra collateral in the order. (e.g. true)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "collateralReturn" $collateralReturn "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Loan Repayment History (USER_DATA)
#
# GET /sapi/v1/loan/repay/history
export def "sapi-loan-repay-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order ID (format: int64, e.g. 10)
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # default 10, max 100 (format: int64, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, repayAmount: string, collateralCoin: string, collateralUsed: string, collateralReturn: string, repayType: string, repayStatus: string, repayTime: int, orderId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/repay/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Loan Adjust LTV (TRADE)
#
# POST /sapi/v1/loan/adjust/ltv
export def "sapi-loan-adjust-ltv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order ID (format: int64, e.g. 123456789)
  --amount: float # Amount (format: double, e.g. 100.5)
  --direction: string@direction-completer # 'ADDITIONAL', 'REDUCED' (e.g. ADDITIONAL)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, collateralCoin: string, direction: string, amount: string, currentLTV: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/adjust/ltv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Loan LTV Adjustment History (USER_DATA)
#
# GET /sapi/v1/loan/ltv/adjustment/history
export def "sapi-loan-ltv-adjustment-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Order ID (format: int64, e.g. 10)
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # default 10, max 100 (format: int64, e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, collateralCoin: string, direction: string, amount: string, preLTV: string, afterLTV: string, adjustTime: int, orderId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/ltv/adjustment/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Loanable Assets Data (USER_DATA)
#
# GET /sapi/v1/loan/loanable/data
export def "sapi-loan-loanable-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, _7dHourlyInterestRate: string, _7dDailyInterestRate: string, _14dHourlyInterestRate: string, _14dDailyInterestRate: string, _30dHourlyInterestRate: string, _30dDailyInterestRate: string, _90dHourlyInterestRate: string, _90dDailyInterestRate: string, _180dHourlyInterestRate: string, _180dDailyInterestRate: string, minLimit: string, maxLimit: string, vipLevel: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/loanable/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Collateral Assets Data (USER_DATA)
#
# GET /sapi/v1/loan/collateral/data
export def "sapi-loan-collateral-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --vipLevel: int # Defaults to user's vip level (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<collateralCoin: string, initialLTV: string, marginCallLTV: string, liquidationLTV: string, maxLimit: string, vipLevel: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "vipLevel" $vipLevel "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/collateral/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Collateral Repay Rate (USER_DATA)
#
# GET /sapi/v1/loan/repay/collateral/rate
export def "sapi-loan-repay-collateral-rate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --repayAmount: float # repay amount of loanCoin (format: float)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, collateralCoin: string, repayAmount: string, rate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "repayAmount" $repayAmount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/repay/collateral/rate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto Loan Customize Margin Call (TRADE)
#
# POST /sapi/v1/loan/customize/margin_call
export def "sapi-loan-customize-margin-call post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # Mandatory when collateralCoin is empty. Send either orderId or collateralCoin, if both parameters are sent, take orderId only. (format: int64)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --marginCall: float # format: float
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<orderId: string, collateralCoin: string, preMarginCall: string, afterMarginCall: string, customizeTime: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "marginCall" $marginCall "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/loan/customize/margin_call" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Borrow - Flexible Loan Borrow (TRADE)
#
# POST /sapi/v2/loan/flexible/borrow
export def "sapi-loan-flexible-borrow post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --loanAmount: float # Loan amount (format: float, e.g. 100.1)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --collateralAmount: float # format: float, e.g. 50.5
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, loanAmount: string, collateralCoin: string, collateralAmount: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "loanAmount" $loanAmount "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "collateralAmount" $collateralAmount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/borrow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Borrow - Get Flexible Loan Ongoing Orders (USER_DATA)
#
# GET /sapi/v2/loan/flexible/ongoing/orders
export def "sapi-loan-flexible-ongoing-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<loanCoin: string, totalDebt: string, collateralCoin: string, collateralAmount: string, currentLTV: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/ongoing/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Borrow - Get Flexible Loan Borrow History (USER_DATA)
#
# GET /sapi/v2/loan/flexible/borrow/history
export def "sapi-loan-flexible-borrow-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, rows: table<loanCoin: string, initialLoanAmount: string, collateralCoin: string, initialCollateralAmount: string, borrowTime: int, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/borrow/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repay - Flexible Loan Repay (TRADE)
#
# POST /sapi/v2/loan/flexible/repay
export def "sapi-loan-flexible-repay post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --repayAmount: float # repay amount of loanCoin (format: float)
  --collateralReturn: string@bool-completer # Default: TRUE. TRUE: Return extra collateral to earn account; FALSE: Keep extra collateral in the order, and lower LTV. (e.g. true)
  --fullRepayment: string@bool-completer # Default: FALSE. TRUE: Full repayment; FALSE: Partial repayment, based on loanAmount (e.g. true)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, collateralCoin: string, remainingDebt: string, remainingCollateral: string, fullRepayment: bool, currentLTV: string, repayStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "repayAmount" $repayAmount "scalar") (serialize-qp "collateralReturn" $collateralReturn "scalar") (serialize-qp "fullRepayment" $fullRepayment "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/repay" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Repay - Get Flexible Loan Repayment History (USER_DATA)
#
# GET /sapi/v2/loan/flexible/repay/history
export def "sapi-loan-flexible-repay-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, repayAmount: string, collateralCoin: string, collateralReturn: string, repayStatus: string, repayTime: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/repay/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adjust LTV - Flexible Loan Adjust LTV (TRADE)
#
# POST /sapi/v2/loan/flexible/adjust/ltv
export def "sapi-loan-flexible-adjust-ltv post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --adjustmentAmount: float # format: float
  --direction: string@direction-completer
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<loanCoin: string, collateralCoin: string, direction: string, adjustmentAmount: string, currentLTV: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "adjustmentAmount" $adjustmentAmount "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/adjust/ltv" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adjust LTV - Get Flexible Loan LTV Adjustment History (USER_DATA)
#
# GET /sapi/v2/loan/flexible/ltv/adjustment/history
export def "sapi-loan-flexible-ltv-adjustment-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --limit: int # Default 500; max 1000. (format: int32, e.g. 5)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, collateralCoin: string, direction: string, collateralAmount: string, preLTV: string, afterLTV: string, adjustTime: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/ltv/adjustment/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Loan Assets Data (USER_DATA)
#
# GET /sapi/v2/loan/flexible/loanable/data
export def "sapi-loan-flexible-loanable-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loanCoin: string # Coin loaned (e.g. BUSD)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<loanCoin: string, flexibleInterestRate: string, flexibleMinLimit: string, flexibleMaxLimit: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loanCoin" $loanCoin "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/loanable/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Loan Collateral Assets Data (USER_DATA)
#
# GET /sapi/v2/loan/flexible/collateral/data
export def "sapi-loan-flexible-collateral-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collateralCoin: string # Coin used as collateral (e.g. BNB)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<collateralCoin: string, initialLTV: string, marginCallLTV: string, liquidationLTV: string, maxLimit: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collateralCoin" $collateralCoin "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/loan/flexible/collateral/data" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Pay Trade History (USER_DATA)
#
# GET /sapi/v1/pay/transactions
export def "sapi-pay-transactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # default 100, max 100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: table<orderType: string, transactionId: string, transactionTime: int, amount: string, currency: string, walletType: int, walletTypes: list, fundsDetail: list, payerInfo: record, receiverInfo: record>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/pay/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List All Convert Pairs
#
# GET /sapi/v1/convert/exchangeInfo
export def "sapi-convert-exchange-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromAsset: string # User spends coin (e.g. BTC)
  --toAsset: string # User receives coin (e.g. USDT)
]: nothing -> table<fromAsset: string, toAsset: string, fromAssetMinAmount: string, fromAssetMaxAmount: string, toAssetMinAmount: string, toAssetMaxAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromAsset" $fromAsset "scalar") (serialize-qp "toAsset" $toAsset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/exchangeInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query order quantity precision per asset (USER_DATA)
#
# GET /sapi/v1/convert/assetInfo
export def "sapi-convert-asset-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<asset: string, fraction: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/assetInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send quote request (USER_DATA)
#
# POST /sapi/v1/convert/getQuote
export def "sapi-convert-get-quote post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromAsset: string # e.g. BTC
  --toAsset: string # e.g. USDT
  --fromAmount: float # When specified, it is the amount you will be debited after the conversion (format: float, e.g. 1.0)
  --toAmount: float # When specified, it is the amount you will be debited after the conversion (format: float, e.g. 1.0)
  --validTime: string # 10s, 30s, 1m, 2m, default 10s (e.g. 10s)
  --walletType: string # SPOT or FUNDING. Default is SPOT (e.g. SPOT)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<quoteId: string, ratio: string, inverseRatio: string, validTimestamp: int, toAmount: string, fromAmount: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromAsset" $fromAsset "scalar") (serialize-qp "toAsset" $toAsset "scalar") (serialize-qp "fromAmount" $fromAmount "scalar") (serialize-qp "toAmount" $toAmount "scalar") (serialize-qp "validTime" $validTime "scalar") (serialize-qp "walletType" $walletType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/getQuote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Quote (TRADE)
#
# POST /sapi/v1/convert/acceptQuote
export def "sapi-convert-accept-quote post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quoteId: string # e.g. 1000
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderId: string, createTime: int, orderStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quoteId" $quoteId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/acceptQuote" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Order status (USER_DATA)
#
# GET /sapi/v1/convert/orderStatus
export def "sapi-convert-order-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: string # e.g. 1000
  --quoteId: string # e.g. 1000
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderId: int, orderStatus: string, fromAsset: string, fromAmount: string, toAsset: string, toAmount: string, ratio: string, inverseRatio: string, createTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "quoteId" $quoteId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/orderStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Place limit order (USER_DATA)
#
# POST /sapi/v1/convert/limit/placeOrder
export def "sapi-convert-limit-place-order post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseAsset: string # e.g. BUSD
  --quoteAsset: string # e.g. USDT
  --limitPrice: float # Symbol limit price (from baseAsset to quoteAsset) (format: double)
  --baseAmount: float # Base asset amount. (One of baseAmount or quoteAmount is required) (format: double)
  --quoteAmount: float # Quote asset amount. (One of baseAmount or quoteAmount is required) (format: double)
  --side: string@side-completer # e.g. SELL
  --walletType: string@walletType-completer # SPOT or FUNDING or SPOT_FUNDING. It is to use which type of assets. Default is SPOT. (e.g. SPOT)
  --expiredType: string@expiredType-completer # 1_D, 3_D, 7_D, 30_D (D means day) (e.g. 1_D)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderId: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseAsset" $baseAsset "scalar") (serialize-qp "quoteAsset" $quoteAsset "scalar") (serialize-qp "limitPrice" $limitPrice "scalar") (serialize-qp "baseAmount" $baseAmount "scalar") (serialize-qp "quoteAmount" $quoteAmount "scalar") (serialize-qp "side" $side "scalar") (serialize-qp "walletType" $walletType "scalar") (serialize-qp "expiredType" $expiredType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/limit/placeOrder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel limit order (USER_DATA)
#
# POST /sapi/v1/convert/limit/cancelOrder
export def "sapi-convert-limit-cancel-order post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderId: int # format: int64, e.g. 1603680255057330400
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<orderId: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderId" $orderId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/limit/cancelOrder" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query limit open orders (USER_DATA)
#
# GET /sapi/v1/convert/limit/queryOpenOrders
export def "sapi-convert-limit-query-open-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<list: table<quoteId: string, orderId: int, orderStatus: string, fromAsset: string, fromAmount: string, toAsset: string, toAmount: string, ratio: string, inverseRatio: string, createTime: int, expiredTimestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/limit/queryOpenOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Convert Trade History (USER_DATA)
#
# GET /sapi/v1/convert/tradeFlow
export def "sapi-convert-trade-flow get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64, e.g. 1624248872184)
  --endTime: int # UTC timestamp in ms (format: int64, e.g. 1624248872185)
  --limit: int # default 100, max 1000 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<list: table<quoteId: string, orderId: int, orderStatus: string, fromAsset: string, fromAmount: string, toAsset: string, toAmount: string, ratio: string, inverseRatio: string, createTime: int>, startTime: int, endTime: int, limit: int, moreData: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/convert/tradeFlow" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Spot Rebate History Records (USER_DATA)
#
# GET /sapi/v1/rebate/taxQuery
export def "sapi-rebate-tax-query get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --page: int # default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<status: string, type: string, code: string, data: record<page: int, totalRecords: int, totalPageNum: int, data: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/rebate/taxQuery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT Transaction History (USER_DATA)
#
# GET /sapi/v1/nft/history/transactions
export def "sapi-nft-history-transactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orderType: int # 0: purchase order, 1: sell order, 2: royalty income, 3: primary market order, 4: mint fee (format: int32, e.g. 1)
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 50, Max 50 (format: int32, e.g. 50)
  --page: int # Default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<orderNo: string, tokens: list, tradeTime: int, tradeAmount: string, tradeCurrency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderType" $orderType "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/nft/history/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT Deposit History(USER_DATA)
#
# GET /sapi/v1/nft/history/deposit
export def "sapi-nft-history-deposit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 50, Max 50 (format: int32, e.g. 50)
  --page: int # Default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<network: string, txID: int, contractAdrress: string, tokenId: string, timestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/nft/history/deposit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT Withdraw History (USER_DATA)
#
# GET /sapi/v1/nft/history/withdraw
export def "sapi-nft-history-withdraw get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --limit: int # Default 50, Max 50 (format: int32, e.g. 50)
  --page: int # Default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<network: string, txID: string, contractAdrress: string, tokenId: string, timestamp: int, fee: float, feeAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/nft/history/withdraw" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get NFT Asset (USER_DATA)
#
# GET /sapi/v1/nft/user/getAsset
export def "sapi-nft-user-get-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Default 50, Max 50 (format: int32, e.g. 50)
  --page: int # Default 1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<network: string, contractAddress: string, tokenId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/nft/user/getAsset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Binance Code (USER_DATA)
#
# POST /sapi/v1/giftcard/createCode
export def "sapi-giftcard-create-code post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # The coin type contained in the Binance Code
  --amount: float # The amount of the coin (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<referenceNo: string, code: string, expiredTime: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/createCode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem a Binance Code (USER_DATA)
#
# POST /sapi/v1/giftcard/redeemCode
export def "sapi-giftcard-redeem-code post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Binance Code
  --externalUid: string # Each external unique ID represents a unique user on the partner platform. The function helps you to identify the redemption behavior of different users, such as redemption frequency and amount. It also helps risk and limit control of a single account, such as daily limit on redemption volume, frequency, and incorrect number of entries. This will also prevent a single user account reach the partner's daily redemption limits. We strongly recommend you to use this feature and transfer us the User ID of your users if you have different users redeeming Binance codes on your platform. To protect user data privacy, you may choose to transfer the user id in any desired format (max. 400 characters).
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<token: string, amount: string, referenceNo: string, identityNo: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "externalUid" $externalUid "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/redeemCode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a Binance Code (USER_DATA)
#
# GET /sapi/v1/giftcard/verify
export def "sapi-giftcard-verify get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --referenceNo: string # reference number
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<valid: bool, token: string, amount: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "referenceNo" $referenceNo "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/verify" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch RSA Public Key (USER_DATA)
#
# GET /sapi/v1/giftcard/cryptography/rsa-public-key
export def "sapi-giftcard-cryptography-rsa-public-key get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/cryptography/rsa-public-key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Buy a Binance Code (TRADE)
#
# POST /sapi/v1/giftcard/buyCode
export def "sapi-giftcard-buy-code post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseToken: string # The token you want to pay, example BUSD
  --faceToken: string # The token you want to buy, example BNB. If faceToken = baseToken, it's the same as createCode endpoint.
  --baseTokenAmount: float # The base token asset quantity, example  1.002 (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<referenceNo: string, code: string, expiredTime: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseToken" $baseToken "scalar") (serialize-qp "faceToken" $faceToken "scalar") (serialize-qp "baseTokenAmount" $baseTokenAmount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/buyCode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Token Limit (USER_DATA)
#
# GET /sapi/v1/giftcard/buyCode/token-limit
export def "sapi-giftcard-buy-code-token-limit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseToken: string # The token you want to pay, example BUSD
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<coin: string, fromMin: string, fromMax: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseToken" $baseToken "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/giftcard/buyCode/token-limit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get target asset list (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/target-asset/list
export def "sapi-lending-auto-invest-target-asset-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetAsset: string
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<targetAssets: string, autoInvestAssetList: table<targetAsset: string, roiAndDimensionTypeList: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetAsset" $targetAsset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/target-asset/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get target asset ROI data (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/target-asset/roi/list
export def "sapi-lending-auto-invest-target-asset-roi-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetAsset: string # e.g. BTC
  --hisRoiType: string # e.g. FIVE_YEAR
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<date: string, simulateRoi: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetAsset" $targetAsset "scalar") (serialize-qp "hisRoiType" $hisRoiType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/target-asset/roi/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query all source asset and target asset (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/all/asset
export def "sapi-lending-auto-invest-all-asset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<targetAssets: list<string>, sourceAssets: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/all/asset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query source asset list (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/source-asset/list
export def "sapi-lending-auto-invest-source-asset-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --targetAsset: string # e.g. BTC
  --indexId: int # format: int64, e.g. 1
  --usageType: string # e.g. RECURRING
  --flexibleAllowedToUse: string@bool-completer # e.g. true
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<feeRate: string, sourceAssets: table<sourceAsset: string, assetMinAmount: string, assetMaxAmount: string, scale: string, flexibleAmount: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "targetAsset" $targetAsset "scalar") (serialize-qp "indexId" $indexId "scalar") (serialize-qp "usageType" $usageType "scalar") (serialize-qp "flexibleAllowedToUse" $flexibleAllowedToUse "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/source-asset/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Investment plan creation (USER_DATA)
#
# POST /sapi/v1/lending/auto-invest/plan/add
export def "sapi-lending-auto-invest-plan-add post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceType: string@sourceType-completer # e.g. MAIN_SITE
  --requestId: string
  --planType: string@planType-completer # e.g. SINGLE
  --IndexId: int # format: int64
  --subscriptionAmount: float # format: float
  --subscriptionCycle: string@subscriptionCycle-completer
  --subscriptionStartDay: int
  --subscriptionStartWeekday: string@subscriptionStartWeekday-completer
  --subscriptionStartTime: int
  --sourceAsset: string # e.g. USDT
  --flexibleAllowedToUse: string@bool-completer # e.g. true
  --details: list
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<planId: int, nextExecutionDateTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceType" $sourceType "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "planType" $planType "scalar") (serialize-qp "IndexId" $IndexId "scalar") (serialize-qp "subscriptionAmount" $subscriptionAmount "scalar") (serialize-qp "subscriptionCycle" $subscriptionCycle "scalar") (serialize-qp "subscriptionStartDay" $subscriptionStartDay "scalar") (serialize-qp "subscriptionStartWeekday" $subscriptionStartWeekday "scalar") (serialize-qp "subscriptionStartTime" $subscriptionStartTime "scalar") (serialize-qp "sourceAsset" $sourceAsset "scalar") (serialize-qp "flexibleAllowedToUse" $flexibleAllowedToUse "scalar") (serialize-qp "details" $details "multi") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/plan/add" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Investment plan adjustment
#
# POST /sapi/v1/lending/auto-invest/plan/edit
export def "sapi-lending-auto-invest-plan-edit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --planId: int
  --subscriptionAmount: float # format: float
  --subscriptionCycle: string@subscriptionCycle-completer
  --subscriptionStartDay: int
  --subscriptionStartWeekday: string@subscriptionStartWeekday-completer
  --subscriptionStartTime: int
  --sourceAsset: string # e.g. USDT
  --flexibleAllowedToUse: string@bool-completer # e.g. true
  --details: list
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<planId: int, nextExecutionDateTime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar") (serialize-qp "subscriptionAmount" $subscriptionAmount "scalar") (serialize-qp "subscriptionCycle" $subscriptionCycle "scalar") (serialize-qp "subscriptionStartDay" $subscriptionStartDay "scalar") (serialize-qp "subscriptionStartWeekday" $subscriptionStartWeekday "scalar") (serialize-qp "subscriptionStartTime" $subscriptionStartTime "scalar") (serialize-qp "sourceAsset" $sourceAsset "scalar") (serialize-qp "flexibleAllowedToUse" $flexibleAllowedToUse "scalar") (serialize-qp "details" $details "multi") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/plan/edit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Plan Status
#
# POST /sapi/v1/lending/auto-invest/plan/edit-status
export def "sapi-lending-auto-invest-plan-edit-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --planId: int
  --status: string@status-completer-1
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<planId: int, nextExecutionDateTime: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/plan/edit-status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of plans
#
# GET /sapi/v1/lending/auto-invest/plan/list
export def "sapi-lending-auto-invest-plan-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --planType: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<planValueInUSD: string, planValueInBTC: string, pnlInUSD: string, roi: string, plan: table<planId: int, planType: string, editAllowed: string, creationDateTime: int, firstExecutionDateTime: int, nextExecutionDateTime: int, status: string, lastUpdatedDateTime: int, targetAsset: string, totalTargetAmount: string, sourceAsset: string, totalInvestedInUSD: string, subscriptionAmount: string, subscriptionCycle: string, subscriptionStartDay: string, subscriptionStartWeekday: string, subscriptionStartTime: string, sourceWallet: string, flexibleAllowedToUse: string, planValueInUSD: string, pnlInUSD: string, roi: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planType" $planType "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/plan/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query holding details of the plan
#
# GET /sapi/v1/lending/auto-invest/plan/id
export def "sapi-lending-auto-invest-plan-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --planId: int # format: int64
  --requestId: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<planValueInUSD: string, planValueInBTC: string, pnlInUSD: string, roi: string, plan: table<planId: int, planType: string, editAllowed: string, flexibleAllowedToUse: string, creationDateTime: int, firstExecutionDateTime: int, nextExecutionDateTime: int, status: string, targetAsset: string, sourceAsset: string, totalInvestedInUSD: string, planValueInUSD: string, pnlInUSD: string, roi: string, details: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/plan/id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query subscription transaction history
#
# GET /sapi/v1/lending/auto-invest/history/list
export def "sapi-lending-auto-invest-history-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --planId: int # format: int64
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --targetAsset: float # format: int64
  --planType: string@planType-completer-1
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<id: int, targetAsset: string, planType: string, planName: string, planId: int, transactionDateTime: int, transactionStatus: string, failedType: string, sourceAsset: string, sourceAssetAmount: string, targetAssetAmount: string, sourceWallet: string, flexibleUsed: string, transactionFee: string, transactionFeeUnit: string, executionPrice: string, executionType: string, subscriptionCycle: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "targetAsset" $targetAsset "scalar") (serialize-qp "planType" $planType "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/history/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Index Details(USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/index/info
export def "sapi-lending-auto-invest-index-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --indexId: int # format: int64
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<indexId: int, indexName: string, status: string, assetAllocation: table<targetAsset: string, allocation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexId" $indexId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/index/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Index Linked Plan Position Details(USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/index/user-summary
export def "sapi-lending-auto-invest-index-user-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --indexId: int # format: int64
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<indexId: int, totalInvestedInUSD: string, currentInvestedInUSD: string, pnlInUSD: string, roi: string, assetAllocation: table<targetAsset: string, allocation: string>, details: table<targetAsset: string, averagePriceInUSD: string, totalInvestedInUSD: string, currentInvestedInUSD: string, purchasedAmount: string, pnlInUSD: string, roi: string, percentage: string, availableAmount: string, redeemedAmount: string, assetValueInUSD: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexId" $indexId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/index/user-summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# One Time Transaction(TRADE)
#
# POST /sapi/v1/lending/auto-invest/one-off
export def "sapi-lending-auto-invest-one-off post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceType: string # e.g. MAIN_SITE
  --requestId: string # e.g. TR12354859
  --subscriptionAmount: float # format: float, e.g. 10.1
  --sourceAsset: string # e.g. USDT
  --flexibleAllowedToUse: string@bool-completer # e.g. true
  --planId: int # format: int64, e.g. 12345
  --indexId: int # format: int64, e.g. 1
  --details: list
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<transactionId: int, waitSecond: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceType" $sourceType "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "subscriptionAmount" $subscriptionAmount "scalar") (serialize-qp "sourceAsset" $sourceAsset "scalar") (serialize-qp "flexibleAllowedToUse" $flexibleAllowedToUse "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "indexId" $indexId "scalar") (serialize-qp "details" $details "multi") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/one-off" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query One-Time Transaction Status (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/one-off/status
export def "sapi-lending-auto-invest-one-off-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --transactionId: int # format: int64, e.g. 12345
  --requestId: string # e.g. TR12354859
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<transactionId: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "transactionId" $transactionId "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/one-off/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Index Linked Plan Redemption (TRADE)
#
# POST /sapi/v1/lending/auto-invest/redeem
export def "sapi-lending-auto-invest-redeem post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --indexId: int # PORTFOLIO plan's Id (format: int64, e.g. 123456)
  --requestId: string # sourceType + unique, transactionId and requestId cannot be empty at the same time (e.g. TR12354859)
  --redemptionPercentage: int # user redeem percentage,10/20/100. (e.g. 10)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<redemptionId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexId" $indexId "scalar") (serialize-qp "requestId" $requestId "scalar") (serialize-qp "redemptionPercentage" $redemptionPercentage "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/redeem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Index Linked Plan Redemption History (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/redeem/history
export def "sapi-lending-auto-invest-redeem-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requestId: int # format: int64, e.g. 12345
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --asset: string # e.g. BTC
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<indexId: int, indexName: string, redemptionId: int, status: string, asset: string, amount: string, redemptionDateTime: int, transactionFee: string, transactionFeeUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/redeem/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Index Linked Plan Rebalance Details (USER_DATA)
#
# GET /sapi/v1/lending/auto-invest/rebalance/history
export def "sapi-lending-auto-invest-rebalance-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<indexId: int, indexName: string, rebalanceId: int, status: string, rebalanceFee: string, rebalanceFeeUnit: string, transactionDetails: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/lending/auto-invest/rebalance/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe ETH Staking V2(TRADE)
#
# POST /sapi/v2/eth-staking/eth/stake
export def "sapi-eth-staking-eth-stake post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: float # Amount in ETH, limit 4 decimals (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, wbethAmount: string, conversionRatio: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/eth-staking/eth/stake" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem ETH (TRADE)
#
# POST /sapi/v1/eth-staking/eth/redeem
export def "sapi-eth-staking-eth-redeem post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # WBETH or BETH, default to BETH
  --amount: float # Amount in BETH, limit 8 decimals (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, arrivalTime: int, ethAmount: string, conversionRatio: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/redeem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETH staking history (USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/history/stakingHistory
export def "sapi-eth-staking-eth-history-staking-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<time: int, asset: string, amount: string, status: string, distributeAmount: string, conversionRatio: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/history/stakingHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ETH redemption history (USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/history/redemptionHistory
export def "sapi-eth-staking-eth-history-redemption-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<time: int, arrivalTime: int, asset: string, amount: string, status: string, distributeAsset: string, distributeAmount: string, conversionRatio: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/history/redemptionHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get BETH rewards distribution history(USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/history/rewardsHistory
export def "sapi-eth-staking-eth-history-rewards-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<time: int, asset: string, holding: string, amount: string, annualPercentageRate: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/history/rewardsHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current ETH staking quota (USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/quota
export def "sapi-eth-staking-eth-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<leftStakingPersonalQuota: string, leftRedemptionPersonalQuota: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/quota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get WBETH Rate History (USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/history/rateHistory
export def "sapi-eth-staking-eth-history-rate-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<annualPercentageRate: string, exchangeRate: string, time: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/history/rateHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ETH Staking account V2(USER_DATA)
#
# GET /sapi/v2/eth-staking/account
export def "sapi-eth-staking-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<holdingInETH: string, holdings: record<wbethAmount: string, bethAmount: string>, thirtyDaysProfitInETH: string, profit: record<amountFromWBETH: string, amountFromBETH: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v2/eth-staking/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Wrap BETH(TRADE)
#
# POST /sapi/v1/eth-staking/wbeth/wrap
export def "sapi-eth-staking-wbeth-wrap post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: float # Amount in BETH, limit 4 decimals (format: double)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool, wbethAmount: string, exchangeRate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/wbeth/wrap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get WBETH wrap history (USER_DATA)
#
# GET /sapi/v1/eth-staking/wbeth/history/wrapHistory
export def "sapi-eth-staking-wbeth-history-wrap-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<time: int, fromAsset: string, fromAmount: string, toAsset: string, toAmount: string, exchangeRate: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/wbeth/history/wrapHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get WBETH unwrap history (USER_DATA)
#
# GET /sapi/v1/eth-staking/wbeth/history/unwrapHistory
export def "sapi-eth-staking-wbeth-history-unwrap-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<time: int, fromAsset: string, fromAmount: string, toAsset: string, toAmount: string, exchangeRate: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/wbeth/history/unwrapHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get WBETH rewards history(USER_DATA)
#
# GET /sapi/v1/eth-staking/eth/history/wbethRewardsHistory
export def "sapi-eth-staking-eth-history-wbeth-rewards-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<estRewardsInETH: string, rows: table<time: int, amountInETH: string, holding: string, holdingInETH: string, annualPercentageRate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/eth-staking/eth/history/wbethRewardsHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Futures Lead Trader Status(TRADE)
#
# GET /sapi/v1/copyTrading/futures/userStatus
export def "sapi-copy-trading-futures-user-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<isLeadTrader: bool, time: int>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/copyTrading/futures/userStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Futures Lead Trading Symbol Whitelist(USER_DATA)
#
# GET /sapi/v1/copyTrading/futures/leadSymbol
export def "sapi-copy-trading-futures-lead-symbol get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<code: string, message: string, data: record<symbol: string, baseAsset: string, quoteAsset: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/copyTrading/futures/leadSymbol" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Simple Earn Flexible Product List (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/list
export def "sapi-simple-earn-flexible-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BTC
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<asset: string, latestAnnualPercentageRate: string, tierAnnualPercentageRate: record, airDropPercentageRate: string, canPurchase: bool, canRedeem: bool, isSoldOut: bool, hot: bool, minPurchaseAmount: string, productId: string, subscriptionStartTime: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Simple Earn Locked Product List (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/list
export def "sapi-simple-earn-locked-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string # e.g. BNB
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<projectId: string, detail: record, quota: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe Flexible Product (TRADE)
#
# POST /sapi/v1/simple-earn/flexible/subscribe
export def "sapi-simple-earn-flexible-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --amount: float # format: double
  --autoSubscribe: string@bool-completer # true or false, default true.
  --sourceAccount: string # SPOT,FUND,ALL, default SPOT
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<purchaseId: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "autoSubscribe" $autoSubscribe "scalar") (serialize-qp "sourceAccount" $sourceAccount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/subscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe Locked Product (TRADE)
#
# POST /sapi/v1/simple-earn/locked/subscribe
export def "sapi-simple-earn-locked-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --amount: float # format: double
  --autoSubscribe: string@bool-completer # true or false, default true.
  --sourceAccount: string # SPOT,FUND,ALL, default SPOT
  --redeemTo: string@redeemTo-completer # SPOT,FLEXIBLE, default FLEXIBLE
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<purchaseId: int, positionId: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "autoSubscribe" $autoSubscribe "scalar") (serialize-qp "sourceAccount" $sourceAccount "scalar") (serialize-qp "redeemTo" $redeemTo "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/subscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem Flexible Product (TRADE)
#
# POST /sapi/v1/simple-earn/flexible/redeem
export def "sapi-simple-earn-flexible-redeem post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --redeemAll: string@bool-completer # true or false, default to false
  --amount: float # if redeemAll is false, amount is mandatory (format: double)
  --destAccount: string # SPOT,FUND,ALL, default SPOT
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<redeemId: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "redeemAll" $redeemAll "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "destAccount" $destAccount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/redeem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Redeem Locked Product (TRADE)
#
# POST /sapi/v1/simple-earn/locked/redeem
export def "sapi-simple-earn-locked-redeem post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: string # 1234
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<redeemId: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/redeem" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Product Position (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/position
export def "sapi-simple-earn-flexible-position get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string
  --productId: string
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<totalAmount: string, tierAnnualPercentageRate: record, latestAnnualPercentageRate: string, yesterdayAirdropPercentageRate: string, asset: string, airDropAsset: string, canRedeem: bool, collateralAmount: string, productId: string, yesterdayRealTimeRewards: string, cumulativeBonusRewards: string, cumulativeRealTimeRewards: string, cumulativeTotalRewards: string, autoSubscribe: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "productId" $productId "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/position" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Product Position (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/position
export def "sapi-simple-earn-locked-position get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asset: string
  --positionId: string
  --projectId: string
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<positionId: string, parentPositionId: string, projectId: string, asset: string, amount: string, purchaseTime: string, duration: string, accrualDays: string, rewardAsset: string, APY: string, rewardAmt: string, extraRewardAsset: string, extraRewardAPR: string, estExtraRewardAmt: string, nextPay: string, nextPayDate: string, payPeriod: string, redeemAmountEarly: string, rewardsEndDate: string, deliverDate: string, redeemPeriod: string, redeemingAmt: string, redeemTo: string, partialAmtDeliverDate: string, canRedeemEarly: bool, canFastRedemption: bool, autoSubscribe: bool, type: string, status: string, canReStake: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset" $asset "scalar") (serialize-qp "positionId" $positionId "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/position" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Simple Account (USER_DATA)
#
# GET /sapi/v1/simple-earn/account
export def "sapi-simple-earn-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalAmountInBTC: string, totalAmountInUSDT: string, totalFlexibleAmountInBTC: string, totalFlexibleAmountInUSDT: string, totalLockedInBTC: string, totalLockedInUSDT: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Subscription Record (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/history/subscriptionRecord
export def "sapi-simple-earn-flexible-history-subscription-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --purchaseId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<amount: string, asset: string, time: int, purchaseId: int, productId: string, type: string, sourceAccount: string, amtFromSpot: string, amtFromFunding: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "purchaseId" $purchaseId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/history/subscriptionRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Subscription Record (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/history/subscriptionRecord
export def "sapi-simple-earn-locked-history-subscription-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --purchaseId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<positionId: string, purchaseId: int, projectId: string, time: int, asset: string, amount: string, lockPeriod: string, type: string, sourceAccount: string, amtFromSpot: string, amtFromFunding: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "purchaseId" $purchaseId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/history/subscriptionRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Redemption Record (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/history/redemptionRecord
export def "sapi-simple-earn-flexible-history-redemption-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --redeemId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
]: nothing -> record<rows: table<amount: string, asset: string, time: int, projectId: string, redeemId: int, destAccount: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "redeemId" $redeemId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/history/redemptionRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Redemption Record (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/history/redemptionRecord
export def "sapi-simple-earn-locked-history-redemption-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: string
  --redeemId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<positionId: string, redeemId: int, time: int, asset: string, lockPeriod: string, amount: string, originalAmount: string, type: string, deliverDate: string, lossAmount: string, isComplete: bool, rewardAsset: string, rewardAmt: string, extraRewardAsset: string, estExtraRewardAmt: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "redeemId" $redeemId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/history/redemptionRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Rewards History (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/history/rewardsRecord
export def "sapi-simple-earn-flexible-history-rewards-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --type: string # "BONUS", "REALTIME", "REWARDS"
]: nothing -> record<rows: table<asset: string, rewards: string, projectId: string, type: string, time: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/history/rewardsRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Rewards History (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/history/rewardsRecord
export def "sapi-simple-earn-locked-history-rewards-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: string
  --asset: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<positionId: string, time: int, asset: string, lockPeriod: string, amount: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "asset" $asset "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/history/rewardsRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Flexible Auto Subscribe (USER_DATA)
#
# POST /sapi/v1/simple-earn/flexible/setAutoSubscribe
export def "sapi-simple-earn-flexible-set-auto-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --autoSubscribe: string@bool-completer # true or false
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "autoSubscribe" $autoSubscribe "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/setAutoSubscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Locked Auto Subscribe (USER_DATA)
#
# POST /sapi/v1/simple-earn/locked/setAutoSubscribe
export def "sapi-simple-earn-locked-set-auto-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: string
  --autoSubscribe: string@bool-completer # true or false
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "autoSubscribe" $autoSubscribe "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/setAutoSubscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Personal Left Quota (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/personalLeftQuota
export def "sapi-simple-earn-flexible-personal-left-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<leftPersonalQuota: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/personalLeftQuota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Personal Left Quota (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/personalLeftQuota
export def "sapi-simple-earn-locked-personal-left-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<leftPersonalQuota: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/personalLeftQuota" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Flexible Subscription Preview (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/subscriptionPreview
export def "sapi-simple-earn-flexible-subscription-preview get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --amount: float # format: double
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalAmount: string, rewardAsset: string, airDropAsset: string, estDailyBonusRewards: string, estDailyRealTimeRewards: string, estDailyAirdropRewards: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/subscriptionPreview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locked Subscription Preview (USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/subscriptionPreview
export def "sapi-simple-earn-locked-subscription-preview get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --projectId: string
  --amount: float # format: double
  --autoSubscribe: string@bool-completer # true or false, default true.
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> table<rewardAsset: string, totalRewardAmt: string, extraRewardAsset: string, estTotalExtraRewardAmt: string, nextPay: string, nextPayDate: string, valueDate: string, rewardsEndDate: string, deliverDate: string, nextSubscriptionDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "projectId" $projectId "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "autoSubscribe" $autoSubscribe "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/subscriptionPreview" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set Locked Product Redeem Option(USER_DATA)
#
# GET /sapi/v1/simple-earn/locked/setRedeemOption
export def "sapi-simple-earn-locked-set-redeem-option get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: string
  --redeemTo: string@redeemTo-completer # SPOT,FLEXIBLE, default FLEXIBLE
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "redeemTo" $redeemTo "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/locked/setRedeemOption" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Rate History (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/history/rateHistory
export def "sapi-simple-earn-flexible-history-rate-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<productId: string, asset: string, annualPercentageRate: string, time: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/history/rateHistory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Collateral Record (USER_DATA)
#
# GET /sapi/v1/simple-earn/flexible/history/collateralRecord
export def "sapi-simple-earn-flexible-history-collateral-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string
  --startTime: int # UTC timestamp in ms (format: int64)
  --endTime: int # UTC timestamp in ms (format: int64)
  --current: int # Current querying page. Start from 1. Default:1 (format: int32, e.g. 1)
  --size: int # Default:10 Max:100 (format: int32, e.g. 100)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<rows: table<amount: string, productId: string, asset: string, createTime: int, type: string, productName: string, orderId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "current" $current "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/simple-earn/flexible/history/collateralRecord" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dual Investment product list(USER_DATA)
#
# GET /sapi/v1/dci/product/list
export def "sapi-dci-product-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --optionType: string@optionType-completer # Input CALL or PUT
  --exercisedCoin: string # Target exercised asset, e.g.: if you subscribe to a high sell product (call option), you should input:   - optionType: CALL,   - exercisedCoin: USDT,   - investCoin: BNB;  if you subscribe to a low buy product (put option), you should input:   - optionType: PUT,   - exercisedCoin: BNB,   - investCoin: USDT;
  --investCoin: string # Asset used for subscribing, e.g.: if you subscribe to a high sell product (call option), you should input:   - optionType: CALL,   - exercisedCoin: USDT,   - investCoin: BNB;  if you subscribe to a low buy product (put option), you should input:   - optionType: PUT,   - exercisedCoin: BNB,   - investCoin: USDT;
  --pageSize: string # MIN 1, MAX 100; Default 100
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<id: string, investCoin: string, exercisedCoin: string, strikePrice: string, duration: int, settleDate: int, purchaseDecimal: int, purchaseEndTime: int, canPurchase: bool, apr: string, orderId: int, minAmount: string, maxAmount: string, createTimestamp: int, optionType: string, isAutoCompoundEnable: bool, autoCompoundPlanList: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "optionType" $optionType "scalar") (serialize-qp "exercisedCoin" $exercisedCoin "scalar") (serialize-qp "investCoin" $investCoin "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/dci/product/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subscribe Dual Investment products(USER_DATA)
#
# POST /sapi/v1/dci/product/subscribe
export def "sapi-dci-product-subscribe post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # get id from /sapi/v1/dci/product/list
  --orderId: string # get orderId from /sapi/v1/dci/product/list
  --depositAmount: float # format: double
  --autoCompoundPlan: string@autoCompoundPlan-completer # NONE: switch off the plan, STANDARD: standard plan, ADVANCED: advanced plan;
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<positionId: int, investCoin: string, exercisedCoin: string, subscriptionAmount: string, duration: int, autoCompoundPlan: string, strikePrice: string, settleDate: int, purchaseStatus: string, apr: string, orderId: int, purchaseTime: int, optionType_: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "orderId" $orderId "scalar") (serialize-qp "depositAmount" $depositAmount "scalar") (serialize-qp "autoCompoundPlan" $autoCompoundPlan "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/dci/product/subscribe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Dual Investment positions(USER_DATA)
#
# GET /sapi/v1/dci/product/positions
export def "sapi-dci-product-positions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-2 # - PENDING: Products are purchasing, will give results later; - PURCHASE_SUCCESS: purchase successfully; - SETTLED: Products are finish settling; - PURCHASE_FAIL: fail to purchase; - REFUNDING: refund ongoing; - REFUND_SUCCESS: refund to spot account successfully; - SETTLING: Products are settling. If don't fill this field, will response all the position status.
  --pageSize: string # MIN 1, MAX 100; Default 100
  --pageIndex: int # Page number, default is first page, start form 1 (format: int32)
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<total: int, list: table<id: string, investCoin: string, exercisedCoin: string, subscriptionAmount: string, strikePrice: string, duration: int, settleDate: int, purchaseStatus: string, apr: string, orderId: int, purchaseEndTime: int, optionType: string, autoCompoundPlan: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageIndex" $pageIndex "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/dci/product/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Dual Investment accounts(USER_DATA)
#
# GET /sapi/v1/dci/product/accounts
export def "sapi-dci-product-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<totalAmountInBTC: string, totalAmountInUSDT: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/dci/product/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Change Auto-Compound status(USER_DATA)
#
# POST /sapi/v1/dci/product/auto_compound/edit-status
export def "sapi-dci-product-auto-compound-edit-status post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --positionId: int # Get positionId from /sapi/v1/dci/product/positions (format: int64)
  --autoCompoundPlan: string@autoCompoundPlan-completer # NONE: switch off the plan, STANDARD: standard plan, ADVANCED: advanced plan;
  --recvWindow: int # The value cannot be greater than 60000 (format: int64, e.g. 5000)
  --timestamp: int # UTC timestamp in ms (format: int64)
  --signature: string # Signature
]: nothing -> record<positionId: string, autoCompoundPlan: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-mbx-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "positionId" $positionId "scalar") (serialize-qp "autoCompoundPlan" $autoCompoundPlan "scalar") (serialize-qp "recvWindow" $recvWindow "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sapi/v1/dci/product/auto_compound/edit-status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
