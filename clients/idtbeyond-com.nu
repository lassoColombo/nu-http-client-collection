# Auto-generated client for Active Documentation for /v1 v1.1.7
# Source: https://api.apis.guru/v2/specs/idtbeyond.com/1.1.7/swagger.json
# Auth: --token flag or $env.ACTIVE_DOCUMENTATION_FOR_V1_TOKEN

const BASE_URL = "https://api.idtbeyond.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACTIVE_DOCUMENTATION_FOR_V1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://api.idtbeyond.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "iatu-balance get" } } | get name | first)
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

# Account balance
#
# GET /iatu/balance
export def "iatu-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of account charges in JSON
#
# GET /iatu/charges/reports/all
export def "iatu-charges-reports-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/charges/reports/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# List of account charges in CSV
#
# GET /iatu/charges/reports/all.csv
export def "iatu-charges-reports-all-csv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/charges/reports/all.csv" $qp)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Mobile number validation
#
# GET /iatu/number-validator
export def "iatu-number-validator get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # 2-digit code of the country in ISO 3166 format. 'BR' (default: BR)
  --mobile-number: string # The mobile number you would like to validate. '5521983115555' (default: 5521983115555)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar") (serialize-qp "mobile_number" $mobile_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/number-validator" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country_code": $country_code, "mobile_number": $mobile_number} | compact), body: null}
}

# Current promotions
#
# GET /iatu/products/promotions
export def "iatu-products-promotions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/products/promotions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of products in JSON format
#
# GET /iatu/products/reports/all
export def "iatu-products-reports-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/products/reports/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of products in CSV format
#
# GET /iatu/products/reports/all.csv
export def "iatu-products-reports-all-csv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/products/reports/all.csv")
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the estimated Local Value of a product
#
# GET /iatu/products/reports/local-value
export def "iatu-products-reports-local-value get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # 2-digit code of the country in ISO 3166 format. 'GT' (default: GT)
  --carrier-code: string # Name of the mobile carrier. 'Claro' (default: Claro)
  --amount: int # This is the amount, in cents, of the product you are purchasing. '500' = $5.00 (default: 500)
  --currency-code: string # The currency code (ISO 4217) on the product you are querying. 'USD' (default: USD)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar") (serialize-qp "carrier_code" $carrier_code "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "currency_code" $currency_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/products/reports/local-value" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country_code": $country_code, "carrier_code": $carrier_code, "amount": $amount, "currency_code": $currency_code} | compact), body: null}
}

# Topup a mobile phone
#
# POST /iatu/topups
export def "iatu-topups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
  --amount: int # The amount, in cents, of the product you are purchasing. '500' = $5.00 (default: 500)
  --carrier-code: string # Name of the mobile carrier. 'Claro' (default: Claro)
  --client-transaction-id: string # UNIQUE 15 char ID you use to track topups. 'trans0123456789' (default: )
  --country-code: string # 2-digit code of the country in ISO 3166 format. 'GT' (default: GT)
  --mobile-number: string # Mobile number to topup. VALIDATE prior to submission. '50231234567' (default: 50231234567)
  --plan: string # The Application plan being used. Case-sensitive. 'Sandbox' or 'Production' (default: Sandbox)
  --product-code: string # Optional code to distinguish one particular product from another. '76560' (default: )
  --terminal-id: string # ID for the Terminal used to perform the topup. 'Kiosk 5' (default: Kiosk 5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/topups")
  let req_body = {"amount": $amount, "carrier_code": $carrier_code, "client_transaction_id": $client_transaction_id, "country_code": $country_code, "mobile_number": $mobile_number, "plan": $plan, "product_code": $product_code, "terminal_id": $terminal_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search topups transactions
#
# POST /iatu/topups/reports
export def "iatu-topups-reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
  --client-transaction-id: string # The UNIQUE 15 char ID used to track topups. 'trans0123456789' (default: trans0123456789)
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). Not used in query by to_service_number. '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). Not used in query by to_service_number. '2016-01-28' (default: 2016-01-28)
  --to-service-number: string # Enter the to_service_number returned in the response to track the current transaction status. '0123456789' (default: 123456789)
  --type-of-report: string # The type of query you would like to search by. (default: client_transaction_id or to_service_number)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/topups/reports")
  let req_body = {"client_transaction_id": $client_transaction_id, "date_from": $date_from, "date_to": $date_to, "to_service_number": $to_service_number, "type_of_report": $type_of_report} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List of account topups in JSON
#
# GET /iatu/topups/reports/all
export def "iatu-topups-reports-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/topups/reports/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# List of account topups in CSV
#
# GET /iatu/topups/reports/all.csv
export def "iatu-topups-reports-all-csv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/topups/reports/all.csv" $qp)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Summary of account topups in JSON
#
# GET /iatu/topups/reports/totals
export def "iatu-topups-reports-totals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # The beginning date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --date-to: string # The ending date of the search IN YYYY-MM-DD format (America/New_York timezone). '2016-01-28' (default: 2016-01-28)
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/iatu/topups/reports/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Reversal of a Topup
#
# POST /iatu/topups/reverse
export def "iatu-topups-reverse create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
  --client-transaction-id: string # UNIQUE 15 char ID you use to track topups. 'trans0123456789' (default: trans0123456789)
  --to-service-number: string # UNIQUE IDT transaction number found in the response of a successful topup request. '0123456789' (default: 123456789)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/iatu/topups/reverse")
  let req_body = {"client_transaction_id": $client_transaction_id, "to_service_number": $to_service_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Status check
#
# GET /status
export def "status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-idt-beyond-app-id: string # Application ID you would like to use
  --x-idt-beyond-app-key: string # Application KEY you would like to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-idt-beyond-app-id": $x_idt_beyond_app_id, "x-idt-beyond-app-key": $x_idt_beyond_app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
