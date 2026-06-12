# Auto-generated client for VAT API v1
# Source: https://api.apis.guru/v2/specs/vatapi.com/1/swagger.json
# Auth: --token flag or $env.VAT_API_TOKEN

const BASE_URL = "https://vatapi.com/v1"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VAT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {apikey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vatapi.com/v1"] }
def auth-scheme-completer [] { ["apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  --code: string # The 2 digit country code
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country: string, country_code: string, rates: record<parking: record<applies_to: string, value: int>, reduced: record<applies_to: string, value: int>, reduced_alt: record<applies_to: string, value: int>, standard: record<value: int>, super_reduced: record<applies_to: string, value: int>>, status: int, vat_applies: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/country-code-check" $qp)
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert a currency
#
# GET /currency-conversion
# operationId: currency_conversion
export def "currency-conversion conversion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --currency-from: string # The currency code you are converting from
  --currency-to: string # The currency code you are converting to
  --amount: int # Optional, an amount you are wanting to convert. Leave blank to just get the current rate
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<amount_from: string, amount_to: string, currency_from: string, currency_to: int, rate: string, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency_from" $currency_from "scalar") (serialize-qp "currency_to" $currency_to "scalar") (serialize-qp "amount" $amount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/currency-conversion" $qp)
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a VAT invoice
#
# POST /invoice
# operationId: create_invoice
# --items item shape: {description: string, price_each: int, quantity: int, vat_rate: int}
export def "invoice invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
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
  let body = {business_address: $business_address, business_name: $business_name, conversion_rate: $conversion_rate, currency_code: $currency_code, currency_code_conversion: $currency_code_conversion, customer_address: $customer_address, customer_name: $customer_name, customer_vat_number: $customer_vat_number, date: $date, discount_rate: $discount_rate, items: $items, notes: $notes, price_type: $price_type, tax_point: $tax_point, type: $type, vat_number: $vat_number, zero_rated: $zero_rated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoice/($id)")
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an invoice
#
# GET /invoice/{id}
# operationId: get_invoice
export def "invoice invoice-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<invoice: record<business_address: string, business_name: string, conversion_rate: int, currency_code: string, currency_code_conversion: string, customer_address: string, customer_name: string, customer_vat_number: string, date: string, discount_rate: int, discount_total: int, id: int, invoice_url: string, items: list<record>, logo_url: string, notes: string, price_type: string, subtotal: int, tax_point: string, total: int, type: string, vat_number: string, vat_total: int, zero_rated: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invoice/($id)")
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
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
  let full_url = (build-url $base $"/invoice/($id)")
  let body = {business_address: $business_address, business_name: $business_name, conversion_rate: $conversion_rate, currency_code: $currency_code, currency_code_conversion: $currency_code_conversion, customer_address: $customer_address, customer_name: $customer_name, customervat_number: $customervat_number, date: $date, discount_rate: $discount_rate, items: $items, logo_url: $logo_url, notes: $notes, tax_point: $tax_point, type: $type, vat_number: $vat_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --address: string # The IP address to search against
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country: string, country_code: string, rates: record<parking: record<applies_to: string, value: int>, reduced: record<applies_to: string, value: int>, reduced_alt: record<applies_to: string, value: int>, standard: record<value: int>, super_reduced: record<applies_to: string, value: int>>, status: int, vat_applies: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip-check" $qp)
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check api requests remaining on current subscription plan
#
# GET /usage-check
# operationId: api_usage
export def "usage-check usage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<requests_remaining: int, requests_used: int, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/usage-check")
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
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
  --vatid: string # The VAT number to validate
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "vatid" $vatid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vat-number-check" $qp)
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert a price to or from VAT price.
#
# GET /vat-price
# operationId: convert_price
export def "vat-price price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # The 2 digit country code
  --country-rate: string # The VAT rate to get the price for. Default: standard
  --price: int # The price you want converting
  --type: string # Optional, if the price is including VAT set the type to 'incl'. Otherwise the default is assumed as excluding VAT already, 'excl'
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<country_code: string, country_rate: string, price_excl_vat: int, price_incl_vat: int, rate: int, status: int, vat: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "country_rate" $country_rate "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vat-price" $qp)
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all current EU VAT rates
#
# GET /vat-rates
# operationId: vat_rates
export def "vat-rates rates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Response-Type: string # The default response type is application/json if you would like to receive an XML response then set this to XML
]: nothing -> record<countries: table<country_code: record>, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vat-rates")
  let extra_headers = {"Response-Type": $Response_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
