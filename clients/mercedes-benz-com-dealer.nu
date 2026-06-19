# Auto-generated client for Dealer v1.0
# Source: https://api.apis.guru/v2/specs/mercedes-benz.com/dealer/1.0/swagger.json
# Auth: --token flag or $env.DEALER_TOKEN

const BASE_URL = "https://api.mercedes-benz.com/dealer_tryout/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEALER_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mercedes-benz.com/dealer_tryout/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def radius-unit-completer [] { ["KM" "M" "MILE"] }
def brand-completer [] { ["MB" "SMT"] }
def product-group-completer [] { ["PASSENGER-CAR" "VAN"] }
def activity-completer [] { ["PARTS" "SALES" "SERVICE" "USED-VEHICLES-TRADE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "countries get" } } | get name | first)
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

# This request returns the countries supported by the Dealer API
#
# GET /countries
# operationId: countriesGET
export def "countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The index of the page to be returned. If this parameter is omitted, the first page will be returned. (format: int32)
  --page-size: int # The index of the page to be returned. If this parameter is omitted, the first page will be returned. (format: int32)
]: nothing -> record<_links: record<next: record<href: string>, previous: record<href: string>, self: record<href: string>>, countries: table<countryId: string, isoCode: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size} | compact), body: null}
}

# This request returns dealers (dealer, garage, retailer, etc.) for given parameters
#
# GET /dealers
# operationId: dealersGET
export def "dealers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dealer-ids: list<string> # Array of dealer ids. The dealer id is dealer’s business key, also known as GS Id. e.g. GS0000857,GS0017621
  --latitude: float # The latitude geo coordinate.
  --longitude: float # The longitude geo coordinate.
  --radius-value: int # The radius value of the search area. The center of the search area is defined by geo coordinates. (latitude, longitude properties) If radiusValue and radiusUnit parameters are missing, then the default radius is 10 km. (default: 10)
  --radius-unit: string@radius-unit-completer # The radius unit of the search area. The center of the search area is defined by geo coordinates. (latitude, longitude properties) If radiusValue and radiusUnit parameters are missing, then the default radius is 10 km. (default: KM)
  --country-iso-code: string # The country of the dealer address defined as ISO two letter ID (e.g. DE, CH, CN, etc.)
  --city: string # The city of the dealer address.
  --name: string # A name of the dealer, the name filter will be applied to all Dealer names (e.g. legalName, nameAddition). You can also search for parts of Dealer names, e.g. the search term 'Niederlassung' will also match 'Niederlassung Stuttgart'.
  --brand: string@brand-completer # Filter by brand, valid values are: * MB: Mercedes-Benz * SMT: Smart
  --product-group: string@product-group-completer # Filter by a product group
  --activity: string@activity-completer # Filter by activity, valid actitvity values are: * PARTS: Spare Parts Sales * SALES: Sales of new vehicles * SERVICE: Maintaining and repair * USED-VEHICLES-TRADE: Sales of used vehicles
  --fields: string # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned. e.g. fields=dealers(dealerId,address(street,city))
  --page: int # The index of the page to be returned. If this parameter is omitted, the first page will be returned. (format: int32)
  --page-size: int # The index of the page to be returned. If this parameter is omitted, the first page will be returned. (format: int32)
]: nothing -> record<_links: record<next: record<href: string>, previous: record<href: string>, self: record<href: string>>, dealers: table<_links: record, address: record, brandCodes: list, communication: record, dealerId: string, distance: record, functions: list, geoCoordinates: record, legalName: string, nameAddition: string, openingHours: list, region: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dealerIds" $dealer_ids "csv") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radiusValue" $radius_value "scalar") (serialize-qp "radiusUnit" $radius_unit "scalar") (serialize-qp "countryIsoCode" $country_iso_code "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "brand" $brand "scalar") (serialize-qp "productGroup" $product_group "scalar") (serialize-qp "activity" $activity "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dealers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"dealerIds": $dealer_ids, "latitude": $latitude, "longitude": $longitude, "radiusValue": $radius_value, "radiusUnit": $radius_unit, "countryIsoCode": $country_iso_code, "city": $city, "name": $name, "brand": $brand, "productGroup": $product_group, "activity": $activity, "fields": $fields, "page": $page, "pageSize": $page_size} | compact), body: null}
}

# This request returns dealers for given parameters
#
# GET /dealers/{dealerId}
# operationId: dealerGET
export def "dealers get" [
  dealer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned. e.g. fields=dealerId,address(street,city)
]: nothing -> record<_links: record<self: record<href: string>>, address: record<addressAddition: string, city: string, countryIsoCode: string, district: string, street: string, zipCode: string>, brandCodes: table<brand: record>, communication: record<general: record<email: string, facebook: string, fax: string, googlePlus: string, mobile: string, phone: string, twitter: string, website: string>>, dealerId: string, distance: record<unit: string, value: float>, functions: table<activity: record, brand: record, productGroup: record>, geoCoordinates: record<latitude: float, longitude: float>, legalName: string, nameAddition: string, openingHours: table<function: record, weekdays: record>, region: record<region: string, subRegion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($dealer_id | is-empty) { error make --unspanned { msg: "path parameter 'dealerId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({dealer_id: (encode-path-segment $dealer_id)} | format pattern "/dealers/{dealer_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}
