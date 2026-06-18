# Auto-generated client for Transport for London Unified API vv1
# Source: https://api.apis.guru/v2/specs/tfl.gov.uk/v1/openapi.json
# Auth: --token flag or $env.TRANSPORT_FOR_LONDON_UNIFIED_API_TOKEN

const BASE_URL = "https://api.digital.tfl.gov.uk"
const DEFAULT_AUTH = "query-app_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRANSPORT_FOR_LONDON_UNIFIED_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-app_key" => { {headers: {}, query: $"app_key=($token_val)"} }
    "query-app_id" => { {headers: {}, query: $"app_id=($token_val)"} }
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

def base-url-completer [] { ["https://api.digital.tfl.gov.uk"] }
def auth-scheme-completer [] { ["query-app_key" "query-app_id"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def time-is-completer [] { ["Arriving" "Departing"] }
def journey-preference-completer [] { ["LeastInterchange" "LeastTime" "LeastWalking"] }
def walking-speed-completer [] { ["Average" "Fast" "Slow"] }
def cycle-preference-completer [] { ["AllTheWay" "CycleHire" "LeaveAtStation" "None" "TakeOnTransport"] }
def direction-completer [] { ["all" "inbound" "outbound"] }
def accept-completer-1 [] { ["application/geo+json" "application/json" "application/xml" "text/json" "text/xml"] }
def direction-completer-1 [] { ["Average" "From" "To"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accident-stats get" } } | get name | first)
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

# Gets all accident details for accidents occuring in the specified year
#
# GET /AccidentStats/{year}
# operationId: AccidentStats_Get
export def "accident-stats get" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<borough: string, casualties: list<record>, date: string, id: int, lat: float, location: string, lon: float, severity: string, vehicles: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/AccidentStats/{year}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets air quality data feed
#
# GET /AirQuality
# operationId: AirQuality_Get
export def "air-quality get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/AirQuality")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all bike point locations. The Place object has an addtionalProperties array which contains the nbBikes, nbDocks and nbSpaces numbers which give the status of the BikePoint. A mismatch in these numbers i.e. nbDocks - (nbBikes + nbSpaces) != 0 indicates broken docks.
#
# GET /BikePoint
# operationId: BikePoint_GetAll
export def "bike-point get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BikePoint")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for bike stations by their name, a bike point's name often contains information about the name of the street or nearby landmarks, for example. Note that the search result does not contain the PlaceProperties i.e. the status or occupancy of the BikePoint, to get that information you should retrieve the BikePoint by its id on /BikePoint/id.
#
# GET /BikePoint/Search
# operationId: BikePoint_Search
export def "bike-point-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The search term e.g. "St. James"
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BikePoint/Search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the bike point with the given id.
#
# GET /BikePoint/{id}
# operationId: BikePoint_Get
export def "bike-point get" [
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
]: nothing -> record<additionalProperties: table<category: string, key: string, modified: string, sourceSystemKey: string, value: string>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/BikePoint/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets taxis and minicabs contact information
#
# GET /Cabwise/search
# operationId: Cabwise_Get
export def "cabwise-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --lat: float # Latitude (format: double)
  --lon: float # Longitude (format: double)
  --optype: string # Operator Type e.g Minicab, Executive, Limousine
  --wc: string # Wheelchair accessible
  --radius: float # The radius of the bounding circle in metres (format: double)
  --name: string # Trading name of operating company
  --max-results: int # An optional parameter to limit the number of results return. Default and maximum is 20. (format: int32)
  --legacy-format: oneof<nothing, bool> # Legacy Format
  --force-xml: oneof<nothing, bool> # Force Xml
  --twenty-four-seven-only: oneof<nothing, bool> # Twenty Four Seven Only
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "optype" $optype "scalar") (serialize-qp "wc" $wc "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "legacyFormat" $legacy_format "scalar") (serialize-qp "forceXml" $force_xml "scalar") (serialize-qp "twentyFourSevenOnly" $twenty_four_seven_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Cabwise/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform a Journey Planner search from the parameters specified in simple types
#
# GET /Journey/JourneyResults/{from}/to/{to}
# operationId: Journey_JourneyResults
export def "journey-journey-results-to get" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --via: string # Travel through point on the journey. Can be WGS84 coordinates expressed as "lat,long", a UK postcode, a Naptan (StopPoint) id, an ICS StopId, or a free-text string (will cause disambiguation unless it exactly matches a point of interest name).
  --national-search: oneof<nothing, bool> # Does the journey cover stops outside London? eg. "nationalSearch=true"
  --date: string # The date must be in yyyyMMdd format
  --time: string # The time must be in HHmm format
  --time-is: string@time-is-completer # Does the time given relate to arrival or leaving time? Possible options: "departing" | "arriving"
  --journey-preference: string@journey-preference-completer # The journey preference eg possible options: "leastinterchange" | "leasttime" | "leastwalking"
  --mode: list<string> # The mode must be a comma separated list of modes. eg possible options: "public-bus,overground,train,tube,coach,dlr,cablecar,tram,river,walking,cycle"
  --accessibility-preference: list<string> # The accessibility preference must be a comma separated list eg. "noSolidStairs,noEscalators,noElevators,stepFreeToVehicle,stepFreeToPlatform"
  --from-name: string # An optional name to associate with the origin of the journey in the results.
  --to-name: string # An optional name to associate with the destination of the journey in the results.
  --via-name: string # An optional name to associate with the via point of the journey in the results.
  --max-transfer-minutes: string # The max walking time in minutes for transfer eg. "120"
  --max-walking-minutes: string # The max walking time in minutes for journeys eg. "120"
  --walking-speed: string@walking-speed-completer # The walking speed. eg possible options: "slow" | "average" | "fast".
  --cycle-preference: string@cycle-preference-completer # The cycle preference. eg possible options: "allTheWay" | "leaveAtStation" | "takeOnTransport" | "cycleHire"
  --adjustment: string # Time adjustment command. eg possible options: "TripFirst" | "TripLast"
  --bike-proficiency: list<string> # A comma separated list of cycling proficiency levels. eg possible options: "easy,moderate,fast"
  --alternative-cycle: oneof<nothing, bool> # Option to determine whether to return alternative cycling journey
  --alternative-walking: oneof<nothing, bool> # Option to determine whether to return alternative walking journey
  --apply-html-markup: oneof<nothing, bool> # Flag to determine whether certain text (e.g. walking instructions) should be output with HTML tags or not.
  --use-multi-modal-call: oneof<nothing, bool> # A boolean to indicate whether or not to return 3 public transport journeys, a bus journey, a cycle hire journey, a personal cycle journey and a walking journey
  --walking-optimization: oneof<nothing, bool> # A boolean to indicate whether to optimize journeys using walking
  --taxi-only-trip: oneof<nothing, bool> # A boolean to indicate whether to return one or more taxi journeys. Note, setting this to true will override "useMultiModalCall".
  --route-between-entrances: oneof<nothing, bool> # A boolean to indicate whether public transport routes should include directions between platforms and station entrances.
  --use-real-time-live-arrivals: oneof<nothing, bool> # A boolean to indicate if we want to receive real time live arrivals data where available.
  --calc-one-direction: oneof<nothing, bool> # A boolean to make Journey Planner calculate journeys in one temporal direction only. In other words, only calculate journeys after the 'depart' time, or before the 'arrive' time. By default, the Journey Planner engine (EFA) calculates journeys in both temporal directions.
]: nothing -> record<cycleHireDockingStationData: record<destinationId: string, destinationNumberOfBikes: int, destinationNumberOfEmptySlots: int, originId: string, originNumberOfBikes: int, originNumberOfEmptySlots: int>, journeyVector: record<from: string, to: string, uri: string, via: string>, journeys: table<arrivalDateTime: string, duration: int, fare: record, legs: list, startDateTime: string>, lines: table<created: string, crowding: record, disruptions: list, id: string, lineStatuses: list, modeName: string, modified: string, name: string, routeSections: list, serviceTypes: list>, recommendedMaxAgeMinutes: int, searchCriteria: record<dateTime: string, dateTimeType: string, timeAdjustments: record<earlier: record, earliest: record, later: record, latest: record>>, stopMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "via" $via "scalar") (serialize-qp "nationalSearch" $national_search "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "timeIs" $time_is "scalar") (serialize-qp "journeyPreference" $journey_preference "scalar") (serialize-qp "mode" $mode "multi") (serialize-qp "accessibilityPreference" $accessibility_preference "multi") (serialize-qp "fromName" $from_name "scalar") (serialize-qp "toName" $to_name "scalar") (serialize-qp "viaName" $via_name "scalar") (serialize-qp "maxTransferMinutes" $max_transfer_minutes "scalar") (serialize-qp "maxWalkingMinutes" $max_walking_minutes "scalar") (serialize-qp "walkingSpeed" $walking_speed "scalar") (serialize-qp "cyclePreference" $cycle_preference "scalar") (serialize-qp "adjustment" $adjustment "scalar") (serialize-qp "bikeProficiency" $bike_proficiency "multi") (serialize-qp "alternativeCycle" $alternative_cycle "scalar") (serialize-qp "alternativeWalking" $alternative_walking "scalar") (serialize-qp "applyHtmlMarkup" $apply_html_markup "scalar") (serialize-qp "useMultiModalCall" $use_multi_modal_call "scalar") (serialize-qp "walkingOptimization" $walking_optimization "scalar") (serialize-qp "taxiOnlyTrip" $taxi_only_trip "scalar") (serialize-qp "routeBetweenEntrances" $route_between_entrances "scalar") (serialize-qp "useRealTimeLiveArrivals" $use_real_time_live_arrivals "scalar") (serialize-qp "calcOneDirection" $calc_one_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/Journey/JourneyResults/{from}/to/{to}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all of the available journey planner modes
#
# GET /Journey/Meta/Modes
# operationId: Journey_Meta
export def "journey-meta-modes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Journey/Meta/Modes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid disruption categories
#
# GET /Line/Meta/DisruptionCategories
# operationId: Line_MetaDisruptionCategories
export def "line-meta-disruption-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Line/Meta/DisruptionCategories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid modes
#
# GET /Line/Meta/Modes
# operationId: Line_MetaModes
export def "line-meta-modes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Line/Meta/Modes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid ServiceTypes to filter on
#
# GET /Line/Meta/ServiceTypes
# operationId: Line_MetaServiceTypes
export def "line-meta-service-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Line/Meta/ServiceTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid severity codes
#
# GET /Line/Meta/Severity
# operationId: Line_MetaSeverity
export def "line-meta-severity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<description: string, modeName: string, severityLevel: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Line/Meta/Severity")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets lines that serve the given modes.
#
# GET /Line/Mode/{modes}
# operationId: Line_GetByMode
export def "line-mode get" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/Line/Mode/{modes}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get disruptions for all lines of the given modes.
#
# GET /Line/Mode/{modes}/Disruption
# operationId: Line_DisruptionByMode
export def "line-mode-disruption get" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/Line/Mode/{modes}/Disruption"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all lines and their valid routes for given modes, including the name and id of the originating and terminating stops for each route
#
# GET /Line/Mode/{modes}/Route
# operationId: Line_RouteByMode
export def "line-mode-route get" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/Line/Mode/{modes}/Route") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status of for all lines for the given modes
#
# GET /Line/Mode/{modes}/Status
# operationId: Line_StatusByMode
export def "line-mode-status get" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
  --severity-level: string # If specified, ensures that only those line status(es) are returned within the lines that have disruptions with the matching severity level.
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar") (serialize-qp "severityLevel" $severity_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/Line/Mode/{modes}/Status") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all valid routes for all lines, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/Route
# operationId: Line_Route
export def "line-route list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/Line/Route" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for lines or routes matching the query string
#
# GET /Line/Search/{query}
# operationId: Line_Search
export def "line-search list" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --modes: list<string> # Optionally filter by the specified modes
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> record<input: string, searchMatches: table<id: string, lat: float, lineId: string, lineName: string, lineRouteSection: list, lon: float, matchedRouteSections: list, matchedStops: list, mode: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "multi") (serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/Line/Search/{query}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status for all lines with a given severity A list of valid severity codes can be obtained from a call to Line/Meta/Severity
#
# GET /Line/Status/{severity}
# operationId: Line_StatusBySeverity
export def "line-status get-by-severity" [
  severity: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({severity: (encode-path-segment $severity)} | format pattern "/Line/Status/{severity}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets lines that match the specified line ids.
#
# GET /Line/{ids}
# operationId: Line_Get
export def "line get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Line/{ids}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of arrival predictions for given line ids based at the given stop
#
# GET /Line/{ids}/Arrivals/{stopPointId}
# operationId: Line_Arrivals
export def "line-arrivals get" [
  ids: list
  stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --direction: string@direction-completer # Optional. The direction of travel. Can be inbound or outbound or all. If left blank, and destinationStopId is set, will default to all
  --destination-station-id: string # Optional. Id of destination stop
]: nothing -> table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "destinationStationId" $destination_station_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids), stop_point_id: (encode-path-segment $stop_point_id)} | format pattern "/Line/{ids}/Arrivals/{stop_point_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get disruptions for the given line ids
#
# GET /Line/{ids}/Disruption
# operationId: Line_Disruption
export def "line-disruption get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<additionalInfo: string, affectedRoutes: list<record>, affectedStops: list<record>, category: string, categoryDescription: string, closureText: string, created: string, description: string, lastUpdate: string, summary: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Line/{ids}/Disruption"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all valid routes for given line ids, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/{ids}/Route
# operationId: Line_LineRoutesByIds
export def "line-route get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Line/{ids}/Route") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status of for given line ids e.g Minor Delays
#
# GET /Line/{ids}/Status
# operationId: Line_StatusByIds
export def "line-status get-by-ids" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Line/{ids}/Status") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status for given line ids during the provided dates e.g Minor Delays
#
# GET /Line/{ids}/Status/{StartDate}/to/{EndDate}
# operationId: Line_Status
export def "line-status-to get" [
  ids: list
  start_date: string
  end_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --detail: oneof<nothing, bool> # Include details of the disruptions that are causing the line status including the affected stops and routes
  --start-date: string
  --end-date: string
  --date-range-start-date: string # format: date-time
  --date-range-end-date: string # format: date-time
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "dateRange.startDate" $date_range_start_date "scalar") (serialize-qp "dateRange.endDate" $date_range_end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids), start_date: (encode-path-segment $start_date), end_date: (encode-path-segment $end_date)} | format pattern "/Line/{ids}/Status/{start_date}/to/{end_date}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all valid routes for given line id, including the sequence of stops on each route.
#
# GET /Line/{id}/Route/Sequence/{direction}
# operationId: Line_RouteSequence
export def "line-route-sequence get" [
  id: string
  direction: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --service-types: list<string> # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
  --exclude-crowding: oneof<nothing, bool> # That excludes crowding from line disruptions. Can be true or false.
]: nothing -> record<direction: string, isOutboundOnly: bool, lineId: string, lineName: string, lineStrings: list<string>, mode: string, orderedLineRoutes: table<name: string, naptanIds: list, serviceType: string>, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, stopPointSequences: table<branchId: int, direction: string, lineId: string, lineName: string, nextBranchIds: list, prevBranchIds: list, serviceType: string, stopPoint: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi") (serialize-qp "excludeCrowding" $exclude_crowding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), direction: (encode-path-segment $direction)} | format pattern "/Line/{id}/Route/Sequence/{direction}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of the stations that serve the given line id
#
# GET /Line/{id}/StopPoints
# operationId: Line_StopPoints
export def "line-stop-points stop" [
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
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail line is requested, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tflOperatedNationalRailStationsOnly" $tfl_operated_national_rail_stations_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Line/{id}/StopPoints") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the timetable for a specified station on the give line
#
# GET /Line/{id}/Timetable/{fromStopPointId}
# operationId: Line_Timetable
export def "line-timetable get" [
  id: string
  from_stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), from_stop_point_id: (encode-path-segment $from_stop_point_id)} | format pattern "/Line/{id}/Timetable/{from_stop_point_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the timetable for a specified station on the give line with specified destination
