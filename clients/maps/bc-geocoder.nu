# Auto-generated client for Geocoder REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/geocoder/2.0.0/openapi.json
# Auth: --token flag or $env.GEOCODER_REST_API_TOKEN

const BASE_URL = "https://geocoder.api.gov.bc.ca"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GEOCODER_REST_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://geocoder.api.gov.bc.ca" "https://geocodertst.api.gov.bc.ca" "https://geocoderdlv.api.gov.bc.ca"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def locationDescriptor-completer [] { ["accessPoint" "any" "frontDoorPoint" "parcelPoint" "rooftopPoint" "routingPoint"] }
def interpolation-completer [] { ["adaptive" "linear" "none"] }
def outputSRS-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "4269" "4326"] }
def unitDesignator-completer [] { ["APT" "BLDG" "BSMT" "FLR" "LOBBY" "LWR" "PAD" "PH" "REAR" "RM" "SIDE" "SITE" "SUITE" "TH" "UNIT" "UPPR"] }
def streetDirection-completer [] { ["E" "N" "NE" "NO" "NW" "O" "S" "SE" "SO" "SW" "W"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addressString: string # Civic or intersection address as a single string. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#addressString target="_blank">addressString</a> (e.g. 525 Superior Street, Victoria, BC)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --interpolation: string@interpolation-completer # accessPoint interpolation method. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#interpolation target="_blank">interpolation</a> (default: adaptive)
  --echo: string@bool-completer # If true, include unmatched address details such as site name in results. (default: true)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --autoComplete: string@bool-completer # If true, addressString is expected to contain a partial address that requires completion. Not supported for shp, csv, gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --minScore: int # The minimum score required for a match to be returned. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#minScore target="_blank">minScore</a> (default: 1)
  --matchPrecision: string # Example: street,locality.  A comma separated list of individual match precision levels to include in results. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#matchPrecision target="_blank">matchPrecision</a>
  --matchPrecisionNot: string # Example: street,locality.  A comma separated list of individual match precision levels to exclude from results. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#matchPrecisionNot target="_blank">matchPrecisionNot</a>
  --siteName: string # A string containing the name of the building, facility, or institution (e.g., Duck Building, Casa Del Mar, Crystal Garden, Bluebird House).See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#siteName target="_blank">siteName</a>
  --unitDesignator: string@unitDesignator-completer # The type of unit within a house or building. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#unitDesignator target="_blank">unitDesignator</a>
  --unitNumber: string # The number of the unit, suite, or apartment within a house or building.
  --unitNumberSuffix: string # A letter that follows the unit number as in Unit 1A or Suite 302B.
  --civicNumber: string # The official number assigned to a site by an address authority. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#civicNumber target="_blank">civicNumber</a>
  --civicNumberSuffix: string # A letter or fraction that follows the civic number (e.g., the A in 1039A Bledsoe St). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#civicNumberSuffix target="_blank">civicNumberSuffix</a>
  --streetName: string # The official name of the street as assigned by an address authority (e.g., the Douglas in 1175 Douglas Street). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetName target="_blank">streetName</a>
  --streetType: string # The type of street as assigned by a municipality (e.g., the ST in 1175 DOUGLAS St). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetType target="_blank">streetType</a>
  --streetDirection: string@streetDirection-completer # The abbreviated compass direction as defined by Canada Post and B.C. civic addressing authorities. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetDirection target="_blank">streetDirection</a>
  --streetQualifier: string # Example: the Bridge in Johnson St Bridge. The qualifier of a street name. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetQualifier target="_blank">streetQualifier</a>
  --localityName: string # The name of the locality assigned to a given site by an address authority. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#localityName target="_blank">localityName</a>
  --provinceCode: string # The ISO 3166-2 Sub-Country Code. The code for British Columbia is BC. (default: BC)
  --localities: string # A comma separated list of locality names that matched addresses must belong to. For example, setting localities to Nanaimo only returns addresses in Nanaimo
  --notLocalities: string # A comma-separated list of localities to exclude from the search.
  --bbox: string # Example: -126.07929,49.7628,-126.0163,49.7907.  A bounding box (xmin,ymin,xmax,ymax) that limits the search area. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#bbox target="_blank">bbox</a>
  --centre: string # Example: -124.0165926,49.2296251 .  The coordinates of a centre point (x,y) used to define a bounding circle that will limit the search area. This parameter must be specified together with 'maxDistance'. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#centre target='_blank'>centre</a>
  --maxDistance: float # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --extrapolate: string@bool-completer # If true, uses supplied parcelPoint to derive an appropriate accessPoint.           See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#extrapolate target="_blank">extrapolate</a>
  --parcelPoint: string # The coordinates of a point (x,y) known to be inside the parcel containing a given address. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#parcelPoint target="_blank">parcelPoint</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addressString" $addressString "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "interpolation" $interpolation "scalar") (serialize-qp "echo" $echo "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "autoComplete" $autoComplete "scalar") (serialize-qp "setBack" $setBack "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "minScore" $minScore "scalar") (serialize-qp "matchPrecision" $matchPrecision "scalar") (serialize-qp "matchPrecisionNot" $matchPrecisionNot "scalar") (serialize-qp "siteName" $siteName "scalar") (serialize-qp "unitDesignator" $unitDesignator "scalar") (serialize-qp "unitNumber" $unitNumber "scalar") (serialize-qp "unitNumberSuffix" $unitNumberSuffix "scalar") (serialize-qp "civicNumber" $civicNumber "scalar") (serialize-qp "civicNumberSuffix" $civicNumberSuffix "scalar") (serialize-qp "streetName" $streetName "scalar") (serialize-qp "streetType" $streetType "scalar") (serialize-qp "streetDirection" $streetDirection "scalar") (serialize-qp "streetQualifier" $streetQualifier "scalar") (serialize-qp "localityName" $localityName "scalar") (serialize-qp "provinceCode" $provinceCode "scalar") (serialize-qp "localities" $localities "scalar") (serialize-qp "notLocalities" $notLocalities "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "centre" $centre "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "extrapolate" $extrapolate "scalar") (serialize-qp "parcelPoint" $parcelPoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/addresses.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find intersections near to a geographic point
#
# GET /intersections/near.{outputFormat}
export def "intersections-near-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --minDegree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --maxDegree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "minDegree" $minDegree "scalar") (serialize-qp "maxDegree" $maxDegree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/intersections/near.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find nearest intersection to a geographic point
#
# GET /intersections/nearest.{outputFormat}
export def "intersections-nearest-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # Example: -122.377,50.121  The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --minDegree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --maxDegree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "minDegree" $minDegree "scalar") (serialize-qp "maxDegree" $maxDegree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/intersections/nearest.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find intersections in a geographic area
#
# GET /intersections/within.{outputFormat}
export def "intersections-within-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#bbox target="_blank">bbox</a> (e.g. -119.51,49.48,-119.53,49.50)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results (default: 200)
  --minDegree: int # The minimum degree an intersection can have to be included in results. A dead-end has a degree of 1. (default: 2)
  --maxDegree: int # The maximum degree an interesection can have to be included in results. A four-way stop has a degree of 4. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "minDegree" $minDegree "scalar") (serialize-qp "maxDegree" $maxDegree "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/intersections/within.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an intersection by its unique ID
#
# GET /intersections/{intersectionID}.{outputFormat}
export def "intersections get" [
  intersectionID: string
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputSRS" $outputSRS "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/intersections/($intersectionID).($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Geocode an address and identify site occupants
#
# GET /occupants/addresses.{outputFormat}
export def "occupants-addresses-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --addressString: string # Occupant name OR Occupant name ** address (e.g. Sir James Douglas Elementary)
  --tags: string # Example: schools;courts;employment<br>A list of tags separated by semicolons.
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --interpolation: string@interpolation-completer # accessPoint interpolation method. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#interpolation target="_blank">interpolation</a> (default: adaptive)
  --echo: string@bool-completer # If true, include unmatched address details such as site name in results. (default: false)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --autoComplete: string@bool-completer # If true, addressString is expected to contain a partial address that requires completion. Not supported for shp, csv, gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --minScore: int # The minimum score required for a match to be returned. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#minScore target="_blank">minScore</a> (default: 1)
  --matchPrecision: string # Example: street,locality.  A comma separated list of individual match precision levels to include in results. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#matchPrecision target="_blank">matchPrecision</a> (default: OCCUPANT)
  --matchPrecisionNot: string # Example: street,locality.  A comma separated list of individual match precision levels to exclude from results. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#matchPrecisionNot target="_blank">matchPrecisionNot</a>
  --siteName: string # A string containing the name of the building, facility, or institution (e.g., Duck Building, Casa Del Mar, Crystal Garden, Bluebird House).See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#siteName target="_blank">siteName</a>
  --unitDesignator: string@unitDesignator-completer # The type of unit within a house or building. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#unitDesignator target="_blank">unitDesignator</a>
  --unitNumber: string # The number of the unit, suite, or apartment within a house or building.
  --unitNumberSuffix: string # A letter that follows the unit number as in Unit 1A or Suite 302B.
  --civicNumber: string # The official number assigned to a site by an address authority. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#civicNumber target="_blank">civicNumber</a>
  --civicNumberSuffix: string # A letter or fraction that follows the civic number (e.g., the A in 1039A Bledsoe St). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#civicNumberSuffix target="_blank">civicNumberSuffix</a>
  --streetName: string # The official name of the street as assigned by an address authority (e.g., the Douglas in 1175 Douglas Street). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetName target="_blank">streetName</a>
  --streetType: string # The type of street as assigned by a municipality (e.g., the ST in 1175 DOUGLAS St). See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetType target="_blank">streetType</a>
  --streetDirection: string@streetDirection-completer # The abbreviated compass direction as defined by Canada Post and B.C. civic addressing authorities. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetDirection target="_blank">streetDirection</a>
  --streetQualifier: string # The qualifier of a street name (e.g., the Bridge in Johnson St Bridge)
  --localityName: string # The name of the locality assigned to a given site by an address authority. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#streetDirection target="_blank">streetDirection</a>
  --provinceCode: string # The ISO 3166-2 Sub-Country Code. The code for British Columbia is BC. (default: BC)
  --localities: string # A comma separated list of locality names that matched addresses must belong to. For example, setting localities to Nanaimo only returns addresses in Nanaimo
  --notLocalities: string # A comma-separated list of localities to exclude from the search.
  --bbox: string # Example: -126.07929,49.7628,-126.0163,49.7907.  A bounding box (xmin,ymin,xmax,ymax) that limits the search area. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#bbox target="_blank">bbox</a>
  --centre: string # Example: -124.0165926,49.2296251 .  The coordinates of a centre point (x,y) used to define a bounding circle that will limit the search area. This parameter must be specified together with 'maxDistance'. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#centre target='_blank'>centre</a>
  --maxDistance: float # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --extrapolate: string@bool-completer # If true, uses supplied parcelPoint to derive an appropriate accessPoint.           See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#extrapolate target="_blank">extrapolate</a>
  --parcelPoint: string # The coordinates of a point (x,y) known to be inside the parcel containing a given address. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#parcelPoint target="_blank">parcelPoint</a>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "addressString" $addressString "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "interpolation" $interpolation "scalar") (serialize-qp "echo" $echo "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "autoComplete" $autoComplete "scalar") (serialize-qp "setBack" $setBack "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "minScore" $minScore "scalar") (serialize-qp "matchPrecision" $matchPrecision "scalar") (serialize-qp "matchPrecisionNot" $matchPrecisionNot "scalar") (serialize-qp "siteName" $siteName "scalar") (serialize-qp "unitDesignator" $unitDesignator "scalar") (serialize-qp "unitNumber" $unitNumber "scalar") (serialize-qp "unitNumberSuffix" $unitNumberSuffix "scalar") (serialize-qp "civicNumber" $civicNumber "scalar") (serialize-qp "civicNumberSuffix" $civicNumberSuffix "scalar") (serialize-qp "streetName" $streetName "scalar") (serialize-qp "streetType" $streetType "scalar") (serialize-qp "streetDirection" $streetDirection "scalar") (serialize-qp "streetQualifier" $streetQualifier "scalar") (serialize-qp "localityName" $localityName "scalar") (serialize-qp "provinceCode" $provinceCode "scalar") (serialize-qp "localities" $localities "scalar") (serialize-qp "notLocalities" $notLocalities "scalar") (serialize-qp "bbox" $bbox "scalar") (serialize-qp "centre" $centre "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "extrapolate" $extrapolate "scalar") (serialize-qp "parcelPoint" $parcelPoint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occupants/addresses.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find occupants of sites near to a geographic point
#
# GET /occupants/near.{outputFormat}
export def "occupants-near-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --tags: string # Example: schools;courts;employment<br>A list of tags separated by semicolons.
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occupants/near.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find occupants of the site nearest to a geographic point
#
# GET /occupants/nearest.{outputFormat}
export def "occupants-nearest-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # The point (x,y) from which the nearest site will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --tags: string # Example: schools;courts;employment<br>A list of tags separated by semicolons.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occupants/nearest.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find occupants of sites in a geographic area
#
# GET /occupants/within.{outputFormat}
export def "occupants-within-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#bbox target="_blank">bbox</a> (e.g. -123.14,49.28,-123.13,49.29)
  --tags: string # Example: schools;courts;employment<br>A list of tags separated by semicolons.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results to return. (default: 200)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occupants/within.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an occupant (of a site) by its unique ID
#
# GET /occupants/{occupantID}.{outputFormat}
export def "occupants get" [
  occupantID: string
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occupants/($occupantID).($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a comma-separated string of all pids for a given site
#
# GET /parcels/pids/{siteID}.{outputFormat}
export def "parcels-pids get" [
  siteID: string
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/parcels/pids/($siteID).($outputFormat)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find sites near to a geographic point
#
# GET /sites/near.{outputFormat}
export def "sites-near-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # The point (x,y) from which the nearby sites will be identified. The coordinates must be specified in the same SRS as given by the 'outputSRS' parameter. (e.g. -122.377,50.121)
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --excludeUnits: string@bool-completer # If true, excludes sites that are units of a parent site (default: false)
  --onlyCivic: string@bool-completer # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "setBack" $setBack "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $excludeUnits "scalar") (serialize-qp "onlyCivic" $onlyCivic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/near.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find the site nearest to a geographic point
#
# GET /sites/nearest.{outputFormat}
export def "sites-nearest-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --point: string # Centre point of search. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#point target="_blank">point</a> (e.g. -122.377,50.121)
  --maxDistance: int # The maximum distance (in metres) to search from the given point.  If not specified, the search distance is unlimited.
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --excludeUnits: string@bool-completer # If true, excludes sites that are units of a parent site (default: false)
  --onlyCivic: string@bool-completer # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "maxDistance" $maxDistance "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "setBack" $setBack "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $excludeUnits "scalar") (serialize-qp "onlyCivic" $onlyCivic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/nearest.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find sites in a geographic area
#
# GET /sites/within.{outputFormat}
export def "sites-within-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bbox: string # A bounding box (xmin,ymin,xmax,ymax) used to limit the search area. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#bbox target="_blank">bbox</a> (e.g. -119.51,49.48,-119.53,49.50)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --maxResults: int # The maximum number of search results to return. (default: 1)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --excludeUnits: string@bool-completer # If true, excludes sites that are units of a parent site (default: false)
  --onlyCivic: string@bool-completer # If true, excludes sites without a civic address (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bbox" $bbox "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "setBack" $setBack "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "excludeUnits" $excludeUnits "scalar") (serialize-qp "onlyCivic" $onlyCivic "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/within.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a site by its unique ID
#
# GET /sites/{siteID}.{outputFormat}
export def "sites get" [
  siteID: string
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($siteID).($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Represents all subsites of a given site
#
# GET /sites/{siteID}/subsites.{outputFormat}
export def "sites-subsites-output-format get" [
  siteID: string
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --locationDescriptor: string@locationDescriptor-completer # Describes the nature of the address location. See <a href=https://github.com/bcgov/ols-geocoder/blob/gh-pages/glossary.md#locationDescriptor target="_blank">locationDescriptor</a> (default: any)
  --brief: string@bool-completer # If true, include only basic match and address details in results. Not supported for shp, csv, and gml formats. (default: false)
  --setBack: int # The distance to move the accessPoint away from the curb and towards the inside of the parcel (in metres). Ignored if locationDescriptor not set to accessPoint. (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "locationDescriptor" $locationDescriptor "scalar") (serialize-qp "brief" $brief "scalar") (serialize-qp "setBack" $setBack "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sites/($siteID)/subsites.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
