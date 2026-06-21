# Auto-generated client for Geocoder REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/geocoder/2.0.0/openapi.json
# Auth: --token flag or $env.GEOCODER_REST_API_TOKEN

const BASE_URL = "https://geocoder.api.gov.bc.ca"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEOCODER_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://geocoder.api.gov.bc.ca" "https://geocodertst.api.gov.bc.ca" "https://geocoderdlv.api.gov.bc.ca"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def location-descriptor-completer [] { ["accessPoint" "any" "frontDoorPoint" "parcelPoint" "rooftopPoint" "routingPoint"] }
def interpolation-completer [] { ["adaptive" "linear" "none"] }
def output-srs-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "4269" "4326"] }
def unit-designator-completer [] { ["APT" "BLDG" "BSMT" "FLR" "LOBBY" "LWR" "PAD" "PH" "REAR" "RM" "SIDE" "SITE" "SUITE" "TH" "UNIT" "UPPR"] }
def street-direction-completer [] { ["E" "N" "NE" "NO" "NW" "O" "S" "SE" "SO" "SW" "W"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addresses-output-format get" } } | get name | first)
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

# Geocode an address
#
# GET /addresses.{outputFormat}
export def "addresses-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-string: string # Civic or intersection address as a single string. See addressString (e.g. 525 Superior Street, Victoria, BC)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --interpolation: string@interpolation-completer # accessPoint interpolation method. See interpolation (default: adaptive)
  --echo: oneof<nothing, bool> # If true, include unmatched address details such as site name in results. (default: true)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --auto-complete: oneof<nothing, bool> # If true, addressString is expected to contain a partial address that requires completion. Not supported for shp, csv, gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --min-score: int # The minimum score required for a match to be returned. See minScore (default: 1)
  --match-precision: string # Example: street,locality. A comma separated list of individual match precision levels to include in results. See matchPrecision
  --match-precision-not: string # Example: street,locality. A comma separated list of individual match precision levels to exclude from results. See matchPrecisionNot
  --site-name: string # A string containing the name of the building, facility, or institution (e.g., Duck Building, Casa Del Mar, Crystal Garden, Bluebird House).See siteName
  --unit-designator: string@unit-designator-completer # The type of unit within a house or building. See unitDesignator
  --unit-number: string # The number of the unit, suite, or apartment within a house or building.
  --unit-number-suffix: string # A letter that follows the unit number as in Unit 1A or Suite 302B.
  --civic-number: string # The official number assigned to a site by an address authority. See civicNumber
  --civic-number-suffix: string # A letter or fraction that follows the civic number (e.g., the A in 1039A Bledsoe St). See civicNumberSuffix
  --street-name: string # The official name of the street as assigned by an address authority (e.g., the Douglas in 1175 Douglas Street). See streetName
  --street-type: string # The type of street as assigned by a municipality (e.g., the ST in 1175 DOUGLAS St). See streetType
  --street-direction: string@street-direction-completer # The abbreviated compass direction as defined by Canada Post and B.C. civic addressing authorities. See streetDirection
  --street-qualifier: string # Example: the Bridge in Johnson St Bridge. The qualifier of a street name. See streetQualifier
  --locality-name: string # The name of the locality assigned to a given site by an address authority. See localityName
  --province-code: string # The ISO 3166-2 Sub-Country Code. The code for British Columbia is BC. (default: BC)
  --localities: string # A comma separated list of locality names that matched addresses must belong to. For example, setting localities to Nanaimo only returns addresses in Nanaimo
  --not-localities: string # A comma-separated list of localities to exclude from the search.
  --bbox: string # Example: -126.07929,49.7628,-126.0163,49.7907. A bounding box (xmin,ymin,xmax,ymax) that limits the search area. See bbox
  --centre: string # Example: -124.0165926,49.2296251 . The coordinates of a centre point (x,y) used to define a bounding circle that will limit the search area. This parameter must be specified together with 'maxDistance'. See centre
  --max-distance: float # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --extrapolate: oneof<nothing, bool> # If true, uses supplied parcelPoint to derive an appropriate accessPoint. See extrapolate
  --parcel-point: string # The coordinates of a point (x,y) known to be inside the parcel containing a given address. See parcelPoint
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "addressString" $address_string "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "interpolation" $interpolation "scalar") (serialize-qp "echo" $echo "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "autoComplete" $auto_complete "scalar") (serialize-qp "setBack" $set_back "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "minScore" $min_score "scalar") (serialize-qp "matchPrecision" $match_precision "scalar") (serialize-qp "matchPrecisionNot" $match_precision_not "scalar") (serialize-qp "siteName" $site_name "scalar") (serialize-qp "unitDesignator" $unit_designator "scalar") (serialize-qp "unitNumber" $unit_number "scalar") (serialize-qp "unitNumberSuffix" $unit_number_suffix "scalar") (serialize-qp "civicNumber" $civic_number "scalar") (serialize-qp "civicNumberSuffix" $civic_number_suffix "scalar") (serialize-qp "streetName" $street_name "scalar") (serialize-qp "streetType" $street_type "scalar") (serialize-qp "streetDirection" $street_direction "scalar") (serialize-qp "streetQualifier" $street_qualifier "scalar") (serialize-qp "localityName" $locality_name "scalar") (serialize-qp "provinceCode" $province_code "scalar") (serialize-qp "localities" $localities "scalar") (serialize-qp "notLocalities" $not_localities "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "centre" $centre "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "extrapolate" $extrapolate "scalar") (serialize-qp "parcelPoint" $parcel_point "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/addresses.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"addressString": $address_string, "locationDescriptor": $location_descriptor, "maxResults": $max_results, "interpolation": $interpolation, "echo": $echo, "brief": $brief, "autoComplete": $auto_complete, "setBack": $set_back, "outputSRS": $output_srs, "minScore": $min_score, "matchPrecision": $match_precision, "matchPrecisionNot": $match_precision_not, "siteName": $site_name, "unitDesignator": $unit_designator, "unitNumber": $unit_number, "unitNumberSuffix": $unit_number_suffix, "civicNumber": $civic_number, "civicNumberSuffix": $civic_number_suffix, "streetName": $street_name, "streetType": $street_type, "streetDirection": $street_direction, "streetQualifier": $street_qualifier, "localityName": $locality_name, "provinceCode": $province_code, "localities": $localities, "notLocalities": $not_localities, "bbox": $bbox, "centre": $centre, "maxDistance": $max_distance, "extrapolate": $extrapolate, "parcelPoint": $parcel_point} | compact), body: null}
}

