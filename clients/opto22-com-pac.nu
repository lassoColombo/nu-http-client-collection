# Auto-generated client for PAC Control REST API vR1.0a
# Source: https://api.apis.guru/v2/specs/opto22.com/pac/R1.0a/swagger.json
# Auth: --token flag or $env.PAC_CONTROL_REST_API_TOKEN

const BASE_URL = "https://localhost/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAC_CONTROL_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://localhost/api/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "device get-details" } } | get name | first)
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

# Returns controller's type; firmware version; both mac addresses; and uptime in seconds
#
# GET /device
# operationId: readDeviceDetails
export def "device get-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<controllerType: string, firmwareDate: string, firmwareTime: string, firmwareVersion: string, mac1: string, mac2: string, upTimeSeconds: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name, date, time, and CRC of the strategy currently in the controller, and the number of charts currently running. Empty strings and a 0 will be returned when there is no strategy.
#
# GET /device/strategy
# operationId: readStrategyDetails
export def "device-strategy get-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<crc: string, date: string, runningCharts: int, strategyName: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name and engineering units (EU) for all analog input points in the strategy
#
# GET /device/strategy/ios/analogInputs
# operationId: readAnalogInputs
export def "device-strategy-ios-analog-inputs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/ios/analogInputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reads the value in engineering units (EU) of the specified analog input
#
# GET /device/strategy/ios/analogInputs/{ioName}/eu
# operationId: readAnalogInputEu
export def "device-strategy-ios-analog-inputs-eu get" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/analogInputs/{io_name}/eu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name and engineering units (EU) for all analog output points in the strategy
#
# GET /device/strategy/ios/analogOutputs
# operationId: readAnalogOutputs
export def "device-strategy-ios-analog-outputs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/ios/analogOutputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reads the value in engineering units (EU) of the specified analog output
#
# GET /device/strategy/ios/analogOutputs/{ioName}/eu
# operationId: readAnalogOutputEu
export def "device-strategy-ios-analog-outputs-eu get" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/analogOutputs/{io_name}/eu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of the specified analog output point
#
# POST /device/strategy/ios/analogOutputs/{ioName}/eu
# operationId: writeAnalogOutputEu
export def "device-strategy-ios-analog-outputs-eu create-write" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float # Value of the float variable (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/analogOutputs/{io_name}/eu"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and state (true = on, false = off) of all digital input points in the strategy. If there is no strategy in the controller, or the strategy includes no digital inputs, the returned array will be empty.
#
# GET /device/strategy/ios/digitalInputs
# operationId: readDigitalInputs
export def "device-strategy-ios-digital-inputs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/ios/digitalInputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the specified digital input point's state (true = on, false = off)
#
# GET /device/strategy/ios/digitalInputs/{ioName}/state
# operationId: readDigitalInputState
export def "device-strategy-ios-digital-inputs-state get" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/digitalInputs/{io_name}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name and state (true = on, false = off) of all digital output points in the strategy
#
# GET /device/strategy/ios/digitalOutputs
# operationId: readDigitalOutputs
export def "device-strategy-ios-digital-outputs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/ios/digitalOutputs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the specified digital output point's state (true = on, false = off)
#
# GET /device/strategy/ios/digitalOutputs/{ioName}/state
# operationId: readDigitalOutputState
export def "device-strategy-ios-digital-outputs-state get" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/digitalOutputs/{io_name}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of the specified digital output point
#
# POST /device/strategy/ios/digitalOutputs/{ioName}/state
# operationId: writeDigitalOutputState
export def "device-strategy-ios-digital-outputs-state create-write" [
  io_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: oneof<nothing, bool> # State of a digital point (true = on, false = off)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($io_name | is-empty) { error make --unspanned { msg: "path parameter 'ioName' must be non-empty" } }
  let full_url = (build-url $base ({io_name: (encode-path-segment $io_name)} | format pattern "/device/strategy/ios/digitalOutputs/{io_name}/state"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns an array of the name and length of all the float tables in the strategy
#
# GET /device/strategy/tables/floats
# operationId: readFloatTables
export def "device-strategy-tables-floats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<length: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/tables/floats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Read table elements #### Examples #### * Read all elements in a table named ftable: https://1.2.3.4/api/v1/device/strategy/tables/floats/ftable * Read elements 5 and up in a table named ftable starting with index 5: https://1.2.3.4/api/v1/device/strategy/tables/floats/ftable?startIndex=5 * Read 3 consecutive elements in a table named ftable starting with the element at index 10: https://1.2.3.4/api/v1/device/strategy/tables/floats/ftable?startIndex=10&numElements=3
#
# GET /device/strategy/tables/floats/{tableName}
# operationId: readFloatTable
export def "device-strategy-tables-floats get" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to read (default is 0) (format: int32)
  --num-elements: int # Number of elements to read (default is number of elements in the table minus startIndex) (format: int32)
]: nothing -> list<float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "numElements" $num_elements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/floats/{table_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startIndex": $start_index, "numElements": $num_elements} | compact), body: null}
}

# Write table elements #### Examples #### * Write the values (1.5, 2.4, 3.5) to 3 consecutive elements in a table named ftable starting with the element at index 10:POST to https://1.2.3.4/api/v1/device/strategy/tables/floats/ftable?startIndex=10 with body of the POST request set to [ 1.5, 2.4, 3.5 ]
#
# POST /device/strategy/tables/floats/{tableName}
# operationId: writeFloatTable
export def "device-strategy-tables-floats create-write" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to write (default is 0) (format: int32)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/floats/{table_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"startIndex": $start_index} | compact), body: $req_body}
}

