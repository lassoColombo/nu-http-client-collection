# Auto-generated client for Taxamo v1
# Source: https://api.apis.guru/v2/specs/taxamo.com/1/swagger.json
# Auth: --token flag or $env.TAXAMO_TOKEN

const BASE_URL = "https://api.taxamo.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TAXAMO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "token" => { {scheme: $scheme, headers: {Token: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.taxamo.com"] }
def auth-scheme-completer [] { ["token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dictionaries-countries get-dict" } } | get name | first)
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

# Countries
#
# GET /api/v1/dictionaries/countries
# operationId: getCountriesDict
export def "dictionaries-countries get-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tax-supported: oneof<nothing, bool> # Should only countries with tax supported be listed?
]: nothing -> record<dictionary: table<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tax_supported" $tax_supported "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/dictionaries/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tax_supported": $tax_supported} | compact), body: null}
}

# Currencies
#
# GET /api/v1/dictionaries/currencies
# operationId: getCurrenciesDict
export def "dictionaries-currencies get-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dictionary: table<code: string, description: string, isocode: string, isonum: int, minorunits: int>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dictionaries/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Product types
#
# GET /api/v1/dictionaries/product_types
# operationId: getProductTypesDict
export def "dictionaries-product-types get-dict" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dictionary: table<code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dictionaries/product_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Locate IP
#
# GET /api/v1/geoip
# operationId: locateMyIP
export def "geoip get-locate-my-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/geoip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Locate provided IP
#
# GET /api/v1/geoip/{ip}
# operationId: locateGivenIP
export def "geoip get-locate-given" [
  ip: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country: record<callingCode: list<string>, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list<string>, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, country_code: string, remote_addr: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($ip | is-empty) { error make --unspanned { msg: "path parameter 'ip' must be non-empty" } }
  let full_url = (build-url $base ({ip: (encode-path-segment $ip)} | format pattern "/api/v1/geoip/{ip}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Calculate domestic summary
#
# GET /api/v1/reports/domestic/summary
# operationId: getDomesticSummaryReport
export def "reports-domestic-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'xml' and 'csv' values are accepted. Default format - json
  --country-code: string # ISO 2-letter country code which will be used for determining which country is domestic.
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. Defaults to the one assigned to MOSS calculations for a given country code.
  --start-month: string # Period start month in yyyy-MM format.
  --end-month: string # Period end month in yyyy-MM format.
  --fx-date-type: string # Which date should be used for FX.
]: nothing -> record<currency_code: string, domestic_refunds_amount: float, domestic_refunds_tax_amount: float, domestic_sales_amount: float, domestic_tax_amount: float, end_date: string, eu_tax_deducted_refunds: float, eu_tax_deducted_sales: float, global_refunds_amount: float, global_refunds_tax_amount: float, global_sales_amount: float, global_sales_tax_amount: float, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "country_code" $country_code "scalar") (serialize-qp "currency_code" $currency_code "scalar") (serialize-qp "start_month" $start_month "scalar") (serialize-qp "end_month" $end_month "scalar") (serialize-qp "fx_date_type" $fx_date_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/reports/domestic/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "country_code": $country_code, "currency_code": $currency_code, "start_month": $start_month, "end_month": $end_month, "fx_date_type": $fx_date_type} | compact), body: null}
}

