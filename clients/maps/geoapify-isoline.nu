# Auto-generated client for Isoline API v1.0.0
# Source: https://raw.githubusercontent.com/geoapify/geoapify-openapi-specs/main/api-specs/isoline/isoline.yaml
# Auth: --token flag or $env.ISOLINE_API_TOKEN

const BASE_URL = "https://api.geoapify.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ISOLINE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.geoapify.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["distance" "time"] }
def mode-completer [] { ["approximated_transit" "bicycle" "bus" "drive" "heavy_truck" "hike" "light_truck" "long_truck" "medium_truck" "motorcycle" "mountain_bike" "road_bike" "scooter" "transit" "truck" "truck_dangerous_goods" "walk"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "isoline get" } } | get name | first)
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

# Calculate Isochrones or Isodistances
#
# GET /isoline
# operationId: getIsoline
export def "isoline get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # Your Geoapify API key to authenticate the request. You can sign up and obtain an API key for free at [https://myprojects.geoapify.com/](https://myprojects.geoapify.com/). The Free plan includes up to 3,000 requests per day. (e.g. YOUR_API_KEY)
  --lat: float # The latitude of the location from which to calculate the isoline. (e.g. 28.293067)
  --lon: float # The longitude of the location from which to calculate the isoline. (e.g. -81.550409)
  --type: string@type-completer # Specifies whether to calculate an isochrone (based on travel time) or an isodistance (based on distance).  (e.g. time)
  --mode: string@mode-completer # Determines how the accessible area is calculated based on the type of transportation or movement.  Available options include: - `drive`: Standard car or automobile. - `light_truck`: Light-duty truck. - `medium_truck`: Medium-duty truck. - `truck`: General truck. - `heavy_truck`: Heavy-duty truck. - `truck_dangerous_goods`: Truck carrying hazardous materials. - `long_truck`: Long or articulated truck. - `bus`: Public or private bus. - `scooter`: Motorized scooter. - `motorcycle`: Motorbike. - `bicycle`: Standard bicycle. - `mountain_bike`: Mountain bike. - `road_bike`: Road bicycle. - `walk`: Walking on foot. - `hike`: Hiking, often on trails or rugged terrain. - `transit`: Public transit routes (based on real-time data). - `approximated_transit`: Estimated public transit routes (without real-time data).  Selecting the appropriate travel mode helps generate an isoline that accurately reflects the time or distance accessible for the specified mode.  (e.g. drive)
  --range: string # The range value for the isoline. For isochrones, the range is specified in seconds (travel time). For isodistances, it is specified in meters (travel distance).  (e.g. 900)
  --avoid: string # Specifies road types or specific locations to avoid during routing. Use this to exclude features like toll roads, highways, ferries, or particular geographic areas.  (e.g. tolls:1|ferries|location:35.234045,-80.836392)
  --traffic: string # The traffic model to be used in route calculations. The default value is `free_flow`, which does not consider real-time traffic. Alternatively, use `approximated` for a traffic-influenced model.
  --route-type: string # Defines the type of route to calculate. Options include `balanced` for a mix of efficiency and speed, `short` for the shortest route, and `less_maneuvers` to minimize turns or complexity. The default is `balanced`.
  --max-speed: float # The maximum speed that a vehicle can travel. This applies to driving mode, all truck modes, and bus modes. The max_speed should be specified within the range of 10 to 252 KPH (6.5 - 155 MPH). For trucks, the standard setting is 90 kilometers per hour (KPH), while for automobiles and buses, it's set at 140 KPH by default.  (e.g. 80)
  --units: string # Specifies the units of measurement for distances in the response. The default is metric. Use `imperial` for miles, feet, etc.
  --id: string # ID of previously generated isoline. This parameter allows you to retrieve previously calculated isolines within a 24-hour window without recalculating them.  (e.g. a235ce27b9fa8a22688f06915cfe53e3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $apiKey "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "route_type" $route_type "scalar") (serialize-qp "max_speed" $max_speed "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/isoline" $qp)
  let accept_val = "application/geo+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