# Read specified table element
#
# GET /device/strategy/tables/floats/{tableName}/{index}
# operationId: readFloatTableElement
export def "device-strategy-tables-floats get-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/floats/{table_name}/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Write specified table element
#
# POST /device/strategy/tables/floats/{tableName}/{index}
# operationId: writeFloatTableElement
export def "device-strategy-tables-floats create-write-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float # Value of the float variable (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/floats/{table_name}/{index}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns an array of the name and length of all the integer32 tables in the strategy
#
# GET /device/strategy/tables/int32s
# operationId: readInt32Tables
export def "device-strategy-tables-int32s list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<length: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/tables/int32s")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# "Read a range of table elements from the specified integer32 table" #### Examples #### * Read all elements in a table named itable: https://1.2.3.4/api/v1/device/strategy/tables/int32s/itable * Read elements 5 and up in a table named itable starting with index 5: https://1.2.3.4/api/v1/device/strategy/tables/int32s/itable?startIndex=5 * Read 3 consecutive elements in a table named itable starting with the element at index 10: https://1.2.3.4/api/v1/device/strategy/tables/int32s/itable?startIndex=10&numElements=3
#
# GET /device/strategy/tables/int32s/{tableName}
# operationId: readInt32Table
export def "device-strategy-tables-int32s get" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to read (default is 0) (format: int32)
  --num-elements: int # Number of elements to read (default is number of elements in the table minus startIndex) (format: int32)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "numElements" $num_elements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int32s/{table_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startIndex": $start_index, "numElements": $num_elements} | compact), body: null}
}

# "Write a range of table elements" #### Examples #### * Write the values (1, 2, 3) to 3 consecutive elements in a table named itable starting with the element at index 10:POST to https://1.2.3.4/api/v1/device/strategy/tables/int32s/itable?startIndex=10 with body of the POST request set to [ 1, 2, 3 ]
#
# POST /device/strategy/tables/int32s/{tableName}
# operationId: writeInt32Table
export def "device-strategy-tables-int32s create-write" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to write (default is 0) (format: int32)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int32s/{table_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"startIndex": $start_index} | compact), body: $req_body}
}

# Read specified integer32 table element
#
# GET /device/strategy/tables/int32s/{tableName}/{index}
# operationId: readInt32TableElement
export def "device-strategy-tables-int32s get-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int32s/{table_name}/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Write specified integer32 table element
#
# POST /device/strategy/tables/int32s/{tableName}/{index}
# operationId: writeInt32TableElement
export def "device-strategy-tables-int32s create-write-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # Value of the integer32 variable (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int32s/{table_name}/{index}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns an array of the name and length of all the integer64 tables in the strategy
#
# GET /device/strategy/tables/int64s
# operationId: readInt64Tables
export def "device-strategy-tables-int64s list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<length: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/tables/int64s")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# "Read a range of table elements from the specified integer64 table" #### Examples #### * Read all elements in a table named i64table: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table * Read elements 5 and up in a table named i64table starting with index 5: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table?startIndex=5 * Read 3 consecutive elements in a table named i64table starting with the element at index 10: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table?startIndex=10&numElements=3
#
# GET /device/strategy/tables/int64s/{tableName}
# operationId: readInt64Table
export def "device-strategy-tables-int64s get" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to read (default is 0) (format: int32)
  --num-elements: int # Number of elements to read (default is number of elements in the table minus startIndex) (format: int32)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "numElements" $num_elements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int64s/{table_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startIndex": $start_index, "numElements": $num_elements} | compact), body: null}
}

