# Auto-generated client for VAT API v1
# Source: https://api.apis.guru/v2/specs/vatapi.com/1/swagger.json
# Auth: --token flag or $env.VAT_API_TOKEN

const BASE_URL = "https://vatapi.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VAT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "apikey" => { {scheme: $scheme, headers: {apikey: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vatapi.com/v1"] }
def auth-scheme-completer [] { ["apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "country-code-check check" } } | get name | first)
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

# Retrieve a countries VAT rates by its 2 digit country code
#
# GET /country-code-check
# operationId: country_code_check
export def "country-code-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # The 2 digit country code
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country: string, country_code: string, rates: record<parking: record<applies_to: string, value: int>, reduced: record<applies_to: string, value: int>, reduced_alt: record<applies_to: string, value: int>, standard: record<value: int>, super_reduced: record<applies_to: string, value: int>>, status: int, vat_applies: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/country-code-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"code": $code} | compact), body: null}
}

# Convert a currency
#
# GET /currency-conversion
# operationId: currency_conversion
export def "currency-conversion get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-from: string # The currency code you are converting from
  --currency-to: string # The currency code you are converting to
  --amount: int # Optional, an amount you are wanting to convert. Leave blank to just get the current rate
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<amount_from: string, amount_to: string, currency_from: string, currency_to: int, rate: string, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency_from" $currency_from "scalar") (serialize-qp "currency_to" $currency_to "scalar") (serialize-qp "amount" $amount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/currency-conversion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currency_from": $currency_from, "currency_to": $currency_to, "amount": $amount} | compact), body: null}
}