# Calculate EU VIES report
#
# GET /api/v1/reports/eu/vies
# operationId: getEuViesReport
export def "reports-eu-vies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-length: string # Length of report period. 'month', 'quarter' and 'year' values are accepted. Required only if Large Filer Format is requested.
  --lff-sequence-number: string # Sequence number used to generate report in Large Filer Format. If not specified then '0000000001' will be used.
  --transformation: string # Which transformation should be applied. Please note that transformation will be applied only for xml and csv formats.
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. Defaults to the one assigned to MOSS calculations for a given country code.
  --end-month: string # Period end month in yyyy-MM format.
  --tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used.
  --start-month: string # Period start month in yyyy-MM format.
  --eu-country-code: string # ISO 2-letter country code which will be used for determining which country is domestic.
  --fx-date-type: string # Which date should be used for FX.
  --format: string # Output format. 'xml', 'csv' and 'lff' (only for Ireland) values are accepted as well
]: nothing -> record<currency_code: string, end_date: string, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period_length" $period_length "scalar") (serialize-qp "lff_sequence_number" $lff_sequence_number "scalar") (serialize-qp "transformation" $transformation "scalar") (serialize-qp "currency_code" $currency_code "scalar") (serialize-qp "end_month" $end_month "scalar") (serialize-qp "tax_id" $tax_id "scalar") (serialize-qp "start_month" $start_month "scalar") (serialize-qp "eu_country_code" $eu_country_code "scalar") (serialize-qp "fx_date_type" $fx_date_type "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/reports/eu/vies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"period_length": $period_length, "lff_sequence_number": $lff_sequence_number, "transformation": $transformation, "currency_code": $currency_code, "end_month": $end_month, "tax_id": $tax_id, "start_month": $start_month, "eu_country_code": $eu_country_code, "fx_date_type": $fx_date_type, "format": $format} | compact), body: null}
}

# Detailed refunds
#
# GET /api/v1/settlement/detailed_refunds
# operationId: getDetailedRefunds
export def "settlement-detailed-refunds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'json' or 'csv'. Default value is 'json'
  --country-codes: string # Comma separated list of 2-letter country codes
  --date-from: string # Take only refunds issued at or after the date. Format: yyyy-MM-dd
  --date-to: string # Take only refunds issued at or before the date. Format: yyyy-MM-dd
  --limit: float # Limit (no more than 1000, defaults to 100).
  --offset: float # Offset. Defaults to 0
]: nothing -> record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "country_codes" $country_codes "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/settlement/detailed_refunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "country_codes": $country_codes, "date_from": $date_from, "date_to": $date_to, "limit": $limit, "offset": $offset} | compact), body: null}
}

# Fetch refunds
#
# GET /api/v1/settlement/refunds
# operationId: getRefunds
export def "settlement-refunds get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Output format. 'csv' value is accepted as well
  --moss-country-code: string # MOSS country code, used to determine currency. If ommited, merchant default setting is used.
  --tax-region: string # Tax region key, defaults to EU for backwards compatibility.
  --date-from: string # Take only refunds issued at or after the date. Format: yyyy-MM-dd
]: nothing -> record<report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "moss_country_code" $moss_country_code "scalar") (serialize-qp "tax_region" $tax_region "scalar") (serialize-qp "date_from" $date_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/settlement/refunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "moss_country_code": $moss_country_code, "tax_region": $tax_region, "date_from": $date_from} | compact), body: null}
}

# Fetch summary
#
# GET /api/v1/settlement/summary/{quarter}
# operationId: getSettlementSummary
export def "settlement-summary get" [
  quarter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moss-country-code: string # MOSS country code, used to determine currency. If ommited, merchant default setting is used.
  --tax-region: string # Tax region key
  --start-month: string # Period start month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --end-month: string # Period end month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
]: nothing -> record<summary: record<currency_code: string, end_date: string, fx_rate_date: string, indicative: bool, quarter: string, start_date: string, tax_amount: float, tax_entity_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($quarter | is-empty) { error make --unspanned { msg: "path parameter 'quarter' must be non-empty" } }
  let qp = [(serialize-qp "moss_country_code" $moss_country_code "scalar") (serialize-qp "tax_region" $tax_region "scalar") (serialize-qp "start_month" $start_month "scalar") (serialize-qp "end_month" $end_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quarter: (encode-path-segment $quarter)} | format pattern "/api/v1/settlement/summary/{quarter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"moss_country_code": $moss_country_code, "tax_region": $tax_region, "start_month": $start_month, "end_month": $end_month} | compact), body: null}
}

