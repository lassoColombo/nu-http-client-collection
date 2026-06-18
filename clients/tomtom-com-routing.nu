# Auto-generated client for Routing v1.0.0
# Source: https://api.apis.guru/v2/specs/tomtom.com/routing/1.0.0/openapi.json
# Auth: --token flag or $env.ROUTING_TOKEN

const BASE_URL = "https://api.tomtom.com"
const DEFAULT_AUTH = "query-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ROUTING_TOKEN | default "" }
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
def report-completer [] { ["effectiveSettings"] }
def route-type-completer [] { ["eco" "fastest" "shortest" "thrilling"] }
def travel-mode-completer [] { ["bicycle" "bus" "car" "motorcycle" "pedestrian" "taxi" "truck" "van"] }
def hilliness-completer [] { ["high" "low" "normal"] }
def windingness-completer [] { ["high" "low" "normal"] }
def vehicle-engine-type-completer [] { ["combustion" "electric"] }
def alternative-type-completer [] { ["anyRoute" "betterRoute"] }
def instructions-type-completer [] { ["coded" "tagged" "text"] }
def route-representation-completer [] { ["none" "polyline"] }
def compute-travel-time-for-completer [] { ["all" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "routing-calculate-reachable-range get" } } | get name | first)
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

# Reachable Range
#
# GET /routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}
export def "routing-calculate-reachable-range get" [
  version_number: int
  origin: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fuel-budget-in-liters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energy-budget-ink-wh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --time-budget-in-sec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fuelBudgetInLiters" $fuel_budget_in_liters "scalar") (serialize-qp "energyBudgetInkWh" $energy_budget_ink_wh "scalar") (serialize-qp "timeBudgetInSec" $time_budget_in_sec "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $depart_at "scalar") (serialize-qp "arriveAt" $arrive_at "scalar") (serialize-qp "routeType" $route_type "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travel_mode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicle_max_speed "scalar") (serialize-qp "vehicleWeight" $vehicle_weight "scalar") (serialize-qp "vehicleAxleWeight" $vehicle_axle_weight "scalar") (serialize-qp "vehicleLength" $vehicle_length "scalar") (serialize-qp "vehicleWidth" $vehicle_width "scalar") (serialize-qp "vehicleHeight" $vehicle_height "scalar") (serialize-qp "vehicleCommercial" $vehicle_commercial "scalar") (serialize-qp "vehicleLoadType" $vehicle_load_type "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constant_speed_consumption_in_liters_per_hundredkm "scalar") (serialize-qp "currentFuelInLiters" $current_fuel_in_liters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliary_power_in_liters_per_hour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuel_energy_density_in_m_joules_per_liter "scalar") (serialize-qp "accelerationEfficiency" $acceleration_efficiency "scalar") (serialize-qp "decelerationEfficiency" $deceleration_efficiency "scalar") (serialize-qp "uphillEfficiency" $uphill_efficiency "scalar") (serialize-qp "downhillEfficiency" $downhill_efficiency "scalar") (serialize-qp "vehicleEngineType" $vehicle_engine_type "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constant_speed_consumption_ink_wh_per_hundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), origin: (encode-path-segment $origin), content_type: (encode-path-segment $content_type)} | format pattern "/routing/{version_number}/calculateReachableRange/{origin}/{content_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reachable Range
#
# POST /routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}
# --avoidAreas shape: {rectangles?: list}
export def "routing-calculate-reachable-range create" [
  version_number: int
  origin: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fuel-budget-in-liters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energy-budget-ink-wh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --time-budget-in-sec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
  --allow-vignette: list<string>
  --avoid-areas: record # shape: {rectangles?: list}
  --avoid-vignette: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fuelBudgetInLiters" $fuel_budget_in_liters "scalar") (serialize-qp "energyBudgetInkWh" $energy_budget_ink_wh "scalar") (serialize-qp "timeBudgetInSec" $time_budget_in_sec "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $depart_at "scalar") (serialize-qp "arriveAt" $arrive_at "scalar") (serialize-qp "routeType" $route_type "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travel_mode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicle_max_speed "scalar") (serialize-qp "vehicleWeight" $vehicle_weight "scalar") (serialize-qp "vehicleAxleWeight" $vehicle_axle_weight "scalar") (serialize-qp "vehicleLength" $vehicle_length "scalar") (serialize-qp "vehicleWidth" $vehicle_width "scalar") (serialize-qp "vehicleHeight" $vehicle_height "scalar") (serialize-qp "vehicleCommercial" $vehicle_commercial "scalar") (serialize-qp "vehicleLoadType" $vehicle_load_type "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constant_speed_consumption_in_liters_per_hundredkm "scalar") (serialize-qp "currentFuelInLiters" $current_fuel_in_liters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliary_power_in_liters_per_hour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuel_energy_density_in_m_joules_per_liter "scalar") (serialize-qp "accelerationEfficiency" $acceleration_efficiency "scalar") (serialize-qp "decelerationEfficiency" $deceleration_efficiency "scalar") (serialize-qp "uphillEfficiency" $uphill_efficiency "scalar") (serialize-qp "downhillEfficiency" $downhill_efficiency "scalar") (serialize-qp "vehicleEngineType" $vehicle_engine_type "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constant_speed_consumption_ink_wh_per_hundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), origin: (encode-path-segment $origin), content_type: (encode-path-segment $content_type)} | format pattern "/routing/{version_number}/calculateReachableRange/{origin}/{content_type}") $qp)
  let req_body = {"allowVignette": $allow_vignette, "avoidAreas": $avoid_areas, "avoidVignette": $avoid_vignette} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Calculate Route
#
# GET /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
export def "routing-calculate-route get" [
  version_number: int
  locations: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-alternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternative-type: string@alternative-type-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --min-deviation-distance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --min-deviation-time: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructions-type: string@instructions-type-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --compute-best-order: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --route-representation: string@route-representation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --compute-travel-time-for: string@compute-travel-time-for-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicle-heading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --section-type: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times. - carTrain, ferry, tunnel or motorway - pedestrian - tollRoad - tollVignette - country - travelMode - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools - alreadyUsedRoads (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion)
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxAlternatives" $max_alternatives "scalar") (serialize-qp "alternativeType" $alternative_type "scalar") (serialize-qp "minDeviationDistance" $min_deviation_distance "scalar") (serialize-qp "minDeviationTime" $min_deviation_time "scalar") (serialize-qp "instructionsType" $instructions_type "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "computeBestOrder" $compute_best_order "scalar") (serialize-qp "routeRepresentation" $route_representation "scalar") (serialize-qp "computeTravelTimeFor" $compute_travel_time_for "scalar") (serialize-qp "vehicleHeading" $vehicle_heading "scalar") (serialize-qp "sectionType" $section_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $depart_at "scalar") (serialize-qp "arriveAt" $arrive_at "scalar") (serialize-qp "routeType" $route_type "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travel_mode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicle_max_speed "scalar") (serialize-qp "vehicleWeight" $vehicle_weight "scalar") (serialize-qp "vehicleAxleWeight" $vehicle_axle_weight "scalar") (serialize-qp "vehicleLength" $vehicle_length "scalar") (serialize-qp "vehicleWidth" $vehicle_width "scalar") (serialize-qp "vehicleHeight" $vehicle_height "scalar") (serialize-qp "vehicleCommercial" $vehicle_commercial "scalar") (serialize-qp "vehicleLoadType" $vehicle_load_type "scalar") (serialize-qp "vehicleEngineType" $vehicle_engine_type "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constant_speed_consumption_in_liters_per_hundredkm "scalar") (serialize-qp "currentFuelInLiters" $current_fuel_in_liters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliary_power_in_liters_per_hour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuel_energy_density_in_m_joules_per_liter "scalar") (serialize-qp "accelerationEfficiency" $acceleration_efficiency "scalar") (serialize-qp "decelerationEfficiency" $deceleration_efficiency "scalar") (serialize-qp "uphillEfficiency" $uphill_efficiency "scalar") (serialize-qp "downhillEfficiency" $downhill_efficiency "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constant_speed_consumption_ink_wh_per_hundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), locations: (encode-path-segment $locations), content_type: (encode-path-segment $content_type)} | format pattern "/routing/{version_number}/calculateRoute/{locations}/{content_type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculate Route
#
# POST /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
# --avoidAreas shape: {rectangles?: list}
# --supportingPoints item shape: {latitude?: string, longitude?: string}
export def "routing-calculate-route create" [
  version_number: int
  locations: string
  content_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-alternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternative-type: string@alternative-type-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --min-deviation-distance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --min-deviation-time: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructions-type: string@instructions-type-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --compute-best-order: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --route-representation: string@route-representation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --compute-travel-time-for: string@compute-travel-time-for-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicle-heading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --section-type: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times. - carTrain, ferry, tunnel or motorway - pedestrian - tollRoad - tollVignette - country - travelMode - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --depart-at: string # The date and time of departure from the origin point. Departure times apart from now must be specified as a dateTime. (default: now)
  --arrive-at: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --route-type: string@route-type-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values: - tollRoads - motorways - ferries - unpavedRoads - carpools - alreadyUsedRoads (e.g. unpavedRoads)
  --travel-mode: string@travel-mode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicle-max-speed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicle-weight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicle-axle-weight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicle-length: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicle-width: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicle-height: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicle-commercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicle-load-type: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US: - USHazmatClass1 Explosives - USHazmatClass2 Compressed gas - USHazmatClass3 Flammable liquids - USHazmatClass4 Flammable solids - USHazmatClass5 Oxidizers - USHazmatClass6 Poisons - USHazmatClass7 Radioactive - USHazmatClass8 Corrosives - USHazmatClass9 Miscellaneous Use these for routing in all other countries: - otherHazmatExplosive Explosives - otherHazmatGeneral Miscellaneous - otherHazmatHarmfulToWater Harmful to water vehicleLoadType can be specified multiple times. This parameter is currently only considered for travelMode=truck.
  --vehicle-engine-type: string@vehicle-engine-type-completer # Engine type of the vehicle. (default: combustion)
  --constant-speed-consumption-in-liters-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --current-fuel-in-liters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliary-power-in-liters-per-hour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuel-energy-density-in-m-joules-per-liter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --acceleration-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --deceleration-efficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphill-efficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhill-efficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constant-speed-consumption-ink-wh-per-hundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --allow-vignette: list<string>
  --avoid-areas: record # shape: {rectangles?: list}
  --avoid-vignette: list<string>
  --supporting-points: list # item shape: {latitude?: string, longitude?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxAlternatives" $max_alternatives "scalar") (serialize-qp "alternativeType" $alternative_type "scalar") (serialize-qp "minDeviationDistance" $min_deviation_distance "scalar") (serialize-qp "minDeviationTime" $min_deviation_time "scalar") (serialize-qp "instructionsType" $instructions_type "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "computeBestOrder" $compute_best_order "scalar") (serialize-qp "routeRepresentation" $route_representation "scalar") (serialize-qp "computeTravelTimeFor" $compute_travel_time_for "scalar") (serialize-qp "vehicleHeading" $vehicle_heading "scalar") (serialize-qp "sectionType" $section_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $depart_at "scalar") (serialize-qp "arriveAt" $arrive_at "scalar") (serialize-qp "routeType" $route_type "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travel_mode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicle_max_speed "scalar") (serialize-qp "vehicleWeight" $vehicle_weight "scalar") (serialize-qp "vehicleAxleWeight" $vehicle_axle_weight "scalar") (serialize-qp "vehicleLength" $vehicle_length "scalar") (serialize-qp "vehicleWidth" $vehicle_width "scalar") (serialize-qp "vehicleHeight" $vehicle_height "scalar") (serialize-qp "vehicleCommercial" $vehicle_commercial "scalar") (serialize-qp "vehicleLoadType" $vehicle_load_type "scalar") (serialize-qp "vehicleEngineType" $vehicle_engine_type "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constant_speed_consumption_in_liters_per_hundredkm "scalar") (serialize-qp "currentFuelInLiters" $current_fuel_in_liters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliary_power_in_liters_per_hour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuel_energy_density_in_m_joules_per_liter "scalar") (serialize-qp "accelerationEfficiency" $acceleration_efficiency "scalar") (serialize-qp "decelerationEfficiency" $deceleration_efficiency "scalar") (serialize-qp "uphillEfficiency" $uphill_efficiency "scalar") (serialize-qp "downhillEfficiency" $downhill_efficiency "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constant_speed_consumption_ink_wh_per_hundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version_number: (encode-path-segment $version_number), locations: (encode-path-segment $locations), content_type: (encode-path-segment $content_type)} | format pattern "/routing/{version_number}/calculateRoute/{locations}/{content_type}") $qp)
  let req_body = {"allowVignette": $allow_vignette, "avoidAreas": $avoid_areas, "avoidVignette": $avoid_vignette, "supportingPoints": $supporting_points} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
