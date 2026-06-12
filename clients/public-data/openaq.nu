# Auto-generated client for OpenAQ v3.0.0
# Source: https://api.openaq.org/openapi.json
# Auth: --token flag or $env.OPENAQ_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENAQ_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "instruments get" } } | get name | first)
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

# Get an instrument by ID
#
# GET /v3/instruments/{instruments_id}
# operationId: instrument_get_v3_instruments__instruments_id__get
export def "instruments get" [
  instruments_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, isMonitor: bool, manufacturer: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/instruments/($instruments_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instruments
#
# GET /v3/instruments
# operationId: instruments_get_v3_instruments_get
export def "instruments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, isMonitor: bool, manufacturer: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/instruments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get instruments by manufacturer ID
#
# GET /v3/manufacturers/{manufacturers_id}/instruments
# operationId: get_instruments_by_manufacturer_v3_manufacturers__manufacturers_id__instruments_get
export def "manufacturers-instruments get" [
  manufacturers_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, isMonitor: bool, manufacturer: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/manufacturers/($manufacturers_id)/instruments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a location by ID
#
# GET /v3/locations/{locations_id}
# operationId: location_get_v3_locations__locations_id__get
export def "locations get" [
  locations_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: any, locality: any, timezone: string, country: record, owner: record, provider: record, isMobile: bool, isMonitor: bool, instruments: list, sensors: list, coordinates: record, licenses: any, bounds: list, distance: any, datetimeFirst: any, datetimeLast: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/locations/($locations_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get locations
#
# GET /v3/locations
# operationId: locations_get_v3_locations_get
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --coordinates: string # WGS 84 Coordinate pair in form latitude,longitude. Supports up to 4 decimal points of precision, additional decimal precision will be truncated in the query e.g. 38.9074,-77.0373
  --radius: string # Search radius from coordinates as center in meters. Maximum of 25,000 (25km) defaults to 1000 (1km) e.g. radius=1000
  --providers-id: string # Limit the results to a specific provider or multiple providers  with a single provider ID or a comma delimited list of IDs
  --parameters-id: string
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
  --owner-contacts-id: string # Limit the results to a specific owner by owner ID with a single owner ID or comma delimited list of IDs
  --manufacturers-id: string
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --licenses-id: string
  --monitor: string # Is the location considered a reference monitor?
  --mobile: string # Is the location considered a mobile location?
  --instruments-id: string
  --iso: string # Limit the results to a specific country using ISO 3166-1 alpha-2 code
  --countries-id: string # Limit the results to a specific country or countries by country ID as a single country ID or a comma delimited list of IDs
  --bbox: string # geospatial bounding box of Min X, min Y, max X, max Y in WGS 84 coordinates. Up to 4 decimal points of precision, addtional decimal precision will be truncated to 4 decimal points precision e.g. -77.037,38.907,-77.0,39.910
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: any, locality: any, timezone: string, country: record, owner: record, provider: record, isMobile: bool, isMonitor: bool, instruments: list, sensors: list, coordinates: record, licenses: any, bounds: list, distance: any, datetimeFirst: any, datetimeLast: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "providers_id" $providers_id "scalar") (serialize-qp "parameters_id" $parameters_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "owner_contacts_id" $owner_contacts_id "scalar") (serialize-qp "manufacturers_id" $manufacturers_id "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "licenses_id" $licenses_id "scalar") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "mobile" $mobile "scalar") (serialize-qp "instruments_id" $instruments_id "scalar") (serialize-qp "iso" $iso "scalar") (serialize-qp "countries_id" $countries_id "scalar") (serialize-qp "bbox" $bbox "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/locations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a license by ID
#
# GET /v3/licenses/{licenses_id}
# operationId: license_get_v3_licenses__licenses_id__get
export def "licenses get" [
  licenses_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, commercialUseAllowed: bool, attributionRequired: bool, shareAlikeRequired: bool, modificationAllowed: bool, redistributionAllowed: bool, sourceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/licenses/($licenses_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get licenses
#
# GET /v3/licenses
# operationId: instruments_get_v3_licenses_get
export def "licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, commercialUseAllowed: bool, attributionRequired: bool, shareAlikeRequired: bool, modificationAllowed: bool, redistributionAllowed: bool, sourceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a parameter by ID
#
# GET /v3/parameters/{parameters_id}
# operationId: parameter_get_v3_parameters__parameters_id__get
export def "parameters get" [
  parameters_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, units: string, displayName: any, description: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/parameters/($parameters_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a parameters
#
# GET /v3/parameters
# operationId: parameters_get_v3_parameters_get
export def "parameters list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --parameter-type: string # Limit the results to a specific parameters type
  --coordinates: string # WGS 84 Coordinate pair in form latitude,longitude. Supports up to 4 decimal points of precision, additional decimal precision will be truncated in the query e.g. 38.9074,-77.0373
  --radius: string # Search radius from coordinates as center in meters. Maximum of 25,000 (25km) defaults to 1000 (1km) e.g. radius=1000
  --bbox: string # geospatial bounding box of Min X, min Y, max X, max Y in WGS 84 coordinates. Up to 4 decimal points of precision, addtional decimal precision will be truncated to 4 decimal points precision e.g. -77.037,38.907,-77.0,39.910
  --iso: string # Limit the results to a specific country using ISO 3166-1 alpha-2 code
  --countries-id: string # Limit the results to a specific country or countries by country ID as a single country ID or a comma delimited list of IDs
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, units: string, displayName: any, description: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "parameter_type" $parameter_type "scalar") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "iso" $iso "scalar") (serialize-qp "countries_id" $countries_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/parameters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a country by ID
#
# GET /v3/countries/{countries_id}
# operationId: country_get_v3_countries__countries_id__get
export def "countries get" [
  countries_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, code: string, name: string, datetimeFirst: any, datetimeLast: any, parameters: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/countries/($countries_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get countries
#
# GET /v3/countries
# operationId: countries_get_v3_countries_get
export def "countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --providers-id: string # Limit the results to a specific provider or multiple providers  with a single provider ID or a comma delimited list of IDs
  --parameters-id: string
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, code: string, name: string, datetimeFirst: any, datetimeLast: any, parameters: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "providers_id" $providers_id "scalar") (serialize-qp "parameters_id" $parameters_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a manufacturer by ID
#
# GET /v3/manufacturers/{manufacturers_id}
# operationId: manufacturer_get_v3_manufacturers__manufacturers_id__get
export def "manufacturers get" [
  manufacturers_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, instruments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/manufacturers/($manufacturers_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get manufacturers
#
# GET /v3/manufacturers
# operationId: manufacturers_get_v3_manufacturers_get
export def "manufacturers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, instruments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/manufacturers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements by sensor ID
#
# GET /v3/sensors/{sensors_id}/measurements
# operationId: sensor_measurements_get_v3_sensors__sensors_id__measurements_get
export def "sensors-measurements get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/measurements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated to hours by sensor ID
#
# GET /v3/sensors/{sensors_id}/measurements/hourly
# operationId: sensor_measurements_aggregated_get_hourly_v3_sensors__sensors_id__measurements_hourly_get
export def "sensors-measurements-hourly get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/measurements/hourly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated to days by sensor ID
#
# GET /v3/sensors/{sensors_id}/measurements/daily
# operationId: sensor_measurements_aggregated_get_daily_v3_sensors__sensors_id__measurements_daily_get
export def "sensors-measurements-daily get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/measurements/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get precomputed hourly measurements by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours
# operationId: sensor_hourly_measurements_get_v3_sensors__sensors_id__hours_get
export def "sensors-hours get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to day by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/daily
# operationId: sensor_hourly_measurements_aggregate_to_day_get_v3_sensors__sensors_id__hours_daily_get
export def "sensors-hours-daily get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/daily" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to month by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/monthly
# operationId: sensor_hourly_measurements_aggregate_to_month_get_v3_sensors__sensors_id__hours_monthly_get
export def "sensors-hours-monthly get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to year by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/yearly
# operationId: sensor_hourly_measurements_aggregate_to_year_get_v3_sensors__sensors_id__hours_yearly_get
export def "sensors-hours-yearly get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/yearly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to hour of day by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/hourofday
# operationId: sensor_hourly_measurements_aggregate_to_hod_get_v3_sensors__sensors_id__hours_hourofday_get
export def "sensors-hours-hourofday get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/hourofday" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to day of week by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/dayofweek
# operationId: sensor_hourly_measurements_aggregate_to_dow_get_v3_sensors__sensors_id__hours_dayofweek_get
export def "sensors-hours-dayofweek get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/dayofweek" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from hour to month of year by sensor ID
#
# GET /v3/sensors/{sensors_id}/hours/monthofyear
# operationId: sensor_hourly_measurements_aggregate_to_moy_get_v3_sensors__sensors_id__hours_monthofyear_get
export def "sensors-hours-monthofyear get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datetime-to: string # To when?
  --datetime-from: string # From when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datetime_to" $datetime_to "scalar") (serialize-qp "datetime_from" $datetime_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/hours/monthofyear" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from day to day of week by sensor ID
#
# GET /v3/sensors/{sensors_id}/days/dayofweek
# operationId: sensor_daily_measurements_aggregate_to_dow_get_v3_sensors__sensors_id__days_dayofweek_get
export def "sensors-days-dayofweek get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/days/dayofweek" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from day to month of year by sensor ID
#
# GET /v3/sensors/{sensors_id}/days/monthofyear
# operationId: sensor_daily_measurements_aggregate_to_moy_get_v3_sensors__sensors_id__days_monthofyear_get
export def "sensors-days-monthofyear get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/days/monthofyear" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated to day by sensor ID
#
# GET /v3/sensors/{sensors_id}/days
# operationId: sensor_daily_get_v3_sensors__sensors_id__days_get
export def "sensors-days get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/days" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from day to month by sensor ID
#
# GET /v3/sensors/{sensors_id}/days/monthly
# operationId: sensor_daily_aggregate_to_month_get_v3_sensors__sensors_id__days_monthly_get
export def "sensors-days-monthly get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/days/monthly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated from day to year by sensor ID
#
# GET /v3/sensors/{sensors_id}/days/yearly
# operationId: sensor_daily_aggregate_to_year_get_v3_sensors__sensors_id__days_yearly_get
export def "sensors-days-yearly get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/days/yearly" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get measurements aggregated to year by sensor ID
#
# GET /v3/sensors/{sensors_id}/years
# operationId: sensor_yearly_get_v3_sensors__sensors_id__years_get
export def "sensors-years get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-to: string # To when?
  --date-from: string # From when?
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<value: any, flagInfo: record, parameter: record, period: any, coordinates: any, summary: any, coverage: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date_to" $date_to "scalar") (serialize-qp "date_from" $date_from "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)/years" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a owner by ID
#
# GET /v3/owners/{owners_id}
# operationId: owner_get_v3_owners__owners_id__get
export def "owners get" [
  owners_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/owners/($owners_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get owners
#
# GET /v3/owners
# operationId: owners_get_v3_owners_get
export def "owners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/owners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a provider by ID
#
# GET /v3/providers/{providers_id}
# operationId: provider_get_v3_providers__providers_id__get
export def "providers get" [
  providers_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, sourceName: string, exportPrefix: string, datetimeAdded: string, datetimeFirst: string, datetimeLast: string, entitiesId: int, parameters: list, bbox: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/providers/($providers_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get providers
#
# GET /v3/providers
# operationId: providers_get_v3_providers_get
export def "providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # The field by which to order results (default: id)
  --sort-order: string # Sort results ascending or descending. Default ASC (default: asc)
  --parameters-id: string
  --monitor: string # Is the location considered a reference monitor?
  --iso: string # Limit the results to a specific country using ISO 3166-1 alpha-2 code
  --countries-id: string # Limit the results to a specific country or countries by country ID as a single country ID or a comma delimited list of IDs
  --bbox: string # geospatial bounding box of Min X, min Y, max X, max Y in WGS 84 coordinates. Up to 4 decimal points of precision, addtional decimal precision will be truncated to 4 decimal points precision e.g. -77.037,38.907,-77.0,39.910
  --coordinates: string # WGS 84 Coordinate pair in form latitude,longitude. Supports up to 4 decimal points of precision, additional decimal precision will be truncated in the query e.g. 38.9074,-77.0373
  --radius: string # Search radius from coordinates as center in meters. Maximum of 25,000 (25km) defaults to 1000 (1km) e.g. radius=1000
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, sourceName: string, exportPrefix: string, datetimeAdded: string, datetimeFirst: string, datetimeLast: string, entitiesId: int, parameters: list, bbox: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "parameters_id" $parameters_id "scalar") (serialize-qp "monitor" $monitor "scalar") (serialize-qp "iso" $iso "scalar") (serialize-qp "countries_id" $countries_id "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "coordinates" $coordinates "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sensors by location ID
#
# GET /v3/locations/{locations_id}/sensors
# operationId: sensors_get_v3_locations__locations_id__sensors_get
export def "locations-sensors get" [
  locations_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, parameter: record, datetimeFirst: any, datetimeLast: any, coverage: any, latest: any, summary: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/locations/($locations_id)/sensors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a sensor by ID
#
# GET /v3/sensors/{sensors_id}
# operationId: sensor_get_v3_sensors__sensors_id__get
export def "sensors get" [
  sensors_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<id: int, name: string, parameter: record, datetimeFirst: any, datetimeLast: any, coverage: any, latest: any, summary: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sensors/($sensors_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get latest measurements by parameters ID
#
# GET /v3/parameters/{parameters_id}/latest
# operationId: parameters_latest_get_v3_parameters__parameters_id__latest_get
export def "parameters-latest get" [
  parameters_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
  --datetime-min: string # Minimum datetime
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<datetime: record, value: float, coordinates: record, sensorsId: int, locationsId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "datetime_min" $datetime_min "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/parameters/($parameters_id)/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a location's latest measurements
#
# GET /v3/locations/{locations_id}/latest
# operationId: location_latest_get_v3_locations__locations_id__latest_get
export def "locations-latest get" [
  locations_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
  --datetime-min: string # Minimum datetime
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<datetime: record, value: float, coordinates: record, sensorsId: int, locationsId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "datetime_min" $datetime_min "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/locations/($locations_id)/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flags by location ID
#
# GET /v3/locations/{locations_id}/flags
# operationId: location_flags_get_v3_locations__locations_id__flags_get
export def "locations-flags get" [
  locations_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
  --datetime-from: string # To when?
  --datetime-to: string # To when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<locationId: int, flagType: record, datetimeFrom: record, datetimeTo: record, sensorIds: list, note: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "datetime_to" $datetime_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/locations/($locations_id)/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flags by sensor ID
#
# GET /v3/sensors/{sensor_id}/flags
# operationId: sensor_flags_get_v3_sensors__sensor_id__flags_get
export def "sensors-flags get" [
  sensor_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Change the number of results returned.         e.g. limit=100 will return up to 100 results (default: 100)
  --page: int # Paginate through results. e.g. page=1 will return first page of results (default: 1)
  --datetime-from: string # To when?
  --datetime-to: string # To when?
]: nothing -> record<meta: record<name: string, website: string, page: int, limit: int, found: any>, results: table<locationId: int, flagType: record, datetimeFrom: record, datetimeTo: record, sensorIds: list, note: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "datetime_from" $datetime_from "scalar") (serialize-qp "datetime_to" $datetime_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/sensors/($sensor_id)/flags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