# Fetch settlement
#
# GET /api/v1/settlement/{quarter}
# operationId: getSettlement
export def "settlement get" [
  quarter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moss-tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used. Deprecated, please use tax-id.
  --currency-code: string # ISO 3-letter currency code, e.g. EUR or USD. If provided, all amounts will be coerced for this currency. Defaults to region's currency code.
  --end-month: string # Period end month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --tax-id: string # MOSS-assigned tax ID - if not provided, merchant's national tax number will be used. Deprecated, please use tax-id.
  --refund-date-kind-override: string # Set to 'order_date' to show only refunds for the transactions in the selected reporting period. Set to 'refund_timestamp' to show refunds that were created in the selected reporting period. Do not set to use the default region's setting.
  --start-month: string # Period start month in yyyy-MM format. Either quarter or start-month and end-month have to be provided.
  --moss-country-code: string # MOSS country code, used to determine currency/region. If ommited, merchant default setting is used. Deprecated: please use tax-country-code.
  --format: string # Output format. 'csv' value is accepted as well
  --tax-country-code: string # Tax entity country code, used to determine currency/region.
]: nothing -> record<end_date: string, fx_rate_date: string, indicative: bool, report: table<amount: float, country_code: string, country_name: string, country_subdivision: string, currency_code: string, skip_moss: bool, tax_amount: float, tax_rate: float, tax_region: string>, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($quarter | is-empty) { error make --unspanned { msg: "path parameter 'quarter' must be non-empty" } }
  let qp = [(serialize-qp "moss_tax_id" $moss_tax_id "scalar") (serialize-qp "currency_code" $currency_code "scalar") (serialize-qp "end_month" $end_month "scalar") (serialize-qp "tax_id" $tax_id "scalar") (serialize-qp "refund_date_kind_override" $refund_date_kind_override "scalar") (serialize-qp "start_month" $start_month "scalar") (serialize-qp "moss_country_code" $moss_country_code "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "tax_country_code" $tax_country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quarter: (encode-path-segment $quarter)} | format pattern "/api/v1/settlement/{quarter}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"moss_tax_id": $moss_tax_id, "currency_code": $currency_code, "end_month": $end_month, "tax_id": $tax_id, "refund_date_kind_override": $refund_date_kind_override, "start_month": $start_month, "moss_country_code": $moss_country_code, "format": $format, "tax_country_code": $tax_country_code} | compact), body: null}
}

# Settlement by country
#
# GET /api/v1/stats/settlement/by_country
# operationId: getSettlementStatsByCountry
export def "stats-settlement-by-country get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format.
  --date-to: string # Date to in yyyy-MM format.
]: nothing -> record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stats/settlement/by_country" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Settlement by tax type
#
# GET /api/v1/stats/settlement/by_taxation_type
# operationId: getSettlementStatsByTaxationType
export def "stats-settlement-by-taxation-type get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format.
  --date-to: string # Date to in yyyy-MM format.
]: nothing -> record<by_taxation_type: record<deducted_count: float, eu_b2b: int, eu_taxed: int, taxed_count: float, transactions_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stats/settlement/by_taxation_type" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Settlement stats over time
#
# GET /api/v1/stats/settlement/daily
# operationId: getDailySettlementStats
export def "stats-settlement-daily get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: string # Interval type - day, week, month.
  --date-from: string # Date from in yyyy-MM format.
  --date-to: string # Date to in yyyy-MM format.
]: nothing -> record<settlement_daily: table<b2b: int, b2c: int, count: int, day: string, day_raw: string, eu_b2b: int, eu_taxed: int, eu_total: int, untaxed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "interval" $interval "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stats/settlement/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"interval": $interval, "date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Transaction stats
#
# GET /api/v1/stats/transactions
# operationId: getTransactionsStats
export def "stats-transactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Date from in yyyy-MM format.
  --date-to: string # Date to in yyyy-MM format.
  --interval: string # Interval. Accepted values are 'day', 'week' and 'month'.
]: nothing -> record<by_status: record<C: list<record>, N: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar") (serialize-qp "interval" $interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stats/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"date_from": $date_from, "date_to": $date_to, "interval": $interval} | compact), body: null}
}

