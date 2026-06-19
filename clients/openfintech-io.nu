# Auto-generated client for OpenFinTech.io v2017-08-24
# Source: https://api.apis.guru/v2/specs/openfintech.io/2017-08-24/swagger.json
# Auth: --token flag or $env.OPENFINTECH_IO_TOKEN

const BASE_URL = "https://api.openfintech.io/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENFINTECH_IO_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.openfintech.io/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "banks list" } } | get name | first)
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

# List of banks
#
# GET /banks
export def "banks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-sort-code: string # Filtering by banks code.
  --filter-code: string # Filtering by code.
  --filter-status: list<string> # Filtration by status.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | code | -code | | status | -status | | sort_code | -sort_code |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[sort_code]" $filter_sort_code "scalar") (serialize-qp "filter[code]" $filter_code "scalar") (serialize-qp "filter[status]" $filter_status "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/banks" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[sort_code]": $filter_sort_code, "filter[code]": $filter_code, "filter[status]": $filter_status, "sort": $qp_sort} | compact), body: null}
}

# Bank by ID
#
# GET /banks/{id}
export def "banks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<account_number: string, bank_code: string, bic: string, code: string, iban: string, name: string, sort_code: string, status: string, vatin: string>, id: string, links: record<self: string>, relationships: record<organization: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/banks/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of countries
#
# GET /countries
export def "countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-region: list<string> # Filtration by region.
  --filter-sub-region: list<string> # Filtration by sub region.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | area | -area | | population | -population | | region | -region | | sub_region | -sub_region |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[region]" $filter_region "csv") (serialize-qp "filter[sub_region]" $filter_sub_region "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/countries" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[region]": $filter_region, "filter[sub_region]": $filter_sub_region, "sort": $qp_sort} | compact), body: null}
}

# Country by ID
#
# GET /countries/{id}
export def "countries get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<area: string, calling_codes: list, capital: string, code_alpha3: string, languages: list, name: string, native_name: string, population: string, region: string, sub_region: string, timezones: list, top_level_domains: list>, id: string, links: record<self: string>, relationships: record<translations: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/countries/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of currencies
#
# GET /currencies
export def "currencies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-search: string # Full text search with name, code, type, code_iso_alpha3, code_jsons_alpha, code_estandards_alpha, category.
  --filter-code-iso-alpha3: string # Filtering by ISO code.
  --filter-code-iso-numeric3: int # Filtering by ISO number.
  --filter-code-estandards-alpha: string # Filtering by estandards code.
  --filter-currency-type: list<string> # Filtration by currency type.
  --filter-category: list<string> # Filtration by category.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | type | -type | | category | -category | | code | -code | | code_iso_alpha3 | -code_iso_alpha3 | | code_iso_numeric3 | -code_iso_numeric3 | | code_estandards_alpha | -code_estandards_alpha |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[search]" $filter_search "scalar") (serialize-qp "filter[code_iso_alpha3]" $filter_code_iso_alpha3 "scalar") (serialize-qp "filter[code_iso_numeric3]" $filter_code_iso_numeric3 "scalar") (serialize-qp "filter[code_estandards_alpha]" $filter_code_estandards_alpha "scalar") (serialize-qp "filter[currency_type]" $filter_currency_type "csv") (serialize-qp "filter[category]" $filter_category "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/currencies" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[search]": $filter_search, "filter[code_iso_alpha3]": $filter_code_iso_alpha3, "filter[code_iso_numeric3]": $filter_code_iso_numeric3, "filter[code_estandards_alpha]": $filter_code_estandards_alpha, "filter[currency_type]": $filter_currency_type, "filter[category]": $filter_category, "sort": $qp_sort} | compact), body: null}
}

# Currency by ID
#
# GET /currencies/{id}
export def "currencies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<category: string, code: string, code_estandards_alpha: string, code_iso_alpha3: string, code_iso_numeric3: int, code_json_alpha: string, created: string, currency_type: string, decimal_e: string, icon: record, issuer: string, name: string, native_symbol: string, symbol: string>, id: string, links: record<self: string>, relationships: record<countries: record, issuer: record, issuer_organization: record, parent: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/currencies/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of deposit methods
#
# GET /deposit-methods
export def "deposit-methods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-search: string # Full text search with id, name, code, category.
  --filter-name: string # Filtering by name.
  --filter-code: string # Filtering by code.
  --filter-processor-name: string # Filtering by processor_name.
  --filter-category: list<string> # Filtering by category.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | code | -code | | processor_name | -processor_name | | category | -category |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[search]" $filter_search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[code]" $filter_code "scalar") (serialize-qp "filter[processor_name]" $filter_processor_name "scalar") (serialize-qp "filter[category]" $filter_category "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/deposit-methods" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[search]": $filter_search, "filter[name]": $filter_name, "filter[code]": $filter_code, "filter[processor_name]": $filter_processor_name, "filter[category]": $filter_category, "sort": $qp_sort} | compact), body: null}
}