#
# GET /Line/{id}/Timetable/{fromStopPointId}/to/{toStopPointId}
# operationId: Line_TimetableTo
export def "line-timetable-to get" [
  id: string
  from_stop_point_id: string
  to_stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id), from_stop_point_id: (encode-path-segment $from_stop_point_id), to_stop_point_id: (encode-path-segment $to_stop_point_id)} | format pattern "/Line/{id}/Timetable/{from_stop_point_id}/to/{to_stop_point_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the service type active for a mode. Currently only supports tube
#
# GET /Mode/ActiveServiceTypes
# operationId: Mode_GetActiveServiceTypes
export def "mode-active-service-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<mode: string, serviceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Mode/ActiveServiceTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the next arrival predictions for all stops of a given mode
#
# GET /Mode/{mode}/Arrivals
# operationId: Mode_Arrivals
export def "mode-arrivals get" [
  mode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --count: int # A number of arrivals to return for each stop, -1 to return all available. (format: int32)
]: nothing -> table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({mode: (encode-path-segment $mode)} | format pattern "/Mode/{mode}/Arrivals") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the occupancy for bike points.
#
# GET /Occupancy/BikePoints/{ids}
# operationId: Occupancy_GetBikePointsOccupancies
export def "occupancy-bike-points get-occupancies" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<bikesCount: int, eBikesCount: int, emptyDocks: int, id: string, name: string, standardBikesCount: int, totalDocks: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Occupancy/BikePoints/{ids}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for all car parks that have occupancy data
#
# GET /Occupancy/CarPark
export def "occupancy-car-park list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<bays: list<record>, carParkDetailsUrl: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Occupancy/CarPark")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for a car park with a given id
#
# GET /Occupancy/CarPark/{id}
# operationId: Occupancy_Get
export def "occupancy-car-park get" [
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
]: nothing -> record<bays: table<bayCount: int, bayType: string, free: int, occupied: int>, carParkDetailsUrl: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Occupancy/CarPark/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for all charge connectors
#
# GET /Occupancy/ChargeConnector
# operationId: Occupancy_GetAllChargeConnectorStatus
export def "occupancy-charge-connector get-list-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, sourceSystemPlaceId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Occupancy/ChargeConnector")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for a charge connectors with a given id (sourceSystemPlaceId)
#
# GET /Occupancy/ChargeConnector/{ids}
# operationId: Occupancy_GetChargeConnectorStatus
export def "occupancy-charge-connector get-status" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<id: int, sourceSystemPlaceId: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Occupancy/ChargeConnector/{ids}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the places that lie within a geographic region. The geographic region of interest can either be specified by using a lat/lon geo-point and a radius in metres to return places within the locus defined by the lat/lon of its centre or alternatively, by the use of a bounding box defined by the lat/lon of its north-west and south-east corners. Optionally filters on type and can strip properties for a smaller payload.
#
# GET /Place
# operationId: Place_GetByGeo
export def "place get-by-geo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --radius: float # The radius of the bounding circle in metres when only lat/lon are specified. (format: double)
  --categories: list<string> # An optional list of comma separated property categories to return in the Place's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /Place/Meta/categories endpoint)
  --include-children: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
  --type: list<string> # Place types to filter on, or null to return all types
  --active-only: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
  --number-of-places-to-return: int # If specified, limits the number of returned places equal to the given value (format: int32)
  --place-geo-sw-lat: float # format: double
  --place-geo-sw-lon: float # format: double
  --place-geo-ne-lat: float # format: double
  --place-geo-ne-lon: float # format: double
  --place-geo-lat: float # format: double
  --place-geo-lon: float # format: double
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "categories" $categories "multi") (serialize-qp "includeChildren" $include_children "scalar") (serialize-qp "type" $type "multi") (serialize-qp "activeOnly" $active_only "scalar") (serialize-qp "numberOfPlacesToReturn" $number_of_places_to_return "scalar") (serialize-qp "placeGeo.swLat" $place_geo_sw_lat "scalar") (serialize-qp "placeGeo.swLon" $place_geo_sw_lon "scalar") (serialize-qp "placeGeo.neLat" $place_geo_ne_lat "scalar") (serialize-qp "placeGeo.neLon" $place_geo_ne_lon "scalar") (serialize-qp "placeGeo.lat" $place_geo_lat "scalar") (serialize-qp "placeGeo.lon" $place_geo_lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Place" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the set of streets associated with a post code.
#
# GET /Place/Address/Streets/{Postcode}
# operationId: Place_GetStreetsByPostCode
export def "place-address-streets get-by-create-code" [
  postcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --postcode: string
  --postcode-input-postcode: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcodeInput.postcode" $postcode_input_postcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postcode: (encode-path-segment $postcode)} | format pattern "/Place/Address/Streets/{postcode}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all of the available place property categories and keys.
#
# GET /Place/Meta/Categories
# operationId: Place_MetaCategories
export def "place-meta-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<availableKeys: list<string>, category: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Place/Meta/Categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of the available types of Place.
#
# GET /Place/Meta/PlaceTypes
# operationId: Place_MetaPlaceTypes
export def "place-meta-place-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<availableKeys: list<string>, category: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Place/Meta/PlaceTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all places that matches the given query
#
# GET /Place/Search
# operationId: Place_Search
export def "place-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The name of the place, you can use the /Place/Types/{types} endpoint to get a list of places for a given type including their names.
  --types: list<string> # A comma-separated list of the types to return. Max. approx 12 types.
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "types" $types "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/Place/Search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all places of a given type
#
# GET /Place/Type/{types}
# operationId: Place_GetByType
export def "place-type get" [
  types: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --active-only: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "activeOnly" $active_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({types: (encode-path-segment $types)} | format pattern "/Place/Type/{types}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the place with the given id.
#
# GET /Place/{id}
# operationId: Place_Get
export def "place get" [
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
  --include-children: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChildren" $include_children "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/Place/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets any places of the given type whose geography intersects the given latitude and longitude. In practice this means the Place must be polygonal e.g. a BoroughBoundary.
#
# GET /Place/{type}/At/{Lat}/{Lon}
# operationId: Place_GetAt
export def "place-at get" [
  type: list
  lat: string
  lon: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --lat: string
  --lon: string
  --location-lat: float # format: double
  --location-lon: float # format: double
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "location.lat" $location_lat "scalar") (serialize-qp "location.lon" $location_lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), lat: (encode-path-segment $lat), lon: (encode-path-segment $lon)} | format pattern "/Place/{type}/At/{lat}/{lon}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the place overlay for a given set of co-ordinates and a given width/height.
#
# GET /Place/{type}/overlay/{z}/{Lat}/{Lon}/{width}/{height}
# operationId: Place_GetOverlay
export def "place-overlay get" [
  type: list
  z: int
  lat: string
  lon: string
  width: int
  height: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --lat: string
  --lon: string
  --location-lat: float # format: double
  --location-lon: float # format: double
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "location.lat" $location_lat "scalar") (serialize-qp "location.lon" $location_lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), z: (encode-path-segment $z), lat: (encode-path-segment $lat), lon: (encode-path-segment $lon), width: (encode-path-segment $width), height: (encode-path-segment $height)} | format pattern "/Place/{type}/overlay/{z}/{lat}/{lon}/{width}/{height}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all roads managed by TfL
#
# GET /Road
# operationId: Road_Get
export def "road list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Road")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid RoadDisruption categories
#
# GET /Road/Meta/Categories
# operationId: Road_MetaCategories
export def "road-meta-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Road/Meta/Categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of valid RoadDisruption severity codes
#
# GET /Road/Meta/Severities
# operationId: Road_MetaSeverities
export def "road-meta-severities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<description: string, modeName: string, severityLevel: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Road/Meta/Severities")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of active disruptions filtered by disruption Ids.
#
# GET /Road/all/Disruption/{disruptionIds}
# operationId: Road_DisruptionById
export def "road-all-disruption get" [
  disruption_ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --strip-content: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location and comments.
]: nothing -> record<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, geometry: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: table<endTime: string, startTime: string>, roadDisruptionImpactAreas: table<endDate: string, endTime: string, id: int, polygon: record, roadDisruptionId: string, startDate: string, startTime: string>, roadDisruptionLines: table<endDate: string, endTime: string, id: int, isDiversion: bool, multiLineString: record, roadDisruptionId: string, startDate: string, startTime: string>, roadProject: record<boroughsBenefited: list<string>, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: table<closure: string, directions: string, name: string, segments: list, sourceSystemId: int, sourceSystemKey: string>, subCategory: string, timeFrame: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripContent" $strip_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({disruption_ids: (encode-path-segment $disruption_ids)} | format pattern "/Road/all/Disruption/{disruption_ids}") $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of disrupted streets. If no date filters are provided, current disruptions are returned.
#
# GET /Road/all/Street/Disruption
# operationId: Road_DisruptedStreets
export def "road-all-street-disruption get-disrupted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-date: string # Optional, the start time to filter on. (format: date-time)
  --end-date: string # Optional, The end time to filter on. (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Road/all/Street/Disruption" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the road with the specified id (e.g. A1)
#
# GET /Road/{ids}
export def "road get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Road/{ids}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get active disruptions, filtered by road ids
#
# GET /Road/{ids}/Disruption
# operationId: Road_Disruption
export def "road-disruption get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --strip-content: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location, comments and streets
  --severities: list<string> # an optional list of Severity names to filter on (a valid list of severities can be obtained from the /Road/Meta/severities endpoint)
  --categories: list<string> # an optional list of category names to filter on (a valid list of categories can be obtained from the /Road/Meta/categories endpoint)
  --closures: oneof<nothing, bool> # Optional, defaults to true. When true, always includes disruptions that have road closures, regardless of the severity filter. When false, the severity filter works as normal.
]: nothing -> table<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record>, geometry: record<geography: record>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: list<record>, roadDisruptionImpactAreas: list<record>, roadDisruptionLines: list<record>, roadProject: record<boroughsBenefited: list, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: list<record>, subCategory: string, timeFrame: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripContent" $strip_content "scalar") (serialize-qp "severities" $severities "multi") (serialize-qp "categories" $categories "multi") (serialize-qp "closures" $closures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Road/{ids}/Disruption") $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified roads with the status aggregated over the date range specified, or now until the end of today if no dates are passed.
#
# GET /Road/{ids}/Status
# operationId: Road_Status
export def "road-status get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --date-range-nullable-start-date: string # format: date-time
  --date-range-nullable-end-date: string # format: date-time
]: nothing -> table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRangeNullable.startDate" $date_range_nullable_start_date "scalar") (serialize-qp "dateRangeNullable.endDate" $date_range_nullable_end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Road/{ids}/Status") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search the site for occurrences of the query string. The maximum number of results returned is equal to the maximum page size of 100. To return subsequent pages, use the paginated overload.
#
# GET /Search
# operationId: Search_Get
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The search query
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches the bus schedules folder on S3 for a given bus number.
#
# GET /Search/BusSchedules
# operationId: Search_BusSchedules
export def "search-bus-schedules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The search query
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Search/BusSchedules" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available search categories.
#
# GET /Search/Meta/Categories
# operationId: Search_MetaCategories
export def "search-meta-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Search/Meta/Categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available searchProvider names.
#
# GET /Search/Meta/SearchProviders
# operationId: Search_MetaSearchProviders
export def "search-meta-search-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Search/Meta/SearchProviders")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the available sorting options.
#
# GET /Search/Meta/Sorts
# operationId: Search_MetaSorts
export def "search-meta-sorts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Search/Meta/Sorts")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of StopPoints within {radius} by the specified criteria
#
# GET /StopPoint
# operationId: StopPoint_GetByGeoPoint
export def "stop-point get-by-geo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stop-types: list<string> # a list of stopTypes that should be returned (a list of valid stop types can be obtained from the StopPoint/meta/stoptypes endpoint)
  --radius: int # the radius of the bounding circle in metres (default : 200) (format: int32)
  --use-stop-point-hierarchy: oneof<nothing, bool> # Re-arrange the output into a parent/child hierarchy
  --modes: list<string> # the list of modes to search (comma separated mode names e.g. tube,dlr)
  --categories: list<string> # an optional list of comma separated property categories to return in the StopPoint's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /StopPoint/Meta/categories endpoint)
  --return-lines: oneof<nothing, bool> # true to return the lines that each stop point serves as a nested resource
  --location-lat: float # format: double
  --location-lon: float # format: double
]: nothing -> record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stopTypes" $stop_types "multi") (serialize-qp "radius" $radius "scalar") (serialize-qp "useStopPointHierarchy" $use_stop_point_hierarchy "scalar") (serialize-qp "modes" $modes "multi") (serialize-qp "categories" $categories "multi") (serialize-qp "returnLines" $return_lines "scalar") (serialize-qp "location.lat" $location_lat "scalar") (serialize-qp "location.lon" $location_lon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of available StopPoint additional information categories
#
# GET /StopPoint/Meta/Categories
# operationId: StopPoint_MetaCategories
export def "stop-point-meta-categories stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<availableKeys: list<string>, category: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StopPoint/Meta/Categories")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of available StopPoint modes
#
# GET /StopPoint/Meta/Modes
# operationId: StopPoint_MetaModes
export def "stop-point-meta-modes stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<isFarePaying: bool, isScheduledService: bool, isTflService: bool, modeName: string, motType: string, network: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StopPoint/Meta/Modes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of available StopPoint types
#
# GET /StopPoint/Meta/StopTypes
# operationId: StopPoint_MetaStopTypes
export def "stop-point-meta-stop-types stop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/StopPoint/Meta/StopTypes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of StopPoints filtered by the modes available at that StopPoint.
#
# GET /StopPoint/Mode/{modes}
# operationId: StopPoint_GetByMode
export def "stop-point-mode get" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The data set page to return. Page 1 equates to the first 1000 stop points, page 2 equates to 1001-2000 etc. Must be entered for bus mode as data set is too large. (format: int32)
]: nothing -> record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/StopPoint/Mode/{modes}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a distinct list of disrupted stop points for the given modes
#
# GET /StopPoint/Mode/{modes}/Disruption
# operationId: StopPoint_DisruptionByMode
export def "stop-point-mode-disruption stop" [
  modes: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-route-blocked-stops: oneof<nothing, bool>
]: nothing -> table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeRouteBlockedStops" $include_route_blocked_stops "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({modes: (encode-path-segment $modes)} | format pattern "/StopPoint/Mode/{modes}/Disruption") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search StopPoints by their common name, or their 5-digit Countdown Bus Stop Code.
#
# GET /StopPoint/Search
export def "stop-point-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # The query string, case-insensitive. Leading and trailing wildcards are applied automatically.
  --modes: list<string> # An optional, parameter separated list of the modes to filter by
  --fares-only: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --max-results: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches, it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list<string> # An optional, parameter separated list of the lines to filter by
  --include-hubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "modes" $modes "multi") (serialize-qp "faresOnly" $fares_only "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "lines" $lines "multi") (serialize-qp "includeHubs" $include_hubs "scalar") (serialize-qp "tflOperatedNationalRailStationsOnly" $tfl_operated_national_rail_stations_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint/Search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search StopPoints by their common name, or their 5-digit Countdown Bus Stop Code.
#
# GET /StopPoint/Search/{query}
# operationId: StopPoint_Search
export def "stop-point-search stop" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --modes: list<string> # An optional, parameter separated list of the modes to filter by
  --fares-only: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --max-results: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches, it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list<string> # An optional, parameter separated list of the lines to filter by
  --include-hubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tfl-operated-national-rail-stations-only: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "multi") (serialize-qp "faresOnly" $fares_only "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "lines" $lines "multi") (serialize-qp "includeHubs" $include_hubs "scalar") (serialize-qp "tflOperatedNationalRailStationsOnly" $tfl_operated_national_rail_stations_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/StopPoint/Search/{query}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service types for a given stoppoint
#
# GET /StopPoint/ServiceTypes
# operationId: StopPoint_GetServiceTypes
export def "stop-point-service-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string # The Naptan id of the stop
  --line-ids: list<string> # The lines which contain the given Naptan id (all lines relevant to the given stoppoint if empty)
  --modes: list<string> # The modes which the lines are relevant to (all if empty)
]: nothing -> table<lineName: string, lineSpecificServiceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "lineIds" $line_ids "multi") (serialize-qp "modes" $modes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint/ServiceTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a StopPoint for a given sms code.
#
# GET /StopPoint/Sms/{id}
# operationId: StopPoint_GetBySms
export def "stop-point-sms get" [
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
  --output: string # If set to "web", a 302 redirect to relevant website bus stop page is returned. Valid values are : web. All other values are ignored.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "output" $output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/StopPoint/Sms/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all stop points of a given type
#
# GET /StopPoint/Type/{types}
# operationId: StopPoint_GetByType
export def "stop-point-type get" [
  types: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({types: (encode-path-segment $types)} | format pattern "/StopPoint/Type/{types}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the stop points of given type(s) with a page number
#
# GET /StopPoint/Type/{types}/page/{page}
# operationId: StopPoint_GetByTypeWithPagination
export def "stop-point-type-page get-by-with-pagination" [
  types: list
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({types: (encode-path-segment $types), page: (encode-path-segment $page)} | format pattern "/StopPoint/Type/{types}/page/{page}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of StopPoints corresponding to the given list of stop ids.
#
# GET /StopPoint/{ids}
# operationId: StopPoint_Get
export def "stop-point get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-crowding-data: oneof<nothing, bool> # Include the crowding data (static). To Filter further use: /StopPoint/{ids}/Crowding/{line}
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCrowdingData" $include_crowding_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/StopPoint/{ids}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all disruptions for the specified StopPointId, plus disruptions for any child Naptan records it may have.
#
# GET /StopPoint/{ids}/Disruption
# operationId: StopPoint_Disruption
export def "stop-point-disruption stop" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --get-family: oneof<nothing, bool> # Specify true to return disruptions for entire family, or false to return disruptions for just this stop point. Defaults to false.
  --include-route-blocked-stops: oneof<nothing, bool>
  --flatten-response: oneof<nothing, bool> # Specify true to associate all disruptions with parent stop point. (Only applicable when getFamily is true).
]: nothing -> table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getFamily" $get_family "scalar") (serialize-qp "includeRouteBlockedStops" $include_route_blocked_stops "scalar") (serialize-qp "flattenResponse" $flatten_response "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/StopPoint/{ids}/Disruption") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of arrival and departure predictions for the given stop point id (overground, Elizabeth line and thameslink only)
#
# GET /StopPoint/{id}/ArrivalDepartures
# operationId: StopPoint_ArrivalDepartures
export def "stop-point-arrival-departures stop" [
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
  --line-ids: list<string> # A comma-separated list of line ids e.g. elizabeth, london-overground, thameslink
]: nothing -> table<cause: string, departureStatus: string, destinationName: string, destinationNaptanId: string, estimatedTimeOfArrival: string, estimatedTimeOfDeparture: string, minutesAndSecondsToArrival: string, minutesAndSecondsToDeparture: string, naptanId: string, platformName: string, scheduledTimeOfArrival: string, scheduledTimeOfDeparture: string, stationName: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lineIds" $line_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/StopPoint/{id}/ArrivalDepartures") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of arrival predictions for the given stop point id
#
# GET /StopPoint/{id}/Arrivals
# operationId: StopPoint_Arrivals
export def "stop-point-arrivals stop" [
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
]: nothing -> table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/StopPoint/{id}/Arrivals"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Stopoints that are reachable from a station/line combination.
#
# GET /StopPoint/{id}/CanReachOnLine/{lineId}
# operationId: StopPoint_ReachableFrom
export def "stop-point-can-reach-on-line stop-reachable" [
  id: string
  line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --service-types: list<string> # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), line_id: (encode-path-segment $line_id)} | format pattern "/StopPoint/{id}/CanReachOnLine/{line_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the Crowding data (static) for the StopPointId, plus crowding data for a given line and optionally a particular direction.
#
# GET /StopPoint/{id}/Crowding/{line}
# operationId: StopPoint_Crowding
export def "stop-point-crowding stop" [
  id: string
  line: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --direction: string@direction-completer # The direction of travel. Can be inbound or outbound.
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), line: (encode-path-segment $line)} | format pattern "/StopPoint/{id}/Crowding/{line}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the canonical direction, "inbound" or "outbound", for a given pair of stop point Ids in the direction from -> to.
#
# GET /StopPoint/{id}/DirectionTo/{toStopPointId}
# operationId: StopPoint_Direction
export def "stop-point-direction-to stop" [
  id: string
  to_stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --line-id: string # Optional line id filter e.g. victoria
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lineId" $line_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), to_stop_point_id: (encode-path-segment $to_stop_point_id)} | format pattern "/StopPoint/{id}/DirectionTo/{to_stop_point_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the route sections for all the lines that service the given stop point ids
#
# GET /StopPoint/{id}/Route
# operationId: StopPoint_Route
export def "stop-point-route stop" [
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
  --service-types: list<string> # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<destinationName: string, direction: string, isActive: bool, lineId: string, lineString: string, mode: string, naptanId: string, routeSectionName: string, serviceType: string, validFrom: string, validTo: string, vehicleDestinationText: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $service_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/StopPoint/{id}/Route") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of places corresponding to a given id and place types.
#
# GET /StopPoint/{id}/placeTypes
export def "stop-point-place-types get" [
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
  --place-types: list<string> # A comcomma-separated value representing the place types.
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeTypes" $place_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/StopPoint/{id}/placeTypes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get car parks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/CarParks
# operationId: StopPoint_GetCarParksById
export def "stop-point-car-parks get" [
  stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stop_point_id: (encode-path-segment $stop_point_id)} | format pattern "/StopPoint/{stop_point_id}/CarParks"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of taxi ranks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/TaxiRanks
# operationId: StopPoint_GetTaxiRanksByIds
export def "stop-point-taxi-ranks get" [
  stop_point_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({stop_point_id: (encode-path-segment $stop_point_id)} | format pattern "/StopPoint/{stop_point_id}/TaxiRanks"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/compareOverlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# operationId: TravelTime_GetCompareOverlay
export def "travel-times-compare-overlay-mapcenter-pinlocation-dimensions get" [
  z: int
  map_center_lat: float
  map_center_lon: float
  pin_lat: float
  pin_lon: float
  width: int
  height: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scenario-title: string # The title of the scenario.
  --time-of-day-id: string # The id for the time of day (AM/INTER/PM)
  --mode-id: string # The id of the mode.
  --direction: string@direction-completer-1 # The direction of travel.
  --travel-time-interval: int # The total minutes between the travel time bands (format: int32)
  --compare-type: string
  --compare-value: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioTitle" $scenario_title "scalar") (serialize-qp "timeOfDayId" $time_of_day_id "scalar") (serialize-qp "modeId" $mode_id "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "travelTimeInterval" $travel_time_interval "scalar") (serialize-qp "compareType" $compare_type "scalar") (serialize-qp "compareValue" $compare_value "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({z: (encode-path-segment $z), map_center_lat: (encode-path-segment $map_center_lat), map_center_lon: (encode-path-segment $map_center_lon), pin_lat: (encode-path-segment $pin_lat), pin_lon: (encode-path-segment $pin_lon), width: (encode-path-segment $width), height: (encode-path-segment $height)} | format pattern "/TravelTimes/compareOverlay/{z}/mapcenter/{map_center_lat}/{map_center_lon}/pinlocation/{pin_lat}/{pin_lon}/dimensions/{width}/{height}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/overlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# operationId: TravelTime_GetOverlay
export def "travel-times-overlay-mapcenter-pinlocation-dimensions get" [
  z: int
  map_center_lat: float
  map_center_lon: float
  pin_lat: float
  pin_lon: float
  width: int
  height: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --scenario-title: string # The title of the scenario.
  --time-of-day-id: string # The id for the time of day (AM/INTER/PM)
  --mode-id: string # The id of the mode.
  --direction: string@direction-completer-1 # The direction of travel.
  --travel-time-interval: int # The total minutes between the travel time bands (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioTitle" $scenario_title "scalar") (serialize-qp "timeOfDayId" $time_of_day_id "scalar") (serialize-qp "modeId" $mode_id "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "travelTimeInterval" $travel_time_interval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({z: (encode-path-segment $z), map_center_lat: (encode-path-segment $map_center_lat), map_center_lon: (encode-path-segment $map_center_lon), pin_lat: (encode-path-segment $pin_lat), pin_lon: (encode-path-segment $pin_lon), width: (encode-path-segment $width), height: (encode-path-segment $height)} | format pattern "/TravelTimes/overlay/{z}/mapcenter/{map_center_lat}/{map_center_lon}/pinlocation/{pin_lat}/{pin_lon}/dimensions/{width}/{height}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the predictions for a given list of vehicle Id's.
#
# GET /Vehicle/{ids}/Arrivals
# operationId: Vehicle_Get
export def "vehicle-arrivals get" [
  ids: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ids: (encode-path-segment $ids)} | format pattern "/Vehicle/{ids}/Arrivals"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
