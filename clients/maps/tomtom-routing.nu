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

def base-url-completer [] { ["https://api.tomtom.com"] }
def auth-scheme-completer [] { ["query-key"] }

# Completers for enum parameters
def report-completer [] { ["effectiveSettings"] }
def routeType-completer [] { ["eco" "fastest" "shortest" "thrilling"] }
def travelMode-completer [] { ["bicycle" "bus" "car" "motorcycle" "pedestrian" "taxi" "truck" "van"] }
def hilliness-completer [] { ["high" "low" "normal"] }
def windingness-completer [] { ["high" "low" "normal"] }
def vehicleEngineType-completer [] { ["combustion" "electric"] }
def alternativeType-completer [] { ["anyRoute" "betterRoute"] }
def instructionsType-completer [] { ["coded" "tagged" "text"] }
def routeRepresentation-completer [] { ["none" "polyline"] }
def computeTravelTimeFor-completer [] { ["all" "none"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  versionNumber: int
  origin: string
  contentType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fuelBudgetInLiters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energyBudgetInkWh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --timeBudgetInSec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --departAt: string # The date and time of departure from the origin point. Departure times apart from <i>now</i> must be specified as a dateTime. (default: now)
  --arriveAt: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --routeType: string@routeType-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values:   - tollRoads   - motorways   - ferries   - unpavedRoads   - carpools (e.g. unpavedRoads)
  --travelMode: string@travelMode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicleMaxSpeed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicleWeight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicleAxleWeight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicleLength: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicleWidth: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicleHeight: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicleCommercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicleLoadType: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US:    - <i>USHazmatClass1</i> Explosives   - <i>USHazmatClass2</i> Compressed gas   - <i>USHazmatClass3</i> Flammable liquids   - <i>USHazmatClass4</i> Flammable solids   - <i>USHazmatClass5</i> Oxidizers   - <i>USHazmatClass6</i> Poisons   - <i>USHazmatClass7</i> Radioactive   - <i>USHazmatClass8</i> Corrosives   - <i>USHazmatClass9</i> Miscellaneous  Use these for routing in all other countries:    - <i>otherHazmatExplosive</i> Explosives   - <i>otherHazmatGeneral</i> Miscellaneous   - <i>otherHazmatHarmfulToWater</i> Harmful to water  vehicleLoadType can be specified multiple times. This parameter is currently only considered for <b>travelMode</b>=<i>truck</i>.
  --constantSpeedConsumptionInLitersPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --currentFuelInLiters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliaryPowerInLitersPerHour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuelEnergyDensityInMJoulesPerLiter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --accelerationEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --decelerationEfficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphillEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhillEfficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicleEngineType: string@vehicleEngineType-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constantSpeedConsumptionInkWhPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fuelBudgetInLiters" $fuelBudgetInLiters "scalar") (serialize-qp "energyBudgetInkWh" $energyBudgetInkWh "scalar") (serialize-qp "timeBudgetInSec" $timeBudgetInSec "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $departAt "scalar") (serialize-qp "arriveAt" $arriveAt "scalar") (serialize-qp "routeType" $routeType "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travelMode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicleMaxSpeed "scalar") (serialize-qp "vehicleWeight" $vehicleWeight "scalar") (serialize-qp "vehicleAxleWeight" $vehicleAxleWeight "scalar") (serialize-qp "vehicleLength" $vehicleLength "scalar") (serialize-qp "vehicleWidth" $vehicleWidth "scalar") (serialize-qp "vehicleHeight" $vehicleHeight "scalar") (serialize-qp "vehicleCommercial" $vehicleCommercial "scalar") (serialize-qp "vehicleLoadType" $vehicleLoadType "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constantSpeedConsumptionInLitersPerHundredkm "scalar") (serialize-qp "currentFuelInLiters" $currentFuelInLiters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliaryPowerInLitersPerHour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuelEnergyDensityInMJoulesPerLiter "scalar") (serialize-qp "accelerationEfficiency" $accelerationEfficiency "scalar") (serialize-qp "decelerationEfficiency" $decelerationEfficiency "scalar") (serialize-qp "uphillEfficiency" $uphillEfficiency "scalar") (serialize-qp "downhillEfficiency" $downhillEfficiency "scalar") (serialize-qp "vehicleEngineType" $vehicleEngineType "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constantSpeedConsumptionInkWhPerHundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/routing/($versionNumber)/calculateReachableRange/($origin)/($contentType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reachable Range
#
# POST /routing/{versionNumber}/calculateReachableRange/{origin}/{contentType}
# --avoidAreas shape: {rectangles?: list}
export def "routing-calculate-reachable-range post" [
  versionNumber: int
  origin: string
  contentType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fuelBudgetInLiters: float # Fuel budget in liters. Determines the maximum vehicle range using the specified Combustion Consumption Model. (format: float)
  --energyBudgetInkWh: float # Electric energy budget in kilowatt hours (kWh). Determines the maximum vehicle range using the specified Electric Consumption Model. (format: float, e.g. 43)
  --timeBudgetInSec: float # Time budget in seconds. Determines the maximum vehicle range using the specified driving time. The consumption parameters in the request will only affect eco-routes, and thereby indirectly the driving time. (format: float)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --departAt: string # The date and time of departure from the origin point. Departure times apart from <i>now</i> must be specified as a dateTime. (default: now)
  --arriveAt: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --routeType: string@routeType-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values:   - tollRoads   - motorways   - ferries   - unpavedRoads   - carpools (e.g. unpavedRoads)
  --travelMode: string@travelMode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicleMaxSpeed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicleWeight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicleAxleWeight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicleLength: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicleWidth: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicleHeight: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicleCommercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicleLoadType: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US:    - <i>USHazmatClass1</i> Explosives   - <i>USHazmatClass2</i> Compressed gas   - <i>USHazmatClass3</i> Flammable liquids   - <i>USHazmatClass4</i> Flammable solids   - <i>USHazmatClass5</i> Oxidizers   - <i>USHazmatClass6</i> Poisons   - <i>USHazmatClass7</i> Radioactive   - <i>USHazmatClass8</i> Corrosives   - <i>USHazmatClass9</i> Miscellaneous  Use these for routing in all other countries:    - <i>otherHazmatExplosive</i> Explosives   - <i>otherHazmatGeneral</i> Miscellaneous   - <i>otherHazmatHarmfulToWater</i> Harmful to water  vehicleLoadType can be specified multiple times. This parameter is currently only considered for <b>travelMode</b>=<i>truck</i>.
  --constantSpeedConsumptionInLitersPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --currentFuelInLiters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliaryPowerInLitersPerHour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuelEnergyDensityInMJoulesPerLiter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --accelerationEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --decelerationEfficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphillEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhillEfficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --vehicleEngineType: string@vehicleEngineType-completer # Engine type of the vehicle. (default: combustion, e.g. electric)
  --constantSpeedConsumptionInkWhPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs. (e.g. 50,8.2:130,21.3)
  --allowVignette: list
  --avoidAreas: record # shape: {rectangles?: list}
  --avoidVignette: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fuelBudgetInLiters" $fuelBudgetInLiters "scalar") (serialize-qp "energyBudgetInkWh" $energyBudgetInkWh "scalar") (serialize-qp "timeBudgetInSec" $timeBudgetInSec "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $departAt "scalar") (serialize-qp "arriveAt" $arriveAt "scalar") (serialize-qp "routeType" $routeType "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travelMode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicleMaxSpeed "scalar") (serialize-qp "vehicleWeight" $vehicleWeight "scalar") (serialize-qp "vehicleAxleWeight" $vehicleAxleWeight "scalar") (serialize-qp "vehicleLength" $vehicleLength "scalar") (serialize-qp "vehicleWidth" $vehicleWidth "scalar") (serialize-qp "vehicleHeight" $vehicleHeight "scalar") (serialize-qp "vehicleCommercial" $vehicleCommercial "scalar") (serialize-qp "vehicleLoadType" $vehicleLoadType "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constantSpeedConsumptionInLitersPerHundredkm "scalar") (serialize-qp "currentFuelInLiters" $currentFuelInLiters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliaryPowerInLitersPerHour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuelEnergyDensityInMJoulesPerLiter "scalar") (serialize-qp "accelerationEfficiency" $accelerationEfficiency "scalar") (serialize-qp "decelerationEfficiency" $decelerationEfficiency "scalar") (serialize-qp "uphillEfficiency" $uphillEfficiency "scalar") (serialize-qp "downhillEfficiency" $downhillEfficiency "scalar") (serialize-qp "vehicleEngineType" $vehicleEngineType "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constantSpeedConsumptionInkWhPerHundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/routing/($versionNumber)/calculateReachableRange/($origin)/($contentType)" $qp)
  let body = {allowVignette: $allowVignette, avoidAreas: $avoidAreas, avoidVignette: $avoidVignette} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate Route
#
# GET /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
export def "routing-calculate-route get" [
  versionNumber: int
  locations: string
  contentType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxAlternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternativeType: string@alternativeType-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --minDeviationDistance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --minDeviationTime: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructionsType: string@instructionsType-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --computeBestOrder: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --routeRepresentation: string@routeRepresentation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --computeTravelTimeFor: string@computeTravelTimeFor-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicleHeading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --sectionType: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times.   - carTrain, ferry, tunnel or motorway   - pedestrian   - tollRoad   - tollVignette   - country   - travelMode   - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --departAt: string # The date and time of departure from the origin point. Departure times apart from <i>now</i> must be specified as a dateTime. (default: now)
  --arriveAt: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --routeType: string@routeType-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values:   - tollRoads   - motorways   - ferries   - unpavedRoads   - carpools   - alreadyUsedRoads (e.g. unpavedRoads)
  --travelMode: string@travelMode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicleMaxSpeed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicleWeight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicleAxleWeight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicleLength: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicleWidth: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicleHeight: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicleCommercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicleLoadType: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US:    - <i>USHazmatClass1</i> Explosives   - <i>USHazmatClass2</i> Compressed gas   - <i>USHazmatClass3</i> Flammable liquids   - <i>USHazmatClass4</i> Flammable solids   - <i>USHazmatClass5</i> Oxidizers   - <i>USHazmatClass6</i> Poisons   - <i>USHazmatClass7</i> Radioactive   - <i>USHazmatClass8</i> Corrosives   - <i>USHazmatClass9</i> Miscellaneous  Use these for routing in all other countries:    - <i>otherHazmatExplosive</i> Explosives   - <i>otherHazmatGeneral</i> Miscellaneous   - <i>otherHazmatHarmfulToWater</i> Harmful to water  vehicleLoadType can be specified multiple times. This parameter is currently only considered for <b>travelMode</b>=<i>truck</i>.
  --vehicleEngineType: string@vehicleEngineType-completer # Engine type of the vehicle. (default: combustion)
  --constantSpeedConsumptionInLitersPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --currentFuelInLiters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliaryPowerInLitersPerHour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuelEnergyDensityInMJoulesPerLiter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --accelerationEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --decelerationEfficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphillEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhillEfficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constantSpeedConsumptionInkWhPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxAlternatives" $maxAlternatives "scalar") (serialize-qp "alternativeType" $alternativeType "scalar") (serialize-qp "minDeviationDistance" $minDeviationDistance "scalar") (serialize-qp "minDeviationTime" $minDeviationTime "scalar") (serialize-qp "instructionsType" $instructionsType "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "computeBestOrder" $computeBestOrder "scalar") (serialize-qp "routeRepresentation" $routeRepresentation "scalar") (serialize-qp "computeTravelTimeFor" $computeTravelTimeFor "scalar") (serialize-qp "vehicleHeading" $vehicleHeading "scalar") (serialize-qp "sectionType" $sectionType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $departAt "scalar") (serialize-qp "arriveAt" $arriveAt "scalar") (serialize-qp "routeType" $routeType "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travelMode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicleMaxSpeed "scalar") (serialize-qp "vehicleWeight" $vehicleWeight "scalar") (serialize-qp "vehicleAxleWeight" $vehicleAxleWeight "scalar") (serialize-qp "vehicleLength" $vehicleLength "scalar") (serialize-qp "vehicleWidth" $vehicleWidth "scalar") (serialize-qp "vehicleHeight" $vehicleHeight "scalar") (serialize-qp "vehicleCommercial" $vehicleCommercial "scalar") (serialize-qp "vehicleLoadType" $vehicleLoadType "scalar") (serialize-qp "vehicleEngineType" $vehicleEngineType "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constantSpeedConsumptionInLitersPerHundredkm "scalar") (serialize-qp "currentFuelInLiters" $currentFuelInLiters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliaryPowerInLitersPerHour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuelEnergyDensityInMJoulesPerLiter "scalar") (serialize-qp "accelerationEfficiency" $accelerationEfficiency "scalar") (serialize-qp "decelerationEfficiency" $decelerationEfficiency "scalar") (serialize-qp "uphillEfficiency" $uphillEfficiency "scalar") (serialize-qp "downhillEfficiency" $downhillEfficiency "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constantSpeedConsumptionInkWhPerHundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/routing/($versionNumber)/calculateRoute/($locations)/($contentType)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Calculate Route
#
# POST /routing/{versionNumber}/calculateRoute/{locations}/{contentType}
# --avoidAreas shape: {rectangles?: list}
# --supportingPoints item shape: {latitude?: string, longitude?: string}
export def "routing-calculate-route post" [
  versionNumber: int
  locations: string
  contentType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxAlternatives: int # Number of alternative routes to be calculated. (default: 0)
  --alternativeType: string@alternativeType-completer # Determines whether the alternative routes to be calculated should be better with respect to the planning criteria provided than the reference route. (default: anyRoute)
  --minDeviationDistance: int # All alternative routes will follow the reference route for the specified minimum number of meters starting from the origin point. (default: 0)
  --minDeviationTime: int # All alternative routes will follow the reference route for the specified minimum number of seconds starting from the origin point. (default: 0)
  --instructionsType: string@instructionsType-completer # If specified, guidance instructions will be returned (if available).
  --language: string # The language parameter determines the language of the guidance messages. (default: en-GB)
  --computeBestOrder: oneof<nothing, bool> # Re-order the route waypoints to reduce the route length. (default: false)
  --routeRepresentation: string@routeRepresentation-completer # Specifies the representation of the set of routes provided as a response. (default: polyline)
  --computeTravelTimeFor: string@computeTravelTimeFor-completer # Specifies whether to return additional travel times using different types of traffic information (none, historic, live) as well as the default best-estimate travel time. (default: none)
  --vehicleHeading: int # The directional heading of the vehicle in degrees. Entered in degrees, measured clockwise from north (so north is 0, east is 90, etc.).
  --sectionType: string # Specifies which section types are explicitly reported in the route response. Can be specified multiple times.   - carTrain, ferry, tunnel or motorway   - pedestrian   - tollRoad   - tollVignette   - country   - travelMode   - traffic (default: travelMode)
  --callback: string # Specifies the jsonp callback method. (default: callback)
  --report: string@report-completer # Specifies which data should be reported for diagnosis purposes.
  --departAt: string # The date and time of departure from the origin point. Departure times apart from <i>now</i> must be specified as a dateTime. (default: now)
  --arriveAt: string # The date and time of arrival at the destination point. It must be specified as a dateTime. (format: dateTime)
  --routeType: string@routeType-completer # The type of route requested. (default: fastest)
  --traffic: oneof<nothing, bool> # Determines whether current traffic is used in route calculations. Note that information on historic road speeds is always used. (default: true)
  --avoid: string # Specifies whether the routing engine should try to avoid specific types of road segment when calculating the route. Can be specified multiple times. Possible values:   - tollRoads   - motorways   - ferries   - unpavedRoads   - carpools   - alreadyUsedRoads (e.g. unpavedRoads)
  --travelMode: string@travelMode-completer # The mode of travel for the requested route. (default: car)
  --hilliness: string@hilliness-completer # Degree of hilliness for calculating a thrilling route. (default: normal)
  --windingness: string@windingness-completer # Amount that a thrilling route should wind. (default: normal)
  --vehicleMaxSpeed: int # Maximum speed of the vehicle in km/hour. (default: 0)
  --vehicleWeight: int # Weight of the vehicle in kilograms. (default: 0)
  --vehicleAxleWeight: int # Weight per axle of the vehicle in kg. (default: 0)
  --vehicleLength: float # Length of the vehicle in meters. (format: float, default: 0)
  --vehicleWidth: float # Width of the vehicle in meters. (format: float, default: 0)
  --vehicleHeight: float # Height of the vehicle in meters. (format: float, default: 0)
  --vehicleCommercial: oneof<nothing, bool> # Indicates that the vehicle is used for commercial purposes. This means it may not be allowed on certain roads. (default: false)
  --vehicleLoadType: string # Indicates what kinds of hazardous materials the vehicle is carrying (if any). This means it may not be allowed on certain roads. Use these for routing in the US:    - <i>USHazmatClass1</i> Explosives   - <i>USHazmatClass2</i> Compressed gas   - <i>USHazmatClass3</i> Flammable liquids   - <i>USHazmatClass4</i> Flammable solids   - <i>USHazmatClass5</i> Oxidizers   - <i>USHazmatClass6</i> Poisons   - <i>USHazmatClass7</i> Radioactive   - <i>USHazmatClass8</i> Corrosives   - <i>USHazmatClass9</i> Miscellaneous  Use these for routing in all other countries:    - <i>otherHazmatExplosive</i> Explosives   - <i>otherHazmatGeneral</i> Miscellaneous   - <i>otherHazmatHarmfulToWater</i> Harmful to water  vehicleLoadType can be specified multiple times. This parameter is currently only considered for <b>travelMode</b>=<i>truck</i>.
  --vehicleEngineType: string@vehicleEngineType-completer # Engine type of the vehicle. (default: combustion)
  --constantSpeedConsumptionInLitersPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --currentFuelInLiters: float # Specifies the current supply of fuel in liters. (format: float)
  --auxiliaryPowerInLitersPerHour: float # Specifies the amount of fuel consumed for sustaining auxiliary systems of the vehicle, in liters per hour. (format: float)
  --fuelEnergyDensityInMJoulesPerLiter: float # Specifies the amount of chemical energy stored in one liter of fuel in megajoules (MJ). (format: float)
  --accelerationEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to kinetic energy when the vehicle accelerates (i.e. KineticEnergyGained/ChemicalEnergyConsumed). (format: float)
  --decelerationEfficiency: float # Specifies the efficiency of converting kinetic energy to saved (not consumed) fuel when the vehicle decelerates (i.e. ChemicalEnergySaved/KineticEnergyLost). (format: float)
  --uphillEfficiency: float # Specifies the efficiency of converting chemical energy stored in fuel to potential energy when the vehicle gains elevation (i.e. PotentialEnergyGained/ChemicalEnergyConsumed). (format: float)
  --downhillEfficiency: float # Specifies the efficiency of converting potential energy to saved (not consumed) fuel when the vehicle loses elevation (i.e. ChemicalEnergySaved/PotentialEnergyLost). (format: float)
  --constantSpeedConsumptionInkWhPerHundredkm: string # Specifies the speed-dependent component of consumption. Provided as an unordered list of speed/consumption-rate pairs.
  --allowVignette: list
  --avoidAreas: record # shape: {rectangles?: list}
  --avoidVignette: list
  --supportingPoints: list # item shape: {latitude?: string, longitude?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxAlternatives" $maxAlternatives "scalar") (serialize-qp "alternativeType" $alternativeType "scalar") (serialize-qp "minDeviationDistance" $minDeviationDistance "scalar") (serialize-qp "minDeviationTime" $minDeviationTime "scalar") (serialize-qp "instructionsType" $instructionsType "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "computeBestOrder" $computeBestOrder "scalar") (serialize-qp "routeRepresentation" $routeRepresentation "scalar") (serialize-qp "computeTravelTimeFor" $computeTravelTimeFor "scalar") (serialize-qp "vehicleHeading" $vehicleHeading "scalar") (serialize-qp "sectionType" $sectionType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "report" $report "scalar") (serialize-qp "departAt" $departAt "scalar") (serialize-qp "arriveAt" $arriveAt "scalar") (serialize-qp "routeType" $routeType "scalar") (serialize-qp "traffic" $traffic "scalar") (serialize-qp "avoid" $avoid "scalar") (serialize-qp "travelMode" $travelMode "scalar") (serialize-qp "hilliness" $hilliness "scalar") (serialize-qp "windingness" $windingness "scalar") (serialize-qp "vehicleMaxSpeed" $vehicleMaxSpeed "scalar") (serialize-qp "vehicleWeight" $vehicleWeight "scalar") (serialize-qp "vehicleAxleWeight" $vehicleAxleWeight "scalar") (serialize-qp "vehicleLength" $vehicleLength "scalar") (serialize-qp "vehicleWidth" $vehicleWidth "scalar") (serialize-qp "vehicleHeight" $vehicleHeight "scalar") (serialize-qp "vehicleCommercial" $vehicleCommercial "scalar") (serialize-qp "vehicleLoadType" $vehicleLoadType "scalar") (serialize-qp "vehicleEngineType" $vehicleEngineType "scalar") (serialize-qp "constantSpeedConsumptionInLitersPerHundredkm" $constantSpeedConsumptionInLitersPerHundredkm "scalar") (serialize-qp "currentFuelInLiters" $currentFuelInLiters "scalar") (serialize-qp "auxiliaryPowerInLitersPerHour" $auxiliaryPowerInLitersPerHour "scalar") (serialize-qp "fuelEnergyDensityInMJoulesPerLiter" $fuelEnergyDensityInMJoulesPerLiter "scalar") (serialize-qp "accelerationEfficiency" $accelerationEfficiency "scalar") (serialize-qp "decelerationEfficiency" $decelerationEfficiency "scalar") (serialize-qp "uphillEfficiency" $uphillEfficiency "scalar") (serialize-qp "downhillEfficiency" $downhillEfficiency "scalar") (serialize-qp "constantSpeedConsumptionInkWhPerHundredkm" $constantSpeedConsumptionInkWhPerHundredkm "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/routing/($versionNumber)/calculateRoute/($locations)/($contentType)" $qp)
  let body = {allowVignette: $allowVignette, avoidAreas: $avoidAreas, avoidVignette: $avoidVignette, supportingPoints: $supportingPoints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
