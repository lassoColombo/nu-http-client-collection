# Auto-generated client for Routing API v1.0.0
# Source: https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/routing/routing.yaml
# Auth: --token flag or $env.ROUTING_API_TOKEN

const BASE_URL = "https://api.geoapify.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ROUTING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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
def base-url-completer [] { ["https://api.geoapify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def mode-completer [] { ["approximated_transit" "bicycle" "bus" "drive" "heavy_truck" "hike" "light_truck" "long_truck" "medium_truck" "motorcycle" "mountain_bike" "road_bike" "scooter" "transit" "truck" "truck_dangerous_goods" "walk"] }
def format-completer [] { ["geojson" "json" "xml"] }
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "routing calculateRoute" } } | get name | first)
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

# Calculate a route between waypoints
#
# GET /routing
# operationId: calculateRoute
export def "routing calculateRoute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --apiKey: string # Your Geoapify API key to authenticate the request. You can sign up and obtain an API key for free at [https://myprojects.geoapify.com/](https://myprojects.geoapify.com/). The Free plan includes up to 3,000 requests per day. (e.g. YOUR_API_KEY)
  --waypoints: string # A list of coordinates representing the waypoints for the route. Each coordinate is specified as a latitude, longitude pair.   Multiple waypoints should be separated by a vertical bar (`|`). At least two waypoints (a start and an endpoint) are required, but additional waypoints can be added to customize the route.   Example format:  "50.679023,4.569876|50.661705,4.578667"  (e.g. 50.679023,4.569876|50.661705,4.578667)
  --mode: string@mode-completer # Specifies how the route will be optimized based on the selected transportation type.  Available options include: - `drive`: Standard car or automobile. - `light_truck`: Light-duty truck. - `medium_truck`: Medium-duty truck. - `truck`: General truck. - `heavy_truck`: Heavy-duty truck. - `truck_dangerous_goods`: Truck carrying dangerous goods. - `long_truck`: Long or articulated truck. - `bus`: Public or private bus. - `scooter`: Motorized scooter. - `motorcycle`: Motorbike. - `bicycle`: Standard bicycle. - `mountain_bike`: Mountain bike. - `road_bike`: Road bicycle. - `walk`: Walking on foot. - `hike`: Hiking on trails or difficult terrain. - `transit`: Public transit routes. - `approximated_transit`: Estimated public transit routes (without real-time data).  Choose the appropriate mode for more accurate route calculations.  (e.g. drive)
  --type: string # Specifies the type of route optimization to apply. This parameter determines how the route will be optimized based on user preferences:  - `balanced`: Provides a balanced route, optimizing for both travel time and distance. - `short`: Prioritizes the shortest possible route in terms of distance, potentially ignoring other factors like travel time. - `less_maneuvers`: Reduces the number of turns or complex maneuvers, providing a simpler route, which can be useful for larger vehicles or ease of navigation.
  --units: string # Specifies the units of measurement for distance in the response. Choose between:  - `metric`: Uses kilometers and meters. - `imperial`: Uses miles and feet.  If not specified, the default is `metric`. Select the appropriate units based on the region or user preferences.
  --lang: string # Result language in [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) format (e.g., 'en' for English). (e.g. en)
  --avoid: string # Specifies the types of roads or locations to avoid during route calculation. You can customize this option by adding one or more types, separated by a vertical bar (`|`), and even assign importance to some avoid types on a scale from 0 to 1.  Available options include:  - **tolls**: Avoid roads with tolls. You can specify importance as `tolls:importance`, where `importance` is a value between 0 and 1 (with 1 being the most important). This option works with modes like `drive`, `truck`, `light_truck`, `medium_truck`, `truck_dangerous_goods`, `heavy_truck`, `long_truck`, and `bus`.   - Example: `avoid=tolls` or `avoid=tolls:0.8`  - **ferries**: Avoid routes that include ferries. You can specify importance as `ferries:importance` (similar to tolls).    - Example: `avoid=ferries` or `avoid=ferries:0.9`  - **highways**: Avoid highways. You can also specify importance as `highways:importance`. This option works with driving-related modes.   - Example: `avoid=highways` or `avoid=highways:0.7`  - **location**: Avoid specific geographic locations. You can provide a latitude and longitude pair in the format `location:lat,lon` or `location_lonlat:lon,lat` to avoid certain areas (e.g., closed roads or barriers).   - Example: `avoid=location:35.234045,-80.836392` or `avoid=location_lonlat:-80.836392,35.234045`  Note: The routing algorithm will take your avoids into account but may still include them if there are no alternative routes. Using the `avoid` parameter may increase calculation time and add extra cost to the API call.  (e.g. tolls:1|ferries)
  --details: string # Specifies additional details to include in the response. You can request multiple types of information, separated by commas. Available options include:  - `instruction_details`: Provides more granular step-by-step navigation instructions. - `route_details`: Includes detailed information about the route, such as distances and durations for each segment. - `elevation`: Adds elevation data along the route, showing the changes in altitude.  You can combine these options as needed to get more comprehensive routing information.  (e.g. instruction_details,route_details)
  --traffic: string # Specifies the traffic model to use during route calculation. The available options are:  - `free_flow`: The default option. Calculates the route optimistically, assuming no traffic delays or congestion. - `approximated`: Adjusts the route by accounting for potential traffic, decreasing speed on roads that are likely to be congested.  This parameter is only applicable to motorized vehicle modes, such as `drive`, `truck`, and other similar modes.
  --max-speed: int # The maximum allowable speed for the route, specified in kilometers per hour (KPH). (e.g. 80)
  --format: string@format-completer # The desired output format for the response, options include 'geojson', 'json', or 'xml'. (e.g. json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $apiKey "scalar") (serialize-qp "waypoints" $waypoints "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "max_speed" $max_speed "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/routing" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