# Settlement by country
#
# GET /api/v1/stats/transactions/by_country
# operationId: getTransactionsStatsByCountry
export def "stats-transactions-by-country get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-currency-code: string # Global currency code to use for conversion - in addition to country's currency if rate is available. Conversion is indicative and based on most-recent rate from ECB.
  --date-from: string # Date from in yyyy-MM format.
  --date-to: string # Date to in yyyy-MM format.
]: nothing -> record<by_country: table<currency_code: string, tax_country_code: string, tax_country_name: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global_currency_code" $global_currency_code "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "date_to" $date_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/stats/transactions/by_country" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"global_currency_code": $global_currency_code, "date_from": $date_from, "date_to": $date_to} | compact), body: null}
}

# Simple tax
#
# GET /api/v1/tax/calculate
# operationId: calculateSimpleTax
export def "tax-calculate get-simple" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --product-type: string # Product type, according to dictionary /dictionaries/product_types.
  --invoice-address-city: string # Invoice address/postal_code
  --buyer-credit-card-prefix: string # First 6 digits of buyer's credit card prefix.
  --currency-code: string # Currency code for transaction - e.g. EUR.
  --invoice-address-region: string # Invoice address/region
  --unit-price: float # Unit price.
  --quantity: float # Quantity Defaults to 1.
  --buyer-tax-number: string # Buyer's tax number - EU VAT number for example. If using EU VAT number, it is possible to provide country code in it (e.g. IE1234567X) or simply use billing_country_code field for that. In the first case, if billing_country_code value was provided, it will be overwritten with country code value extracted from VAT number - but only if the VAT has been verified properly.
  --force-country-code: string # Two-letter ISO country code, e.g. FR. Use it to force country code for tax calculation.
  --order-date: string # Order date in yyyy-MM-dd format, in merchant's timezone. If provided by the API caller, no timezone conversion is performed. Default value is current date and time. When using public token, the default value is used.
  --amount: float # Amount. Required if total amount or both unit price and quantity are not provided.
  --billing-country-code: string # Billing two letter ISO country code.
  --invoice-address-postal-code: string # Invoice address/postal_code
  --total-amount: float # Total amount. Required if amount or both unit price and quantity are not provided.
  --tax-deducted: oneof<nothing, bool> # If the transaction is in a country supported by Taxamo, but the tax is not calculated due to merchant settings or EU B2B transaction for example.
]: nothing -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "product_type" $product_type "scalar") (serialize-qp "invoice_address_city" $invoice_address_city "scalar") (serialize-qp "buyer_credit_card_prefix" $buyer_credit_card_prefix "scalar") (serialize-qp "currency_code" $currency_code "scalar") (serialize-qp "invoice_address_region" $invoice_address_region "scalar") (serialize-qp "unit_price" $unit_price "scalar") (serialize-qp "quantity" $quantity "scalar") (serialize-qp "buyer_tax_number" $buyer_tax_number "scalar") (serialize-qp "force_country_code" $force_country_code "scalar") (serialize-qp "order_date" $order_date "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "billing_country_code" $billing_country_code "scalar") (serialize-qp "invoice_address_postal_code" $invoice_address_postal_code "scalar") (serialize-qp "total_amount" $total_amount "scalar") (serialize-qp "tax_deducted" $tax_deducted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tax/calculate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"product_type": $product_type, "invoice_address_city": $invoice_address_city, "buyer_credit_card_prefix": $buyer_credit_card_prefix, "currency_code": $currency_code, "invoice_address_region": $invoice_address_region, "unit_price": $unit_price, "quantity": $quantity, "buyer_tax_number": $buyer_tax_number, "force_country_code": $force_country_code, "order_date": $order_date, "amount": $amount, "billing_country_code": $billing_country_code, "invoice_address_postal_code": $invoice_address_postal_code, "total_amount": $total_amount, "tax_deducted": $tax_deducted} | compact), body: null}
}

