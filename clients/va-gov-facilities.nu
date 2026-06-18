# Auto-generated client for VA Facilities v0.0.1
# Source: https://api.apis.guru/v2/specs/va.gov/facilities/0.0.1/openapi.json
# Auth: --token flag or $env.VA_FACILITIES_TOKEN

const BASE_URL = "https://sandbox-api.va.gov/services/va_facilities/v0"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VA_FACILITIES_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox-api.va.gov/services/va_facilities/v0" "https://api.va.gov/services/va_facilities/v0"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def type-completer [] { ["benefits" "cemetery" "health" "vet_center"] }
def accept-completer [] { ["application/geo+json" "application/json" "application/vnd.geo+json"] }
def accept-completer-1 [] { ["application/geo+json" "application/vnd.geo+json" "text/csv"] }
def accept-completer-2 [] { ["application/geo+json" "application/json" "application/vnd.geo+json" "text/csv"] }
def drive-time-completer [] { ["10" "20" "30" "40" "50" "60" "70" "80" "90"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "facilities get-by-location" } } | get name | first)
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

# Query facilities by location or IDs, with optional filters
#
# GET /facilities
# operationId: getFacilitiesByLocation
export def "facilities get-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ids: list<string> # List of comma-separated facility IDs to retrieve in a single request. Can be combined with lat and long parameters to retrieve facilities sorted by distance from a location.
  --zip: string # Zip code to search for facilities. More detailed zip codes can be passed in, but only the first five digits are used to determine facilities to return. (format: ##### or #####-####)
  --state: string # State in which to search for facilities. Except in rare cases, this is two characters. (format: XX)
  --lat: float # Latitude of point to search for facilities, in WGS84 coordinate reference system. (format: float)
  --long: float # Longitude of point to search for facilities, in WGS84 coordinate reference system. (format: float)
  --bbox: list<float> # Bounding box (longitude, latitude, longitude, latitude) within which facilities will be returned. (WGS84 coordinate reference system)
  --visn: float # VISN search of matching facilities.
  --type: string@type-completer # Optional facility type search filter
  --services: list<string> # Optional facility service search filter
  --mobile: oneof<nothing, bool> # Optional facility mobile search filter
  --page: int # Page of results to return per paginated response. (format: int64, default: 1)
  --per-page: int # Number of results to return per paginated response. (format: int64, default: 10)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, links: record<first: string, last: string, next: string, prev: string, related: string, self: string>, meta: record<distances: list<record>, pagination: record<current_page: int, per_page: int, total_entries: int, total_pages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "zip" $zip "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "long" $long "scalar") (serialize-qp "bbox[]" $bbox "multi") (serialize-qp "visn" $visn "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "services[]" $services "multi") (serialize-qp "mobile" $mobile "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/facilities" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk download information for all facilities
#
# GET /facilities/all
# operationId: getAllFacilities
export def "facilities-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --hdr-accept: string@accept-completer-1 # e.g. application/geo+json
]: nothing -> record<features: table<geometry: record, properties: record, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/facilities/all")
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a specific facility by ID
#
# GET /facilities/{id}
# operationId: getFacilityById
export def "facilities get-facility" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<data: record<attributes: record<active_status: string, address: record, classification: string, detailed_services: list, facility_type: string, hours: record, lat: float, long: float, mobile: bool, name: string, operating_status: record, operational_hours_special_instructions: string, phone: record, satisfaction: record, services: record, time_zone: string, visn: string, wait_times: record, website: string>, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/facilities/{id}"))
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk download of all facility IDs
#
# GET /ids
# operationId: getFacilityIds
export def "ids get-facility" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Optional facility type search filter
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve all VA health facilities reachable by driving within the specified time period
#
# GET /nearby
# operationId: getNearbyFacilities
export def "nearby get-facilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --street-address: string # Street address of the location from which drive time will be calculated.
  --city: string # City of the location from which drive time will be calculated.
  --state: string # Two character state code of the location from which drive time will be calculated.
  --zip: string # Zip code of the location from which drive time will be calculated.
  --lat: float # Latitude of the location from which drive time will be calculated. (format: float)
  --lng: float # Longitude of the location from which drive time will be calculated. (format: float)
  --drive-time: int@drive-time-completer # Filter to only include facilities that are within the specified number of drive time minutes from the requested location. (format: int32, default: 90)
  --services: list<string> # Optional facility service search filter
  --page: int # Page of results to return per paginated response. (format: int32, default: 1)
  --per-page: int # Number of results to return per paginated response. (format: int32, default: 20)
]: nothing -> record<data: table<attributes: record, id: string, type: string>, meta: record<band_version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "street_address" $street_address "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "drive_time" $drive_time "scalar") (serialize-qp "services[]" $services "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nearby" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
