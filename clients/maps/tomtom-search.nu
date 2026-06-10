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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def geometriesZoom-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "3" "4" "5" "6" "7" "8" "9"] }
def view-completer [] { ["IL" "IN" "MA" "PK" "Unified"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  versionNumber: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --geometries: string # Comma separated list of geometry UUIDs, previously retrieved from an Search API request. (e.g. 00004631-3400-3c00-0000-0000673c4d2e,00004631-3400-3c00-0000-0000673c42fe)
  --geometriesZoom: int@geometriesZoom-completer # Defines the precision of the geometries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometries" $geometries "scalar") (serialize-qp "geometriesZoom" $geometriesZoom "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/additionalData.($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Low Bandwith Category Search
#
# GET /search/{versionNumber}/cS/{category}.{ext}
# DEPRECATED
@deprecated
export def "search-c-s get" [
  versionNumber: int
  category: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "idxSet" $idxSet "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/cS/($category).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Category Search
#
# GET /search/{versionNumber}/categorySearch/{query}.{ext}
export def "search-category-search get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/categorySearch/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geocode
#
# GET /search/{versionNumber}/geocode/{query}.{ext}
@deprecated --flag storeResult
export def "search-geocode get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --storeResult: string@bool-completer # If the "storeResult" flag is set, the query will be interpreted as a stored geocode and will be billed according to the terms of use. (DEPRECATED, default: false)
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeResult" $storeResult "scalar") (serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/geocode/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geometry Filter
#
# GET /search/{versionNumber}/geometryFilter.{ext}
export def "search-geometry-filter-ext get" [
  versionNumber: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --geometryList: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (e.g. [{"type":"CIRCLE", "position":"40.80558, -73.96548", "radius":100}, {"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}])
  --poiList: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (e.g. [{"poi":{"name":"S Restaurant Toms"},"address":{"freeformAddress":"2880 Broadway, New York, NY 10025"},"position":{"lat":40.80558,"lon":-73.96548}},{"poi":{"name":"Yasha Raman Corporation"},"address":{"freeformAddress":"940 Amsterdam Ave, New York, NY 10025"},"position":{"lat":40.80076,"lon":-73.96556}}])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometryList" $geometryList "scalar") (serialize-qp "poiList" $poiList "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/geometryFilter.($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geometry Filter
#
# POST /search/{versionNumber}/geometryFilter.{ext}
# --geometryList item shape: {position?: string, radius?: int, type?: string, vertices?: list}
# --poiList item shape: {address?: record, poi?: record, position?: record}
export def "search-geometry-filter-ext post" [
  versionNumber: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --geometryList: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list}
  --poiList: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/search/($versionNumber)/geometryFilter.($ext)")
  let body = {geometryList: $geometryList, poiList: $poiList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Geometry Search
#
# GET /search/{versionNumber}/geometrySearch/{query}.{ext}
export def "search-geometry-search get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --geometryList: string # List of geometries to filter by. Available types are CIRCLE (with the radius expressed in meters) and POLYGON. (e.g. [{"type":"POLYGON", "vertices":["37.7524152343544, -122.43576049804686", "37.70660472542312, -122.43301391601562", "37.712059855877314, -122.36434936523438", "37.75350561243041, -122.37396240234374"]}, {"type":"CIRCLE", "position":"37.71205, -121.36434", "radius":6000}, {"type":"CIRCLE", "position":"37.31205, -121.36434", "radius":1000}])
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geometryList" $geometryList "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "idxSet" $idxSet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/geometrySearch/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geometry Search
#
# POST /search/{versionNumber}/geometrySearch/{query}.{ext}
# --geometryList item shape: {position?: string, radius?: int, type?: string, vertices?: list}
export def "search-geometry-search post" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
  --geometryList: list # item shape: {position?: string, radius?: int, type?: string, vertices?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "idxSet" $idxSet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/geometrySearch/($query).($ext)" $qp)
  let body = {geometryList: $geometryList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Nearby Search
#
# GET /search/{versionNumber}/nearbySearch/.{ext}
@deprecated --flag topLeft
@deprecated --flag btmRight
export def "search-nearby-search-ext get" [
  versionNumber: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --radius: int # If radius and position are set, the results will be constrained to the defined area. The radius parameter is specified in meters. (default: 10000)
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (DEPRECATED, e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --minFuzzyLevel: int # Minimum fuzziness level to be used. (default: 1)
  --maxFuzzyLevel: int # Maximum fuzziness level to be used. (default: 2)
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "minFuzzyLevel" $minFuzzyLevel "scalar") (serialize-qp "maxFuzzyLevel" $maxFuzzyLevel "scalar") (serialize-qp "idxSet" $idxSet "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/nearbySearch/.($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Points of Interest Search
#
# GET /search/{versionNumber}/poiSearch/{query}.{ext}
export def "search-poi-search get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/poiSearch/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cross Street lookup
#
# GET /search/{versionNumber}/reverseGeocode/crossStreet/{position}.{ext}
@deprecated --flag spatialKeys
export def "search-reverse-geocode-cross-street get" [
  versionNumber: int
  position: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Maximum number of cross-streets to return. (default: 1)
  --spatialKeys: string@bool-completer # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "spatialKeys" $spatialKeys "scalar") (serialize-qp "heading" $heading "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/reverseGeocode/crossStreet/($position).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reverse Geocode
#
# GET /search/{versionNumber}/reverseGeocode/{position}.{ext}
@deprecated --flag spatialKeys
export def "search-reverse-geocode get" [
  versionNumber: int
  position: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --spatialKeys: string@bool-completer # If the "spatialKeys" flag is set, the response will also contain a proprietary geospatial keys for a specified location. (DEPRECATED, default: false)
  --returnSpeedLimit: string@bool-completer # To enable return of the posted speed limit (where available). (default: false)
  --heading: float # The directional heading in degrees, usually similar to the course along a road segment. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.) (format: float)
  --radius: int # The maximum distance in meters from the specified position for the reverse geocoder to consider. (default: 10000)
  --number: string # If a number is sent in along with the request, the response may include the side of the street (Left/Right) and an offset position for that number.
  --returnRoadUse: string@bool-completer # Enables return of the road use array for reverse geocodes at street level. (default: false)
  --roadUse: string # Restricts reverse geocodes to a certain type of road use. The road use array for reverse geocodes can be one or more of: ["LimitedAccess", "Arterial", "Terminal", "Ramp", "Rotary", "LocalStreet"].
  --callback: string # Specifies the jsonp callback method. (default: cb)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "spatialKeys" $spatialKeys "scalar") (serialize-qp "returnSpeedLimit" $returnSpeedLimit "scalar") (serialize-qp "heading" $heading "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "number" $number "scalar") (serialize-qp "returnRoadUse" $returnRoadUse "scalar") (serialize-qp "roadUse" $roadUse "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/reverseGeocode/($position).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routed Filter
#
# GET /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "search-routed-filter get" [
  versionNumber: int
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
  --poiList: string # List of POIs to filter. The only required attribute of a POI is position, everything else is optional and will be echoed back when passed in. (e.g. [{"poi":{"name":"Cleaire Advanced Emission Controls"},"address":{"freeformAddress":"7220 Trade St, San Diego, CA 92121"},"position":{"lat":"37.83274","lon":"-122.27631"}}])
  --routingTimeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "poiList" $poiList "scalar") (serialize-qp "routingTimeout" $routingTimeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/routedFilter/($position)/($heading).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Routed Filter
#
# POST /search/{versionNumber}/routedFilter/{position}/{heading}.{ext}
# DEPRECATED
# --poiList item shape: {address?: record, poi?: record, position?: record}
@deprecated
export def "search-routed-filter post" [
  versionNumber: int
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
  --routingTimeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --poiList: list # item shape: {address?: record, poi?: record, position?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "routingTimeout" $routingTimeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/routedFilter/($position)/($heading).($ext)" $qp)
  let body = {poiList: $poiList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Routed Search
#
# GET /search/{versionNumber}/routedSearch/{query}/{position}/{heading}.{ext}
# DEPRECATED
@deprecated
export def "search-routed-search get" [
  versionNumber: int
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
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --multiplier: int # Multiplies the limit by N to gather more candidate POIs, which will then be sorted by drive distance, returning only the top candidates according to the limit. (default: 2)
  --routingTimeout: int # Only return results that arrive from routing engine within this time limit. (default: 4000)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "multiplier" $multiplier "scalar") (serialize-qp "routingTimeout" $routingTimeout "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "idxSet" $idxSet "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/routedSearch/($query)/($position)/($heading).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Low bandwith Search
#
# GET /search/{versionNumber}/s/{query}.{ext}
# DEPRECATED
@deprecated
export def "search-s get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "idxSet" $idxSet "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/s/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fuzzy Search
#
# GET /search/{versionNumber}/search/{query}.{ext}
export def "search-search get" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeahead: string@bool-completer # If the "typeahead" flag is set, the query will be interpreted as a partial input and the search will enter <b>predictive</b> mode. (default: false)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --countrySet: string # Comma separated string of country codes. This will limit the search to the specified countries. (e.g. FR)
  --lat: float # Latitude where results should be biased. NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. 37.337)
  --lon: float # Longitude where results should be biased NOTE: supplying a lat/lon without a radius will return search results biased to that point. (format: float, e.g. -121.89)
  --radius: int # If radius <b>and</b> position are set, the results will be constrained to the defined area. The radius parameter is specified in meters.
  --topLeft: string # Top left position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.553,-122.453)
  --btmRight: string # Bottom right position of the bounding box. This is specified as a comma separated string composed of lat., lon. (e.g. 37.4,-122.55)
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
  --minFuzzyLevel: int # Minimum fuzziness level to be used. (default: 1)
  --maxFuzzyLevel: int # Maximum fuzziness level to be used. (default: 2)
  --idxSet: string # A comma separated list of indexes which should be utilized for the search. Item order does not matter. Available indexes are:   - <b>Addr</b> = Address range interpolation (when there is no PAD)   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of interest   - <b>Str</b> = Streets   - <b>Xstr</b> = Cross Streets (intersections) (e.g. POI)
  --view: string@view-completer # Geopolitical View. (default: Unified)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeahead" $typeahead "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "countrySet" $countrySet "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "topLeft" $topLeft "scalar") (serialize-qp "btmRight" $btmRight "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar") (serialize-qp "minFuzzyLevel" $minFuzzyLevel "scalar") (serialize-qp "maxFuzzyLevel" $maxFuzzyLevel "scalar") (serialize-qp "idxSet" $idxSet "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/search/($query).($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Along Route Search
#
# POST /search/{versionNumber}/searchAlongRoute/{query}.{ext}
# --route shape: {points?: list}
export def "search-search-along-route post" [
  versionNumber: int
  query: string
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxDetourTime: int # Maximum detour time (e.g. 1200)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --route: record # shape: {points?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxDetourTime" $maxDetourTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/searchAlongRoute/($query).($ext)" $qp)
  let body = {route: $route} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Structured Geocode
#
# GET /search/{versionNumber}/structuredGeocode.{ext}
export def "search-structured-geocode-ext get" [
  versionNumber: int
  ext: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --countryCode: string # 2 or 3 letter country code (e.g.: FR, ES). (e.g. NL)
  --limit: int # Maximum number of search results that will be returned. (default: 10)
  --ofs: int # Starting offset of the returned results within the full result set. (default: 0)
  --streetNumber: string # The street number for the structured address.
  --streetName: string # The street name for the structured address.
  --crossStreet: string # The cross street name for the structured address.
  --municipality: string # The municipality (city/town) for the structured address. (e.g. Amsterdam)
  --municipalitySubdivision: string # The municipality subdivision (sub/super city) for the structured address.
  --countryTertiarySubdivision: string # The named area for the structured address.
  --countrySecondarySubdivision: string # The county for the structured address.
  --countrySubdivision: string # The state or province for the structured address.
  --postalCode: string # The zip code or postal code for the structured address.
  --language: string # Language in which search results should be returned. Should be one of <a href="/search-api/search-api-documentation/supported-languages">supported IETF language tags</a>, case insensitive.
  --extendedPostalCodesFor: string # Indexes for which extended postal codes should be included in the results. Available indexes are:   - <b>Addr</b> = Address ranges   - <b>Geo</b> = Geographies   - <b>PAD</b> = Point Addresses   - <b>POI</b> = Points of Interest   - <b>Str</b> = Streets   - <b>XStr</b> = Cross Streets (intersections)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "countryCode" $countryCode "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "ofs" $ofs "scalar") (serialize-qp "streetNumber" $streetNumber "scalar") (serialize-qp "streetName" $streetName "scalar") (serialize-qp "crossStreet" $crossStreet "scalar") (serialize-qp "municipality" $municipality "scalar") (serialize-qp "municipalitySubdivision" $municipalitySubdivision "scalar") (serialize-qp "countryTertiarySubdivision" $countryTertiarySubdivision "scalar") (serialize-qp "countrySecondarySubdivision" $countrySecondarySubdivision "scalar") (serialize-qp "countrySubdivision" $countrySubdivision "scalar") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "extendedPostalCodesFor" $extendedPostalCodesFor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($versionNumber)/structuredGeocode.($ext)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