# Calculate tax
#
# POST /api/v1/tax/calculate
# operationId: calculateTax
# --transaction shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
export def "tax-calculate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/tax/calculate")
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Calculate location
#
# GET /api/v1/tax/location/calculate
# operationId: calculateTaxLocation
export def "tax-location-calculate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-country-code: string # Billing two letter ISO country code.
  --buyer-credit-card-prefix: string # First 6 digits of buyer's credit card prefix.
]: nothing -> record<billing_country_code: string, buyer_credit_card_prefix: string, buyer_ip: string, countries: record<by_2003_rules: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_billing: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_cc: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_tax_number: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, by_token: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, detected: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, forced: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, guessed_from_ip: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, other_commercially_relevant_info: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>, self_declaration: record<callingCode: list, cca2: string, cca3: string, ccn3: string, code: string, code_long: string, codenum: string, currency: list, name: string, tax_number_country_code: string, tax_region: string, tax_supported: bool>>, evidence: record<by_2003_rules: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_billing: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_cc: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_payment_method: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_tax_number: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, by_token: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, forced: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, guessed_from_ip: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, other_commercially_relevant_info: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>, self_declaration: record<evidence_type: string, evidence_value: string, resolved_country_code: string, used: bool>>, tax_country_code: string, tax_deducted: bool, tax_supported: bool> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "billing_country_code" $billing_country_code "scalar") (serialize-qp "buyer_credit_card_prefix" $buyer_credit_card_prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tax/location/calculate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"billing_country_code": $billing_country_code, "buyer_credit_card_prefix": $buyer_credit_card_prefix} | compact), body: null}
}

# Validate VAT number
#
# GET /api/v1/tax/vat_numbers/{tax_number}/validate
# operationId: validateTaxNumber
export def "tax-vat-numbers-validate validate" [
  tax_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # Two-letter ISO country code.
]: nothing -> record<billing_country_code: string, buyer_tax_number: string, buyer_tax_number_valid: bool, tax_deducted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($tax_number | is-empty) { error make --unspanned { msg: "path parameter 'tax_number' must be non-empty" } }
  let qp = [(serialize-qp "country_code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tax_number: (encode-path-segment $tax_number)} | format pattern "/api/v1/tax/vat_numbers/{tax_number}/validate") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country_code": $country_code} | compact), body: null}
}

# Browse transactions
#
# GET /api/v1/transactions
# operationId: listTransactions
export def "transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-text: string # Filtering expression
  --offset: int # Offset
  --has-note: oneof<nothing, bool> # Return only transactions with a note field set.
  --key-or-custom-id: string # Taxamo provided transaction key or custom id
  --currency-code: string # Three letter ISO currency code.
  --order-date-to: string # Order date to in yyyy-MM-dd format.
  --sort-reverse: oneof<nothing, bool> # If true, results are sorted in descending order.
  --limit: int # Limit (no more than 1000, defaults to 100).
  --invoice-number: string # Transaction invoice number.
  --tax-country-codes: string # Comma separated list of two letter ISO tax country codes.
  --statuses: string # Comma separated list of of transaction statuses. 'N' - unconfirmed transaction, 'C' - confirmed transaction.
  --original-transaction-key: string # Taxamo provided original transaction key
  --order-date-from: string # Order date from in yyyy-MM-dd format.
  --total-amount-greater-than: string # Return only transactions with total amount greater than given number. Transactions with total amount equal to a given number (e.g. 0) are not returned.
  --format: string # Output format - supports 'csv' value for this operation.
  --total-amount-less-than: string # Return only transactions with total amount less than a given number. Transactions with total amount equal to a given number (e.g. 1) are not returned.
  --tax-country-code: string # Two letter ISO tax country code.
]: nothing -> record<transactions: table<additional_currencies: record, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list, verification_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_text" $filter_text "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "has_note" $has_note "scalar") (serialize-qp "key_or_custom_id" $key_or_custom_id "scalar") (serialize-qp "currency_code" $currency_code "scalar") (serialize-qp "order_date_to" $order_date_to "scalar") (serialize-qp "sort_reverse" $sort_reverse "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "invoice_number" $invoice_number "scalar") (serialize-qp "tax_country_codes" $tax_country_codes "scalar") (serialize-qp "statuses" $statuses "scalar") (serialize-qp "original_transaction_key" $original_transaction_key "scalar") (serialize-qp "order_date_from" $order_date_from "scalar") (serialize-qp "total_amount_greater_than" $total_amount_greater_than "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "total_amount_less_than" $total_amount_less_than "scalar") (serialize-qp "tax_country_code" $tax_country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter_text": $filter_text, "offset": $offset, "has_note": $has_note, "key_or_custom_id": $key_or_custom_id, "currency_code": $currency_code, "order_date_to": $order_date_to, "sort_reverse": $sort_reverse, "limit": $limit, "invoice_number": $invoice_number, "tax_country_codes": $tax_country_codes, "statuses": $statuses, "original_transaction_key": $original_transaction_key, "order_date_from": $order_date_from, "total_amount_greater_than": $total_amount_greater_than, "format": $format, "total_amount_less_than": $total_amount_less_than, "tax_country_code": $tax_country_code} | compact), body: null}
}

