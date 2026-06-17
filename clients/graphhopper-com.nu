# Auto-generated client for GraphHopper Directions API v1.0.0
# Source: https://api.apis.guru/v2/specs/graphhopper.com/1.0.0/openapi.json
# Auth: --token flag or $env.GRAPHHOPPER_DIRECTIONS_API_TOKEN

const BASE_URL = "https://graphhopper.com/api/1"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GRAPHHOPPER_DIRECTIONS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://graphhopper.com/api/1"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def vehicle-completer [] { ["bike" "car" "foot" "hike" "mtb" "racingbike" "scooter" "small_truck" "truck"] }
def weighting-completer [] { ["fastest" "shortest"] }
def algorithm-completer [] { ["alternative_route" "round_trip"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cluster solveClusteringProblem" } } | get name | first)
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

# POST Cluster Endpoint
#
# POST /cluster
# operationId: solveClusteringProblem
# --configuration shape: {clustering?: record, response_type?: string, routing?: record}
# --customers item shape: {address?: record, id?: string, quantity?: float}
export def "cluster solveClusteringProblem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: record # shape: {clustering?: record, response_type?: string, routing?: record}
  --customers: list # item shape: {address?: record, id?: string, quantity?: float}
]: any -> record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster")
  let body = {"configuration": $configuration, "customers": $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch Cluster Endpoint
#
# POST /cluster/calculate
# operationId: asyncClusteringProblem
# --configuration shape: {clustering?: record, response_type?: string, routing?: record}
# --customers item shape: {address?: record, id?: string, quantity?: float}
export def "cluster-calculate asyncClusteringProblem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration: record # shape: {clustering?: record, response_type?: string, routing?: record}
  --customers: list # item shape: {address?: record, id?: string, quantity?: float}
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cluster/calculate")
  let body = {"configuration": $configuration, "customers": $customers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET Batch Solution Endpoint
#
# GET /cluster/solution/{jobId}
# operationId: getClusterSolution
export def "cluster-solution get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clusters: table<ids: list, quantity: float>, copyrights: list<string>, processing_time: float, status: string, waiting_time_in_queue: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/cluster/solution/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Geocoding Endpoint
#
# GET /geocode
# operationId: getGeocode
export def "geocode get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # If you do forward geocoding, this is `required` and is a textual description of the address you are looking for.
  --locale: string # Display the search results for the specified locale. Currently French (fr), English (en), German (de) and Italian (it) are supported. If the locale wasn't found the default (en) is used. (default: en)
  --limit: int # Specify the maximum number of results to return (format: int32, default: 10)
  --reverse: oneof<nothing, bool> # It is `required` to be `true` if you want to do a reverse geocoding request. If it is `true`, `point` must be defined as well, and `q` must not be used. (default: false)
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted. (default: false)
  --point: string # _Forward geocoding_: The location bias in the format 'latitude,longitude' e.g. point=45.93272,11.58803. _Reverse geocoding_: The location to find amenities, cities.
  --provider: string # The provider parameter is currently under development and can fall back to `default` at any time. The intend is to provide alternatives to our default geocoder. Each provider has its own strenghts and might fit better for certain scenarios, so it's worth to compare the different providers. To try it append the `provider`parameter to the URL like `&provider=nominatim`, the result structure should be identical in all cases - if not, please report this back to us. Keep in mind that some providers do not support certain parameters or don't return some fields, for example `osm_id` and `osm_type` are not supported by every geocoding provider. If you would like to use additional parameters of one of the providers, but it's not available for the GraphHopper Geocoding API, yet? Please contact us.  The credit costs can be different for all providers - see [here](https://support.graphhopper.com/support/solutions/articles/44000718211-what-is-one-credit-) for more information about it.  Currently, only the default provider and gisgraphy supports autocompletion of partial search strings.  All providers support normal "forward" geocoding and reverse geocoding via `reverse=true`.  #### Default (`provider=default`)  This provider returns results of our internal geocoding engine, as described above. In addition to the above documented parameters the following parameters are possible: * `bbox` - the expected format is `minLon,minLat,maxLon,maxLat` * `osm_tag` - you can filter `key:value` or exclude places with certain OpenStreetMap tags `!key:value`. E.g. `osm_tag=tourism:museum` or just the key `osm_tag=tourism`. To exclude multiple tags you add multiple `osm_tag` parameters.  #### Nominatim (`provider=nominatim`)  The GraphHopper Directions API uses a commercially hosted Nominatim geocoder. You can try this provider [here](https://nominatim.openstreetmap.org/). The provider does **not** fall under the [restrictions](https://operations.osmfoundation.org/policies/nominatim/) of the Nominatim instance hosted by OpenStreetMap.  In addition to the above documented parameters Nominatim allows to use the following parameters, which can be used as documented [here](https://github.com/openstreetmap/Nominatim/blob/master/docs/api/Search.md#parameters):  * `viewbox` - the expected format is `minLon,minLat,maxLon,maxLat` * `bounded` - If 1 and a viewbox is given, restrict the result to items contained within that viewbox. Default is 0.  #### Gisgraphy (`provider=gisgraphy`)  This provider returns results from the Gisgraphy geocoder which you can try [here](https://services.gisgraphy.com/static/leaflet/index.html).  **Limitations:** The `locale` parameter is not supported. Gisgraphy does not return OSM tags or an extent.  Gisgraphy has a special autocomplete API, which you can use by adding `autocomplete=true` (does not work with `reverse=true`). The autocomplete API is optimized on predicting text input, but returns less information.  In addition to the above documented parameters Gisgraphy allows to use the following parameters, which can be used as documented [here](https://www.gisgraphy.com/documentation/user-guide.php#geocodingservice):  * `radius` - radius in meters * `country` - restrict search for the specified country. The value must be the ISO 3166 Alpha 2 code of the country.  #### NetToolKit (`provider=nettoolkit`)  This provider returns results from the NetToolKit provider which is specialized for US addresses and provides a wrapper around Nominatim for other addresses. You can try it [here](https://www.nettoolkit.com/geo/demo).  The following additional NetToolKit parameters are supported (read [here](https://www.nettoolkit.com/docs/geo/geocoding) for more details): - `source`: User can choose which source provider to geocode the address, this value is "NetToolKit" by default - `country_code`: an iso-3166-2 country code (e.g : US) filter the results to the specify country code  **Limitations:** NetToolKit does not support the `locale` parameter. NetToolKit does not return OSM tags (e.g. osm_id, osm_type, osm_value).  #### OpenCage Data (`provider=opencagedata`)  This provider returns results from the OpenCageData geocoder which you can try [here](https://geocoder.opencagedata.com/demo).  In addition to the above documented parameters OpenCage Data allows to use the following parameters, which can be used as documented [here](https://geocoder.opencagedata.com/api#forward-opt):  * countrycode - The country code is a two letter code as defined by the ISO 3166-1 Alpha 2 standard. E.g. gb for the United Kingdom, fr for France, us for United States.  * bounds - the expected format is `minLon,minLat,maxLon,maxLat`  (default: default)
]: nothing -> record<hits: table<city: string, country: string, housenumber: string, name: string, osm_id: string, osm_key: string, osm_type: string, point: record, postcode: string, state: string, street: string>, took: float> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "reverse" $reverse "scalar") (serialize-qp "debug" $debug "scalar") (serialize-qp "point" $point "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Isochrone Endpoint
#
# GET /isochrone
# operationId: getIsochrone
export def "isochrone get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: string # Specify the start coordinate
  --time-limit: int # Specify which time the vehicle should travel. In seconds. (format: int32, default: 600)
  --distance-limit: int # Specify which distance the vehicle should travel. In meters. (format: int32)
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated.  (default: car)
  --buckets: int # Number by which to divide the given `time_limit` to create `buckets` nested isochrones of time intervals `time_limit-n*time_limit/buckets`. Applies analogously to `distance_limit`. (format: int32, default: 1)
  --reverse-flow: oneof<nothing, bool> # If `false` the flow goes from point to the polygon, if `true` the flow goes from the polygon "inside" to the point. Example use case for `false`&#58; *How many potential customer can be reached within 30min travel time from your store* vs. `true`&#58; *How many customers can reach your store within 30min travel time.*  (default: false)
  --weighting: string@weighting-completer # Use `"shortest"` to get an isodistance line instead of an isochrone. (default: fastest)
]: nothing -> record<copyrights: list<string>, polygons: table<geometry: record, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "scalar") (serialize-qp "time_limit" $time_limit "scalar") (serialize-qp "distance_limit" $distance_limit "scalar") (serialize-qp "vehicle" $vehicle "scalar") (serialize-qp "buckets" $buckets "scalar") (serialize-qp "reverse_flow" $reverse_flow "scalar") (serialize-qp "weighting" $weighting "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/isochrone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Map-match a GPX file
#
# POST /match
# operationId: postGPX
export def "match create-gpx" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gps-accuracy: int # Specify the precision of a point, in meter
  --vehicle: string # Specify the vehicle profile like car
]: nothing -> record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gps_accuracy" $gps_accuracy "scalar") (serialize-qp "vehicle" $vehicle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET Matrix Endpoint
#
# GET /matrix
# operationId: getMatrix
export def "matrix get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: list # Specify multiple points in `latitude,longitude` for which the weight-, route-, time- or distance-matrix should be calculated. In this case the starts are identical to the destinations. If there are N points, then NxN entries will be calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with from_point or to_point.
  --from-point: list # The starting points for the routes in `latitude,longitude`. E.g. if you want to calculate the three routes A-&gt;1, A-&gt;2, A-&gt;3 then you have one from_point parameter and three to_point parameters.
  --to-point: list # The destination points for the routes in `latitude,longitude`.
  --point-hint: list # Optional parameter. Specifies a hint for each `point` parameter to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --from-point-hint: list # For the from_point parameter. See point_hint
  --to-point-hint: list # For the to_point parameter. See point_hint
  --snap-prevention: list # Optional parameter to avoid snapping to a certain road class or road environment. Current supported values `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford`. Multiple values are specified like `snap_prevention=ferry&snap_prevention=motorway`
  --curbside: list # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --from-curbside: list # Curbside setting for the from_point parameter. See curbside.
  --to-curbside: list # Curbside setting for the to_point parameter. See curbside.
  --out-array: list # Specifies which arrays should be included in the response. Specify one or more of the following options 'weights', 'times', 'distances'. To specify more than one array use e.g. out_array=times&out_array=distances. The units of the entries of distances are meters, of times are seconds and of weights is arbitrary and it can differ for different vehicles or versions of this API.
  --vehicle: string@vehicle-completer # The vehicle profile for which the matrix should be calculated. (default: car)
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
]: nothing -> record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "multi") (serialize-qp "from_point" $from_point "multi") (serialize-qp "to_point" $to_point "multi") (serialize-qp "point_hint" $point_hint "multi") (serialize-qp "from_point_hint" $from_point_hint "multi") (serialize-qp "to_point_hint" $to_point_hint "multi") (serialize-qp "snap_prevention" $snap_prevention "multi") (serialize-qp "curbside" $curbside "multi") (serialize-qp "from_curbside" $from_curbside "multi") (serialize-qp "to_curbside" $to_curbside "multi") (serialize-qp "out_array" $out_array "multi") (serialize-qp "vehicle" $vehicle "scalar") (serialize-qp "fail_fast" $fail_fast "scalar") (serialize-qp "turn_costs" $turn_costs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matrix" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST Matrix Endpoint
#
# POST /matrix
# operationId: postMatrix
export def "matrix create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --from-curbsides: list # See `curbsides`of symmetrical matrix
  --from-point-hints: list # See `point_hints`of symmetrical matrix
  --from-points: list # The starting points for the routes in an array of `[longitude,latitude]`. For instance, if you want to calculate three routes from point A such as A->1, A->2, A->3 then you have one `from_point` parameter and three `to_point` parameters.
  --out-arrays: list # Specifies which matrices should be included in the response. Specify one or more of the following options `weights`, `times`, `distances`. The units of the entries of `distances` are meters, of `times` are seconds and of `weights` is arbitrary and it can differ for different vehicles or versions of this API.
  --snap-preventions: list # See `snap_preventions` of symmetrical matrix
  --to-curbsides: list # See `curbsides`of symmetrical matrix
  --to-point-hints: list # See `point_hints`of symmetrical matrix
  --to-points: list # The destination points for the routes in an array of `[longitude,latitude]`.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
  --vehicle: any
  --curbsides: list # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --point-hints: list # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --points: list # Specify multiple points for which the weight-, route-, time- or distance-matrix should be calculated as follows: `[longitude,latitude]`. In this case the origins are identical to the destinations. Thus, if there are N points, NxN entries are calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with `from_point` or `to_point.`.
]: any -> record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/matrix")
  let body = {"fail_fast": $fail_fast, "from_curbsides": $from_curbsides, "from_point_hints": $from_point_hints, "from_points": $from_points, "out_arrays": $out_arrays, "snap_preventions": $snap_preventions, "to_curbsides": $to_curbsides, "to_point_hints": $to_point_hints, "to_points": $to_points, "turn_costs": $turn_costs, "vehicle": $vehicle, "curbsides": $curbsides, "point_hints": $point_hints, "points": $points} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch Matrix Endpoint
