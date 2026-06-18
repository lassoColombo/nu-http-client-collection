# Auto-generated client for climateKuul live v1.0
# Source: https://api.apis.guru/v2/specs/climatekuul.com/1.0/openapi.json
# Auth: --token flag or $env.CLIMATEKUUL_LIVE_TOKEN

const BASE_URL = "http://api.climatekuul.com:8000/footprint"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLIMATEKUUL_LIVE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
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

def base-url-completer [] { ["http://api.climatekuul.com:8000/footprint"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "airtravel-coordinates create" } } | get name | first)
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

# airtravelCoordinates
#
# POST /airtravelCoordinates
# operationId: airtravelCoordinates
export def "airtravel-coordinates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # e.g. application/x-www-form-urlencoded
  api_key_l1: string # Client Api Key (e.g. d95fead6-e8a6-4547-9fb9-7835101a3960)
  api_key_l2: string # Integration Partner Api Key (e.g. c60f8db5-7204-4427-960d-27400c38b166)
  destination_airport_latitude: float # Destination latitude (like: 50.870752, value = -90<=x<=90) (format: double, e.g. 24.9056)
  destination_airport_longitude: float # Destination longitude (like: 4.669490, value = -180<=x<=180) (format: double, e.g. 67.1569)
  number_of_passengers: int # Number of passengers (like: 1, 2 ,3 ) (format: int32, e.g. 2)
  origin_airport_latitude: float # Origin latitude (like: 23.372628 value = -90<=x<=90 ) (format: double, e.g. 31.5208)
  origin_airport_longitude: float # Origin longitude (like: 113.159339, value = -180<=x<=180 ) (format: double, e.g. 74.4028)
  travel_class: string # Travel class can be 'First Class', 'Economy', 'Business' or 'Premium Economy' (e.g. Economy)
  travel_mode: string # Travel mode can be 'one way' or 'round trip' (e.g. round trip)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelCoordinates")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "destination_airport_latitude": $destination_airport_latitude, "destination_airport_longitude": $destination_airport_longitude, "number_of_passengers": $number_of_passengers, "origin_airport_latitude": $origin_airport_latitude, "origin_airport_longitude": $origin_airport_longitude, "travel_class": $travel_class, "travel_mode": $travel_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/x-www-form-urlencoded")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# confirmCarbonOffset