# Deposit method by ID
#
# GET /deposit-methods/{id}
export def "deposit-methods get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<category: string, code: string, name: string, processor_name: string>, id: string, links: record<self: string>, relationships: record<actiove_in_countries: record, currencies: record, payment_processor: record, supported_psps: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/deposit-methods/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of exchangers
#
# GET /exchangers
export def "exchangers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-name: string # Filtering by name.
  --filter-status: list<string> # Filtration by status.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | status | -status | | wmid | -wmid | | rate_type | -rate_type | | rates_export_standard | -rates_export_standard |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[status]" $filter_status "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/exchangers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name]": $filter_name, "filter[status]": $filter_status, "sort": $qp_sort} | compact), body: null}
}

# Exchanger by ID
#
# GET /exchangers/{id}
export def "exchangers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<name: string, rates_export_standard: string, rates_export_url: string, status: string, wmid: int>, id: string, links: record<self: string>, relationships: record<organization: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/exchangers/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of merchant industries
#
# GET /merchant-industries
export def "merchant-industries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-name: string # Filtering by name.
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name]" $filter_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/merchant-industries" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name]": $filter_name} | compact), body: null}
}

# Merchant industry by ID
#
# GET /merchant-industries/{id}
export def "merchant-industries get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<name: string>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/merchant-industries/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of organizations
#
# GET /organizations
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-search: string # Full text search with id, name, code.
  --filter-name: string # Filtering by name.
  --filter-code: string # Filtering by code.
  --filter-status: list<string> # Filtration by status.
  --filter-industries: string # Filtering by industries.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | code | -code | | status | -status | | description | -description |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[search]" $filter_search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[code]" $filter_code "scalar") (serialize-qp "filter[status]" $filter_status "csv") (serialize-qp "filter[industries]" $filter_industries "scalar") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[search]": $filter_search, "filter[name]": $filter_name, "filter[code]": $filter_code, "filter[status]": $filter_status, "filter[industries]": $filter_industries, "sort": $qp_sort} | compact), body: null}
}

# Organization by ID
#
# GET /organizations/{id}
export def "organizations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<address: record, blog: string, code: string, contacts: record, description: string, icon: record, industries: list, logo: record, name: string, site: string, social_profiles: record, status: string, wiki: string>, id: string, links: record<self: string>, relationships: record<active_in_countries: record, hq_in_country: record, source_register_org: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/organizations/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of payment methods
#
# GET /payment-methods
export def "payment-methods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-search: string # Full text search with id, name, code, category.
  --filter-name: string # Filtering by name.
  --filter-code: string # Filtering by code.
  --filter-processor-name: string # Filtering by processor_name.
  --filter-category: list<string> # Filtering by category.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | code | -code | | processor_name | -processor_name | | category | -category |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[search]" $filter_search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[code]" $filter_code "scalar") (serialize-qp "filter[processor_name]" $filter_processor_name "scalar") (serialize-qp "filter[category]" $filter_category "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/payment-methods" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[search]": $filter_search, "filter[name]": $filter_name, "filter[code]": $filter_code, "filter[processor_name]": $filter_processor_name, "filter[category]": $filter_category, "sort": $qp_sort} | compact), body: null}
}

# Payment method by ID
#
# GET /payment-methods/{id}
export def "payment-methods get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<category: string, code: string, name: string, processor_name: string>, id: string, links: record<self: string>, relationships: record<currencies: record, payment_processor: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-methods/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of payment providers
#
# GET /payment-providers
export def "payment-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Current page number.
  --page-size: int # Page size.*Default value: 100*
  --filter-search: string # Full text search with id, code, name.
  --filter-name: string # Filtering by name.
  --filter-code: string # Filtering by code.
  --filter-types: list<string> # Filtering by types.
  --filter-sales-channels: list<string> # Filtering by sales channels.
  --filter-features: list<string> # Filtering by features.
  --qp-sort: list<string> # Sort params: | ASC | DESC | |-----|------| | name | -name | | code | -code |
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, last: string, next: string, prev: string>, meta: record<pages: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[search]" $filter_search "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[code]" $filter_code "scalar") (serialize-qp "filter[types]" $filter_types "csv") (serialize-qp "filter[sales_channels]" $filter_sales_channels "csv") (serialize-qp "filter[features]" $filter_features "csv") (serialize-qp "sort" $qp_sort "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/payment-providers" $qp)
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[search]": $filter_search, "filter[name]": $filter_name, "filter[code]": $filter_code, "filter[types]": $filter_types, "filter[sales_channels]": $filter_sales_channels, "filter[features]": $filter_features, "sort": $qp_sort} | compact), body: null}
}

# Payment provider by ID
#
# GET /payment-providers/{id}
export def "payment-providers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attributes: record<code: string, features: list, name: string, sales_channels: list, types: list>, id: string, links: record<self: string>, relationships: record<organization: record, payment_methods: record>, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/payment-providers/{id}"))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