# Find intersections near to a geographic point
#
# GET /intersections/near.{outputFormat}
export def "intersections-near-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --min-degree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --max-degree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "minDegree" $min_degree "scalar") (serialize-qp "maxDegree" $max_degree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/intersections/near.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "maxDistance": $max_distance, "outputSRS": $output_srs, "maxResults": $max_results, "minDegree": $min_degree, "maxDegree": $max_degree} | compact), body: null}
}

# Find nearest intersection to a geographic point
#
# GET /intersections/nearest.{outputFormat}
export def "intersections-nearest-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # Example: -122.377,50.121 The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --min-degree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --max-degree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "minDegree" $min_degree "scalar") (serialize-qp "maxDegree" $max_degree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/intersections/nearest.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "maxDistance": $max_distance, "outputSRS": $output_srs, "minDegree": $min_degree, "maxDegree": $max_degree} | compact), body: null}
}

# Find intersections in a geographic area
#
# GET /intersections/within.{outputFormat}
export def "intersections-within-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See bbox (e.g. -119.51,49.48,-119.53,49.50)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results (default: 200)
  --min-degree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --max-degree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "minDegree" $min_degree "scalar") (serialize-qp "maxDegree" $max_degree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/intersections/within.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"bbox": $bbox, "outputSRS": $output_srs, "maxResults": $max_results, "minDegree": $min_degree, "maxDegree": $max_degree} | compact), body: null}
}