# Store transaction
#
# POST /api/v1/transactions
# operationId: createTransaction
# --transaction shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
export def "transactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --manual-mode: oneof<nothing, bool> # Use manual mode, bypassing country detection. Only allowed with private token. This flag allows to use original_transaction_key field
  transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/transactions")
  let req_body = {"manual_mode": $manual_mode, "transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete transaction
#
# DELETE /api/v1/transactions/{key}
# operationId: cancelTransaction
export def "transactions cancel" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve transaction data.
#
# GET /api/v1/transactions/{key}
# operationId: getTransaction
export def "transactions get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update transaction
#
# PUT /api/v1/transactions/{key}
# operationId: updateTransaction
# --transaction shape: {additional_currencies?: record, amount?: float, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, buyer_tax_number_valid?: bool, comments?: string, confirm_timestamp?: string, countries?: record, create_timestamp?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, deducted_tax_amount?: float, description?: string, ... (33 more fields)}
export def "transactions update" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, amount?: float, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, buyer_tax_number_valid?: bool, comments?: string, confirm_timestamp?: string, countries?: record, create_timestamp?: string, currency_code: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, deducted_tax_amount?: float, description?: string, ... (33 more fields)}
]: any -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}"))
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Confirm transaction
#
# POST /api/v1/transactions/{key}/confirm
# operationId: confirmTransaction
# --transaction shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
export def "transactions-confirm confirm" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/confirm"))
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Email credit note
#
# POST /api/v1/transactions/{key}/invoice/refunds/{refund_note_number}/send_email
# operationId: emailRefund
export def "transactions-invoice-refunds-send-email create" [
  key: string
  refund_note_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buyer-email: string # Email to send the credit note/refund note. If not provided, transaction.buyer_email will be used.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  if ($refund_note_number | is-empty) { error make --unspanned { msg: "path parameter 'refund_note_number' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key), refund_note_number: (encode-path-segment $refund_note_number)} | format pattern "/api/v1/transactions/{key}/invoice/refunds/{refund_note_number}/send_email"))
  let req_body = {"buyer_email": $buyer_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Email invoice
#
# POST /api/v1/transactions/{key}/invoice/send_email
# operationId: emailInvoice
export def "transactions-invoice-send-email create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --buyer-email: string # Email to send the invoice. If not provided, transaction.buyer_email will be used.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/invoice/send_email"))
  let req_body = {"buyer_email": $buyer_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List payments
#
# GET /api/v1/transactions/{key}/payments
# operationId: listPayments
export def "transactions-payments list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Max record count (no more than 100, defaults to 10).
  --offset: string # How many records need to be skipped, defaults to 0.
]: nothing -> record<payments: table<amount: float, payment_information: string, payment_timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/payments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Register a payment
#
# POST /api/v1/transactions/{key}/payments
# operationId: createPayment
export def "transactions-payments create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Amount that has been paid. Use negative value to register refunds.
  --payment-information: string # Additional payment information.
  --payment-timestamp: string # When the payment was received in yyyy-MM-dd'T'HH:mm:ss(.SSS)'Z' format (24 hour, UTC timezone). Defaults to current date and time.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/payments"))
  let req_body = {"amount": $amount, "payment_information": $payment_information, "payment_timestamp": $payment_timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Capture payment
#
# POST /api/v1/transactions/{key}/payments/capture
# operationId: capturePayment
export def "transactions-payments-capture create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/payments/capture"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get transaction refunds
#
# GET /api/v1/transactions/{key}/refunds
# operationId: listRefunds
export def "transactions-refunds list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<refunds: table<amount: float, informative: bool, line_key: string, refund_note_number: string, refund_note_url: string, refund_reason: string, refund_timestamp: string, tax_amount: float, tax_rate: float, total_amount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/refunds"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a refund
#
# POST /api/v1/transactions/{key}/refunds
# operationId: createRefund
export def "transactions-refunds create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # Amount (without tax) to be refunded. Either amount or total amount is required. In case of line key and custom id missing, only total_amount can be used.
  --custom-id: string # Line custom identifier. If neither line key or custom id is provided, the refund amount will be assigned to lines in order.
  --line-key: string # Line identifier. If neither line key or custom id is provided, the refund amount will be assigned to lines in order.
  --refund-reason: string # Refund reason, displayed on the credit note.
  --total-amount: float # Total amount, including tax, to be refunded. Either amount or total amount is required. In case of line key and custom id missing, only total_amount can be used.
]: any -> record<refunded_tax_amount: float, refunded_total_amount: float, tax_amount: float, total_amount: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/refunds"))
  let req_body = {"amount": $amount, "custom_id": $custom_id, "line_key": $line_key, "refund_reason": $refund_reason, "total_amount": $total_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Un-confirm the transaction
#
# POST /api/v1/transactions/{key}/unconfirm
# operationId: unconfirmTransaction
# --transaction shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
export def "transactions-unconfirm create" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --transaction: record # shape: {additional_currencies?: record, billing_country_code?: string, buyer_credit_card_prefix?: string, buyer_email?: string, buyer_ip?: string, buyer_name?: string, buyer_tax_number?: string, comments?: string, currency_code?: string, custom_data?: string, custom_fields?: list, custom_id?: string, customer_id?: string, description?: string, evidence?: record, force_country_code?: string, invoice_address?: record, invoice_date?: string, invoice_number?: string, invoice_place?: string, note?: string, ... (10 more fields)}
]: any -> record<storage_required_fields: table<field_name: string>, tax_required_fields: table<field_name: string>, transaction: record<additional_currencies: record<invoice: record>, amount: float, billing_country_code: string, buyer_credit_card_prefix: string, buyer_email: string, buyer_ip: string, buyer_name: string, buyer_tax_number: string, buyer_tax_number_valid: bool, comments: string, confirm_timestamp: string, countries: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_tax_number: record, by_token: record, detected: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, create_timestamp: string, currency_code: string, custom_data: string, custom_fields: list<record>, custom_id: string, customer_id: string, deducted_tax_amount: float, description: string, evidence: record<by_2003_rules: record, by_billing: record, by_cc: record, by_ip: record, by_payment_method: record, by_tax_number: record, by_token: record, forced: record, guessed_from_ip: record, other_commercially_relevant_info: record, self_declaration: record>, external_key: string, force_country_code: string, fully_informative: bool, invoice_address: record<address_detail: string, building_number: string, city: string, country: string, freeform_address: string, postal_code: string, region: string, street_name: string>, invoice_date: string, invoice_image_url: string, invoice_number: string, invoice_place: string, key: string, kind: string, manual: bool, note: string, order_date: string, original_transaction_key: string, refunded_tax_amount: float, refunded_total_amount: float, source: string, status: string, sub_account_id: string, supply_date: string, tax_amount: float, tax_country_code: string, tax_data: record<us_tax_exemption_certificate: record>, tax_deducted: bool, tax_entity_name: string, tax_number_service: string, tax_supported: bool, tax_timezone: string, test: bool, total_amount: float, transaction_lines: list<record>, verification_token: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/api/v1/transactions/{key}/unconfirm"))
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create SMS token
#
# POST /api/v1/verification/sms
# operationId: createSMSToken
export def "verification-sms create-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country_code: string # Two letter ISO country code.
  recipient: string # Recipient phone number.
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/verification/sms")
  let req_body = {"country_code": $country_code, "recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify SMS token
#
# GET /api/v1/verification/sms/{token}
# operationId: verifySMSToken
export def "verification-sms verify" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<country_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "token"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/api/v1/verification/sms/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