#
# POST /matrix/calculate
# operationId: calculateMatrix
export def "matrix-calculate calculateMatrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fail-fast: oneof<nothing, bool> # Specifies whether or not the matrix calculation should return with an error as soon as possible in case some points cannot be found or some points are not connected. If set to `false` the time/weight/distance matrix will be calculated for all valid points and contain the `null` value for all entries that could not be calculated. The `hint` field of the response will also contain additional information about what went wrong (see its documentation). (default: true)
  --from-curbsides: list # See `curbsides`of symmetrical matrix
  --from-point-hints: list # See `point_hints`of symmetrical matrix
  --from-points: list # The starting points for the routes in an array of `[longitude,latitude]`. For instance, if you want to calculate three routes from point A such as A->1, A->2, A->3 then you have one `from_point` parameter and three `to_point` parameters.
  --out-arrays: list # Specifies which matrices should be included in the response. Specify one or more of the following options `weights`, `times`, `distances`. The units of the entries of `distances` are meters, of `times` are seconds and of `weights` is arbitrary and it can differ for different vehicles or versions of this API.
  --snap-preventions: list # See `snap_preventions` of symmetrical matrix
  --to-curbsides: list # See `curbsides`of symmetrical matrix
  --to-point-hints: list # See `point_hints`of symmetrical matrix
  --to-points: list # The destination points for the routes in an array of `[longitude,latitude]`.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the matrix computation time. Only supported for motor vehicles and OpenStreetMap. (default: false)
  --vehicle: any
  --curbsides: list # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --point-hints: list # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up.
  --points: list # Specify multiple points for which the weight-, route-, time- or distance-matrix should be calculated as follows: `[longitude,latitude]`. In this case the origins are identical to the destinations. Thus, if there are N points, NxN entries are calculated. The order of the point parameter is important. Specify at least three points. Cannot be used together with `from_point` or `to_point.`.
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/matrix/calculate")
  let body = {"fail_fast": $fail_fast, "from_curbsides": $from_curbsides, "from_point_hints": $from_point_hints, "from_points": $from_points, "out_arrays": $out_arrays, "snap_preventions": $snap_preventions, "to_curbsides": $to_curbsides, "to_point_hints": $to_point_hints, "to_points": $to_points, "turn_costs": $turn_costs, "vehicle": $vehicle, "curbsides": $curbsides, "point_hints": $point_hints, "points": $points} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET Batch Matrix Endpoint