# Get an intersection by its unique ID
#
# GET /intersections/{intersectionID}.{outputFormat}
export def "intersections get" [
  intersection_id: string
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($intersection_id | is-empty) { error make --unspanned { msg: "path parameter 'intersectionID' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "outputSRS" $output_srs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({intersection_id: (encode-path-segment $intersection_id), output_format: (encode-path-segment $output_format)} | format pattern "/intersections/{intersection_id}.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputSRS": $output_srs} | compact), body: null}
}

# Geocode an address and identify site occupants
#
# GET /occupants/addresses.{outputFormat}
export def "occupants-addresses-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-string: string # Occupant name OR Occupant name ** address (e.g. Sir James Douglas Elementary)
  --tags: string # Example: schools;courts;employmentA list of tags separated by semicolons.
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --interpolation: string@interpolation-completer # accessPoint interpolation method. See interpolation (default: adaptive)
  --echo: oneof<nothing, bool> # If true, include unmatched address details such as site name in results. (default: false)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --auto-complete: oneof<nothing, bool> # If true, addressString is expected to contain a partial address that requires completion. Not supported for shp, csv, gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --min-score: int # The minimum score required for a match to be returned. See minScore (default: 1)
  --match-precision: string # Example: street,locality. A comma separated list of individual match precision levels to include in results. See matchPrecision (default: OCCUPANT)
  --match-precision-not: string # Example: street,locality. A comma separated list of individual match precision levels to exclude from results. See matchPrecisionNot
  --site-name: string # A string containing the name of the building, facility, or institution (e.g., Duck Building, Casa Del Mar, Crystal Garden, Bluebird House).See siteName
  --unit-designator: string@unit-designator-completer # The type of unit within a house or building. See unitDesignator
  --unit-number: string # The number of the unit, suite, or apartment within a house or building.
  --unit-number-suffix: string # A letter that follows the unit number as in Unit 1A or Suite 302B.
  --civic-number: string # The official number assigned to a site by an address authority. See civicNumber
  --civic-number-suffix: string # A letter or fraction that follows the civic number (e.g., the A in 1039A Bledsoe St). See civicNumberSuffix
  --street-name: string # The official name of the street as assigned by an address authority (e.g., the Douglas in 1175 Douglas Street). See streetName
  --street-type: string # The type of street as assigned by a municipality (e.g., the ST in 1175 DOUGLAS St). See streetType
  --street-direction: string@street-direction-completer # The abbreviated compass direction as defined by Canada Post and B.C. civic addressing authorities. See streetDirection
  --street-qualifier: string # The qualifier of a street name (e.g., the Bridge in Johnson St Bridge)
  --locality-name: string # The name of the locality assigned to a given site by an address authority. See streetDirection
  --province-code: string # The ISO 3166-2 Sub-Country Code. The code for British Columbia is BC. (default: BC)
  --localities: string # A comma separated list of locality names that matched addresses must belong to. For example, setting localities to Nanaimo only returns addresses in Nanaimo
  --not-localities: string # A comma-separated list of localities to exclude from the search.
  --bbox: string # Example: -126.07929,49.7628,-126.0163,49.7907. A bounding box (xmin,ymin,xmax,ymax) that limits the search area. See bbox
  --centre: string # Example: -124.0165926,49.2296251 . The coordinates of a centre point (x,y) used to define a bounding circle that will limit the search area. This parameter must be specified together with 'maxDistance'. See centre
  --max-distance: float # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --extrapolate: oneof<nothing, bool> # If true, uses supplied parcelPoint to derive an appropriate accessPoint. See extrapolate
  --parcel-point: string # The coordinates of a point (x,y) known to be inside the parcel containing a given address. See parcelPoint
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "addressString" $address_string "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "interpolation" $interpolation "scalar") (serialize-qp "echo" $echo "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "autoComplete" $auto_complete "scalar") (serialize-qp "setBack" $set_back "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "minScore" $min_score "scalar") (serialize-qp "matchPrecision" $match_precision "scalar") (serialize-qp "matchPrecisionNot" $match_precision_not "scalar") (serialize-qp "siteName" $site_name "scalar") (serialize-qp "unitDesignator" $unit_designator "scalar") (serialize-qp "unitNumber" $unit_number "scalar") (serialize-qp "unitNumberSuffix" $unit_number_suffix "scalar") (serialize-qp "civicNumber" $civic_number "scalar") (serialize-qp "civicNumberSuffix" $civic_number_suffix "scalar") (serialize-qp "streetName" $street_name "scalar") (serialize-qp "streetType" $street_type "scalar") (serialize-qp "streetDirection" $street_direction "scalar") (serialize-qp "streetQualifier" $street_qualifier "scalar") (serialize-qp "localityName" $locality_name "scalar") (serialize-qp "provinceCode" $province_code "scalar") (serialize-qp "localities" $localities "scalar") (serialize-qp "notLocalities" $not_localities "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "centre" $centre "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "extrapolate" $extrapolate "scalar") (serialize-qp "parcelPoint" $parcel_point "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/occupants/addresses.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"addressString": $address_string, "tags": $tags, "locationDescriptor": $location_descriptor, "maxResults": $max_results, "interpolation": $interpolation, "echo": $echo, "brief": $brief, "autoComplete": $auto_complete, "setBack": $set_back, "outputSRS": $output_srs, "minScore": $min_score, "matchPrecision": $match_precision, "matchPrecisionNot": $match_precision_not, "siteName": $site_name, "unitDesignator": $unit_designator, "unitNumber": $unit_number, "unitNumberSuffix": $unit_number_suffix, "civicNumber": $civic_number, "civicNumberSuffix": $civic_number_suffix, "streetName": $street_name, "streetType": $street_type, "streetDirection": $street_direction, "streetQualifier": $street_qualifier, "localityName": $locality_name, "provinceCode": $province_code, "localities": $localities, "notLocalities": $not_localities, "bbox": $bbox, "centre": $centre, "maxDistance": $max_distance, "extrapolate": $extrapolate, "parcelPoint": $parcel_point} | compact), body: null}
}

