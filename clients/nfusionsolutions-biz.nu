# Auto-generated client for nFusion Solutions Market Data API v1
# Source: https://api.apis.guru/v2/specs/nfusionsolutions.biz/1/openapi.json
# Auth: --token flag or $env.NFUSION_SOLUTIONS_MARKET_DATA_API_TOKEN

const BASE_URL = "https://api.nfusionsolutions.biz"
const DEFAULT_AUTH = "query-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NFUSION_SOLUTIONS_MARKET_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-token" => { {headers: {}, query: $"(encode-path-segment "token")=(encode-path-segment $token_val)"} }
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

def base-url-completer [] { ["https://api.nfusionsolutions.biz"] }
def auth-scheme-completer [] { ["query-token"] }

# Completers for enum parameters
def format-completer [] { ["json" "xml"] }
def accept-completer [] { ["application/json" "application/xml"] }
def unitofmeasure-completer [] { ["ct" "dwt" "g" "gr" "kg" "mg" "oz" "toz"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "currencies-history get" } } | get name | first)
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

# Get historical prices for requested currency pairs
#
# GET /api/v1/Currencies/history
# operationId: Currencies_History_GET
export def "currencies-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pairs: string # comma separated list of currency pairs. For example: USD/CAD,USD/EUR,USD/AUD
  --start: string # start date of time period. format is yyyy-mm-dd (format: date-time)
  --end: string # end date of time period. format is yyyy-mm-dd. Default is current date. (format: date-time)
  --interval: string # aggregation interval. Composed of an optional integer value (which defaults to 1 when not specified), followed by a type string which must be one of the following values: y=year, m=month, w=week, d=day, h=hour, mi=minute For example, a yearly interval can be specified as "y" and 6 month interval as "6m". If not specified the interval parameter default is 1 Day.
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pairs" $pairs "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of currency pairs supported by the history endpoint
#
# GET /api/v1/Currencies/history/supported
# operationId: Currencies_SupportedCurrencies_History_GET
export def "currencies-history-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/history/supported" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get latest mid rate for requested currency pairs
#
# GET /api/v1/Currencies/rate
# operationId: Currencies_Rate_GET
export def "currencies-rate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pairs: string # comma separated list of currency pairs. For example: USD/CAD,USD/EUR,USD/AUD
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<symbol: string, timestamp: string, value: float>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pairs" $pairs "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/rate" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of currencies supported by the rate endpoint
#
# GET /api/v1/Currencies/rate/supported
# operationId: Currencies_SupportedCurrencies_Rate_GET
export def "currencies-rate-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/rate/supported" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get latest Summary for requested currency pairs
#
# GET /api/v1/Currencies/summary
# operationId: Currencies_Summary_GET
export def "currencies-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pairs: string # comma separated list of currency pairs. For example: USD/CAD,USD/EUR,USD/AUD
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<ask: float, baseCurrency: string, bid: float, fiftyTwoWeekHigh: float, fiftyTwoWeekLow: float, fiftyTwoWeekPercentChange: float, fourWeekPercentChange: float, high: float, last: float, low: float, oneDayChange: float, oneDayPercentChange: float, oneDayValue: float, open: float, symbol: string, timeStamp: string, twelveWeekPercentChange: float, yearToDatePercentChange: float>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pairs" $pairs "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of currency pairs supported by the Summary endpoint
#
# GET /api/v1/Currencies/summary/supported
# operationId: Currencies_SupportedCurrencies_Summary_GET
export def "currencies-summary-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Currencies/summary/supported" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get historical benchmark prices for requested metals
#
# GET /api/v1/Metals/benchmark/history
# operationId: Metals_BenchmarkHistory_GET
export def "metals-benchmark-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --start: string # start date of time period. format is yyyy-mm-dd (format: date-time)
  --end: string # end date of time period. format is yyyy-mm-dd. Default is current date. (format: date-time)
  --interval: string # aggregation interval. Composed of an optional integer value (which defaults to 1 when not specified), followed by a type string which must be one of the following values: y=year, m=month, w=week, d=day, h=hour, mi=minute For example, a yearly interval can be specified as "y" and 6 month interval as "6m". If not specified the interval parameter default is 1 Day.
  --historicalfx: oneof<nothing, bool> # if true use historical currency rates otherwise current currency rates. Defaults to true.
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "historicalfx" $historicalfx "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/benchmark/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get latest Benchmark prices for requested metals
#
# GET /api/v1/Metals/benchmark/summary
# operationId: Metals_BenchmarkSummary_GET
export def "metals-benchmark-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<ask: float, baseCurrency: string, bid: float, fiftyTwoWeekHigh: float, fiftyTwoWeekLow: float, fiftyTwoWeekPercentChange: float, fourWeekPercentChange: float, high: float, last: float, low: float, oneDayChange: float, oneDayPercentChange: float, oneDayValue: float, open: float, symbol: string, timeStamp: string, twelveWeekPercentChange: float, yearToDatePercentChange: float>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/benchmark/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of symbols supported by the benchmark endpoints
#
# GET /api/v1/Metals/benchmark/supported
# operationId: Metals_BenchmarkSupportedMetals_GET
export def "metals-benchmark-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/benchmark/supported" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get historical Spot prices for requested metals
#
# GET /api/v1/Metals/spot/history
# operationId: Metals_SpotHistory_GET
export def "metals-spot-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --start: string # start date of time period. format is yyyy-mm-dd (format: date-time)
  --end: string # end date of time period. format is yyyy-mm-dd. Default is current date. (format: date-time)
  --interval: string # aggregation interval. Composed of an optional integer value (which defaults to 1 when not specified), followed by a type string which must be one of the following values: y=year, m=month, w=week, d=day, h=hour, mi=minute For example, a yearly interval can be specified as "y" and 6 month interval as "6m". If not specified the interval parameter default is 1 Day.
  --historicalfx: oneof<nothing, bool> # if true use historical currency rates otherwise current currency rates. Defaults to true.
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "historicalfx" $historicalfx "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Historical Performance for requested metals
#
# GET /api/v1/Metals/spot/performance
# operationId: Metals_SpotHistoricalPerformance_GET
export def "metals-spot-performance get-historical" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/performance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Historical Annual Performance for requested metals
#
# GET /api/v1/Metals/spot/performance/annual
# operationId: Metals_SpotAnnualHistoricalPerformance_GET
export def "metals-spot-performance-annual get-historical" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
  --years: int # Number of years of history to return. Defaults to 10. (format: int32)
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "years" $years "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/performance/annual" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get historical Spot Ratio prices for requested metals
#
# GET /api/v1/Metals/spot/ratio/history
# operationId: Metals_SpotRatioHistory_GET
export def "metals-spot-ratio-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pairs: string # comma separated list of metals
  --start: string # start date of time period. format is yyyy-mm-dd (format: date-time)
  --end: string # end date of time period. format is yyyy-mm-dd. Default is current date. (format: date-time)
  --interval: string # aggregation interval. Composed of an optional integer value (which defaults to 1 when not specified), followed by a type string which must be one of the following values: y=year, m=month, w=week, d=day, h=hour, mi=minute For example, a yearly interval can be specified as "y" and 6 month interval as "6m". If not specified the interval parameter default is 1 Day.
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<baseCurrency: string, intervals: list, name: string, symbol: string>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pairs" $pairs "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/ratio/history" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get latest Spot Summary for requested metal ratios
#
# GET /api/v1/Metals/spot/ratio/summary
# operationId: Metals_SpotRatioSummary_GET
export def "metals-spot-ratio-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pairs: string # comma separated list of metal pairs. For example: gold/silver,gold/platinum,silver/palladium
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<ask: float, baseCurrency: string, bid: float, fiftyTwoWeekHigh: float, fiftyTwoWeekLow: float, fiftyTwoWeekPercentChange: float, fourWeekPercentChange: float, high: float, last: float, low: float, oneDayChange: float, oneDayPercentChange: float, oneDayValue: float, open: float, symbol: string, timeStamp: string, twelveWeekPercentChange: float, yearToDatePercentChange: float>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pairs" $pairs "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/ratio/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get latest Spot Summary for requested metals
#
# GET /api/v1/Metals/spot/summary
# operationId: Metals_SpotSummary_GET
export def "metals-spot-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --metals: string # comma separated list of metals
  --currency: string # comma separated list of conversion currencies, defaults to USD
  --unitofmeasure: string@unitofmeasure-completer # unit of meaure, defaults to troy ounces. allowed values are: mg=milligram g=gram kg=kilogram gr=grain oz=ounce toz=troy ounce ct=carat dwt=pennyweight
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> table<data: record<ask: float, baseCurrency: string, bid: float, fiftyTwoWeekHigh: float, fiftyTwoWeekLow: float, fiftyTwoWeekPercentChange: float, fourWeekPercentChange: float, high: float, last: float, low: float, oneDayChange: float, oneDayPercentChange: float, oneDayValue: float, open: float, symbol: string, timeStamp: string, twelveWeekPercentChange: float, yearToDatePercentChange: float>, error: string, requestedCurrency: string, requestedSymbol: string, requestedUnitOfMeasure: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metals" $metals "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "unitofmeasure" $unitofmeasure "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of symbols supported by the spot endpoints
#
# GET /api/v1/Metals/spot/supported
# operationId: Metals_SpotSupportedMetals_GET
export def "metals-spot-supported get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/spot/supported" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get list of currencies supported by metals endpoints for currency conversion
#
# GET /api/v1/Metals/supported/currency
# operationId: Metals_SupportedCurrencies_Metals_GET
export def "metals-supported-currency get-currencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # to override content negotiation specify a value of json or xml
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Metals/supported/currency" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