# "Write a range of table elements" #### Examples #### * Write the values (1, 2, 3) to 3 consecutive elements in a table named i64table starting with the element at index 10:POST to https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table?startIndex=10 with body of the POST request set to [ 1, 2, 3 ]
#
# POST /device/strategy/tables/int64s/{tableName}
# operationId: writeInt64Table
export def "device-strategy-tables-int64s create-write" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to write; default is 0 (format: int32)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int64s/{table_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"startIndex": $start_index} | compact), body: $req_body}
}

# "Read a range of table elements from the specified integer64 table" #### Examples #### * Read all elements in a table named i64table: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table/_string * Read elements 5 and up in a table named i64table starting with index 5: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table/_string?startIndex=5 * Read 3 consecutive elements in a table named i64table starting with the element at index 10: https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table/_string?startIndex=10&numElements=3
#
# GET /device/strategy/tables/int64s/{tableName}/_string
# operationId: readInt64TableAsString
export def "device-strategy-tables-int64s-string get" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to read (default is 0) (format: int32)
  --num-elements: int # Number of elements to read (default is number of elements in the table minus startIndex) (format: int32)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "numElements" $num_elements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int64s/{table_name}/_string") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startIndex": $start_index, "numElements": $num_elements} | compact), body: null}
}

# "Write a range of table elements" #### Examples #### * Write the values (1, 2, 3) to 3 consecutive elements in a table named i64table starting with the element at index 10:POST to https://1.2.3.4/api/v1/device/strategy/tables/int64s/i64table/_string?startIndex=10 with body of the POST request set to [ "1", "2", "3" ]
#
# POST /device/strategy/tables/int64s/{tableName}/_string
# operationId: writeInt64TableAsString
export def "device-strategy-tables-int64s-string create-write" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to write; default is 0. (format: int32)
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/int64s/{table_name}/_string") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"startIndex": $start_index} | compact), body: $req_body}
}

# Read specified integer64 table element
#
# GET /device/strategy/tables/int64s/{tableName}/{index}
# operationId: readInt64TableElement
export def "device-strategy-tables-int64s get-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int64s/{table_name}/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Write specified integer64 table element
#
# POST /device/strategy/tables/int64s/{tableName}/{index}
# operationId: writeInt64TableElement
export def "device-strategy-tables-int64s create-write-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # Value of the integer64 variable (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int64s/{table_name}/{index}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Read specified integer64 table element as string
#
# GET /device/strategy/tables/int64s/{tableName}/{index}/_string
# operationId: readInt64TableElementAsString
export def "device-strategy-tables-int64s-string get-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int64s/{table_name}/{index}/_string"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Write specified integer64 table element as string
#
# POST /device/strategy/tables/int64s/{tableName}/{index}/_string
# operationId: writeInt64TableElementAsString
export def "device-strategy-tables-int64s-string create-write-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # Value of the integer64 variable expressed as decimal string, e.g. "34359738367"
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/int64s/{table_name}/{index}/_string"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns an array of the name and length of all the string tables in the strategy
#
# GET /device/strategy/tables/strings
# operationId: readStringTables
export def "device-strategy-tables-strings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<length: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/tables/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# "Read a range of table elements from the specified string table" #### Examples #### * Read all elements in a table named strTable: https://1.2.3.4/api/v1/device/strategy/tables/strings/strTable * Read elements 5 and up in a table named i64table starting with index 5: https://1.2.3.4/api/v1/device/strategy/tables/strings/strTable?startIndex=5 * Read 3 consecutive elements in a table named i64table starting with the element at index 10: https://1.2.3.4/api/v1/device/strategy/tables/strings/strTable?startIndex=10&numElements=3
#
# GET /device/strategy/tables/strings/{tableName}
# operationId: readStringTable
export def "device-strategy-tables-strings get" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to read (default is 0) (format: int32)
  --num-elements: int # Number of elements to read (default is number of elements in the table minus startIndex) (format: int32)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar") (serialize-qp "numElements" $num_elements "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/strings/{table_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startIndex": $start_index, "numElements": $num_elements} | compact), body: null}
}