# Find occupants of sites near to a geographic point
#
# GET /occupants/near.{outputFormat}
export def "occupants-near-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --tags: string # Example: schools;courts;employmentA list of tags separated by semicolons.
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/occupants/near.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "tags": $tags, "maxDistance": $max_distance, "outputSRS": $output_srs, "maxResults": $max_results, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}

# Find occupants of the site nearest to a geographic point
#
# GET /occupants/nearest.{outputFormat}
export def "occupants-nearest-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --tags: string # Example: schools;courts;employmentA list of tags separated by semicolons.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/occupants/nearest.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "maxDistance": $max_distance, "tags": $tags, "outputSRS": $output_srs, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}

# Find occupants of sites in a geographic area
#
# GET /occupants/within.{outputFormat}
export def "occupants-within-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See bbox (e.g. -123.14,49.28,-123.13,49.29)
  --tags: string # Example: schools;courts;employmentA list of tags separated by semicolons.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results to return. (default: 200)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/occupants/within.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"bbox": $bbox, "tags": $tags, "outputSRS": $output_srs, "maxResults": $max_results, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}

# Get an occupant (of a site) by its unique ID
#
# GET /occupants/{occupantID}.{outputFormat}
export def "occupants get" [
  occupant_id: string
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($occupant_id | is-empty) { error make --unspanned { msg: "path parameter 'occupantID' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({occupant_id: (encode-path-segment $occupant_id), output_format: (encode-path-segment $output_format)} | format pattern "/occupants/{occupant_id}.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputSRS": $output_srs, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}

# Get a comma-separated string of all pids for a given site
#
# GET /parcels/pids/{siteID}.{outputFormat}
export def "parcels-pids get" [
  site_id: string
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteID' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), output_format: (encode-path-segment $output_format)} | format pattern "/parcels/pids/{site_id}.{output_format}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find sites near to a geographic point
#
# GET /sites/near.{outputFormat}
export def "sites-near-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # The point (x,y) from which the nearby sites will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --exclude-units: oneof<nothing, bool> # If true, excludes sites that are units of a parent site (default: false)
  --only-civic: oneof<nothing, bool> # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "setBack" $set_back "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $exclude_units "scalar") (serialize-qp "onlyCivic" $only_civic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/sites/near.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "maxDistance": $max_distance, "outputSRS": $output_srs, "maxResults": $max_results, "locationDescriptor": $location_descriptor, "setBack": $set_back, "brief": $brief, "excludeUnits": $exclude_units, "onlyCivic": $only_civic} | compact), body: null}
}

# Find the site nearest to a geographic point
#
# GET /sites/nearest.{outputFormat}
export def "sites-nearest-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # Centre point of search. See point (e.g. -122.377,50.121)
  --max-distance: int # The maximum distance (in metres) to search from the given point. If not specified, the search distance is unlimited.
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --exclude-units: oneof<nothing, bool> # If true, excludes sites that are units of a parent site (default: false)
  --only-civic: oneof<nothing, bool> # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "setBack" $set_back "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $exclude_units "scalar") (serialize-qp "onlyCivic" $only_civic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/sites/nearest.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"point": $point, "maxDistance": $max_distance, "outputSRS": $output_srs, "locationDescriptor": $location_descriptor, "setBack": $set_back, "brief": $brief, "excludeUnits": $exclude_units, "onlyCivic": $only_civic} | compact), body: null}
}

# Find sites in a geographic area
#
# GET /sites/within.{outputFormat}
export def "sites-within-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See bbox (e.g. -119.51,49.48,-119.53,49.50)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --max-results: int # The maximum number of search results to return. (default: 1)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --exclude-units: oneof<nothing, bool> # If true, excludes sites that are units of a parent site (default: false)
  --only-civic: oneof<nothing, bool> # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "setBack" $set_back "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $exclude_units "scalar") (serialize-qp "onlyCivic" $only_civic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/sites/within.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"bbox": $bbox, "outputSRS": $output_srs, "maxResults": $max_results, "locationDescriptor": $location_descriptor, "setBack": $set_back, "brief": $brief, "excludeUnits": $exclude_units, "onlyCivic": $only_civic} | compact), body: null}
}

# Get a site by its unique ID
#
# GET /sites/{siteID}.{outputFormat}
export def "sites get" [
  site_id: string
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteID' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), output_format: (encode-path-segment $output_format)} | format pattern "/sites/{site_id}.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputSRS": $output_srs, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}

# Represents all subsites of a given site
#
# GET /sites/{siteID}/subsites.{outputFormat}
export def "sites-subsites-output-format get" [
  site_id: string
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --location-descriptor: string@location-descriptor-completer # Describes the nature of the address location. See locationDescriptor (default: any)
  --brief: oneof<nothing, bool> # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --set-back: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteID' must be non-empty" } }
  if ($output_format | is-empty) { error make --unspanned { msg: "path parameter 'outputFormat' must be non-empty" } }
  let qp = [(serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "locationDescriptor" $location_descriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $set_back "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id), output_format: (encode-path-segment $output_format)} | format pattern "/sites/{site_id}/subsites.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"outputSRS": $output_srs, "locationDescriptor": $location_descriptor, "brief": $brief, "setBack": $set_back} | compact), body: null}
}
