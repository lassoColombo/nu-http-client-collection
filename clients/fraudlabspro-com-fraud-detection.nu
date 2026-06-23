# Auto-generated client for FraudLabs Pro Fraud Detection v1.1
# Source: https://api.apis.guru/v2/specs/fraudlabspro.com/fraud-detection/1.1/openapi.json
# Auth: --token flag or $env.FRAUDLABS_PRO_FRAUD_DETECTION_TOKEN

const BASE_URL = "https://api.fraudlabspro.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FRAUDLABS_PRO_FRAUD_DETECTION_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.fraudlabspro.com" "https://virtserver.swaggerhub.com/fraudlabspro/fraudlabspro/1.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def format-completer [] { ["json" "xml"] }
def action-completer [] { ["APPROVE" "REJECT" "REJECT_BLACKLIST"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "order-feedback create" } } | get name | first)
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

# Feedback the status of an order transaction.
#
# POST /v1/order/feedback
export def "order-feedback create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --key: string
  --format: string@format-completer
  --action: string@action-completer
  --notes: string # allows empty value
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/order/feedback" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "key": $key, "format": $format, "action": $action, "notes": $notes} | compact), body: null}
}

# Screen order for payment fraud.
#
# POST /v1/order/screen
export def "order-screen create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string
  --key: string
  --format: string@format-completer
  --last-name: string # allows empty value
  --first-name: string # allows empty value
  --bill-addr: string # allows empty value
  --bill-city: string # allows empty value
  --bill-state: string # allows empty value
  --bill-country: string # allows empty value
  --bill-zip-code: string # allows empty value
  --ship-addr: string # allows empty value
  --ship-city: string # allows empty value
  --ship-state: string # allows empty value
  --ship-country: string
  --ship-zip-code: string # allows empty value
  --email-domain: string # allows empty value
  --user-phone: string # allows empty value
  --email: string # allows empty value
  --email-hash: string # allows empty value
  --username-hash: string # allows empty value
  --password-hash: string # allows empty value
  --bin-no: string # allows empty value
  --card-hash: string # allows empty value
  --avs-result: string # allows empty value
  --cvv-result: string # allows empty value
  --user-order-id: string # allows empty value
  --user-order-memo: string # allows empty value
  --amount: float # allows empty value
  --quantity: int # allows empty value
  --currency: string # allows empty value
  --department: string # allows empty value
  --payment-mode: string # allows empty value
  --flp-checksum: string # allows empty value
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "last_name" $last_name "scalar") (serialize-qp "first_name" $first_name "scalar") (serialize-qp "bill_addr" $bill_addr "scalar") (serialize-qp "bill_city" $bill_city "scalar") (serialize-qp "bill_state" $bill_state "scalar") (serialize-qp "bill_country" $bill_country "scalar") (serialize-qp "bill_zip_code" $bill_zip_code "scalar") (serialize-qp "ship_addr" $ship_addr "scalar") (serialize-qp "ship_city" $ship_city "scalar") (serialize-qp "ship_state" $ship_state "scalar") (serialize-qp "ship_country" $ship_country "scalar") (serialize-qp "ship_zip_code" $ship_zip_code "scalar") (serialize-qp "email_domain" $email_domain "scalar") (serialize-qp "user_phone" $user_phone "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "email_hash" $email_hash "scalar") (serialize-qp "username_hash" $username_hash "scalar") (serialize-qp "password_hash" $password_hash "scalar") (serialize-qp "bin_no" $bin_no "scalar") (serialize-qp "card_hash" $card_hash "scalar") (serialize-qp "avs_result" $avs_result "scalar") (serialize-qp "cvv_result" $cvv_result "scalar") (serialize-qp "user_order_id" $user_order_id "scalar") (serialize-qp "user_order_memo" $user_order_memo "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "department" $department "scalar") (serialize-qp "payment_mode" $payment_mode "scalar") (serialize-qp "flp_checksum" $flp_checksum "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/order/screen" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ip": $ip, "key": $key, "format": $format, "last_name": $last_name, "first_name": $first_name, "bill_addr": $bill_addr, "bill_city": $bill_city, "bill_state": $bill_state, "bill_country": $bill_country, "bill_zip_code": $bill_zip_code, "ship_addr": $ship_addr, "ship_city": $ship_city, "ship_state": $ship_state, "ship_country": $ship_country, "ship_zip_code": $ship_zip_code, "email_domain": $email_domain, "user_phone": $user_phone, "email": $email, "email_hash": $email_hash, "username_hash": $username_hash, "password_hash": $password_hash, "bin_no": $bin_no, "card_hash": $card_hash, "avs_result": $avs_result, "cvv_result": $cvv_result, "user_order_id": $user_order_id, "user_order_memo": $user_order_memo, "amount": $amount, "quantity": $quantity, "currency": $currency, "department": $department, "payment_mode": $payment_mode, "flp_checksum": $flp_checksum} | compact), body: null}
}
