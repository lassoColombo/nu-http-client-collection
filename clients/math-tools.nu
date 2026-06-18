# Auto-generated client for Numbers API v1.5
# Source: https://api.apis.guru/v2/specs/math.tools/1.5/openapi.json
# Auth: --token flag or $env.NUMBERS_API_TOKEN

const BASE_URL = "https://api.math.tools"
const DEFAULT_AUTH = "x-mathtools-api-secret"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NUMBERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-mathtools-api-secret" => { {headers: {X-Mathtools-Api-Secret: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.math.tools" "http://api.math.tools"] }
def auth-scheme-completer [] { ["x-mathtools-api-secret"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "numbers-base get" } } | get name | first)
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

# Convert a given number from one base to another base
#
# GET /numbers/base
export def "numbers-base get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert to the target base (format: integer)
  --qp-from: int # Base of the supplied number (Optional base 10 assumed by default) (format: integer)
  --qp-to: int # Target base to convert to (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/base" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert a given number to binary
#
# GET /numbers/base/binary
export def "numbers-base-binary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert to binary (format: integer)
  --qp-from: int # Base of the supplied number (Optional base 10 assumed by default) (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/base/binary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert a given number to hexadecimal
#
# GET /numbers/base/hex
export def "numbers-base-hex get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert to hex (format: integer)
  --qp-from: int # Base of the supplied number (Optional base 10 assumed by default) (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/base/hex" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert a given number to octal
#
# GET /numbers/base/octal
export def "numbers-base-octal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert to octal (format: integer)
  --qp-from: int # Base of the supplied number (Optional base 10 assumed by default) (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/base/octal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the cardinal of the given number
#
# GET /numbers/cardinal
export def "numbers-cardinal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number value (format: integer)
  --language: string # Language to use (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/cardinal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Spells out the number as a currency
#
# GET /numbers/currency
export def "numbers-currency get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to spell (format: integer)
  --language: string # Language to use (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/currency" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a random fact about a number
#
# GET /numbers/fact
export def "numbers-fact get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number value (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/fact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a cube number or not.
#
# GET /numbers/is-cube
export def "numbers-is-cube get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/is-cube" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a palindrome number or not.
#
# GET /numbers/is-palindrome
export def "numbers-is-palindrome get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/is-palindrome" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a square number or not.
#
# GET /numbers/is-square
export def "numbers-is-square get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/is-square" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a triangle number or not.
#
# GET /numbers/is-triangle
export def "numbers-is-triangle get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/is-triangle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the number of the day for current day
#
# GET /numbers/nod
export def "numbers-nod get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/numbers/nod")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert base 10 representation of a given number to chinese numeral.
#
# GET /numbers/numeral/chinese
export def "numbers-numeral-chinese get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/numeral/chinese" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert base 10 representation of a given number to egyptian numeral.
#
# GET /numbers/numeral/egyptian
export def "numbers-numeral-egyptian get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/numeral/egyptian" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Convert base 10 representation of a given number to roman numeral.
#
# GET /numbers/numeral/roman
export def "numbers-numeral-roman get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to convert (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/numeral/roman" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the ordinal of the given number
#
# GET /numbers/ordinal
export def "numbers-ordinal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number value (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/ordinal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get digits of pi (Ï€)
#
# GET /numbers/pi
export def "numbers-pi get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: int # Optional start position (format: integer)
  --qp-to: int # Optional start position (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/pi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the prime factors of a given number.
#
# GET /numbers/prime/factors
export def "numbers-prime-factors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to get the factors (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/factors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known fermat prime number or not.
#
# GET /numbers/prime/is-fermat-prime
export def "numbers-prime-is-fermat-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-fermat-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known fibonacci prime number or not.
#
# GET /numbers/prime/is-fibonacci-prime
export def "numbers-prime-is-fibonacci-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-fibonacci-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known mersenne prime number or not.
#
# GET /numbers/prime/is-mersenne-prime
export def "numbers-prime-is-mersenne-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-mersenne-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known partition prime number or not.
#
# GET /numbers/prime/is-partition-prime
export def "numbers-prime-is-partition-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-partition-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known pell prime number or not.
#
# GET /numbers/prime/is-pell-prime
export def "numbers-prime-is-pell-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-pell-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a perfect number or not.
#
# GET /numbers/prime/is-perfect
export def "numbers-prime-is-perfect get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-perfect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether a given number is a known prime number or not.
#
# GET /numbers/prime/is-prime
export def "numbers-prime-is-prime get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --number: int # Number to check (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/prime/is-prime" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Generate random number(s)
#
# GET /numbers/random
export def "numbers-random get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --min: int # Minimum Number value in the range (format: integer)
  --max: int # Maximum Number value (format: integer)
  --total: int # Total number of random numbers to generate. Defaults to 1 (format: integer)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-mathtools-api-secret"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min" $min "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "total" $total "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/numbers/random" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