# Create a VAT invoice
#
# POST /invoice
# operationId: create_invoice
# --items item shape: {description: string, price_each: int, quantity: int, vat_rate: int}
export def "invoice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
  business_address: string # Your business address
  business_name: string # Your business name
  --conversion-rate: int # The rate of conversion at time of supply
  currency_code: string # 3 character currency code for invoice
  --currency-code-conversion: string # 3 character currency code to be converted from original transaction currency
  --customer-address: string # Your customers address
  --customer-name: string # Your customers name or trading name
  --customer-vat-number: string # Optional customers VAT number
  --date: string # The date the invoice was issued
  --discount-rate: string # The discount rate per item
  items: list # An array of your invoice items — item shape: {description: string, price_each: int, quantity: int, vat_rate: int}
  --notes: string # Add a note to the invoice.
  --price-type: string # Optional, if the price is including VAT set the type to 'incl'. Otherwise the default is assumed as excluding VAT already, 'excl'
  --tax-point: string # (or 'time of supply') if this is different from the invoice date
  type: string # The type of invoice. Either 'sale' or 'refund'
  vat_number: string # Your VAT number
  --zero-rated: string # To Zero-Rate the VAT, set to true.
]: any -> record<invoice: record<business_address: string, business_name: string, conversion_rate: int, currency_code: string, currency_code_conversion: string, customer_address: string, customer_name: string, customer_vat_number: string, date: string, discount_rate: int, discount_total: int, invoice_number: int, invoice_url: string, items: list<record>, logo_url: string, notes: string, subtotal: int, tax_point: string, total: int, type: string, vat_number: string, vat_total: int>, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invoice")
  let req_body = {"business_address": $business_address, "business_name": $business_name, "conversion_rate": $conversion_rate, "currency_code": $currency_code, "currency_code_conversion": $currency_code_conversion, "customer_address": $customer_address, "customer_name": $customer_name, "customer_vat_number": $customer_vat_number, "date": $date, "discount_rate": $discount_rate, "items": $items, "notes": $notes, "price_type": $price_type, "tax_point": $tax_point, "type": $type, "vat_number": $vat_number, "zero_rated": $zero_rated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an invoice
#
# DELETE /invoice/{id}
# operationId: invoice_delete
export def "invoice delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoice/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an invoice
#
# GET /invoice/{id}
# operationId: get_invoice
export def "invoice get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<invoice: record<business_address: string, business_name: string, conversion_rate: int, currency_code: string, currency_code_conversion: string, customer_address: string, customer_name: string, customer_vat_number: string, date: string, discount_rate: int, discount_total: int, id: int, invoice_url: string, items: list<record>, logo_url: string, notes: string, price_type: string, subtotal: int, tax_point: string, total: int, type: string, vat_number: string, vat_total: int, zero_rated: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoice/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an existing invoice
#
# PUT /invoice/{id}
# operationId: invoice_update
# --items item shape: {description: string, price_each: int, quantity: int, vat_rate: int}
export def "invoice update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
  business_address: string # Your business address
  business_name: string # Your business name
  --conversion-rate: int # The rate of conversion at time of supply
  currency_code: string # 3 character currency code for invoice
  --currency-code-conversion: string # 3 character currency code to be converted from original transaction currency
  --customer-address: string # Your customers address
  --customer-name: string # Your customers name or trading name
  customervat_number: string # Customers VAT number
  --date: string # The date the invoice was issued
  --discount-rate: string # The discount rate per item
  items: list # An array of your invoice items — item shape: {description: string, price_each: int, quantity: int, vat_rate: int}
  --logo-url: string # A URL to your logo image. Must be SSL hosted. https://sslimagehost.com is recommended
  --notes: string # Add a note to the invoice.
  --tax-point: string # (or 'time of supply') if this is different from the invoice date
  type: string # The type of invoice. Either 'sale' or 'refund'
  --vat-number: string # Your VAT number
]: any -> record<invoice: record<business_address: string, business_name: string, conversion_rate: int, currency_code: string, currency_code_conversion: string, customer_address: string, customer_name: string, customer_vat_number: string, date: string, discount_rate: int, discount_total: int, id: int, invoice_url: string, items: list<record>, logo_url: string, notes: string, price_type: string, subtotal: int, tax_point: string, total: int, type: string, vat_number: string, vat_total: int, zero_rated: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/invoice/{id}"))
  let req_body = {"business_address": $business_address, "business_name": $business_name, "conversion_rate": $conversion_rate, "currency_code": $currency_code, "currency_code_conversion": $currency_code_conversion, "customer_address": $customer_address, "customer_name": $customer_name, "customervat_number": $customervat_number, "date": $date, "discount_rate": $discount_rate, "items": $items, "logo_url": $logo_url, "notes": $notes, "tax_point": $tax_point, "type": $type, "vat_number": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a countries VAT rates from an IP address
#
# GET /ip-check
# operationId: ip_check
export def "ip-check check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: string # The IP address to search against
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country: string, country_code: string, rates: record<parking: record<applies_to: string, value: int>, reduced: record<applies_to: string, value: int>, reduced_alt: record<applies_to: string, value: int>, standard: record<value: int>, super_reduced: record<applies_to: string, value: int>>, status: int, vat_applies: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"address": $address} | compact), body: null}
}

# Check api requests remaining on current subscription plan
#
# GET /usage-check
# operationId: api_usage
export def "usage-check get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<requests_remaining: int, requests_used: int, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage-check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Validate a VAT number
#
# GET /vat-number-check
# operationId: vat_number_validate
export def "vat-number-check validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vatid: string # The VAT number to validate
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vatid" $vatid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vat-number-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"vatid": $vatid} | compact), body: null}
}

# Convert a price to or from VAT price.
#
# GET /vat-price
# operationId: convert_price
export def "vat-price get-convert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # The 2 digit country code
  --country-rate: string # The VAT rate to get the price for. Default: standard
  --price: int # The price you want converting
  --type: string # Optional, if the price is including VAT set the type to 'incl'. Otherwise the default is assumed as excluding VAT already, 'excl'
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country_code: string, country_rate: string, price_excl_vat: int, price_incl_vat: int, rate: int, status: int, vat: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "country_rate" $country_rate "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vat-price" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"code": $code, "country_rate": $country_rate, "price": $price, "type": $type} | compact), body: null}
}

# Retrieve all current EU VAT rates
#
# GET /vat-rates
# operationId: vat_rates
export def "vat-rates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<countries: table<country_code: record>, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vat-rates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Response-Type": $response_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