#
# PATCH /airtravelCoordinates/confirmCarbonOffset
# operationId: confirmCarbonOffset4
export def "airtravel-coordinates-confirm-carbon-offset confirm-offset4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  carbon_offset: string # Confirm Carbon Offset (Value = y/n) (e.g. y)
  --contact-email: string # Contact email (e.g. example@example.com)
  --contact-first-name: string # Contact first name (e.g. abc)
  --contact-last-name: string # Contact last name (e.g. xyz)
  transaction_id: string # transaction_id (e.g. 60a78ed201d88997746c91b5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelCoordinates/confirmCarbonOffset")
  let req_body = {"carbonOffset": $carbon_offset, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPayment
#
# PATCH /airtravelCoordinates/confirmPayment
# operationId: confirmPayment4
export def "airtravel-coordinates-confirm-payment confirm-payment4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_payment: string # Confirm Payment (Value = y/n) (e.g. y)
  payment_id: int # Payment Id (format: int32, e.g. 34567878)
  transaction_id: string # transaction_id (e.g. 60a78ed201d88997746c91b5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelCoordinates/confirmPayment")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPayment": $confirm_payment, "paymentID": $payment_id, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPlanting
#
# PATCH /airtravelCoordinates/confirmPlanting
# operationId: confirmsPlanting4
export def "airtravel-coordinates-confirm-planting update-planting4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_planting: string # Confirm Planting (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a78ed201d88997746c91b5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelCoordinates/confirmPlanting")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPlanting": $confirm_planting, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmTransaction
#
# PATCH /airtravelCoordinates/confirmTransaction
# operationId: confirmPaymentOfTransaction4
export def "airtravel-coordinates-confirm-transaction confirm-payment-of-transaction4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirm_transaction: string # Confirm Payment Of Transaction (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a78ed201d88997746c91b5)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelCoordinates/confirmTransaction")
  let req_body = {"confirmTransaction": $confirm_transaction, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# airtravelMultileg
#
# POST /airtravelMultileg
# operationId: airtravelMultileg
# --leg1 shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
# --leg2 shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
# --leg3 shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
export def "airtravel-multileg create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string
  api_key_l2: string
  contact_email: string
  contact_first_name: string
  contact_last_name: string
  leg1: record # e.g. {destination_airport_code: DXB, origin_airport_code: KHI, travel_class: Economy} — shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
  leg2: record # e.g. {destination_airport_code: DXB, origin_airport_code: KHI, travel_class: Economy} — shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
  leg3: record # e.g. {destination_airport_code: DXB, origin_airport_code: KHI, travel_class: Economy} — shape: {destination_airport_code: string, origin_airport_code: string, travel_class: string}
  legs_count: string
  number_of_passengers: string
  travel_mode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelMultileg")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "leg1": $leg1, "leg2": $leg2, "leg3": $leg3, "legs_count": $legs_count, "number_of_passengers": $number_of_passengers, "travel_mode": $travel_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# confirmCarbonOffset
#
# PATCH /airtravelMultileg/confirmCarbonOffset
# operationId: confirmCarbonOffset3
export def "airtravel-multileg-confirm-carbon-offset confirm-offset3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  carbon_offset: string # Confirm Carbon Offset (Value = y/n) (e.g. y)
  --contact-email: string # Contact email (e.g. example@example.com)
  --contact-first-name: string # Contact first name (e.g. abc)
  --contact-last-name: string # Contact last name (e.g. xyz)
  transaction_id: string # transaction_id (e.g. 60a75c0e94c8cb95a6d0e02e)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelMultileg/confirmCarbonOffset")
  let req_body = {"carbonOffset": $carbon_offset, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPayment
#
# PATCH /airtravelMultileg/confirmPayment
# operationId: confirmPayment3
export def "airtravel-multileg-confirm-payment confirm-payment3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_payment: string # Confirm Payment (Value = y/n) (e.g. y)
  payment_id: int # Payment Id (format: int32, e.g. 34567878)
  transaction_id: string # transaction_id (e.g. 60a75c0e94c8cb95a6d0e02e)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelMultileg/confirmPayment")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPayment": $confirm_payment, "paymentID": $payment_id, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPlanting
#
# PATCH /airtravelMultileg/confirmPlanting
# operationId: confirmsPlanting3
export def "airtravel-multileg-confirm-planting update-planting3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_planting: string # Confirm Planting (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a75c0e94c8cb95a6d0e02e)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelMultileg/confirmPlanting")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPlanting": $confirm_planting, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmTransaction
#
# PATCH /airtravelMultileg/confirmTransaction
# operationId: confirmPaymentOfTransaction3
export def "airtravel-multileg-confirm-transaction confirm-payment-of-transaction3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirm_transaction: string # Confirm Payment Of Transaction (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a75c0e94c8cb95a6d0e02e)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/airtravelMultileg/confirmTransaction")
  let req_body = {"confirmTransaction": $confirm_transaction, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# ecommerceDelivery
#
# POST /ecommerceDelivery
# operationId: ecommerceDelivery
export def "ecommerce-delivery create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # e.g. application/x-www-form-urlencoded
  api_key_l1: string # Client Api Key (e.g. d95fead6-e8a6-4547-9fb9-7835101a3960)
  api_key_l2: string # Integration Partner Api Key (e.g. c60f8db5-7204-4427-960d-27400c38b166)
  --destination-airport-code: string # valid airport code of destination (e.g. BRU)
  destination_latitude: float # valid latitude of destination (format: double, e.g. 50.870752)
  destination_longitude: float # valid longitude of destination (format: double, e.g. 4.66949)
  --origin-airport-code: string # valid airport code of origin (e.g. KHI)
  origin_latitude: float # valid latitude of origin (format: double, e.g. 23.372628)
  origin_longitude: float # valid longitude of origin (format: double, e.g. 113.159339)
  volumetric_weight: float # Volumetric weight' (like:2.70) (format: double, e.g. 2.7)
  waybill_type: string # this can be 'air only', 'road only' or 'air and road' (e.g. road only)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/ecommerceDelivery")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "destination_airport_code": $destination_airport_code, "destination_latitude": $destination_latitude, "destination_longitude": $destination_longitude, "origin_airport_code": $origin_airport_code, "origin_latitude": $origin_latitude, "origin_longitude": $origin_longitude, "volumetric_weight": $volumetric_weight, "waybill_type": $waybill_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/x-www-form-urlencoded")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# confirmCarbonOffset
#
# PATCH /ecommerceDelivery/confirmCarbonOffset
# operationId: confirmCarbonOffset1
export def "ecommerce-delivery-confirm-carbon-offset confirm-offset1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  carbon_offset: string # Confirm Carbon Offset (Value = y/n) (e.g. y)
  --contact-email: string # Contact email (e.g. example@example.com)
  --contact-first-name: string # Contact first name (e.g. abc)
  --contact-last-name: string # Contact last name (e.g. xyz)
  transaction_id: string # transaction_id (e.g. 60a766d401d88997746c91a0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/ecommerceDelivery/confirmCarbonOffset")
  let req_body = {"carbonOffset": $carbon_offset, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPayment
#
# PATCH /ecommerceDelivery/confirmPayment
# operationId: confirmPayment1
export def "ecommerce-delivery-confirm-payment confirm-payment1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_payment: string # Confirm Payment (Value = y/n) (e.g. y)
  payment_id: int # Payment Id (format: int32, e.g. 34567878)
  transaction_id: string # transaction_id (e.g. 60a766d401d88997746c91a0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/ecommerceDelivery/confirmPayment")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPayment": $confirm_payment, "paymentID": $payment_id, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPlanting
#
# PATCH /ecommerceDelivery/confirmPlanting
# operationId: confirmsPlanting2
export def "ecommerce-delivery-confirm-planting update-planting2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_planting: string # Confirm Planting (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a766d401d88997746c91a0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/ecommerceDelivery/confirmPlanting")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPlanting": $confirm_planting, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmTransaction
#
# PATCH /ecommerceDelivery/confirmTransaction
# operationId: confirmPaymentOfTransaction1
export def "ecommerce-delivery-confirm-transaction confirm-payment-of-transaction1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirm_transaction: string # Confirm Payment Of Transaction (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a766d401d88997746c91a0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/ecommerceDelivery/confirmTransaction")
  let req_body = {"confirmTransaction": $confirm_transaction, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# requestApiKey
#
# POST /requestApiKey
# operationId: requestApiKey
export def "request-api-key request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # Api Key for client (e.g. qNahlSrEaduQ)
  api_key_l2: string # Integration Partner Api Key (e.g. eCqMeAfaDBWG)
  email: string # User email (e.g. abcd@gmail.com)
  password: int # User password (format: int32, e.g. 234)
  user_first_name: string # User first name (e.g. usman)
  user_last_name: string # User last name (e.g. ch)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/requestApiKey")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "email": $email, "password": $password, "userFirstName": $user_first_name, "userLastName": $user_last_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# RoadDistance
#
# POST /roadDistance
# operationId: roadDistance
export def "road-distance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # Client Api Key (e.g. d95fead6-e8a6-4547-9fb9-7835101a3960)
  api_key_l2: string # Integration Partner Api Key (e.g. c60f8db5-7204-4427-960d-27400c38b166)
  travel_distance: int # format: int32, e.g. 2450
  trip_end: int # timestamp in epoch time (like: 1606780799) (format: int32, e.g. 18)
  trip_start: int # timestamp in epoch time (like: 1604188800) (format: int32, e.g. 16)
  --vehicle-make: string # vehicle make (like: Honda, Toyota, Smart), Required only when vehicle_type is 'personal car' (e.g. Honda)
  vehicle_type: string # Vehicle type can be 'personal car', 'light truck' or 'heavy-duty truck' (e.g. personal car)
  --vehicle-year: int # vehicle year (like: 2010, 2015, 2019), Required only when vehicle_type is 'personal car' (format: int32, e.g. 2010)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/roadDistance")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "travel_distance": $travel_distance, "trip_end": $trip_end, "trip_start": $trip_start, "vehicle_make": $vehicle_make, "vehicle_type": $vehicle_type, "vehicle_year": $vehicle_year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmCarbonOffset
#
# PATCH /roadDistance/confirmCarbonOffset
# operationId: confirmCarbonOffset5
export def "road-distance-confirm-carbon-offset confirm-offset5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  carbon_offset: string # Confirm Carbon Offset (Value = y/n) (e.g. y)
  --contact-email: string # Contact email (e.g. example@example.com)
  --contact-first-name: string # Contact first name (e.g. abc)
  --contact-last-name: string # Contact last name (e.g. xyz)
  transaction_id: string # transaction_id (e.g. 60a7823401d88997746c91a7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/roadDistance/confirmCarbonOffset")
  let req_body = {"carbonOffset": $carbon_offset, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPayment
#
# PATCH /roadDistance/confirmPayment
# operationId: confirmPayment5
export def "road-distance-confirm-payment confirm-payment5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_payment: string # Confirm Payment (Value = y/n) (e.g. y)
  payment_id: int # Payment Id (format: int32, e.g. 34567878)
  transaction_id: string # transaction_id (e.g. 60a7823401d88997746c91a7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/roadDistance/confirmPayment")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPayment": $confirm_payment, "paymentID": $payment_id, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPlanting
#
# PATCH /roadDistance/confirmPlanting
# operationId: confirmsPlanting5
export def "road-distance-confirm-planting update-planting5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_planting: string # Confirm Planting (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a7823401d88997746c91a7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/roadDistance/confirmPlanting")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPlanting": $confirm_planting, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmTransaction
#
# PATCH /roadDistance/confirmTransaction
# operationId: confirmPaymentOfTransaction5
export def "road-distance-confirm-transaction confirm-payment-of-transaction5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirm_transaction: string # Confirm Payment Of Transaction (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a7823401d88997746c91a7)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/roadDistance/confirmTransaction")
  let req_body = {"confirmTransaction": $confirm_transaction, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# urbanDelivery
#
# POST /urbanDelivery
# operationId: urbanDelivery
export def "urban-delivery create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # Client Api Key (e.g. d95fead6-e8a6-4547-9fb9-7835101a3960)
  api_key_l2: string # Integration Partner Api Key (e.g. c60f8db5-7204-4427-960d-27400c38b166)
  destination_latitude: float # Destination latitude (like: 50.870752, value = -90<=x<=90) (format: double, e.g. -89.870752)
  destination_longitude: float # Destination longitude (like: 4.669490, value = -180<=x<=180) (format: double, e.g. 179.66949)
  item_count: int # item_count' (like:2, value = 0<x<=100) (format: int32, e.g. 3)
  origin_latitude: float # Origin latitude (like: 23.372628, value = -90<=x<=90) (format: double, e.g. -89.372628)
  origin_longitude: float # Origin longitude (like: 113.159339, value = -180<=x<=180) (format: double, e.g. -179.159339)
  vehicle_type: string # Vehicle type (like: private car, motorcycle,cargo van,zero-emission) (e.g. PRIVATE CAR)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/urbanDelivery")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "destination_latitude": $destination_latitude, "destination_longitude": $destination_longitude, "item_count": $item_count, "origin_latitude": $origin_latitude, "origin_longitude": $origin_longitude, "vehicle_type": $vehicle_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmCarbonOffset
#
# PATCH /urbanDelivery/confirmCarbonOffset
# operationId: confirmCarbonOffset
export def "urban-delivery-confirm-carbon-offset confirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  carbon_offset: string # Confirm Carbon Offset (Value = y/n) (e.g. y)
  --contact-email: string # Contact email (e.g. example@example.com)
  --contact-first-name: string # Contact first name (e.g. abc)
  --contact-last-name: string # Contact last name (e.g. xyz)
  transaction_id: string # transaction_id (e.g. 60a7875a01d88997746c91ae)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/urbanDelivery/confirmCarbonOffset")
  let req_body = {"carbonOffset": $carbon_offset, "contactEmail": $contact_email, "contactFirstName": $contact_first_name, "contactLastName": $contact_last_name, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPayment
#
# PATCH /urbanDelivery/confirmPayment
# operationId: confirmPayment
export def "urban-delivery-confirm-payment confirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_payment: string # Confirm Payment (Value = y/n) (e.g. y)
  payment_id: int # Payment Id (format: int32, e.g. 34567878)
  transaction_id: string # transaction_id (e.g. 60a7875a01d88997746c91ae)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/urbanDelivery/confirmPayment")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPayment": $confirm_payment, "paymentID": $payment_id, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmPlanting
#
# PATCH /urbanDelivery/confirmPlanting
# operationId: confirmsPlanting
export def "urban-delivery-confirm-planting update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key_l1: string # apikey_l1 (Like: d95fead6-e8a6-4247-9fb9-7835101a4560) (e.g. d95fead6-e8a6-4247-9fb9-7835101a4560)
  api_key_l2: string # apikey_l2 (Like: c60f8db5-7904-4227-960d-27400c38b166) (e.g. c60f8db5-7904-4227-960d-27400c38b166)
  confirm_planting: string # Confirm Planting (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a7875a01d88997746c91ae)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/urbanDelivery/confirmPlanting")
  let req_body = {"apiKey_l1": $api_key_l1, "apiKey_l2": $api_key_l2, "confirmPlanting": $confirm_planting, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# confirmTransaction
#
# PATCH /urbanDelivery/confirmTransaction
# operationId: confirmPaymentOfTransaction
export def "urban-delivery-confirm-transaction confirm-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirm_transaction: string # Confirm Payment Of Transaction (Value = y/n) (e.g. y)
  transaction_id: string # transaction_id (e.g. 60a7875a01d88997746c91ae)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "http://api.climatekuul.com:8000/footprint")
  let full_url = (build-url $base "/urbanDelivery/confirmTransaction")
  let req_body = {"confirmTransaction": $confirm_transaction, "transaction_id": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}
