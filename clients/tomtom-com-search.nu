# Auto-generated client for Search v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/search/1.0.0/openapi.json
# Auth: --token flag or $env.SEARCH_TOKEN

const BASE_URL = "https://api.tomtom.com"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-key" => { {headers: {}, query: $"key=($token_val)"} }
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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def geometries-zoom-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "3" "4" "5" "6" "7" "8" "9"] }
def view-completer [] { ["IL" "IN" "MA" "PK" "Unified"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search-additional-data-ext get" } } | get name | first)
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

# Additional Data
#
# GET /search/{versionNumber}/additionalData.{ext}
export def "search-additional-data-ext get" [
  version_number: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometries: string # Comma separated list of geometry UUIDs, previously retrieved from an Search API request. (e.g. 00004631-3400-3c00-0000-0000673c4d2e,00004631-3400-3c00-0000-0000673c42fe)
  --geometries-zoom: int@geometries-zoom-completer # Defines the precision of the geometries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometries" $geometries "scalar") (serialize-qp "geometriesZoom" $geometries_zoom "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/additionalData.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Low Bandwith Category Search
#
# GET /search/{versionNumber}/cS/{category}.{ext}
# DEPRECATED
@deprecated
export def "search-c-s get" [
  version_number: int
  category: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "idxSet" $idx_set "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), category: (encode-path-segment $category), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/cS/{category}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Category Search
#
# GET /search/{versionNumber}/categorySearch/{query}.{ext}
export def "search-category-search get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/categorySearch/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geocode
#
# GET /search/{versionNumber}/geocode/{query}.{ext}
@deprecated --flag store-result
export def "search-geocode get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-result: oneof<nothing, bool> # If the "storeResult" flag is set, the query will be interpreted as a stored geocode and will be billed according to the terms of use. (DEPRECATED, default: false)
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeResult" $store_result "scalar") (serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/geocode/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geometry Filter
#
# GET /search/{versionNumber}/geometryFilter.{ext}
export def "search-geometry-filter-ext get" [
  version_number: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (e.g. [{"type":"CIRCLE", "position":"40.80558, -73.96548", "radius":100}, {"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}])
  --poi-list: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (e.g. [{"poi":{"name":"S Restaurant Toms"},"address":{"freeformAddress":"2880 Broadway, New York, NY 10025"},"position":{"lat":40.80558,"lon":-73.96548}},{"poi":{"name":"Yasha Raman Corporation"},"address":{"freeformAddress":"940 Amsterdam Ave, New York, NY 10025"},"position":{"lat":40.80076,"lon":-73.96556}}])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometryList" $geometry_list "scalar") (serialize-qp "poiList" $poi_list "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/geometryFilter.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geometry Filter
#
# POST /search/{versionNumber}/geometryFilter.{ext}
# --geometryList item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
# --poiList item shape: {address?: record, poi?: record, position?: record}
export def "search-geometry-filter-ext create" [
  version_number: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
  --poi-list: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/geometryFilter.{ext}"))
  let req_body = {"geometryList": $geometry_list, "poiList": $poi_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Geometry Search
#
# GET /search/{versionNumber}/geometrySearch/{query}.{ext}
export def "search-geometry-search get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geometry-list: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (e.g. [{"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}, {"type":"CIRCLE", "position":"37.71205, -121.36434", "radius":6000}, {"type":"CIRCLE", "position":"37.31205, -121.36434", "radius":1000}])
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometryList" $geometry_list "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "idxSet" $idx_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/geometrySearch/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geometry Search
#
# POST /search/{versionNumber}/geometrySearch/{query}.{ext}
# --geometryList item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
export def "search-geometry-search create" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --geometry-list: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "idxSet" $idx_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/geometrySearch/{query}.{ext}") $qp)
  let req_body = {"geometryList": $geometry_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Nearby Search
#
# GET /search/{versionNumber}/nearbySearch/.{ext}
@deprecated --flag top-left
@deprecated --flag btm-right
export def "search-nearby-search-ext get" [
  version_number: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters. (default: 10000)
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --min-fuzzy-level: int # Minimum fuzziness level to be used. (default: 1)
  --max-fuzzy-level: int # Maximum fuzziness level to be used. (default: 2)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "minFuzzyLevel" $min_fuzzy_level "scalar") (serialize-qp "maxFuzzyLevel" $max_fuzzy_level "scalar") (serialize-qp "idxSet" $idx_set "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/nearbySearch/.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Points of Interest Search
#
# GET /search/{versionNumber}/poiSearch/{query}.{ext}
export def "search-poi-search get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/poiSearch/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cross Street lookup
#
# GET /search/{versionNumber}/reverseGeocode/crossStreet/{position}.{ext}
@deprecated --flag spatial-keys
export def "search-reverse-geocode-cross-street get" [
  version_number: int
  position: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Maximum number of cross-streets to return. (default: 1)
  --spatial-keys: oneof<nothing, bool> # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "spatialKeys" $spatial_keys "scalar") (serialize-qp "heading" $heading "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), position: (encode-path-segment $position), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/reverseGeocode/crossStreet/{position}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reverse Geocode
#
# GET /search/{versionNumber}/reverseGeocode/{position}.{ext}
@deprecated --flag spatial-keys
export def "search-reverse-geocode get" [
  version_number: int
  position: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --spatial-keys: oneof<nothing, bool> # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --return-speed-limit: oneof<nothing, bool> # To enable return of the posted speed limit (where available). (default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --number: string # If a number is sent in along with the request, the response may include the side of the street (Left/Right) and an offset position for that number.
  --return-road-use: oneof<nothing, bool> # Enables return of the road use array for reverse geocodes at street level. (default: false)
  --road-use: string # Restricts reverse geocodes to a certain type of road use. The road use array for reverse geocodes can be one or more of: ["LimitedAccess", "Arterial", "Terminal", "Ramp", "Rotary", "LocalStreet"].
  --callback: string # Specifies the jsonp callback method. (default: cb)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spatialKeys" $spatial_keys "scalar") (serialize-qp "returnSpeedLimit" $return_speed_limit "scalar") (serialize-qp "heading" $heading "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "returnRoadUse" $return_road_use "scalar") (serialize-qp "roadUse" $road_use "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), position: (encode-path-segment $position), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/reverseGeocode/{position}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Routed Filter
#
# GET /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "search-routed-filter get" [
  version_number: int
  position: string
  heading: float
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --poi-list: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (e.g. [{"poi":{"name":"Cleaire Advanced Emission Controls"},"address":{"freeformAddress":"7220 Trade St, San Diego, CA 92121"},"position":{"lat":"37.83274","lon":"-122.27631"}}])
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "poiList" $poi_list "scalar") (serialize-qp "routingTimeout" $routing_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), position: (encode-path-segment $position), heading: (encode-path-segment $heading), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/routedFilter/{position}/{heading}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Routed Filter
#
# POST /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
# --poiList item shape: {address?: record, poi?: record, position?: record}
@deprecated
export def "search-routed-filter create" [
  version_number: int
  position: string
  heading: float
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --poi-list: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "routingTimeout" $routing_timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), position: (encode-path-segment $position), heading: (encode-path-segment $heading), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/routedFilter/{position}/{heading}.{ext}") $qp)
  let req_body = {"poiList": $poi_list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Routed Search
#
# GET /search/{versionNumber}/routedSearch/{query}/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "search-routed-search get" [
  version_number: int
  query: string
  position: string
  heading: float
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --multiplier: int # Multiplies the limit by N to gather more candidate POIs, which will then be sorted by drive distance, returning only the top candidates according to the limit. (default: 2)
  --routing-timeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "multiplier" $multiplier "scalar") (serialize-qp "routingTimeout" $routing_timeout "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "idxSet" $idx_set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), position: (encode-path-segment $position), heading: (encode-path-segment $heading), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/routedSearch/{query}/{position}/{heading}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Low bandwith Search
#
# GET /search/{versionNumber}/s/{query}.{ext}
# DEPRECATED
@deprecated
export def "search-s get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "idxSet" $idx_set "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/s/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fuzzy Search
#
# GET /search/{versionNumber}/search/{query}.{ext}
export def "search-search get" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeahead: oneof<nothing, bool> # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter predictive mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --country-set: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --top-left: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btm-right: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
  --min-fuzzy-level: int # Minimum fuzziness level to be used. (default: 1)
  --max-fuzzy-level: int # Maximum fuzziness level to be used. (default: 2)
  --idx-set: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are: - Addr = Address range interpolation (when there is no PAD) - Geo = Geographies - PAD = Point Addresses - POI = Points of interest - Str = Streets - Xstr = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $country_set "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $top_left "scalar") (serialize-qp "btmRight" $btm_right "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar") (serialize-qp "minFuzzyLevel" $min_fuzzy_level "scalar") (serialize-qp "maxFuzzyLevel" $max_fuzzy_level "scalar") (serialize-qp "idxSet" $idx_set "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/search/{query}.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Along Route Search
#
# POST /search/{versionNumber}/searchAlongRoute/{query}.{ext}
# --route shape: {points?: list}
export def "search-search-along-route create" [
  version_number: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-detour-time: int # Maximum detour time (e.g. 1200)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --route: record # shape: {points?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxDetourTime" $max_detour_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), query: (encode-path-segment $query), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/searchAlongRoute/{query}.{ext}") $qp)
  let req_body = {"route": $route} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Structured Geocode
#
# GET /search/{versionNumber}/structuredGeocode.{ext}
export def "search-structured-geocode-ext get" [
  version_number: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # 2 or 3 letter country code (e.g.: FR, ES). (e.g. NL)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --street-number: string # The street number for the structured address.
  --street-name: string # The street name for the structured address.
  --cross-street: string # The cross street name for the structured address.
  --municipality: string # The municipality (city/town) for the structured address. (e.g. Amsterdam)
  --municipality-subdivision: string # The municipality subdivision (sub/super city) for the structured address.
  --country-tertiary-subdivision: string # The named area for the structured address.
  --country-secondary-subdivision: string # The county for the structured address.
  --country-subdivision: string # The state or province for the structured address.
  --postal-code: string # The zip code or postal code for the structured address.
  --language: string # Language in which search results should be returned. Should be one of supported IETF language tags (/search-api/search-api-documentation/supported-languages), case insensitive.
  --extended-postal-codes-for: string # Indexes for which extended postal codes should be included in the results. Available indexes are: - Addr = Address ranges - Geo = Geographies - PAD = Point Addresses - POI = Points of Interest - Str = Streets - XStr = Cross Streets (intersections)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $country_code "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "streetNumber" $street_number "scalar") (serialize-qp "streetName" $street_name "scalar") (serialize-qp "crossStreet" $cross_street "scalar") (serialize-qp "municipality" $municipality "scalar") (serialize-qp "municipalitySubdivision" $municipality_subdivision "scalar") (serialize-qp "countryTertiarySubdivision" $country_tertiary_subdivision "scalar") (serialize-qp "countrySecondarySubdivision" $country_secondary_subdivision "scalar") (serialize-qp "countrySubdivision" $country_subdivision "scalar") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extended_postal_codes_for "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), ext: (encode-path-segment $ext)} | format pattern "/search/{version_number}/structuredGeocode.{ext}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
