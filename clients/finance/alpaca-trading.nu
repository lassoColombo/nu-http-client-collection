# Auto-generated client for Trader API v2.0.0
# Source: https://raw.githubusercontent.com/alpacahq/alpaca-docs/master/oas/trading/openapi.yaml
# Auth: --token flag or $env.TRADER_API_TOKEN

const BASE_URL = "https://paper-api.alpaca.markets"
const DEFAULT_AUTH = "apca-api-key-id"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRADER_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://paper-api.alpaca.markets" "https://api.alpaca.markets"] }
def auth-scheme-completer [] { ["apca-api-key-id" "apca-api-secret-key"] }

# Completers for enum parameters
def asset-class-completer [] { ["crypto" "us_equity"] }
def order-class-completer [] { ["" "bracket" "oco" "oto" "simple"] }
def type-completer [] { ["limit" "market" "stop" "stop_limit" "trailing_stop"] }
def side-completer [] { ["buy" "sell"] }
def time-in-force-completer [] { ["cls" "day" "fok" "gtc" "ioc" "opg"] }
def status-completer [] { ["accepted" "accepted_for_bidding" "calculated" "canceled" "done_for_day" "expired" "filled" "new" "partially_filled" "pending_cancel" "pending_new" "pending_replace" "rejected" "replaced" "stopped" "suspended"] }
def status-completer-1 [] { ["all" "closed" "open"] }
def direction-completer [] { ["asc" "desc"] }
def dtbp-check-completer [] { ["both" "entry" "exit"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Get account
#
# GET /v2/account
# operationId: getAccount
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_number: string, status: string, currency: string, cash: string, portfolio_value: string, pattern_day_trader: bool, trade_suspended_by_user: bool, trading_blocked: bool, transfers_blocked: bool, account_blocked: bool, created_at: string, shorting_enabled: bool, long_market_value: string, short_market_value: string, equity: string, last_equity: string, multiplier: string, buying_power: string, initial_margin: string, maintenance_margin: string, sma: string, daytrade_count: int, last_maintenance_margin: string, daytrading_buying_power: string, regt_buying_power: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Order
#
# POST /v2/orders
# operationId: postOrder
# --legs item shape: {id?: string, client_order_id?: string, created_at?: string, updated_at?: string, submitted_at?: string, filled_at?: string, expired_at?: string, canceled_at?: string, failed_at?: string, replaced_at?: string, replaced_by?: string, replaces?: string, asset_id?: string, symbol: string, asset_class?: "us_equity"|"crypto", notional: string, qty: string, filled_qty?: string, filled_avg_price?: string, order_class?: "simple"|"bracket"|"oco"|"oto"|"", order_type?: string, type: "market"|"limit"|"stop"|"stop_limit"|"trailing_stop", side: "buy"|"sell", time_in_force: "day"|"gtc"|"opg"|"cls"|"ioc"|"fok", limit_price?: string, stop_price?: string, status?: "new"|"partially_filled"|"filled"|"done_for_day"|"canceled"|"expired"|"replaced"|"pending_cancel"|"pending_replace"|"accepted"|"pending_new"|"accepted_for_bidding"|"stopped"|"rejected"|"suspended"|"calculated", extended_hours?: bool, legs?: list, trail_percent?: string, trail_price?: string, hwm?: string}
@deprecated --flag order-type
export def "orders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Order ID
  --client-order-id: string # Client unique order ID
  --created-at: string # format: date-time
  --updated-at: string # nullable, format: date-time
  --submitted-at: string # nullable, format: date-time
  --filled-at: string # nullable, format: date-time
  --expired-at: string # nullable, format: date-time
  --canceled-at: string # nullable, format: date-time
  --failed-at: string # nullable, format: date-time
  --replaced-at: string # nullable, format: date-time
  --replaced-by: string # The order ID that this order was replaced by (nullable, format: uuid)
  --replaces: string # The order ID that this order replaces (nullable, format: uuid)
  --asset-id: string # Asset ID (format: uuid)
  symbol: string # Asset symbol
  --asset-class: string@asset-class-completer # Represents what class of asset this is. Currently only supports `us_equity` or `crypto` (e.g. us_equity)
  --notional: string # Ordered notional amount. If entered, qty will be null. Can take up to 9 decimal points. (nullable)
  --qty: string # Ordered quantity. If entered, notional will be null. Can take up to 9 decimal points. (nullable)
  --filled-qty: string # Filled quantity
  --filled-avg-price: string # Filled average price (nullable)
  --order-class: string@order-class-completer # This will either be the empty string "", "simple", "bracket", "oco", or "oto". (e.g. bracket)
  --order-type: string # Deprecated in favour of the field "type"  (DEPRECATED)
  type: string@type-completer # Represents the types of orders Alpaca currently supports  - market - limit - stop - stop_limit - trailing_stop (e.g. stop)
  side: string@side-completer # Represents which side this order was on:  - buy - sell (e.g. buy)
  time_in_force: string@time-in-force-completer # Note: For Crypto Trading, Alpaca supports the following Time-In-Force designations: day, gtc, ioc and fok. OPG and CLS are not supported.  Alpaca supports the following Time-In-Force designations:  - day   A day order is eligible for execution only on the day it is live. By default, the order is only valid during Regular Trading Hours (9:30am - 4:00pm ET). If unfilled after the closing auction, it is automatically canceled. If submitted after the close, it is queued and submitted the following trading day. However, if marked as eligible for extended hours, the order can also execute during supported extended hours.  - gtc   The order is good until canceled. Non-marketable GTC limit orders are subject to price adjustments to offset corporate actions affecting the issue. We do not currently support Do Not Reduce(DNR) orders to opt out of such price adjustments.  - opg   Use this TIF with a market/limit order type to submit “market on open” (MOO) and “limit on open” (LOO) orders. This order is eligible to execute only in the market opening auction. Any unfilled orders after the open will be cancelled. OPG orders submitted after 9:28am but before 7:00pm ET will be rejected. OPG orders submitted after 7:00pm will be queued and routed to the following day’s opening auction. On open/on close orders are routed to the primary exchange. Such orders do not necessarily execute exactly at 9:30am / 4:00pm ET but execute per the exchange’s auction rules.  - cls   Use this TIF with a market/limit order type to submit “market on close” (MOC) and “limit on close” (LOC) orders. This order is eligible to execute only in the market closing auction. Any unfilled orders after the close will be cancelled. CLS orders submitted after 3:50pm but before 7:00pm ET will be rejected. CLS orders submitted after 7:00pm will be queued and routed to the following day’s closing auction. Only available with API v2.  - ioc   An Immediate Or Cancel (IOC) order requires all or part of the order to be executed immediately. Any unfilled portion of the order is canceled. Only available with API v2. Most market makers who receive IOC orders will attempt to fill the order on a principal basis only, and cancel any unfilled balance. On occasion, this can result in the entire order being cancelled if the market maker does not have any existing inventory of the security in question.  - fok   A Fill or Kill (FOK) order is only executed if the entire order quantity can be filled, otherwise the order is canceled. Only available with API v2. (e.g. day)
  --limit-price: string # Limit price (nullable)
  --stop-price: string # Stop price (nullable)
  --status: string@status-completer # An order executed through Alpaca can experience several status changes during its lifecycle. The most common statuses are described in detail below:  - new   The order has been received by Alpaca, and routed to exchanges for execution. This is the usual initial state of an order.  - partially_filled   The order has been partially filled.  - filled   The order has been filled, and no further updates will occur for the order.  - done_for_day   The order is done executing for the day, and will not receive further updates until the next trading day.  - canceled   The order has been canceled, and no further updates will occur for the order. This can be either due to a cancel request by the user, or the order has been canceled by the exchanges due to its time-in-force.  - expired   The order has expired, and no further updates will occur for the order.  - replaced   The order was replaced by another order, or was updated due to a market event such as corporate action.  - pending_cancel   The order is waiting to be canceled.  - pending_replace   The order is waiting to be replaced by another order. The order will reject cancel request while in this state.  Less common states are described below. Note that these states only occur on very rare occasions, and most users will likely never see their orders reach these states:  - accepted   The order has been received by Alpaca, but hasn’t yet been routed to the execution venue. This could be seen often out side of trading session hours.  - pending_new   The order has been received by Alpaca, and routed to the exchanges, but has not yet been accepted for execution. This state only occurs on rare occasions.  - accepted_for_bidding   The order has been received by exchanges, and is evaluated for pricing. This state only occurs on rare occasions.  - stopped   The order has been stopped, and a trade is guaranteed for the order, usually at a stated price or better, but has not yet occurred. This state only occurs on rare occasions.  - rejected   The order has been rejected, and no further updates will occur for the order. This state occurs on rare occasions and may occur based on various conditions decided by the exchanges.  - suspended   The order has been suspended, and is not eligible for trading. This state only occurs on rare occasions.  - calculated   The order has been completed for the day (either filled or done for day), but remaining settlement calculations are still pending. This state only occurs on rare occasions.   An order may be canceled through the API up until the point it reaches a state of either filled, canceled, or expired. (e.g. new)
  --extended-hours: string@bool-completer # If true, eligible for execution outside regular trading hours.
  --legs: list # When querying non-simple order_class orders in a nested style, an array of Order entities associated with this order. Otherwise, null. (nullable) — item shape: {id?: string, client_order_id?: string, created_at?: string, updated_at?: string, submitted_at?: string, filled_at?: string, expired_at?: string, canceled_at?: string, failed_at?: string, replaced_at?: string, replaced_by?: string, replaces?: string, asset_id?: string, symbol: string, asset_class?: "us_equity"|"crypto", notional: string, qty: string, filled_qty?: string, filled_avg_price?: string, order_class?: "simple"|"bracket"|"oco"|"oto"|"", order_type?: string, type: "market"|"limit"|"stop"|"stop_limit"|"trailing_stop", side: "buy"|"sell", time_in_force: "day"|"gtc"|"opg"|"cls"|"ioc"|"fok", limit_price?: string, stop_price?: string, status?: "new"|"partially_filled"|"filled"|"done_for_day"|"canceled"|"expired"|"replaced"|"pending_cancel"|"pending_replace"|"accepted"|"pending_new"|"accepted_for_bidding"|"stopped"|"rejected"|"suspended"|"calculated", extended_hours?: bool, legs?: list, trail_percent?: string, trail_price?: string, hwm?: string}
  --trail-percent: string # The percent value away from the high water mark for trailing stop orders.
  --trail-price: string # The dollar value away from the high water mark for trailing stop orders.
  --hwm: string # The highest (lowest) market price seen since the trailing stop order was submitted.
]: any -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_percent: string, trail_price: string, hwm: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders")
  let body = {id: $id, client_order_id: $client_order_id, created_at: $created_at, updated_at: $updated_at, submitted_at: $submitted_at, filled_at: $filled_at, expired_at: $expired_at, canceled_at: $canceled_at, failed_at: $failed_at, replaced_at: $replaced_at, replaced_by: $replaced_by, replaces: $replaces, asset_id: $asset_id, symbol: $symbol, asset_class: $asset_class, notional: $notional, qty: $qty, filled_qty: $filled_qty, filled_avg_price: $filled_avg_price, order_class: $order_class, order_type: $order_type, type: $type, side: $side, time_in_force: $time_in_force, limit_price: $limit_price, stop_price: $stop_price, status: $status, extended_hours: $extended_hours, legs: $legs, trail_percent: $trail_percent, trail_price: $trail_price, hwm: $hwm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# All Orders
#
# GET /v2/orders
# operationId: getAllOrders
export def "orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Order status to be queried. open, closed or all. Defaults to open. (e.g. open)
  --limit: int # The maximum number of orders in response. Defaults to 50 and max is 500.
  --after: string # The response will include only ones submitted after this timestamp (exclusive.)
  --until: string # The response will include only ones submitted until this timestamp (exclusive.)
  --direction: string@direction-completer # The chronological order of response based on the submission time. asc or desc. Defaults to desc.
  --nested: string@bool-completer # If true, the result will roll up multi-leg orders under the legs field of primary order.
  --symbols: string # A comma-separated list of symbols to filter by (ex. “AAPL,TSLA,MSFT”). A currency pair is required for crypto orders (ex. “BTCUSD,BCHUSD,LTCUSD,ETCUSD”).
]: nothing -> table<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_percent: string, trail_price: string, hwm: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "nested" $nested "scalar") (serialize-qp "symbols" $symbols "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All Orders
#
# DELETE /v2/orders
# operationId: deleteAllOrders
export def "orders delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/orders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Order by Order ID
#
# GET /v2/orders/{order_id}
# operationId: getOrderByOrderID
export def "orders get" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nested: string@bool-completer # If true, the result will roll up multi-leg orders under the legs field of primary order.
]: nothing -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_percent: string, trail_price: string, hwm: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nested" $nested "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/orders/($order_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Order
#
# PATCH /v2/orders/{order_id}
# operationId: patchOrderByOrderId
export def "orders patch" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qty: string # number of shares to trade
  --time-in-force: string@time-in-force-completer # Note: For Crypto Trading, Alpaca supports the following Time-In-Force designations: day, gtc, ioc and fok. OPG and CLS are not supported.  Alpaca supports the following Time-In-Force designations:  - day   A day order is eligible for execution only on the day it is live. By default, the order is only valid during Regular Trading Hours (9:30am - 4:00pm ET). If unfilled after the closing auction, it is automatically canceled. If submitted after the close, it is queued and submitted the following trading day. However, if marked as eligible for extended hours, the order can also execute during supported extended hours.  - gtc   The order is good until canceled. Non-marketable GTC limit orders are subject to price adjustments to offset corporate actions affecting the issue. We do not currently support Do Not Reduce(DNR) orders to opt out of such price adjustments.  - opg   Use this TIF with a market/limit order type to submit “market on open” (MOO) and “limit on open” (LOO) orders. This order is eligible to execute only in the market opening auction. Any unfilled orders after the open will be cancelled. OPG orders submitted after 9:28am but before 7:00pm ET will be rejected. OPG orders submitted after 7:00pm will be queued and routed to the following day’s opening auction. On open/on close orders are routed to the primary exchange. Such orders do not necessarily execute exactly at 9:30am / 4:00pm ET but execute per the exchange’s auction rules.  - cls   Use this TIF with a market/limit order type to submit “market on close” (MOC) and “limit on close” (LOC) orders. This order is eligible to execute only in the market closing auction. Any unfilled orders after the close will be cancelled. CLS orders submitted after 3:50pm but before 7:00pm ET will be rejected. CLS orders submitted after 7:00pm will be queued and routed to the following day’s closing auction. Only available with API v2.  - ioc   An Immediate Or Cancel (IOC) order requires all or part of the order to be executed immediately. Any unfilled portion of the order is canceled. Only available with API v2. Most market makers who receive IOC orders will attempt to fill the order on a principal basis only, and cancel any unfilled balance. On occasion, this can result in the entire order being cancelled if the market maker does not have any existing inventory of the security in question.  - fok   A Fill or Kill (FOK) order is only executed if the entire order quantity can be filled, otherwise the order is canceled. Only available with API v2. (e.g. day)
  --limit-price: string # required if original order type is limit or stop_limit
  --stop-price: string # required if original order type is limit or stop_limit
  --trail: string # the new value of the trail_price or trail_percent value (works only for type=“trailing_stop”)
  --client-order-id: string # A unique identifier for the order. Automatically generated if not sent.
]: any -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_percent: string, trail_price: string, hwm: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)")
  let body = {qty: $qty, time_in_force: $time_in_force, limit_price: $limit_price, stop_price: $stop_price, trail: $trail, client_order_id: $client_order_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Order by Order ID
#
# DELETE /v2/orders/{order_id}
# operationId: deleteOrderByOrderID
export def "orders delete-by-order_id" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/orders/($order_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All Open Positions
#
# GET /v2/positions
# operationId: getAllOpenPositions
export def "positions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<asset_id: string, symbol: string, exchange: string, asset_class: string, avg_entry_price: string, qty: string, qty_available: string, side: string, market_value: string, cost_basis: string, unrealized_pl: string, unrealized_plpc: string, unrealized_intraday_pl: string, unrealized_intraday_plpc: string, current_price: string, lastday_price: string, change_today: string, asset_marginable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/positions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All Positions
#
# DELETE /v2/positions
# operationId: deleteAllOpenPositions
export def "positions delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cancel-orders: string@bool-completer # If true is specified, cancel all open orders before liquidating all positions.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cancel_orders" $cancel_orders "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/positions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Open Position
#
# GET /v2/positions/{symbol_or_asset_id}
# operationId: getOpenPosition
export def "positions get" [
  symbol_or_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<asset_id: string, symbol: string, exchange: string, asset_class: string, avg_entry_price: string, qty: string, qty_available: string, side: string, market_value: string, cost_basis: string, unrealized_pl: string, unrealized_plpc: string, unrealized_intraday_pl: string, unrealized_intraday_plpc: string, current_price: string, lastday_price: string, change_today: string, asset_marginable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/positions/($symbol_or_asset_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Position
#
# DELETE /v2/positions/{symbol_or_asset_id}
# operationId: deleteOpenPosition
export def "positions delete-by-symbol_or_asset_id" [
  symbol_or_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qty: float # the number of shares to liquidate. Can accept up to 9 decimal points. Cannot work with percentage
  --percentage: float # percentage of position to liquidate. Must be between 0 and 100. Would only sell fractional if position is originally fractional. Can accept up to 9 decimal points. Cannot work with qty
]: nothing -> record<id: string, client_order_id: string, created_at: string, updated_at: string, submitted_at: string, filled_at: string, expired_at: string, canceled_at: string, failed_at: string, replaced_at: string, replaced_by: string, replaces: string, asset_id: string, symbol: string, asset_class: string, notional: string, qty: string, filled_qty: string, filled_avg_price: string, order_class: string, order_type: string, type: string, side: string, time_in_force: string, limit_price: string, stop_price: string, status: string, extended_hours: bool, legs: list<any>, trail_percent: string, trail_price: string, hwm: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "qty" $qty "scalar") (serialize-qp "percentage" $percentage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/positions/($symbol_or_asset_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Portfolio History
#
# GET /v2/account/portfolio/history
# operationId: getAccountPortfolioHistory
export def "account-portfolio-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --period: string # The duration of the data in <number> + <unit>, such as 1D, where <unit> can be D for day, W for week, M for month and A for year. Defaults to 1M.
  --timeframe: string # The resolution of time window. 1Min, 5Min, 15Min, 1H, or 1D. If omitted, 1Min for less than 7 days period, 15Min for less than 30 days, or otherwise 1D.
  --date-end: string # The date the data is returned up to, in “YYYY-MM-DD” format. Defaults to the current market date (rolls over at the market open if extended_hours is false, otherwise at 7am ET) (format: date, e.g. 2022-05-15)
  --extended-hours: string # If true, include extended hours in the result. This is effective only for timeframe less than 1D.
]: nothing -> record<timestamp: list<int>, equity: list<float>, profit_loss: list<float>, profit_loss_pct: list<float>, base_value: float, timeframe: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "extended_hours" $extended_hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account/portfolio/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Watchlists
#
# GET /v2/watchlists
# operationId: getWatchlists
export def "watchlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/watchlists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Watchlist
#
# POST /v2/watchlists
# operationId: postWatchlist
export def "watchlists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --symbols: list
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/watchlists")
  let body = {name: $name, symbols: $symbols} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Watchlist by ID
#
# GET /v2/watchlists/{watchlist_id}
# operationId: getWatchlistById
export def "watchlists get" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/watchlists/($watchlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Watchlist By Id
#
# PUT /v2/watchlists/{watchlist_id}
# operationId: updateWatchlistById
export def "watchlists updateWatchlistById" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --symbols: list
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/watchlists/($watchlist_id)")
  let body = {name: $name, symbols: $symbols} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Asset to Watchlist
#
# POST /v2/watchlists/{watchlist_id}
# operationId: addAssetToWatchlist
export def "watchlists addAssetToWatchlist" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --symbol: string # symbol name to append to watchlist (e.g. AAPL)
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/watchlists/($watchlist_id)")
  let body = {symbol: $symbol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Watchlist By Id
#
# DELETE /v2/watchlists/{watchlist_id}
# operationId: deleteWatchlistById
export def "watchlists delete" [
  watchlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/watchlists/($watchlist_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Watchlist by Name
#
# GET /v2/watchlists:by_name
# operationId: getWatchlistByName
export def "watchlists-by-name get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the watchlist
]: nothing -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/watchlists:by_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Watchlist By Name
#
# PUT /v2/watchlists:by_name
# operationId: updateWatchlistByName
export def "watchlists-by-name updateWatchlistByName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the watchlist
  name: string
  --symbols: list
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/watchlists:by_name" $qp)
  let body = {name: $name, symbols: $symbols} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Asset to Watchlist By Name
#
# POST /v2/watchlists:by_name
# operationId: addAssetToWatchlistByName
export def "watchlists-by-name addAssetToWatchlistByName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the watchlist
  --symbol: string # symbol name to append to watchlist (e.g. AAPL)
]: any -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/watchlists:by_name" $qp)
  let body = {symbol: $symbol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Watchlist By Name
#
# DELETE /v2/watchlists:by_name
# operationId: deleteWatchlistByName
export def "watchlists-by-name delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the watchlist
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/watchlists:by_name" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Symbol from Watchlist
#
# DELETE /v2/watchlists/{watchlist_id}/{symbol}
# operationId: removeAssetFromWatchlist
export def "watchlists removeAssetFromWatchlist" [
  watchlist_id: string
  symbol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account_id: string, created_at: string, updated_at: string, name: string, assets: table<id: string, class: string, exchange: string, symbol: string, name: string, status: string, tradable: bool, marginable: bool, shortable: bool, easy_to_borrow: bool, fractionable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/watchlists/($watchlist_id)/($symbol)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Configurations
#
# GET /v2/account/configurations
# operationId: getAccountConfig
export def "account-configurations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dtbp_check: string, trade_confirm_email: string, suspend_trade: bool, no_shorting: bool, fractional_trading: bool, max_margin_multiplier: string, pdt_check: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account/configurations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Configurations
#
# PATCH /v2/account/configurations
# operationId: patchAccountConfig
export def "account-configurations patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dtbp-check: string@dtbp-check-completer # both, entry, or exit. Controls Day Trading Margin Call (DTMC) checks.
  --trade-confirm-email: string # all or none. If none, emails for order fills are not sent.
  --suspend-trade: string@bool-completer # If true, new orders are blocked.
  --no-shorting: string@bool-completer # If true, account becomes long-only mode.
  --fractional-trading: string@bool-completer # If true, account is able to participate in fractional trading
  --max-margin-multiplier: string # Can be "1" or "2"
  --pdt-check: string # e.g. entry
]: any -> record<dtbp_check: string, trade_confirm_email: string, suspend_trade: bool, no_shorting: bool, fractional_trading: bool, max_margin_multiplier: string, pdt_check: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/account/configurations")
  let body = {dtbp_check: $dtbp_check, trade_confirm_email: $trade_confirm_email, suspend_trade: $suspend_trade, no_shorting: $no_shorting, fractional_trading: $fractional_trading, max_margin_multiplier: $max_margin_multiplier, pdt_check: $pdt_check} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get account activities of one type
#
# GET /v2/account/activities
# operationId: getAccountActivities
export def "account-activities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # The date for which you want to see activities. (format: date-time)
  --until: string # The response will contain only activities submitted before this date. (Cannot be used with date.) (format: date-time)
  --after: string # The response will contain only activities submitted after this date. (Cannot be used with date.) (format: date-time)
  --direction: string@direction-completer # asc or desc (default desc if unspecified.) (e.g. desc)
  --page-size: int # The maximum number of entries to return in the response. (See the section on paging above.)
  --page-token: string # The ID of the end of your current page of results. 
  --activity-types: string # A comma-separated list of the activity types to include in the response. If unspecified, activities of all types will be returned. See ActivityType model for values (e.g. FILL)
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "activity_types" $activity_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/account/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account activities of one type
#
# GET /v2/account/activities/{activity_type}
# operationId: getAccountActivitiesByActivityType
export def "account-activities get" [
  activity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # The date for which you want to see activities. (format: date-time)
  --until: string # The response will contain only activities submitted before this date. (Cannot be used with date.) (format: date-time)
  --after: string # The response will contain only activities submitted after this date. (Cannot be used with date.) (format: date-time)
  --direction: string@direction-completer # asc or desc (default desc if unspecified.) (e.g. desc)
  --page-size: int # The maximum number of entries to return in the response. (See the section on paging above.)
  --page-token: string # The ID of the end of your current page of results. 
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/account/activities/($activity_type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Market Calendar info
#
# GET /v2/calendar
# operationId: getCalendar
export def "calendar get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The first date to retrieve data for (inclusive) (format: date-time)
  --end: string # The last date to retrieve data for (inclusive) (format: date-time)
]: nothing -> table<date: string, open: string, close: string, session_open: string, session_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Market Clock info
#
# GET /v2/clock
# operationId: getClock
export def "clock get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<timestamp: string, is_open: bool, next_open: string, next_close: string> {
  let auth = (build-auth $token ($auth_scheme | default "apca-api-key-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/clock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