#
# GET /matrix/solution/{jobId}
# operationId: getMatrixSolution
export def "matrix-solution get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<distances: list<list<float>>, hints: table<details: string, invalid_from_points: list, invalid_to_points: list, message: string, point_pairs: list>, info: record<copyrights: list<string>, took: float>, times: list<list<float>>, weights: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/matrix/solution/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET Route Endpoint
#
# GET /route
# operationId: getRoute
export def "route get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --point: list # The points for which the route should be calculated. Format: `[latitude,longitude]`. Specify at least an origin and a destination. Via points are possible. The maximum number depends on your plan.
  --point-hint: list # The `point_hint` is typically a road name to which the associated `point` parameter should be snapped to. Specify no `point_hint` parameter or the same number as you have `point` parameters.
  --snap-prevention: list # Optional parameter to avoid snapping to a certain road class or road environment. Currently supported values are `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford`. Multiple values are specified like `snap_prevention=ferry&snap_prevention=motorway`.
  --vehicle: string@vehicle-completer # The vehicle profile for which the route should be calculated.  (default: car)
  --curbside: list # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap.
  --turn-costs: oneof<nothing, bool> # Specifies if turn restrictions should be considered. Enabling this option increases the route computation time. Only supported for motor vehicles and OpenStreetMap.  (default: false)
  --locale: string # The locale of the resulting turn instructions. E.g. `pt_PT` for Portuguese or `de` for German.  (default: en)
  --elevation: oneof<nothing, bool> # If `true`, a third coordinate, the altitude, is included with all positions in the response. This changes the format of the `points` and `snapped_waypoints` fields of the response, in both their encodings. Unless you switch off the `points_encoded` parameter, you need special code on the client side that can handle three-dimensional coordinates. A request can fail if the vehicle profile does not support elevation. See the features object for every vehicle profile.  (default: false)
  --details: list # Optional parameter to retrieve path details. You can request additional details for the route: `street_name`,  `time`, `distance`, `max_speed`, `toll`, `road_class`, `road_class_link`, `road_access`, `road_environment`, `lanes`, and `surface`. Read more about the usage of path details [here](https://discuss.graphhopper.com/t/2539).
  --optimize: string # Normally, the calculated route will visit the points in the order you specified them. If you have more than two points, you can set this parameter to `"true"` and the points may be re-ordered to minimize the total travel time. Keep in mind that the limits on the number of locations of the Route Optimization API applies, and the request costs more credits.  (default: false)
  --instructions: oneof<nothing, bool> # If instructions should be calculated and returned  (default: true)
  --calc-points: oneof<nothing, bool> # If the points for the route should be calculated at all.  (default: true)
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted.  (default: false)
  --points-encoded: oneof<nothing, bool> # Allows changing the encoding of location data in the response. The default is polyline encoding, which is compact but requires special client code to unpack. (We provide it in our JavaScript client library!) Set this parameter to `false` to switch the encoding to simple coordinate pairs like `[lon,lat]`, or `[lon,lat,elevation]`. See the description of the response format for more information.  (default: true)
  --ch-disable: oneof<nothing, bool> # Use this parameter in combination with one or more parameters from below.  (default: false)
  --weighting: string # Determines the way the "best" route is calculated. Besides `fastest` you can use `short_fastest` which finds a reasonable balance between the distance influence (`shortest`) and the time (`fastest`). You could also use `shortest` but is deprecated and not recommended for motor vehicles. All except `fastest` require `ch.disable=true`.  (default: fastest)
  --heading: list # Favour a heading direction for a certain point. Specify either one heading for the start point or as many as there are points. In this case headings are associated by their order to the specific points. Headings are given as north based clockwise angle between 0 and 360 degree. This parameter also influences the tour generated with `algorithm=round_trip` and forces the initial direction.  Requires `ch.disable=true`.
  --heading-penalty: int # Time penalty in seconds for not obeying a specified heading. Requires `ch.disable=true`.  (format: int32, default: 120)
  --pass-through: oneof<nothing, bool> # If `true`, u-turns are avoided at via-points with regard to the `heading_penalty`. Requires `ch.disable=true`.  (default: false)
  --block-area: string # Block road access by specifying a point close to the road segment to be blocked, with the format `lat,lon`. You can also block all road segments crossing a geometric shape. Specify a circle using the format `lat,lon,radius`, or a polygon using the format `lat1,lon1,lat2,lon2,...,latN,lonN`. You can specify several shapes, separating them with `;`. Requires `ch.disable=true`.
  --avoid: string # Specify which road classes and environments you would like to avoid.  Possible values are `motorway`, `steps`, `track`, `toll`, `ferry`, `tunnel` and `bridge`. Separate several values with `;`. Obviously not all the values make sense for all vehicle profiles e.g. `bike` is already forbidden on a `motorway`. Requires `ch.disable=true`.
  --algorithm: string@algorithm-completer # Rather than looking for the shortest or fastest path, this parameter lets you solve two different problems related to routing: With `alternative_route`, we give you not one but several routes that are close to optimal, but not too similar to each other.  With `round_trip`, the route will get you back to where you started. This is meant for fun (think of a bike trip), so we will add some randomness. The `round_trip` option requires `ch.disable=true`. You can control both of these features with additional parameters, see below. 
  --round-trip-distance: int # If `algorithm=round_trip`, this parameter configures approximative length of the resulting round trip. Requires `ch.disable=true`.  (format: int32, default: 10000)
  --round-trip-seed: int # If `algorithm=round_trip`, this sets the random seed. Change this to get a different tour for each value.  (format: int64)
  --alternative-route-max-paths: int # If `algorithm=alternative_route`, this parameter sets the number of maximum paths which should be calculated. Increasing can lead to worse alternatives.  (format: int32, default: 2)
  --alternative-route-max-weight-factor: float # If `algorithm=alternative_route`, this parameter sets the factor by which the alternatives routes can be longer than the optimal route. Increasing can lead to worse alternatives.  (default: 1.4)
  --alternative-route-max-share-factor: float # If `algorithm=alternative_route`, this parameter specifies how similar an alternative route can be to the optimal route. Increasing can lead to worse alternatives.  (default: 0.6)
]: nothing -> record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point" $point "multi") (serialize-qp "point_hint" $point_hint "multi") (serialize-qp "snap_prevention" $snap_prevention "multi") (serialize-qp "vehicle" $vehicle "scalar") (serialize-qp "curbside" $curbside "multi") (serialize-qp "turn_costs" $turn_costs "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "elevation" $elevation "scalar") (serialize-qp "details" $details "multi") (serialize-qp "optimize" $optimize "scalar") (serialize-qp "instructions" $instructions "scalar") (serialize-qp "calc_points" $calc_points "scalar") (serialize-qp "debug" $debug "scalar") (serialize-qp "points_encoded" $points_encoded "scalar") (serialize-qp "ch.disable" $ch_disable "scalar") (serialize-qp "weighting" $weighting "scalar") (serialize-qp "heading" $heading "multi") (serialize-qp "heading_penalty" $heading_penalty "scalar") (serialize-qp "pass_through" $pass_through "scalar") (serialize-qp "block_area" $block_area "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "algorithm" $algorithm "scalar") (serialize-qp "round_trip.distance" $round_trip_distance "scalar") (serialize-qp "round_trip.seed" $round_trip_seed "scalar") (serialize-qp "alternative_route.max_paths" $alternative_route_max_paths "scalar") (serialize-qp "alternative_route.max_weight_factor" $alternative_route_max_weight_factor "scalar") (serialize-qp "alternative_route.max_share_factor" $alternative_route_max_share_factor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/route" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST Route Endpoint
#
# POST /route
# operationId: postRoute
export def "route create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: string@algorithm-completer # Rather than looking for the shortest or fastest path, this lets you solve two different problems related to routing: With `round_trip`, the route will get you back to where you started. This is meant for fun (think of a bike trip), so we will add some randomness. This requires `ch.disable=true`. With `alternative_route`, we give you not one but several routes that are close to optimal, but not too similar to each other. You can control both of these features with additional parameters, see below.
  --alternative-route-max-paths: int # If `algorithm=alternative_route`, this parameter sets the number of maximum paths which should be calculated. Increasing can lead to worse alternatives.  (format: int32, default: 2)
  --alternative-route-max-share-factor: float # If `algorithm=alternative_route`, this parameter specifies how similar an alternative route can be to the optimal route. Increasing can lead to worse alternatives.  (default: 0.6)
  --alternative-route-max-weight-factor: float # If `algorithm=alternative_route`, this parameter sets the factor by which the alternatives routes can be longer than the optimal route. Increasing can lead to worse alternatives.  (default: 1.4)
  --avoid: string # Specify which road classes and environments you would like to avoid. Possible values are `motorway`, `steps`, `track`, `toll`, `ferry`, `tunnel` and `bridge`. Separate several values with `;`. Obviously not all the values make sense for all vehicle profiles e.g. `bike` is already forbidden on a `motorway`. Requires `ch.disable=true`.
  --block-area: string # Block road access via a point with the format `latitude,longitude` or an area defined by a circle `lat,lon,radius` or a rectangle `lat1,lon1,lat2,lon2`. Separate several values with `;`. Requires `ch.disable=true`.
  --calc-points: oneof<nothing, bool> # If the points for the route should be calculated at all.  (default: true)
  --ch-disable: oneof<nothing, bool> # Use this parameter in combination with one or more parameters from below.  (default: false)
  --curbsides: list # Optional parameter. It specifies on which side a point should be relative to the driver when she leaves/arrives at a start/target/via point. You need to specify this parameter for either none or all points. Only supported for motor vehicles and OpenStreetMap. (e.g. [any, right])
  --debug: oneof<nothing, bool> # If `true`, the output will be formatted.  (default: false)
  --details: list # Optional parameter to retrieve path details. You can request additional details for the route: `street_name`, `time`, `distance`, `max_speed`, `toll`, `road_class`, `road_class_link`, `road_access`, `road_environment`, `lanes`, and `surface`. Read more about the usage of path details [here](https://discuss.graphhopper.com/t/2539).
  --elevation: oneof<nothing, bool> # If `true`, a third coordinate, the altitude, is included with all positions in the response. This changes the format of the `points` and `snapped_waypoints` fields of the response, in both their encodings. Unless you switch off the `points_encoded` parameter, you need special code on the client side that can handle three-dimensional coordinates. A request can fail if the vehicle profile does not support elevation. See the features object for every vehicle profile.  (default: false)
  --heading-penalty: int # Time penalty in seconds for not obeying a specified heading. Requires `ch.disable=true`.  (format: int32, default: 120)
  --headings: list # Favour a heading direction for a certain point. Specify either one heading for the start point or as many as there are points. In this case headings are associated by their order to the specific points. Headings are given as north based clockwise angle between 0 and 360 degree. This parameter also influences the tour generated with `algorithm=round_trip` and forces the initial direction.  Requires `ch.disable=true`.
  --instructions: oneof<nothing, bool> # If instructions should be calculated and returned  (default: true)
  --locale: string # The locale of the resulting turn instructions. E.g. `pt_PT` for Portuguese or `de` for German.  (default: en)
  --optimize: string # Normally, the calculated route will visit the points in the order you specified them. If you have more than two points, you can set this parameter to `"true"` and the points may be re-ordered to minimize the total travel time. Keep in mind that the limits on the number of locations of the Route Optimization API applies, and the request costs more credits.  (default: false)
  --pass-through: oneof<nothing, bool> # If `true`, u-turns are avoided at via-points with regard to the `heading_penalty`. Requires `ch.disable=true`.  (default: false)
  --point-hints: list # Optional parameter. Specifies a hint for each point in the `points` array to prefer a certain street for the closest location lookup. E.g. if there is an address or house with two or more neighboring streets you can control for which street the closest location is looked up. (e.g. [Lindenschmitstraße, Thalkirchener Str.])
  --points: list # The points for the route in an array of `[longitude,latitude]`. For instance, if you want to calculate a route from point A to B to C then you specify `points: [ [A_longitude, A_latitude], [B_longitude, B_latitude], [C_longitude, C_latitude]]  (e.g. [[11.539421, 48.118477], [11.559023, 48.12228]])
  --points-encoded: oneof<nothing, bool> # Allows changing the encoding of location data in the response. The default is polyline encoding, which is compact but requires special client code to unpack. (We provide it in our JavaScript client library!) Set this parameter to `false` to switch the encoding to simple coordinate pairs like `[lon,lat]`, or `[lon,lat,elevation]`. See the description of the response format for more information.  (default: true)
  --round-trip-distance: int # If `algorithm=round_trip`, this parameter configures approximative length of the resulting round trip. Requires `ch.disable=true`.  (format: int32, default: 10000)
  --round-trip-seed: int # If `algorithm=round_trip`, this sets the random seed. Change this to get a different tour for each value.  (format: int64)
  --snap-preventions: list # Optional parameter to avoid snapping to a certain road class or road environment. Current supported values `motorway`, `trunk`, `ferry`, `tunnel`, `bridge` and `ford` (e.g. [motorway, ferry, tunnel])
  --vehicle: any # e.g. bike
  --weighting: string # Determines the way the ''best'' route is calculated. Default is `fastest`. Other options are `shortest` (e.g. for `vehicle=foot` or `bike`) and `short_fastest` which finds a reasonable balance between `shortest` and `fastest`. Requires `ch.disable=true`.  (default: fastest)
]: any -> record<info: record<copyrights: list<string>, took: float>, paths: table<ascend: float, bbox: list, descend: float, details: record, distance: float, instructions: list, points: record, points_encoded: bool, points_order: list, snapped_waypoints: record, time: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route")
  let body = {"algorithm": $algorithm, "alternative_route.max_paths": $alternative_route_max_paths, "alternative_route.max_share_factor": $alternative_route_max_share_factor, "alternative_route.max_weight_factor": $alternative_route_max_weight_factor, "avoid": $avoid, "block_area": $block_area, "calc_points": $calc_points, "ch.disable": $ch_disable, "curbsides": $curbsides, "debug": $debug, "details": $details, "elevation": $elevation, "heading_penalty": $heading_penalty, "headings": $headings, "instructions": $instructions, "locale": $locale, "optimize": $optimize, "pass_through": $pass_through, "point_hints": $point_hints, "points": $points, "points_encoded": $points_encoded, "round_trip.distance": $round_trip_distance, "round_trip.seed": $round_trip_seed, "snap_preventions": $snap_preventions, "vehicle": $vehicle, "weighting": $weighting} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Coverage information