# "Write a range of table elements" #### Examples #### * Write the values ("first", "second", "third") to 3 consecutive elements in a table named strTable starting with the element at index 10:POST to https://1.2.3.4/api/v1/device/strategy/tables/strings/strtable?startIndex=10 with body of the POST request set to [ "first", "second", "third" ]
#
# POST /device/strategy/tables/strings/{tableName}
# operationId: writeStringTable
export def "device-strategy-tables-strings create-write" [
  table_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-index: int # Index of first element to write (default is 0) (format: int32)
  --body: list
]: any -> record<errorCode: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  let qp = [(serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name)} | format pattern "/device/strategy/tables/strings/{table_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"startIndex": $start_index} | compact), body: $req_body}
}

# Read specified table element
#
# GET /device/strategy/tables/strings/{tableName}/{index}
# operationId: readStringTableElement
export def "device-strategy-tables-strings get-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/strings/{table_name}/{index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Write specified table element
#
# POST /device/strategy/tables/strings/{tableName}/{index}
# operationId: writeStringTableElement
export def "device-strategy-tables-strings create-write-element" [
  table_name: string
  index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The value of a string; string width (max length) for each string variable is defined in the strategy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($table_name | is-empty) { error make --unspanned { msg: "path parameter 'tableName' must be non-empty" } }
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({table_name: (encode-path-segment $table_name), index: (encode-path-segment $index)} | format pattern "/device/strategy/tables/strings/{table_name}/{index}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and current value of all down timers in the strategy
#
# GET /device/strategy/vars/downTimers
# operationId: readDownTimerVars
export def "device-strategy-vars-down-timers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/downTimers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns current value of the specified down timer
#
# GET /device/strategy/vars/downTimers/{downTimerName}/value
# operationId: readDownTimerValue
export def "device-strategy-vars-down-timers-value get" [
  down_timer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($down_timer_name | is-empty) { error make --unspanned { msg: "path parameter 'downTimerName' must be non-empty" } }
  let full_url = (build-url $base ({down_timer_name: (encode-path-segment $down_timer_name)} | format pattern "/device/strategy/vars/downTimers/{down_timer_name}/value"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name and value of all (single-precision) float variables in the strategy
#
# GET /device/strategy/vars/floats
# operationId: readFloatVars
export def "device-strategy-vars-floats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/floats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns value of the specified float variable
#
# GET /device/strategy/vars/floats/{floatName}
# operationId: readFloatVar
export def "device-strategy-vars-floats get" [
  float_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($float_name | is-empty) { error make --unspanned { msg: "path parameter 'floatName' must be non-empty" } }
  let full_url = (build-url $base ({float_name: (encode-path-segment $float_name)} | format pattern "/device/strategy/vars/floats/{float_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of a float variable
#
# POST /device/strategy/vars/floats/{floatName}
# operationId: writeFloatVar
export def "device-strategy-vars-floats create-write" [
  float_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float # Value of the float variable (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($float_name | is-empty) { error make --unspanned { msg: "path parameter 'floatName' must be non-empty" } }
  let full_url = (build-url $base ({float_name: (encode-path-segment $float_name)} | format pattern "/device/strategy/vars/floats/{float_name}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and value of all integer32 variables in the strategy
#
# GET /device/strategy/vars/int32s
# operationId: readInt32Vars
export def "device-strategy-vars-int32s list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/int32s")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns value of the specified integer32 variable
#
# GET /device/strategy/vars/int32s/{int32Name}
# operationId: readInt32Var
export def "device-strategy-vars-int32s get" [
  int32_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int32_name | is-empty) { error make --unspanned { msg: "path parameter 'int32Name' must be non-empty" } }
  let full_url = (build-url $base ({int32_name: (encode-path-segment $int32_name)} | format pattern "/device/strategy/vars/int32s/{int32_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of an integer32 variable
#
# POST /device/strategy/vars/int32s/{int32Name}
# operationId: writeInt32Var
export def "device-strategy-vars-int32s create-write" [
  int32_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # Value of the integer32 variable (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int32_name | is-empty) { error make --unspanned { msg: "path parameter 'int32Name' must be non-empty" } }
  let full_url = (build-url $base ({int32_name: (encode-path-segment $int32_name)} | format pattern "/device/strategy/vars/int32s/{int32_name}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and value of all integer64 variables in the strategy
#
# GET /device/strategy/vars/int64s
# operationId: readInt64Vars
export def "device-strategy-vars-int64s list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/int64s")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the name and value as a string of all integer64 variables in the strategy
#
# GET /device/strategy/vars/int64s/_string
# operationId: readInt64VarsAsStrings
export def "device-strategy-vars-int64s-string list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/int64s/_string")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns value of the specified integer64 variable
#
# GET /device/strategy/vars/int64s/{int64Name}
# operationId: readInt64Var
export def "device-strategy-vars-int64s get" [
  int64_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int64_name | is-empty) { error make --unspanned { msg: "path parameter 'int64Name' must be non-empty" } }
  let full_url = (build-url $base ({int64_name: (encode-path-segment $int64_name)} | format pattern "/device/strategy/vars/int64s/{int64_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of an integer64 variable
#
# POST /device/strategy/vars/int64s/{int64Name}
# operationId: writeInt64Var
export def "device-strategy-vars-int64s create-write" [
  int64_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # Value of the integer64 variable (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int64_name | is-empty) { error make --unspanned { msg: "path parameter 'int64Name' must be non-empty" } }
  let full_url = (build-url $base ({int64_name: (encode-path-segment $int64_name)} | format pattern "/device/strategy/vars/int64s/{int64_name}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns value of the specified integer64 variable as a string
#
# GET /device/strategy/vars/int64s/{int64Name}/_string
# operationId: readInt64VarAsString
export def "device-strategy-vars-int64s-string get" [
  int64_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int64_name | is-empty) { error make --unspanned { msg: "path parameter 'int64Name' must be non-empty" } }
  let full_url = (build-url $base ({int64_name: (encode-path-segment $int64_name)} | format pattern "/device/strategy/vars/int64s/{int64_name}/_string"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of an integer64 variable as a string
#
# POST /device/strategy/vars/int64s/{int64Name}/_string
# operationId: writeInt64VarAsString
export def "device-strategy-vars-int64s-string create-write" [
  int64_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # Value of the integer64 variable expressed as decimal string, e.g. "34359738367"
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($int64_name | is-empty) { error make --unspanned { msg: "path parameter 'int64Name' must be non-empty" } }
  let full_url = (build-url $base ({int64_name: (encode-path-segment $int64_name)} | format pattern "/device/strategy/vars/int64s/{int64_name}/_string"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and value of all string variables in the strategy
#
# GET /device/strategy/vars/strings
# operationId: readStringVars
export def "device-strategy-vars-strings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns value of the specified string
#
# GET /device/strategy/vars/strings/{stringName}
# operationId: readStringVar
export def "device-strategy-vars-strings get" [
  string_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($string_name | is-empty) { error make --unspanned { msg: "path parameter 'stringName' must be non-empty" } }
  let full_url = (build-url $base ({string_name: (encode-path-segment $string_name)} | format pattern "/device/strategy/vars/strings/{string_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sets the value of a string variable
#
# POST /device/strategy/vars/strings/{stringName}
# operationId: writeStringVar
export def "device-strategy-vars-strings create-write" [
  string_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The value of a string; string width (max length) for each string variable is defined in the strategy
]: any -> record<errorCode: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($string_name | is-empty) { error make --unspanned { msg: "path parameter 'stringName' must be non-empty" } }
  let full_url = (build-url $base ({string_name: (encode-path-segment $string_name)} | format pattern "/device/strategy/vars/strings/{string_name}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns the name and current value of all up timers in the strategy
#
# GET /device/strategy/vars/upTimers
# operationId: readUpTimerVars
export def "device-strategy-vars-up-timers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/device/strategy/vars/upTimers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns current value of the specified up timer
#
# GET /device/strategy/vars/upTimers/{upTimerName}/value
# operationId: readUpTimerValue
export def "device-strategy-vars-up-timers-value get" [
  up_timer_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: float> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($up_timer_name | is-empty) { error make --unspanned { msg: "path parameter 'upTimerName' must be non-empty" } }
  let full_url = (build-url $base ({up_timer_name: (encode-path-segment $up_timer_name)} | format pattern "/device/strategy/vars/upTimers/{up_timer_name}/value"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
