# Auto-generated client for Tradematic Cloud API v1.0.2
# Source: https://api.apis.guru/v2/specs/tradematic.com/1.0.2/swagger.json
# Auth: --token flag or $env.TRADEMATIC_CLOUD_API_TOKEN

const BASE_URL = "https://api.tradematic.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRADEMATIC_CLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.tradematic.com"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "autofollow-strategies list" } } | get name | first)
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

# Get autofollow strategies list
#
# GET /autofollow/strategies
export def "autofollow-strategies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list, longexit: list>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/autofollow/strategies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create new autofollow strategy
#
# POST /autofollow/strategies
# --strategy shape: {apr?: string, author?: string, content?: string, description?: string, drawdown?: string, guid?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, positionsize?: string, strategytypeid?: string, symbols?: string, timeframe?: string}
export def "autofollow-strategies create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {apr?: string, author?: string, content?: string, description?: string, drawdown?: string, guid?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, positionsize?: string, strategytypeid?: string, symbols?: string, timeframe?: string}
]: any -> record<strategyid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/autofollow/strategies")
  let req_body = {"strategy": $strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get autofollow strategy by ID
#
# GET /autofollow/strategies/{strategyid}
export def "autofollow-strategies get" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apr: string, author: string, brokername: string, code: string, datascale: string, description: string, drawdown: string, folder: string, guid: string, image: string, limitorder: string, marketname: string, multiposition: string, name: string, owner: string, permissions: string, positionsize: string, risklevelcode: string, risklevelid: string, risklevelname: string, rules: record<longentry: list<record>, longexit: list<record>>, strategyid: string, strategytypeid: string, symbols: list<string>, taskfolder: string, taskid: string, taskresult: record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string>, timeframe: string, updatedate: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update autofollow strategy
#
# PUT /autofollow/strategies/{strategyid}
# --strategy shape: {author?: string, description?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, symbols?: string}
export def "autofollow-strategies update" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {author?: string, description?: string, limitorder?: string, marketname?: string, multiposition?: string, name?: string, symbols?: string}
]: any -> record<result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}"))
  let req_body = {"strategy": $strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update rules for strategy that was created with strategy builder
#
# PUT /autofollow/strategies/{strategyid}/content
# --strategy shape: {rules?: record}
export def "autofollow-strategies-content update" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --strategy: record # shape: {rules?: record}
]: any -> record<strategyid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}/content"))
  let req_body = {"strategy": $strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get positions for strategy
#
# GET /autofollow/strategies/{strategyid}/positions
export def "autofollow-strategies-positions get" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<date: string, price: string, size: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}/positions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get trading signals for strategy
#
# GET /autofollow/strategies/{strategyid}/signals
export def "autofollow-strategies-signals get" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # format: int64
]: nothing -> table<position: string, price: string, shares: string, signalid: string, size: string, symbol: string, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}/signals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count} | compact), body: null}
}