#
# GET /route/info
export def "route-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bbox: string, features: record, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST route optimization problem
#
# POST /vrp
# operationId: solveVRP
# --algorithm shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
# --configuration shape: {routing?: record}
# --cost_matrices item shape: {data?: record, location_ids?: list, profile?: string, type?: "default"|"google"}
# --objectives item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
# --services item shape: {address?: record, allowed_vehicles?: list, disallowed_vehicles?: list, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list, size?: list, time_windows?: list, type?: "service"|"pickup"|"delivery"}
# --shipments item shape: {allowed_vehicles?: list, delivery: record, disallowed_vehicles?: list, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list, size?: list}
# --vehicle_types item shape: {capacity?: list, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: any, service_time_factor?: float, speed_factor?: float, type_id: string}
# --vehicles item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list, start_address: record, type_id?: string, vehicle_id: string}
@deprecated --flag algorithm
export def "vrp solveVRP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: record # Use `objectives` instead. (DEPRECATED) — shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
  --configuration: record # Specifies general configurations that are taken into account when solving the vehicle routing problem. — shape: {routing?: record}
  --cost-matrices: list # Specifies your own tranport time and distance matrices. (e.g. [{data: {distances: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]], times: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]]}, location_ids: [start, Dammstrasse, Bergstrasse, Koppstrasse, start2, nirvana], profile: car}]) — item shape: {data?: record, location_ids?: list, profile?: string, type?: "default"|"google"}
  --objectives: list # Specifies an objective function. The vehicle routing problem is solved in such a way that this objective function is minimized. (e.g. [{type: min, value: vehicles}, {type: min, value: completion_time}]) — item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
  --relations: list # Defines additional relationships between orders.
  --services: list # Specifies the orders of the type "service". These are, for example, pick-ups, deliveries or other stops that are to be approached by the specified vehicles. Each of these orders contains only one location. — item shape: {address?: record, allowed_vehicles?: list, disallowed_vehicles?: list, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list, size?: list, time_windows?: list, type?: "service"|"pickup"|"delivery"}
  --shipments: list # Specifies the available shipments. Each shipment contains a pickup and a delivery stop, which must be processed one after the other. — item shape: {allowed_vehicles?: list, delivery: record, disallowed_vehicles?: list, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list, size?: list}
  --vehicle-types: list # Specifies the available vehicle types. These types can be assigned to vehicles. — item shape: {capacity?: list, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: any, service_time_factor?: float, speed_factor?: float, type_id: string}
  --vehicles: list # Specifies the available vehicles. — item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list, start_address: record, type_id?: string, vehicle_id: string}
]: any -> record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vrp")
  let body = {"algorithm": $algorithm, "configuration": $configuration, "cost_matrices": $cost_matrices, "objectives": $objectives, "relations": $relations, "services": $services, "shipments": $shipments, "vehicle_types": $vehicle_types, "vehicles": $vehicles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST route optimization problem (batch mode)
#
# POST /vrp/optimize
# operationId: asyncVRP
# --algorithm shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
# --configuration shape: {routing?: record}
# --cost_matrices item shape: {data?: record, location_ids?: list, profile?: string, type?: "default"|"google"}
# --objectives item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
# --services item shape: {address?: record, allowed_vehicles?: list, disallowed_vehicles?: list, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list, size?: list, time_windows?: list, type?: "service"|"pickup"|"delivery"}
# --shipments item shape: {allowed_vehicles?: list, delivery: record, disallowed_vehicles?: list, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list, size?: list}
# --vehicle_types item shape: {capacity?: list, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: any, service_time_factor?: float, speed_factor?: float, type_id: string}
# --vehicles item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list, start_address: record, type_id?: string, vehicle_id: string}
@deprecated --flag algorithm
export def "vrp-optimize asyncVRP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --algorithm: record # Use `objectives` instead. (DEPRECATED) — shape: {objective?: "transport_time"|"completion_time", problem_type?: "min"|"min-max"}
  --configuration: record # Specifies general configurations that are taken into account when solving the vehicle routing problem. — shape: {routing?: record}
  --cost-matrices: list # Specifies your own tranport time and distance matrices. (e.g. [{data: {distances: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]], times: [[0, 1000, 1400, 2000, 0, 4000], [1000, 0, 1000, 2100, 1000, 4000], [1400, 1000, 0, 1100, 1100, 4000], [2000, 2100, 1100, 0, 1200, 4000], [0, 1000, 1400, 2000, 0, 4000], [4000, 4000, 4000, 4000, 4000, 4000]]}, location_ids: [start, Dammstrasse, Bergstrasse, Koppstrasse, start2, nirvana], profile: car}]) — item shape: {data?: record, location_ids?: list, profile?: string, type?: "default"|"google"}
  --objectives: list # Specifies an objective function. The vehicle routing problem is solved in such a way that this objective function is minimized. (e.g. [{type: min, value: vehicles}, {type: min, value: completion_time}]) — item shape: {type: "min"|"min-max", value: "completion_time"|"transport_time"|"vehicles"|"activities"}
  --relations: list # Defines additional relationships between orders.
  --services: list # Specifies the orders of the type "service". These are, for example, pick-ups, deliveries or other stops that are to be approached by the specified vehicles. Each of these orders contains only one location. — item shape: {address?: record, allowed_vehicles?: list, disallowed_vehicles?: list, duration?: int, group?: string, id: string, max_time_in_vehicle?: int, name?: string, preparation_time?: int, priority?: int, required_skills?: list, size?: list, time_windows?: list, type?: "service"|"pickup"|"delivery"}
  --shipments: list # Specifies the available shipments. Each shipment contains a pickup and a delivery stop, which must be processed one after the other. — item shape: {allowed_vehicles?: list, delivery: record, disallowed_vehicles?: list, id: string, max_time_in_vehicle?: int, name?: string, pickup: record, priority?: int, required_skills?: list, size?: list}
  --vehicle-types: list # Specifies the available vehicle types. These types can be assigned to vehicles. — item shape: {capacity?: list, consider_traffic?: bool, cost_per_activation?: float, cost_per_meter?: float, cost_per_second?: float, network_data_provider?: "openstreetmap"|"tomtom", profile?: any, service_time_factor?: float, speed_factor?: float, type_id: string}
  --vehicles: list # Specifies the available vehicles. — item shape: {break?: any, earliest_start?: int, end_address?: record, latest_end?: int, max_activities?: int, max_distance?: int, max_driving_time?: int, max_jobs?: int, min_jobs?: int, move_to_end_address?: bool, return_to_depot?: bool, skills?: list, start_address: record, type_id?: string, vehicle_id: string}
]: any -> record<job_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vrp/optimize")
  let body = {"algorithm": $algorithm, "configuration": $configuration, "cost_matrices": $cost_matrices, "objectives": $objectives, "relations": $relations, "services": $services, "shipments": $shipments, "vehicle_types": $vehicle_types, "vehicles": $vehicles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET the solution (batch mode)
#
# GET /vrp/solution/{jobId}
# operationId: getSolution
export def "vrp-solution get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<copyrights: list<string>, processing_time: int, solution: record<completion_time: int, costs: int, distance: int, max_operation_time: int, no_unassigned: int, no_vehicles: int, preparation_time: int, routes: list<record>, service_duration: int, time: int, transport_time: int, unassigned: record<breaks: list, details: list, services: list, shipments: list>, waiting_time: int>, status: string, waiting_time_in_queue: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/vrp/solution/{job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
