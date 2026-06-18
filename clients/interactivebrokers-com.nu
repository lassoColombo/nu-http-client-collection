# Auto-generated client for IBKR 3rd Party Web API v1.0.0
# Source: https://api.apis.guru/v2/specs/interactivebrokers.com/1.0.0/openapi.json
# Auth: --token flag or $env.IBKR_3RD_PARTY_WEB_API_TOKEN

const BASE_URL = "https://www.interactivebrokers.com/tradingapi/v1"
const DEFAULT_AUTH = "portal"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IBKR_3RD_PARTY_WEB_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "portal" => { {headers: {portal: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://www.interactivebrokers.com/tradingapi/v1"] }
def auth-scheme-completer [] { ["portal"] }

# Completers for enum parameters
def order-type-completer [] { ["1" "2" "3" "4"] }
def side-completer [] { ["1" "2"] }
def time-in-force-completer [] { ["0" "1" "2" "3" "7"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts get" } } | get name | first)
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

# Brokerage Accounts
#
# GET /accounts
export def "accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # Account Number
]: nothing -> record<accounts: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return margin impact info
#
# POST /accounts/{account}/order_impact
export def "accounts-order-impact create" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required price to support Stop and Stop Limit orders
  --contract-id: float # The internal IB identifier for the trading product specified as an integer (can be obtained in response to /secdef request)
  --currency: string # The currency in which the FX pair trades (only for InstrumentType=CASH)
  --customer-order-id: string # The order ID assigned by the customer.
  --instrument-type: string # The instrument type of the contract
  --listing-exchange: string # The exchange on which the trading product is listed (only for InstrumentType=STK)
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --ticker: string # The symbol that identifies the trading product
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> record<Commission: float, CommissionsCurrency: string, EquityWithLoan: float, InitMargin: float, InitMarginBefore: float, MaintMargin: float, MaintMarginBefore: float, MarginCurrency: string, MaxCommissions: float, MinCommissions: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/order_impact"))
  let req_body = {"Aux Price": $aux_price, "ContractId": $contract_id, "Currency": $currency, "CustomerOrderId": $customer_order_id, "InstrumentType": $instrument_type, "ListingExchange": $listing_exchange, "Order Type": $order_type, "Price": $price, "Quantity": $quantity, "Side": $side, "Ticker": $ticker, "Time in Force": $time_in_force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Open Orders
#
# GET /accounts/{account}/orders
export def "accounts-orders list" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/orders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Place Order
#
# POST /accounts/{account}/orders
export def "accounts-orders create" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required Price to support Stop and Stop Limit orders
  --contract-id: float # The internal IB identifier for the trading product specified as an integer (can be obtained in response to /secdef request)
  --currency: string # The currency in which the FX pair trades (only for InstrumentType=CASH)
  --customer-order-id: string # The order ID assigned by the customer.
  --german-hft-algo: oneof<nothing, bool> # By setting this bool to false the customer attests that the order is not subject to German HFT Act, was not generated using any automated algorithm, and no algorithm determined or changed financial instrument, side, quantity, order type, limit or other price, trading venue or timing of this order. Currently we cannot accept orders where this flag is set to true. Such orders will be rejected.
  --instrument-type: string # The instrument type of the contract
  --listing-exchange: string # The exchange on which the trading product is listed (only for InstrumentType=STK)
  --mifid2-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for investment decisions
  --mifid2-decision-maker: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for decision makers.
  --mifid2-execution-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for handling/routing of the order.
  --mifid2-execution-trader: string # This field permits specification of the user's preregistered (via account management) MiFID II person responsible for handling/routing of the order
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --order-restrictions: float # MultiValueString representing the restrictions associated with an order. If more than one restriction is applicable to an order, this field can contain multiple instructions separated by space. '1' Program Trade '2' Index Arbitrage '3' Non-Index Arbitrage
  --outside-rth: float # Indicates if order is active outside regular trading hours, where defined. 0 = no (default), 1 = yes
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --ticker: string # The symbol that identifies the trading product
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/orders"))
  let req_body = {"Aux Price": $aux_price, "ContractId": $contract_id, "Currency": $currency, "CustomerOrderId": $customer_order_id, "GermanHftAlgo": $german_hft_algo, "InstrumentType": $instrument_type, "ListingExchange": $listing_exchange, "Mifid2Algo": $mifid2_algo, "Mifid2DecisionMaker": $mifid2_decision_maker, "Mifid2ExecutionAlgo": $mifid2_execution_algo, "Mifid2ExecutionTrader": $mifid2_execution_trader, "Order Type": $order_type, "OrderRestrictions": $order_restrictions, "Outside RTH": $outside_rth, "Price": $price, "Quantity": $quantity, "Side": $side, "Ticker": $ticker, "Time in Force": $time_in_force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel Order
#
# DELETE /accounts/{account}/orders/{CustomerOrderId}
export def "accounts-orders delete" [
  account: string
  customer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account), customer_order_id: (encode-path-segment $customer_order_id)} | format pattern "/accounts/{account}/orders/{customer_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Return specific order info
#
# GET /accounts/{account}/orders/{CustomerOrderId}
export def "accounts-orders get" [
  account: string
  customer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ContractId: float, CustomerOrderId: float, FilledQuantity: float, ListingExchange: string, OrderType: float, OutsideRTH: string, Price: float, RemainingQuantity: float, Side: string, Status: string, Ticker: string, TimeInForce: float, TransactionTime: string, Warning: string> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account), customer_order_id: (encode-path-segment $customer_order_id)} | format pattern "/accounts/{account}/orders/{customer_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Modify Order
#
# PUT /accounts/{account}/orders/{CustomerOrderId}
export def "accounts-orders update" [
  account: string
  customer_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aux-price: float # Required Price to support Stop and Stop Limit orders
  --body-customer-order-id: string # The new order ID assigned by the customer for the modification.
  --german-hft-algo: oneof<nothing, bool> # By setting this bool to false the customer attests that the order is not subject to German HFT Act, was not generated using any automated algorithm, and no algorithm determined or changed financial instrument, side, quantity, order type, limit or other price, trading venue or timing of this order. Currently we cannot accept orders where this flag is set to true. Such orders will be rejected.
  --mifid2-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for investment decisions
  --mifid2-decision-maker: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for decision makers.
  --mifid2-execution-algo: string # This field permits specification of the user's preregistered (via account management) MiFID II short code for algos that are responsible for handling/routing of the order.
  --mifid2-execution-trader: string # This field permits specification of the user's preregistered (via account management) MiFID II person responsible for handling/routing of the order
  --order-type: float@order-type-completer # Market = '1' Limit = '2' Stop = '3' StopLimit = '4'
  --orig-customer-order-id: string # The order ID assigned by the customer
  --outside-rth: float # Indicates if order is active outside regular trading hours, where defined. 0 = no (default), 1 = yes
  --price: float # The order price
  --quantity: float # The number of units in the order; contracts or shares
  --side: float@side-completer # Buy = '1', Sell = '2'
  --time-in-force: float@time-in-force-completer # Defines order's active lifetime. Day = '0' GTC (Good till Cancel) = '1' IOC (Immediate or Cancel) = '3' Open = '2' Close = '7'
]: any -> table<CustomerOrderId: string, OrderQty: float, OrderType: float, Price: string, Side: float, Status: string, Symbol: float, Warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account), customer_order_id: (encode-path-segment $customer_order_id)} | format pattern "/accounts/{account}/orders/{customer_order_id}"))
  let req_body = {"Aux Price": $aux_price, "CustomerOrderId": $body_customer_order_id, "GermanHftAlgo": $german_hft_algo, "Mifid2Algo": $mifid2_algo, "Mifid2DecisionMaker": $mifid2_decision_maker, "Mifid2ExecutionAlgo": $mifid2_execution_algo, "Mifid2ExecutionTrader": $mifid2_execution_trader, "Order Type": $order_type, "OrigCustomerOrderId": $orig_customer_order_id, "Outside RTH": $outside_rth, "Price": $price, "Quantity": $quantity, "Side": $side, "Time in Force": $time_in_force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Account Positions
#
# GET /accounts/{account}/positions
export def "accounts-positions get" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AverageCost: float, ContractId: float, Position: float> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/positions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Account Values Summary
#
# GET /accounts/{account}/summary
export def "accounts-summary get" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Info: record<AccountCode: string, AccountReady: string, AccountType: string, Cushion: string, DayTradesRemaining: string, DayTradesRemainingT: string, DayTradesRemainingT_2: string, DayTradesRemainingT_3: string, DayTradesRemainingT_4: string, HighestSeverity: string, Leverage_S: string, LookAheadNextChange: string, SegmentTitle_C: string, SegmentTitle_S: string, TradingType_S: string, WhatIfPMEnabled: string>, Ledger: table<CashBalance: float, CashBalanceFXSegment: float, CashCumQty: float, ExchangeRate: float, FutureOptionMarketValue: float, FuturePNL: float, NetDividend: float, NetInterest: float, NetLiquidation: float, OptionMarketValue: float, RealizedPNL: float, StockMarketValue: float, TotalCashBalance: float, UnrealizedPNL: float>, Summary: record<AccruedCash: float, AccruedCash_C: float, AccruedCash_S: float, AccruedDividend: float, AccruedDividend_C: float, AccruedDividend_S: float, AvailableFunds: float, AvailableFunds_C: float, AvailableFunds_S: float, Billable: float, Billable_C: float, Billable_S: float, BuyingPower: float, EquityWithLoanValue: float, EquityWithLoanValue_C: float, EquityWithLoanValue_S: float, ExcessLiquidity: float, ExcessLiquidity_C: float, ExcessLiquidity_S: float, FullAvailableFunds: float, FullAvailableFunds_C: float, FullAvailableFunds_S: float, FullExcessLiquidity: float, FullExcessLiquidity_C: float, FullExcessLiquidity_S: float, FullInitMarginReq: float, FullInitMarginReq_C: float, FullInitMarginReq_S: float, FullMaintMarginReq: float, FullMaintMarginReq_C: float, FullMaintMarginReq_S: float, GrossPositionValue: float, GrossPositionValue_C: float, GrossPositionValue_S: float, IndianStockHaircut: float, IndianStockHaircut_C: float, IndianStockHaircut_S: float, InitMarginReq: float, InitMarginReq_C: float, InitMarginReq_S: float, InsuredDeposit: float, InsuredDeposit_C: float, InsuredDeposit_S: float, LookAheadAvailableFunds: float, LookAheadAvailableFunds_C: float, LookAheadAvailableFunds_S: float, LookAheadExcessLiquidity: float, LookAheadExcessLiquidity_C: float, LookAheadExcessLiquidity_S: float, LookAheadInitMarginReq: float, LookAheadInitMarginReq_C: float, LookAheadInitMarginReq_S: float, LookAheadMaintMarginReq: float, LookAheadMaintMarginReq_C: float, LookAheadMaintMarginReq_S: float, MaintMarginReq: float, MaintMarginReq_C: float, MaintMarginReq_S: float, NetLiquidation: float, NetLiquidation_C: float, NetLiquidation_S: float, NetLiquidationUncertainty: float, PASharesValue: float, PASharesValue_C: float, PASharesValue_S: float, PostExpirationExcess: float, PostExpirationExcess_C: float, PostExpirationExcess_S: float, PostExpirationMargin: float, PostExpirationMargin_C: float, PostExpirationMargin_S: float, RegTEquity: float, RegTEquity_S: float, RegTMargin: float, RegTMargin_S: float, SMA: float, SMA_S: float, TotalCashValue: float, TotalCashValue_C: float, TotalCashValue_S: float>> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/summary"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Returns trades in account
#
# GET /accounts/{account}/trades
export def "accounts-trades get" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> table<AvgPrice: float, Commission: float, CommissionCurrency: string, ContractId: float, Currency: string, CustomerOrderId: float, ExecId: string, ExecutionTime: string, FilledQuantity: float, LastMarket: string, ListingExchange: string, OrderId: string, OrderType: float, Quantity: float, RemainingQuantity: float, Side: string, Ticker: string, TradePrice: float, TradeSize: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/accounts/{account}/trades"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Exchange Components
#
# GET /marketdata/exchange_components
export def "marketdata-exchange-components get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Complete: bool, ConId: float, mapping: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketdata/exchange_components")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Market Data Snapshot
#
# GET /marketdata/snapshot
export def "marketdata-snapshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<Bid: record<market: float, price: float, size: float>, Closing: record<price: float>, Complete: bool, Conid: string, Offer: record<market: float, price: float, size: float>, Temporality: float, Trade: record<market: float, price: float, size: float, time: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketdata/snapshot")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Obtain a access token
#
# POST /oauth/access_token
export def "oauth-access-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
  --oauth-token: string # The request token obtained from IB via /request_token.
  --oauth-verifier: string # The verification code received from IB after the user has granted authorization.
]: any -> record<oauth_token: string, oauth_token_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/access_token")
  let req_body = {"oauth_consumer_key": $oauth_consumer_key, "oauth_nonce": $oauth_nonce, "oauth_signature": $oauth_signature, "oauth_signature_method": $oauth_signature_method, "oauth_timestamp": $oauth_timestamp, "oauth_token": $oauth_token, "oauth_verifier": $oauth_verifier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Obtain a live session token
#
# POST /oauth/live_session_token
export def "oauth-live-session-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --diffie-hellman-challenge: string # Challenge value calculated using the Diffie-Hellman prime and generated provided during the registration process. See the "OAuth at Interactive Brokers" document for more details.
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
  --oauth-token: string # The request token obtained from IB via /request_token.
]: any -> record<diffie_hellman_response: string, live_session_token_signature: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/live_session_token")
  let req_body = {"diffie_hellman_challenge": $diffie_hellman_challenge, "oauth_consumer_key": $oauth_consumer_key, "oauth_nonce": $oauth_nonce, "oauth_signature": $oauth_signature, "oauth_signature_method": $oauth_signature_method, "oauth_timestamp": $oauth_timestamp, "oauth_token": $oauth_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Obtain a request token
#
# POST /oauth/request_token
export def "oauth-request-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --oauth-callback: string # An absolute URL to which IB will redirect the user. This URL is provided by the consumer during registration. This parameter must be set to 'oob'.
  --oauth-consumer-key: string # The 25-character hexadecimal string that was obtained from Interactive Brokers during the OAuth consumer registration process.
  --oauth-nonce: string # A random string uniquely generated for each request.
  --oauth-signature: string # The signature for the request generated using the method specified in the oauth_signature_method parameter. See section 9 of the OAuth v1.0a specification for more details on signing requests.
  --oauth-signature-method: string # The signature method used to sign the request. Currently only 'RSA-SHA256' is supported.
  --oauth-timestamp: string # Timestamp expressed in seconds since 1/1/1970 00:00:00 GMT. Must be a positive integer and greater than or equal to any timestamp used in previous requests.
]: any -> record<oauth_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/request_token")
  let req_body = {"oauth_callback": $oauth_callback, "oauth_consumer_key": $oauth_consumer_key, "oauth_nonce": $oauth_nonce, "oauth_signature": $oauth_signature, "oauth_signature_method": $oauth_signature_method, "oauth_timestamp": $oauth_timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get security definition
#
# GET /secdef
export def "secdef get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conid: float # The internal IB identifier for the trading product specified as an integer.
  --currency: string # The currency in which the given pair trades.
  --exchange: string # The exchange on which the trading product is listed (required for type=STK).
  --symbol: string # The symbol that identifies the trading product.
  --type: string # The instrument type of the contract (CASH).
]: any -> table<CompanyName: string, ContractId: float, Currency: string, Exchange: string, SecurityType: string, Ticker: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "portal"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/secdef")
  let req_body = {"conid": $conid, "currency": $currency, "exchange": $exchange, "symbol": $symbol, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