# Send a new signal for autofollow strategy
#
# POST /autofollow/strategies/{strategyid}/signals
# --signal shape: {position?: string, price?: string, shares?: string, size?: string, symbol?: string, timestamp?: string, type?: string}
export def "autofollow-strategies-signals create" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --signal: record # shape: {position?: string, price?: string, shares?: string, size?: string, symbol?: string, timestamp?: string, type?: string}
]: any -> record<signalid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/autofollow/strategies/{strategyid}/signals"))
  let req_body = {"signal": $signal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get strategy builder rules list
#
# GET /builder/rules
export def "builder-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/builder/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get strategy builder rules by ID
#
# GET /builder/rules/{ruleid}
export def "builder-rules get" [
  ruleid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, description: string, guid: string, name: string, parameters: list<record>, ruletype: string, validnot: string, validor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($ruleid | is-empty) { error make --unspanned { msg: "path parameter 'ruleid' must be non-empty" } }
  let full_url = (build-url $base ({ruleid: (encode-path-segment $ruleid)} | format pattern "/builder/rules/{ruleid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get API keys
#
# GET /client/apikeys
export def "client-apikeys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, keyid: string, permissions: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/apikeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create new API key
#
# POST /client/apikeys
export def "client-apikeys create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, keyid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/apikeys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete API key
#
# DELETE /client/apikeys/{keyid}
export def "client-apikeys delete" [
  keyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keyid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($keyid | is-empty) { error make --unspanned { msg: "path parameter 'keyid' must be non-empty" } }
  let full_url = (build-url $base ({keyid: (encode-path-segment $keyid)} | format pattern "/client/apikeys/{keyid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get users list
#
# GET /client/users
export def "client-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Logs user into the system
#
# POST /client/users/login
export def "client-users-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, userid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/users/login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a new user
#
# POST /client/users/register
# --user shape: {name?: string, password?: string, username?: string}
export def "client-users-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # shape: {name?: string, password?: string, username?: string}
]: any -> record<userid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client/users/register")
  let req_body = {"user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get user by ID
#
# GET /client/users/{userid}
export def "client-users get" [
  userid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comments: string, createdby: string, name: string, regdate: string, userid: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($userid | is-empty) { error make --unspanned { msg: "path parameter 'userid' must be non-empty" } }
  let full_url = (build-url $base ({userid: (encode-path-segment $userid)} | format pattern "/client/users/{userid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get trading accounts list
#
# GET /cloud/accounts
export def "cloud-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get trading account by ID
#
# GET /cloud/accounts/{accountid}
export def "cloud-accounts get" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, accountid: string, accounttypename: string, cash: string, change: string, changepercent: string, comments: string, computer: string, currencyid: string, currencytext: string, hwid: string, positions: record, positionspercent: record, sessionid: string, typeid: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Close all positions by account
#
# POST /cloud/accounts/{accountid}/closeall
export def "cloud-accounts-closeall create" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commandid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/closeall"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get orders list by account
#
# GET /cloud/accounts/{accountid}/orders
export def "cloud-accounts-orders get" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, buy: string, message: string, number: string, orderid: string, price: string, shares: string, status: string, statusname: string, symbol: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/orders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Place a new order
#
# POST /cloud/accounts/{accountid}/orders
# --order shape: {buy?: string, price?: string, shares?: string, symbol?: string, type?: string}
export def "cloud-accounts-orders create" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: record # shape: {buy?: string, price?: string, shares?: string, symbol?: string, type?: string}
]: any -> record<commandid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/orders"))
  let req_body = {"order": $order} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancel an order by ID
#
# DELETE /cloud/accounts/{accountid}/orders/{orderid}
export def "cloud-accounts-orders delete" [
  accountid: int
  orderid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commandid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  if ($orderid | is-empty) { error make --unspanned { msg: "path parameter 'orderid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid), orderid: (encode-path-segment $orderid)} | format pattern "/cloud/accounts/{accountid}/orders/{orderid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get account equity and cash snapshots
#
# GET /cloud/accounts/{accountid}/snapshots
export def "cloud-accounts-snapshots get" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<cash: string, daynum: string, snapshotid: string, timestamp: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/snapshots"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Syhchronize an account with account active strategies
#
# POST /cloud/accounts/{accountid}/sync
export def "cloud-accounts-sync create" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commandid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/sync"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get trades list by account
#
# GET /cloud/accounts/{accountid}/trades
export def "cloud-accounts-trades get" [
  accountid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, buy: string, number: string, price: string, shares: string, symbol: string, timestamp: string, tradeid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($accountid | is-empty) { error make --unspanned { msg: "path parameter 'accountid' must be non-empty" } }
  let full_url = (build-url $base ({accountid: (encode-path-segment $accountid)} | format pattern "/cloud/accounts/{accountid}/trades"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get commands list
#
# GET /cloud/commands
export def "cloud-commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/commands")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get command by ID
#
# GET /cloud/commands/{commandid}
export def "cloud-commands get" [
  commandid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, accountid: string, commanddate: string, commandid: string, commandstatusname: string, commandtypename: string, computer: string, hwid: string, message: string, parameters: record, status: string, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($commandid | is-empty) { error make --unspanned { msg: "path parameter 'commandid' must be non-empty" } }
  let full_url = (build-url $base ({commandid: (encode-path-segment $commandid)} | format pattern "/cloud/commands/{commandid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get connections list
#
# GET /cloud/connections
export def "cloud-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new connection
#
# POST /cloud/connections
# --connection shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
export def "cloud-connections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record # shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
]: any -> record<connectionid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/connections")
  let req_body = {"connection": $connection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete connection by ID
#
# DELETE /cloud/connections/{connectionid}
export def "cloud-connections delete" [
  connectionid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectionid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($connectionid | is-empty) { error make --unspanned { msg: "path parameter 'connectionid' must be non-empty" } }
  let full_url = (build-url $base ({connectionid: (encode-path-segment $connectionid)} | format pattern "/cloud/connections/{connectionid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get connection by ID
#
# GET /cloud/connections/{connectionid}
export def "cloud-connections get" [
  connectionid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: string, connectionid: string, connectionstring: string, connectorcode: string, connectorid: string, connectorname: string, connectortypename: string, creationdate: string, host: string, login: string, password: string, port: string, sessionid: string, updatedate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($connectionid | is-empty) { error make --unspanned { msg: "path parameter 'connectionid' must be non-empty" } }
  let full_url = (build-url $base ({connectionid: (encode-path-segment $connectionid)} | format pattern "/cloud/connections/{connectionid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update existing connection
#
# PUT /cloud/connections/{connectionid}
# --connection shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
export def "cloud-connections update" [
  connectionid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection: record # shape: {active?: string, connectorid?: string, host?: string, login?: string, password?: string, port?: string}
]: any -> record<connectionid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($connectionid | is-empty) { error make --unspanned { msg: "path parameter 'connectionid' must be non-empty" } }
  let full_url = (build-url $base ({connectionid: (encode-path-segment $connectionid)} | format pattern "/cloud/connections/{connectionid}"))
  let req_body = {"connection": $connection} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get available connectors list
#
# GET /cloud/connectors
export def "cloud-connectors list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, connectorid: string, connectortypename: string, name: string, typeid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/connectors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get connector by ID
#
# GET /cloud/connectors/{connectorid}
export def "cloud-connectors get" [
  connectorid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, connectorid: string, connectortypename: string, name: string, typeid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($connectorid | is-empty) { error make --unspanned { msg: "path parameter 'connectorid' must be non-empty" } }
  let full_url = (build-url $base ({connectorid: (encode-path-segment $connectorid)} | format pattern "/cloud/connectors/{connectorid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get sessions list
#
# GET /cloud/sessions
export def "cloud-sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get session by ID
#
# GET /cloud/sessions/{sessionid}
export def "cloud-sessions get" [
  sessionid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<computer: string, hwid: string, login: string, mode: string, sessionid: string, sessionmodename: string, sessionstatusname: string, status: string, timestamp: string, type: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($sessionid | is-empty) { error make --unspanned { msg: "path parameter 'sessionid' must be non-empty" } }
  let full_url = (build-url $base ({sessionid: (encode-path-segment $sessionid)} | format pattern "/cloud/sessions/{sessionid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get list of active (executing) strategies
#
# GET /cloud/strategies
export def "cloud-strategies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/strategies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Start a strategy execution for account
#
# POST /cloud/strategies/start
# --data shape: {accountid?: string, strategyid?: string}
export def "cloud-strategies-start create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record # shape: {accountid?: string, strategyid?: string}
]: any -> record<commandid: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cloud/strategies/start")
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get active (executing) strategy by ID
#
# GET /cloud/strategies/{strategyid}
export def "cloud-strategies get" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: string, computer: string, hwid: string, message: string, status: string, strategy: string, strategyid: string, strategystatusname: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/cloud/strategies/{strategyid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Stop a strategy execution by ID
#
# POST /cloud/strategies/{strategyid}/stop
export def "cloud-strategies-stop create" [
  strategyid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commandid: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($strategyid | is-empty) { error make --unspanned { msg: "path parameter 'strategyid' must be non-empty" } }
  let full_url = (build-url $base ({strategyid: (encode-path-segment $strategyid)} | format pattern "/cloud/strategies/{strategyid}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get markets list
#
# GET /marketdata/markets
export def "marketdata-markets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, countryid: string, marketid: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/marketdata/markets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get market by ID
#
# GET /marketdata/markets/{marketid}
export def "marketdata-markets get" [
  marketid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, countryid: string, marketid: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($marketid | is-empty) { error make --unspanned { msg: "path parameter 'marketid' must be non-empty" } }
  let full_url = (build-url $base ({marketid: (encode-path-segment $marketid)} | format pattern "/marketdata/markets/{marketid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get symbols list
#
# GET /marketdata/symbols
export def "marketdata-symbols list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketid: int # format: int64
  --filter: int # format: int64
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketid" $marketid "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/marketdata/symbols" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"marketid": $marketid, "filter": $filter} | compact), body: null}
}

# Get symbol by ID
#
# GET /marketdata/symbols/{symbolid}
export def "marketdata-symbols get" [
  symbolid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($symbolid | is-empty) { error make --unspanned { msg: "path parameter 'symbolid' must be non-empty" } }
  let full_url = (build-url $base ({symbolid: (encode-path-segment $symbolid)} | format pattern "/marketdata/symbols/{symbolid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get historical data for instrument
#
# GET /marketdata/symbols/{symbolid}/histdata
export def "marketdata-symbols-histdata get" [
  symbolid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tf: int # format: int64
  --qp-from: int # format: int64
  --qp-to: int # format: int64
]: nothing -> record<adjusted: bool, queryCount: int, results: table<c: float, h: float, l: float, n: int, o: float, t: int, v: int>, resultsCount: int, status: string, ticker: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($symbolid | is-empty) { error make --unspanned { msg: "path parameter 'symbolid' must be non-empty" } }
  let qp = [(serialize-qp "tf" $tf "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({symbolid: (encode-path-segment $symbolid)} | format pattern "/marketdata/symbols/{symbolid}/histdata") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tf": $tf, "from": $qp_from, "to": $qp_to} | compact), body: null}
}

# Get news list
#
# GET /news/news
export def "news-news list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: string, newsid: string, source: string, timestamp: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/news/news")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get news by ID
#
# GET /news/news/{newsid}
export def "news-news get" [
  newsid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: string, newsid: string, source: string, timestamp: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($newsid | is-empty) { error make --unspanned { msg: "path parameter 'newsid' must be non-empty" } }
  let full_url = (build-url $base ({newsid: (encode-path-segment $newsid)} | format pattern "/news/news/{newsid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Ping
#
# GET /ping
export def "ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get tasks list
#
# GET /taskmanager/tasks
export def "taskmanager-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taskmanager/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new task
#
# POST /taskmanager/tasks
# --task shape: {isbenchmark?: string, strategyid?: string, tasktypeid?: string, userid2?: string}
export def "taskmanager-tasks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --task: record # shape: {isbenchmark?: string, strategyid?: string, tasktypeid?: string, userid2?: string}
]: any -> record<taskid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/taskmanager/tasks")
  let req_body = {"task": $task} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get task by ID
#
# GET /taskmanager/tasks/{taskid}
export def "taskmanager-tasks get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isbenchmark: string, name: string, status: string, statusupdatedate: string, strategyid: string, taskid: string, usestaticdata: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest data for equity chart, grouped by months
#
# GET /taskmanager/tasks/{taskid}/bymonths
export def "taskmanager-tasks-bymonths get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<equitypct: string, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/bymonths"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest data for equity chart, grouped by quarters
#
# GET /taskmanager/tasks/{taskid}/byquarters
export def "taskmanager-tasks-byquarters get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<equitypct: string, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/byquarters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest data for equity chart, grouped by years
#
# GET /taskmanager/tasks/{taskid}/byyears
export def "taskmanager-tasks-byyears get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<equitypct: string, period: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/byyears"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest symbol contribution data
#
# GET /taskmanager/tasks/{taskid}/contribution
export def "taskmanager-tasks-contribution get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<pandl: string, share: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/contribution"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get data for drawdown chart
#
# GET /taskmanager/tasks/{taskid}/drawdown
export def "taskmanager-tasks-drawdown get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<drawdownpct: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/drawdown"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get data for equity chart
#
# GET /taskmanager/tasks/{taskid}/equity
export def "taskmanager-tasks-equity get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<cash: string, equity: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/equity"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get data for equity chart (%)
#
# GET /taskmanager/tasks/{taskid}/equitypct
export def "taskmanager-tasks-equitypct get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<buyandhold: string, equity: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/equitypct"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get spared data for equity chart (%)
#
# GET /taskmanager/tasks/{taskid}/equitypctsm
export def "taskmanager-tasks-equitypctsm get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<buyandhold: string, equity: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/equitypctsm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get task result folder name
#
# GET /taskmanager/tasks/{taskid}/folder
export def "taskmanager-tasks-folder get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<folder: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/folder"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest statistics
#
# GET /taskmanager/tasks/{taskid}/performance
export def "taskmanager-tasks-performance get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<buyandhold: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, long: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, longshort: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>, short: record<apr: string, avgbarsheld: string, avgloss: string, avglossbarsheld: string, avglosspct: string, avgprofit: string, avgprofitavgloss: string, avgprofitbarsheld: string, avgprofitpct: string, endcapital: string, exposure: string, grossloss: string, grossprofit: string, losingtrades: string, losingtradespct: string, mar: string, margininterest: string, maxconsecloss: string, maxconsecwin: string, maxdrawdown: string, maxdrawdowndate: string, maxdrawdownlength: string, maxdrawdownpct: string, maxdrawdownpctdate: string, mpr: string, netprofit: string, netprofitpct: string, profitabletrades: string, profitabletradespct: string, profitfactor: string, profitriskratio: string, rar: string, recoveryfactor: string, sharperatio: string, sortinoratio: string, startcapital: string, totalcommission: string, totaltrades: string, totalvolume: string, turnover: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/performance"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get task result
#
# GET /taskmanager/tasks/{taskid}/result
export def "taskmanager-tasks-result get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bymonths_csv: string, bymonths_png: string, byquarters_csv: string, byquarters_png: string, byyears_csv: string, byyears_png: string, contribution_csv: string, contribution_png: string, drawdown_csv: string, drawdown_png: string, equity_csv: string, equity_png: string, equitypct_csv: string, equitypct_png: string, equitypctnofill_csv: string, equitypctnofill_png: string, equitypctsm: string, equitypctsm_csv: string, equitypctsm_png: string, performance_csv: string, performance_png: string, trades_csv: string, trades_png: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/result"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get task result (version 2)
#
# GET /taskmanager/tasks/{taskid}/result2
export def "taskmanager-tasks-result2 get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apr: string, curMonthProfit: string, curYearProfit: string, drawdown: string, halfYearProfit: string, monthProfit: string, prevMonthProfit: string, totalProfit: string, weekProfit: string, yearProfit: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/result2"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get task status
#
# GET /taskmanager/tasks/{taskid}/status
export def "taskmanager-tasks-status get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get backtest trades list
#
# GET /taskmanager/tasks/{taskid}/trades
export def "taskmanager-tasks-trades get" [
  taskid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<barsheld: string, changepct: string, commission: string, entrydatetime: string, entryprice: string, entrysignal: string, exitdatetime: string, exitprice: string, exitsignal: string, mae: string, mfe: string, pandl: string, position: string, shares: string, size: string, symbol: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($taskid | is-empty) { error make --unspanned { msg: "path parameter 'taskid' must be non-empty" } }
  let full_url = (build-url $base ({taskid: (encode-path-segment $taskid)} | format pattern "/taskmanager/tasks/{taskid}/trades"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get current server time
#
# GET /time
export def "time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<servertime: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
