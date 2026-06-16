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
def timeIs-completer [] { ["Arriving" "Departing"] }
def journeyPreference-completer [] { ["LeastInterchange" "LeastTime" "LeastWalking"] }
def walkingSpeed-completer [] { ["Average" "Fast" "Slow"] }
def cyclePreference-completer [] { ["AllTheWay" "CycleHire" "LeaveAtStation" "None" "TakeOnTransport"] }
def direction-completer [] { ["all" "inbound" "outbound"] }
def accept-completer-1 [] { ["application/geo+json" "application/json" "application/xml" "text/json" "text/xml"] }
def direction-completer-1 [] { ["Average" "From" "To"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accident-stats Get" } } | get name | first)
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
export def "accident-stats Get" [
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
  let full_url = (build-url $base $"/AccidentStats/($year)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets air quality data feed
#
# GET /AirQuality
# operationId: AirQuality_Get
export def "air-quality Get" [
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

# Gets all bike point locations. The Place object has an addtionalProperties array which contains the nbBikes, nbDocks and nbSpaces             numbers which give the status of the BikePoint. A mismatch in these numbers i.e. nbDocks - (nbBikes + nbSpaces) != 0 indicates broken docks.
#
# GET /BikePoint
# operationId: BikePoint_GetAll
export def "bike-point GetAll" [
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

# Search for bike stations by their name, a bike point's name often contains information about the name of the street             or nearby landmarks, for example. Note that the search result does not contain the PlaceProperties i.e. the status             or occupancy of the BikePoint, to get that information you should retrieve the BikePoint by its id on /BikePoint/id.
#
# GET /BikePoint/Search
# operationId: BikePoint_Search
export def "bike-point-search Search" [
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
export def "bike-point Get" [
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
  let full_url = (build-url $base $"/BikePoint/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets taxis and minicabs contact information
#
# GET /Cabwise/search
# operationId: Cabwise_Get
export def "cabwise-search Get" [
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
  --maxResults: int # An optional parameter to limit the number of results return. Default and maximum is 20. (format: int32)
  --legacyFormat: oneof<nothing, bool> # Legacy Format
  --forceXml: oneof<nothing, bool> # Force Xml
  --twentyFourSevenOnly: oneof<nothing, bool> # Twenty Four Seven Only
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "optype" $optype "scalar") (serialize-qp "wc" $wc "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "legacyFormat" $legacyFormat "scalar") (serialize-qp "forceXml" $forceXml "scalar") (serialize-qp "twentyFourSevenOnly" $twentyFourSevenOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Cabwise/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform a Journey Planner search from the parameters specified in simple types
#
# GET /Journey/JourneyResults/{from}/to/{to}
# operationId: Journey_JourneyResults
export def "journey-journey-results-to JourneyResults" [
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
  --nationalSearch: oneof<nothing, bool> # Does the journey cover stops outside London? eg. "nationalSearch=true"
  --date: string # The date must be in yyyyMMdd format
  --time: string # The time must be in HHmm format
  --timeIs: string@timeIs-completer # Does the time given relate to arrival or leaving time? Possible options: "departing" | "arriving"
  --journeyPreference: string@journeyPreference-completer # The journey preference eg possible options: "leastinterchange" | "leasttime" | "leastwalking"
  --mode: list # The mode must be a comma separated list of modes. eg possible options: "public-bus,overground,train,tube,coach,dlr,cablecar,tram,river,walking,cycle"
  --accessibilityPreference: list # The accessibility preference must be a comma separated list eg. "noSolidStairs,noEscalators,noElevators,stepFreeToVehicle,stepFreeToPlatform"
  --fromName: string # An optional name to associate with the origin of the journey in the results.
  --toName: string # An optional name to associate with the destination of the journey in the results.
  --viaName: string # An optional name to associate with the via point of the journey in the results.
  --maxTransferMinutes: string # The max walking time in minutes for transfer eg. "120"
  --maxWalkingMinutes: string # The max walking time in minutes for journeys eg. "120"
  --walkingSpeed: string@walkingSpeed-completer # The walking speed. eg possible options: "slow" | "average" | "fast".
  --cyclePreference: string@cyclePreference-completer # The cycle preference. eg possible options: "allTheWay" | "leaveAtStation" | "takeOnTransport" | "cycleHire"
  --adjustment: string # Time adjustment command. eg possible options: "TripFirst" | "TripLast"
  --bikeProficiency: list # A comma separated list of cycling proficiency levels. eg possible options: "easy,moderate,fast"
  --alternativeCycle: oneof<nothing, bool> # Option to determine whether to return alternative cycling journey
  --alternativeWalking: oneof<nothing, bool> # Option to determine whether to return alternative walking journey
  --applyHtmlMarkup: oneof<nothing, bool> # Flag to determine whether certain text (e.g. walking instructions) should be output with HTML tags or not.
  --useMultiModalCall: oneof<nothing, bool> # A boolean to indicate whether or not to return 3 public transport journeys, a bus journey, a cycle hire journey, a personal cycle journey and a walking journey
  --walkingOptimization: oneof<nothing, bool> # A boolean to indicate whether to optimize journeys using walking
  --taxiOnlyTrip: oneof<nothing, bool> # A boolean to indicate whether to return one or more taxi journeys. Note, setting this to true will override "useMultiModalCall".
  --routeBetweenEntrances: oneof<nothing, bool> # A boolean to indicate whether public transport routes should include directions between platforms and station entrances.
  --useRealTimeLiveArrivals: oneof<nothing, bool> # A boolean to indicate if we want to receive real time live arrivals data where available.
  --calcOneDirection: oneof<nothing, bool> # A boolean to make Journey Planner calculate journeys in one temporal direction only. In other words, only calculate journeys after the 'depart' time, or before the 'arrive' time. By default, the Journey Planner engine (EFA) calculates journeys in both temporal directions.
]: nothing -> record<cycleHireDockingStationData: record<destinationId: string, destinationNumberOfBikes: int, destinationNumberOfEmptySlots: int, originId: string, originNumberOfBikes: int, originNumberOfEmptySlots: int>, journeyVector: record<from: string, to: string, uri: string, via: string>, journeys: table<arrivalDateTime: string, duration: int, fare: record, legs: list, startDateTime: string>, lines: table<created: string, crowding: record, disruptions: list, id: string, lineStatuses: list, modeName: string, modified: string, name: string, routeSections: list, serviceTypes: list>, recommendedMaxAgeMinutes: int, searchCriteria: record<dateTime: string, dateTimeType: string, timeAdjustments: record<earlier: record, earliest: record, later: record, latest: record>>, stopMessages: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "via" $via "scalar") (serialize-qp "nationalSearch" $nationalSearch "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "timeIs" $timeIs "scalar") (serialize-qp "journeyPreference" $journeyPreference "scalar") (serialize-qp "mode" $mode "multi") (serialize-qp "accessibilityPreference" $accessibilityPreference "multi") (serialize-qp "fromName" $fromName "scalar") (serialize-qp "toName" $toName "scalar") (serialize-qp "viaName" $viaName "scalar") (serialize-qp "maxTransferMinutes" $maxTransferMinutes "scalar") (serialize-qp "maxWalkingMinutes" $maxWalkingMinutes "scalar") (serialize-qp "walkingSpeed" $walkingSpeed "scalar") (serialize-qp "cyclePreference" $cyclePreference "scalar") (serialize-qp "adjustment" $adjustment "scalar") (serialize-qp "bikeProficiency" $bikeProficiency "multi") (serialize-qp "alternativeCycle" $alternativeCycle "scalar") (serialize-qp "alternativeWalking" $alternativeWalking "scalar") (serialize-qp "applyHtmlMarkup" $applyHtmlMarkup "scalar") (serialize-qp "useMultiModalCall" $useMultiModalCall "scalar") (serialize-qp "walkingOptimization" $walkingOptimization "scalar") (serialize-qp "taxiOnlyTrip" $taxiOnlyTrip "scalar") (serialize-qp "routeBetweenEntrances" $routeBetweenEntrances "scalar") (serialize-qp "useRealTimeLiveArrivals" $useRealTimeLiveArrivals "scalar") (serialize-qp "calcOneDirection" $calcOneDirection "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Journey/JourneyResults/($from)/to/($to)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all of the available journey planner modes
#
# GET /Journey/Meta/Modes
# operationId: Journey_Meta
export def "journey-meta-modes Meta" [
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
export def "line-meta-disruption-categories MetaDisruptionCategories" [
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
export def "line-meta-modes MetaModes" [
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
export def "line-meta-service-types MetaServiceTypes" [
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
export def "line-meta-severity MetaSeverity" [
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
export def "line-mode GetByMode" [
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
  let full_url = (build-url $base $"/Line/Mode/($modes)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get disruptions for all lines of the given modes.
#
# GET /Line/Mode/{modes}/Disruption
# operationId: Line_DisruptionByMode
export def "line-mode-disruption DisruptionByMode" [
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
  let full_url = (build-url $base $"/Line/Mode/($modes)/Disruption")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all lines and their valid routes for given modes, including the name and id of the originating and terminating stops for each route
#
# GET /Line/Mode/{modes}/Route
# operationId: Line_RouteByMode
export def "line-mode-route RouteByMode" [
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
  --serviceTypes: list # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/Mode/($modes)/Route" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status of for all lines for the given modes
#
# GET /Line/Mode/{modes}/Status
# operationId: Line_StatusByMode
export def "line-mode-status StatusByMode" [
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
  --severityLevel: string # If specified, ensures that only those line status(es) are returned within the lines that have disruptions with the matching severity level.
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar") (serialize-qp "severityLevel" $severityLevel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/Mode/($modes)/Status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all valid routes for all lines, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/Route
# operationId: Line_Route
export def "line-route Route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serviceTypes: list # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/Line/Route" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for lines or routes matching the query string
#
# GET /Line/Search/{query}
# operationId: Line_Search
export def "line-search Search" [
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
  --modes: list # Optionally filter by the specified modes
  --serviceTypes: list # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> record<input: string, searchMatches: table<id: string, lat: float, lineId: string, lineName: string, lineRouteSection: list, lon: float, matchedRouteSections: list, matchedStops: list, mode: string, name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "multi") (serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/Search/($query)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status for all lines with a given severity             A list of valid severity codes can be obtained from a call to Line/Meta/Severity
#
# GET /Line/Status/{severity}
# operationId: Line_StatusBySeverity
export def "line-status StatusBySeverity" [
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
  let full_url = (build-url $base $"/Line/Status/($severity)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets lines that match the specified line ids.
#
# GET /Line/{ids}
# operationId: Line_Get
export def "line Get" [
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
  let full_url = (build-url $base $"/Line/($ids)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of arrival predictions for given line ids based at the given stop
#
# GET /Line/{ids}/Arrivals/{stopPointId}
# operationId: Line_Arrivals
export def "line-arrivals Arrivals" [
  ids: list
  stopPointId: string
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
  --destinationStationId: string # Optional. Id of destination stop
]: nothing -> table<bearing: string, currentLocation: string, destinationName: string, destinationNaptanId: string, direction: string, expectedArrival: string, id: string, lineId: string, lineName: string, modeName: string, naptanId: string, operationType: int, platformName: string, stationName: string, timeToLive: string, timeToStation: int, timestamp: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>, towards: string, vehicleId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar") (serialize-qp "destinationStationId" $destinationStationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/($ids)/Arrivals/($stopPointId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get disruptions for the given line ids
#
# GET /Line/{ids}/Disruption
# operationId: Line_Disruption
export def "line-disruption Disruption" [
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
  let full_url = (build-url $base $"/Line/($ids)/Disruption")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all valid routes for given line ids, including the name and id of the originating and terminating stops for each route.
#
# GET /Line/{ids}/Route
# operationId: Line_LineRoutesByIds
export def "line-route LineRoutesByIds" [
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
  --serviceTypes: list # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/($ids)/Route" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status of for given line ids e.g Minor Delays
#
# GET /Line/{ids}/Status
# operationId: Line_StatusByIds
export def "line-status StatusByIds" [
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
  let full_url = (build-url $base $"/Line/($ids)/Status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the line status for given line ids during the provided dates e.g Minor Delays
#
# GET /Line/{ids}/Status/{StartDate}/to/{EndDate}
# operationId: Line_Status
export def "line-status-to Status" [
  ids: list
  StartDate: string
  EndDate: string
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
  --startDate: string
  --endDate: string
  --dateRangestartDate: string # format: date-time
  --dateRangeendDate: string # format: date-time
]: nothing -> table<created: string, crowding: record<passengerFlows: list, trainLoadings: list>, disruptions: list<record>, id: string, lineStatuses: list<record>, modeName: string, modified: string, name: string, routeSections: list<record>, serviceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detail" $detail "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "dateRange.startDate" $dateRangestartDate "scalar") (serialize-qp "dateRange.endDate" $dateRangeendDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/($ids)/Status/($StartDate)/to/($EndDate)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all valid routes for given line id, including the sequence of stops on each route.
#
# GET /Line/{id}/Route/Sequence/{direction}
# operationId: Line_RouteSequence
export def "line-route-sequence RouteSequence" [
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
  --serviceTypes: list # A comma seperated list of service types to filter on. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
  --excludeCrowding: oneof<nothing, bool> # That excludes crowding from line disruptions. Can be true or false.
]: nothing -> record<direction: string, isOutboundOnly: bool, lineId: string, lineName: string, lineStrings: list<string>, mode: string, orderedLineRoutes: table<name: string, naptanIds: list, serviceType: string>, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, stopPointSequences: table<branchId: int, direction: string, lineId: string, lineName: string, nextBranchIds: list, prevBranchIds: list, serviceType: string, stopPoint: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi") (serialize-qp "excludeCrowding" $excludeCrowding "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/($id)/Route/Sequence/($direction)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of the stations that serve the given line id
#
# GET /Line/{id}/StopPoints
# operationId: Line_StopPoints
export def "line-stop-points StopPoints" [
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
  --tflOperatedNationalRailStationsOnly: oneof<nothing, bool> # If the national-rail line is requested, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tflOperatedNationalRailStationsOnly" $tflOperatedNationalRailStationsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Line/($id)/StopPoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the timetable for a specified station on the give line
#
# GET /Line/{id}/Timetable/{fromStopPointId}
# operationId: Line_Timetable
export def "line-timetable Timetable" [
  fromStopPointId: string
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
]: nothing -> record<direction: string, disambiguation: record<disambiguationOptions: list<record>>, lineId: string, lineName: string, pdfUrl: string, stations: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, statusErrorMessage: string, stops: table<accessibilitySummary: string, direction: string, hasDisruption: bool, icsId: string, id: string, lat: float, lines: list, lon: float, modes: list, name: string, parentId: string, routeId: int, stationId: string, status: bool, stopLetter: string, stopType: string, topMostParentId: string, towards: string, url: string, zone: string>, timetable: record<departureStopId: string, routes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Line/($id)/Timetable/($fromStopPointId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the timetable for a specified station on the give line with specified destination
#
# GET /Line/{id}/Timetable/{fromStopPointId}/to/{toStopPointId}
# operationId: Line_TimetableTo
export def "line-timetable-to TimetableTo" [
  fromStopPointId: string
  id: string
  toStopPointId: string
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
  let full_url = (build-url $base $"/Line/($id)/Timetable/($fromStopPointId)/to/($toStopPointId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the service type active for a mode.             Currently only supports tube
#
# GET /Mode/ActiveServiceTypes
# operationId: Mode_GetActiveServiceTypes
export def "mode-active-service-types GetActiveServiceTypes" [
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
export def "mode-arrivals Arrivals" [
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
  let full_url = (build-url $base $"/Mode/($mode)/Arrivals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the occupancy for bike points.
#
# GET /Occupancy/BikePoints/{ids}
# operationId: Occupancy_GetBikePointsOccupancies
export def "occupancy-bike-points GetBikePointsOccupancies" [
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
  let full_url = (build-url $base $"/Occupancy/BikePoints/($ids)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for all car parks that have occupancy data
#
# GET /Occupancy/CarPark
export def "occupancy-car-park get" [
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
export def "occupancy-car-park Get" [
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
  let full_url = (build-url $base $"/Occupancy/CarPark/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the occupancy for all charge connectors
#
# GET /Occupancy/ChargeConnector
# operationId: Occupancy_GetAllChargeConnectorStatus
export def "occupancy-charge-connector GetAllChargeConnectorStatus" [
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
export def "occupancy-charge-connector GetChargeConnectorStatus" [
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
  let full_url = (build-url $base $"/Occupancy/ChargeConnector/($ids)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the places that lie within a geographic region. The geographic region of interest can either be specified             by using a lat/lon geo-point and a radius in metres to return places within the locus defined by the lat/lon of             its centre or alternatively, by the use of a bounding box defined by the lat/lon of its north-west and south-east corners.             Optionally filters on type and can strip properties for a smaller payload.
#
# GET /Place
# operationId: Place_GetByGeo
export def "place GetByGeo" [
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
  --categories: list # An optional list of comma separated property categories to return in the Place's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /Place/Meta/categories endpoint)
  --includeChildren: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
  --type: list # Place types to filter on, or null to return all types
  --activeOnly: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
  --numberOfPlacesToReturn: int # If specified, limits the number of returned places equal to the given value (format: int32)
  --placeGeoswLat: float # format: double
  --placeGeoswLon: float # format: double
  --placeGeoneLat: float # format: double
  --placeGeoneLon: float # format: double
  --placeGeolat: float # format: double
  --placeGeolon: float # format: double
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "categories" $categories "multi") (serialize-qp "includeChildren" $includeChildren "scalar") (serialize-qp "type" $type "multi") (serialize-qp "activeOnly" $activeOnly "scalar") (serialize-qp "numberOfPlacesToReturn" $numberOfPlacesToReturn "scalar") (serialize-qp "placeGeo.swLat" $placeGeoswLat "scalar") (serialize-qp "placeGeo.swLon" $placeGeoswLon "scalar") (serialize-qp "placeGeo.neLat" $placeGeoneLat "scalar") (serialize-qp "placeGeo.neLon" $placeGeoneLon "scalar") (serialize-qp "placeGeo.lat" $placeGeolat "scalar") (serialize-qp "placeGeo.lon" $placeGeolon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Place" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the set of streets associated with a post code.
#
# GET /Place/Address/Streets/{Postcode}
# operationId: Place_GetStreetsByPostCode
export def "place-address-streets GetStreetsByPostCode" [
  Postcode: string
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
  --postcodeInputpostcode: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "postcode" $postcode "scalar") (serialize-qp "postcodeInput.postcode" $postcodeInputpostcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Place/Address/Streets/($Postcode)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of all of the available place property categories and keys.
#
# GET /Place/Meta/Categories
# operationId: Place_MetaCategories
export def "place-meta-categories MetaCategories" [
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
export def "place-meta-place-types MetaPlaceTypes" [
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
export def "place-search Search" [
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
  --types: list # A comma-separated list of the types to return. Max. approx 12 types.
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
export def "place-type GetByType" [
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
  --activeOnly: oneof<nothing, bool> # An optional parameter to limit the results to active records only (Currently only the 'VariableMessageSign' place type is supported)
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "activeOnly" $activeOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Place/Type/($types)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the place with the given id.
#
# GET /Place/{id}
# operationId: Place_Get
export def "place Get" [
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
  --includeChildren: oneof<nothing, bool> # Defaults to false. If true child places e.g. individual charging stations at a charge point while be included, otherwise just the URLs of any child places will be returned
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeChildren" $includeChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Place/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets any places of the given type whose geography intersects the given latitude and longitude. In practice this means the Place             must be polygonal e.g. a BoroughBoundary.
#
# GET /Place/{type}/At/{Lat}/{Lon}
# operationId: Place_GetAt
export def "place-at GetAt" [
  type: list
  Lat: string
  Lon: string
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
  --locationlat: float # format: double
  --locationlon: float # format: double
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "location.lat" $locationlat "scalar") (serialize-qp "location.lon" $locationlon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Place/($type)/At/($Lat)/($Lon)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the place overlay for a given set of co-ordinates and a given width/height.
#
# GET /Place/{type}/overlay/{z}/{Lat}/{Lon}/{width}/{height}
# operationId: Place_GetOverlay
export def "place-overlay GetOverlay" [
  z: int
  type: list
  width: int
  height: int
  Lat: string
  Lon: string
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
  --locationlat: float # format: double
  --locationlon: float # format: double
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "location.lat" $locationlat "scalar") (serialize-qp "location.lon" $locationlon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Place/($type)/overlay/($z)/($Lat)/($Lon)/($width)/($height)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all roads managed by TfL
#
# GET /Road
# operationId: Road_Get
export def "road Get" [
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
export def "road-meta-categories MetaCategories" [
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
export def "road-meta-severities MetaSeverities" [
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
export def "road-all-disruption DisruptionById" [
  disruptionIds: list
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --stripContent: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location and comments.
]: nothing -> record<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, geometry: record<geography: record<coordinateSystemId: int, wellKnownBinary: string, wellKnownText: string>>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: table<endTime: string, startTime: string>, roadDisruptionImpactAreas: table<endDate: string, endTime: string, id: int, polygon: record, roadDisruptionId: string, startDate: string, startTime: string>, roadDisruptionLines: table<endDate: string, endTime: string, id: int, isDiversion: bool, multiLineString: record, roadDisruptionId: string, startDate: string, startTime: string>, roadProject: record<boroughsBenefited: list<string>, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: table<closure: string, directions: string, name: string, segments: list, sourceSystemId: int, sourceSystemKey: string>, subCategory: string, timeFrame: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripContent" $stripContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Road/all/Disruption/($disruptionIds)" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of disrupted streets. If no date filters are provided, current disruptions are returned.
#
# GET /Road/all/Street/Disruption
# operationId: Road_DisruptedStreets
export def "road-all-street-disruption DisruptedStreets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --startDate: string # Optional, the start time to filter on. (format: date-time)
  --endDate: string # Optional, The end time to filter on. (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
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
  let full_url = (build-url $base $"/Road/($ids)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get active disruptions, filtered by road ids
#
# GET /Road/{ids}/Disruption
# operationId: Road_Disruption
export def "road-disruption Disruption" [
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
  --stripContent: oneof<nothing, bool> # Optional, defaults to false. When true, removes every property/node except for id, point, severity, severityDescription, startDate, endDate, corridor details, location, comments and streets
  --severities: list # an optional list of Severity names to filter on (a valid list of severities can be obtained from the /Road/Meta/severities endpoint)
  --categories: list # an optional list of category names to filter on (a valid list of categories can be obtained from the /Road/Meta/categories endpoint)
  --closures: oneof<nothing, bool> # Optional, defaults to true. When true, always includes disruptions that have road closures, regardless of the severity filter. When false, the severity filter works as normal.
]: nothing -> table<category: string, comments: string, corridorIds: list<string>, currentUpdate: string, currentUpdateDateTime: string, endDateTime: string, geography: record<geography: record>, geometry: record<geography: record>, hasClosures: bool, id: string, isProvisional: bool, lastModifiedTime: string, levelOfInterest: string, linkText: string, linkUrl: string, location: string, ordinal: int, point: string, publishEndDate: string, publishStartDate: string, recurringSchedules: list<record>, roadDisruptionImpactAreas: list<record>, roadDisruptionLines: list<record>, roadProject: record<boroughsBenefited: list, constructionEndDate: string, constructionStartDate: string, consultationEndDate: string, consultationPageUrl: string, consultationStartDate: string, contactEmail: string, contactName: string, cycleSuperhighwayId: string, externalPageUrl: string, phase: string, projectDescription: string, projectId: string, projectName: string, projectPageUrl: string, projectSummaryPageUrl: string, schemeName: string>, severity: string, startDateTime: string, status: string, streets: list<record>, subCategory: string, timeFrame: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stripContent" $stripContent "scalar") (serialize-qp "severities" $severities "multi") (serialize-qp "categories" $categories "multi") (serialize-qp "closures" $closures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Road/($ids)/Disruption" $qp)
  let accept_val = ($accept | default "application/geo+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified roads with the status aggregated over the date range specified, or now until the end of today if no dates are passed.
#
# GET /Road/{ids}/Status
# operationId: Road_Status
export def "road-status Status" [
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
  --dateRangeNullablestartDate: string # format: date-time
  --dateRangeNullableendDate: string # format: date-time
]: nothing -> table<bounds: string, displayName: string, envelope: string, group: string, id: string, statusAggregationEndDate: string, statusAggregationStartDate: string, statusSeverity: string, statusSeverityDescription: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRangeNullable.startDate" $dateRangeNullablestartDate "scalar") (serialize-qp "dateRangeNullable.endDate" $dateRangeNullableendDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Road/($ids)/Status" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search the site for occurrences of the query string. The maximum number of results returned is equal to the maximum page size             of 100. To return subsequent pages, use the paginated overload.
#
# GET /Search
# operationId: Search_Get
export def "search Get" [
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
export def "search-bus-schedules BusSchedules" [
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
export def "search-meta-categories MetaCategories" [
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
export def "search-meta-search-providers MetaSearchProviders" [
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
export def "search-meta-sorts MetaSorts" [
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
export def "stop-point GetByGeoPoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stopTypes: list # a list of stopTypes that should be returned (a list of valid stop types can be obtained from the StopPoint/meta/stoptypes endpoint)
  --radius: int # the radius of the bounding circle in metres (default : 200) (format: int32)
  --useStopPointHierarchy: oneof<nothing, bool> # Re-arrange the output into a parent/child hierarchy
  --modes: list # the list of modes to search (comma separated mode names e.g. tube,dlr)
  --categories: list # an optional list of comma separated property categories to return in the StopPoint's property bag. If null or empty, all categories of property are returned. Pass the keyword "none" to return no properties (a valid list of categories can be obtained from the /StopPoint/Meta/categories endpoint)
  --returnLines: oneof<nothing, bool> # true to return the lines that each stop point serves as a nested resource
  --locationlat: float # format: double
  --locationlon: float # format: double
]: nothing -> record<centrePoint: list<float>, page: int, pageSize: int, stopPoints: table<accessibilitySummary: string, additionalProperties: list, children: list, childrenUrls: list, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list, lineModeGroups: list, lines: list, lon: float, modes: list, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stopTypes" $stopTypes "multi") (serialize-qp "radius" $radius "scalar") (serialize-qp "useStopPointHierarchy" $useStopPointHierarchy "scalar") (serialize-qp "modes" $modes "multi") (serialize-qp "categories" $categories "multi") (serialize-qp "returnLines" $returnLines "scalar") (serialize-qp "location.lat" $locationlat "scalar") (serialize-qp "location.lon" $locationlon "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of available StopPoint additional information categories
#
# GET /StopPoint/Meta/Categories
# operationId: StopPoint_MetaCategories
export def "stop-point-meta-categories MetaCategories" [
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
export def "stop-point-meta-modes MetaModes" [
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
export def "stop-point-meta-stop-types MetaStopTypes" [
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
export def "stop-point-mode GetByMode" [
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
  let full_url = (build-url $base $"/StopPoint/Mode/($modes)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a distinct list of disrupted stop points for the given modes
#
# GET /StopPoint/Mode/{modes}/Disruption
# operationId: StopPoint_DisruptionByMode
export def "stop-point-mode-disruption DisruptionByMode" [
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
  --includeRouteBlockedStops: oneof<nothing, bool>
]: nothing -> table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeRouteBlockedStops" $includeRouteBlockedStops "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/Mode/($modes)/Disruption" $qp)
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
  --modes: list # An optional, parameter separated list of the modes to filter by
  --faresOnly: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --maxResults: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches,             it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list # An optional, parameter separated list of the lines to filter by
  --includeHubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tflOperatedNationalRailStationsOnly: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "modes" $modes "multi") (serialize-qp "faresOnly" $faresOnly "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "lines" $lines "multi") (serialize-qp "includeHubs" $includeHubs "scalar") (serialize-qp "tflOperatedNationalRailStationsOnly" $tflOperatedNationalRailStationsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint/Search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search StopPoints by their common name, or their 5-digit Countdown Bus Stop Code.
#
# GET /StopPoint/Search/{query}
# operationId: StopPoint_Search
export def "stop-point-search Search" [
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
  --modes: list # An optional, parameter separated list of the modes to filter by
  --faresOnly: oneof<nothing, bool> # True to only return stations in that have Fares data available for single fares to another station.
  --maxResults: int # An optional result limit, defaulting to and with a maximum of 50. Since children of the stop point heirarchy are returned for matches,             it is possible that the flattened result set will contain more than 50 items. (format: int32)
  --lines: list # An optional, parameter separated list of the lines to filter by
  --includeHubs: oneof<nothing, bool> # If true, returns results including HUBs.
  --tflOperatedNationalRailStationsOnly: oneof<nothing, bool> # If the national-rail mode is included, this flag will filter the national rail stations so that only those operated by TfL are returned
]: nothing -> record<from: int, matches: table<id: string, lat: float, lon: float, name: string, url: string>, maxScore: float, page: int, pageSize: int, provider: string, query: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "multi") (serialize-qp "faresOnly" $faresOnly "scalar") (serialize-qp "maxResults" $maxResults "scalar") (serialize-qp "lines" $lines "multi") (serialize-qp "includeHubs" $includeHubs "scalar") (serialize-qp "tflOperatedNationalRailStationsOnly" $tflOperatedNationalRailStationsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/Search/($query)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the service types for a given stoppoint
#
# GET /StopPoint/ServiceTypes
# operationId: StopPoint_GetServiceTypes
export def "stop-point-service-types GetServiceTypes" [
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
  --lineIds: list # The lines which contain the given Naptan id (all lines relevant to the given stoppoint if empty)
  --modes: list # The modes which the lines are relevant to (all if empty)
]: nothing -> table<lineName: string, lineSpecificServiceTypes: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "lineIds" $lineIds "multi") (serialize-qp "modes" $modes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/StopPoint/ServiceTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a StopPoint for a given sms code.
#
# GET /StopPoint/Sms/{id}
# operationId: StopPoint_GetBySms
export def "stop-point-sms GetBySms" [
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
  let full_url = (build-url $base $"/StopPoint/Sms/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all stop points of a given type
#
# GET /StopPoint/Type/{types}
# operationId: StopPoint_GetByType
export def "stop-point-type GetByType" [
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
  let full_url = (build-url $base $"/StopPoint/Type/($types)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the stop points of given type(s) with a page number
#
# GET /StopPoint/Type/{types}/page/{page}
# operationId: StopPoint_GetByTypeWithPagination
export def "stop-point-type-page GetByTypeWithPagination" [
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
  let full_url = (build-url $base $"/StopPoint/Type/($types)/page/($page)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of StopPoints corresponding to the given list of stop ids.
#
# GET /StopPoint/{ids}
# operationId: StopPoint_Get
export def "stop-point Get" [
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
  --includeCrowdingData: oneof<nothing, bool> # Include the crowding data (static). To Filter further use: /StopPoint/{ids}/Crowding/{line}
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeCrowdingData" $includeCrowdingData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($ids)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all disruptions for the specified StopPointId, plus disruptions for any child Naptan records it may have.
#
# GET /StopPoint/{ids}/Disruption
# operationId: StopPoint_Disruption
export def "stop-point-disruption Disruption" [
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
  --getFamily: oneof<nothing, bool> # Specify true to return disruptions for entire family, or false to return disruptions for just this stop point. Defaults to false.
  --includeRouteBlockedStops: oneof<nothing, bool>
  --flattenResponse: oneof<nothing, bool> # Specify true to associate all disruptions with parent stop point. (Only applicable when getFamily is true).
]: nothing -> table<additionalInformation: string, appearance: string, atcoCode: string, commonName: string, description: string, fromDate: string, mode: string, stationAtcoCode: string, toDate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getFamily" $getFamily "scalar") (serialize-qp "includeRouteBlockedStops" $includeRouteBlockedStops "scalar") (serialize-qp "flattenResponse" $flattenResponse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($ids)/Disruption" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of arrival and departure predictions for the given stop point id (overground, Elizabeth line and thameslink only)
#
# GET /StopPoint/{id}/ArrivalDepartures
# operationId: StopPoint_ArrivalDepartures
export def "stop-point-arrival-departures ArrivalDepartures" [
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
  --lineIds: list # A comma-separated list of line ids e.g. elizabeth, london-overground, thameslink
]: nothing -> table<cause: string, departureStatus: string, destinationName: string, destinationNaptanId: string, estimatedTimeOfArrival: string, estimatedTimeOfDeparture: string, minutesAndSecondsToArrival: string, minutesAndSecondsToDeparture: string, naptanId: string, platformName: string, scheduledTimeOfArrival: string, scheduledTimeOfDeparture: string, stationName: string, timing: record<countdownServerAdjustment: string, insert: string, read: string, received: string, sent: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lineIds" $lineIds "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($id)/ArrivalDepartures" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the list of arrival predictions for the given stop point id
#
# GET /StopPoint/{id}/Arrivals
# operationId: StopPoint_Arrivals
export def "stop-point-arrivals Arrivals" [
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
  let full_url = (build-url $base $"/StopPoint/($id)/Arrivals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets Stopoints that are reachable from a station/line combination.
#
# GET /StopPoint/{id}/CanReachOnLine/{lineId}
# operationId: StopPoint_ReachableFrom
export def "stop-point-can-reach-on-line ReachableFrom" [
  id: string
  lineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --serviceTypes: list # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<accessibilitySummary: string, additionalProperties: list<record>, children: list<record>, childrenUrls: list<string>, commonName: string, distance: float, fullName: string, hubNaptanCode: string, icsCode: string, id: string, indicator: string, individualStopId: string, lat: float, lineGroup: list<record>, lineModeGroups: list<record>, lines: list<record>, lon: float, modes: list<string>, naptanId: string, naptanMode: string, placeType: string, platformName: string, smsCode: string, stationNaptan: string, status: bool, stopLetter: string, stopType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($id)/CanReachOnLine/($lineId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all the Crowding data (static) for the StopPointId, plus crowding data for a given line and optionally a particular direction.
#
# GET /StopPoint/{id}/Crowding/{line}
# operationId: StopPoint_Crowding
export def "stop-point-crowding Crowding" [
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
  let full_url = (build-url $base $"/StopPoint/($id)/Crowding/($line)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the canonical direction, "inbound" or "outbound", for a given pair of stop point Ids in the direction from -&gt; to.
#
# GET /StopPoint/{id}/DirectionTo/{toStopPointId}
# operationId: StopPoint_Direction
export def "stop-point-direction-to Direction" [
  id: string
  toStopPointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --lineId: string # Optional line id filter e.g. victoria
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lineId" $lineId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($id)/DirectionTo/($toStopPointId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the route sections for all the lines that service the given stop point ids
#
# GET /StopPoint/{id}/Route
# operationId: StopPoint_Route
export def "stop-point-route Route" [
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
  --serviceTypes: list # A comma-separated list of service types to filter on. If not specified. Supported values: Regular, Night. Defaulted to 'Regular' if not specified
]: nothing -> table<destinationName: string, direction: string, isActive: bool, lineId: string, lineString: string, mode: string, naptanId: string, routeSectionName: string, serviceType: string, validFrom: string, validTo: string, vehicleDestinationText: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "serviceTypes" $serviceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($id)/Route" $qp)
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
  --placeTypes: list # A comcomma-separated value representing the place types.
]: nothing -> table<additionalProperties: list<record>, children: list<any>, childrenUrls: list<string>, commonName: string, distance: float, id: string, lat: float, lon: float, placeType: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeTypes" $placeTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/StopPoint/($id)/placeTypes" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get car parks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/CarParks
# operationId: StopPoint_GetCarParksById
export def "stop-point-car-parks GetCarParksById" [
  stopPointId: string
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
  let full_url = (build-url $base $"/StopPoint/($stopPointId)/CarParks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of taxi ranks corresponding to the given stop point id.
#
# GET /StopPoint/{stopPointId}/TaxiRanks
# operationId: StopPoint_GetTaxiRanksByIds
export def "stop-point-taxi-ranks GetTaxiRanksByIds" [
  stopPointId: string
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
  let full_url = (build-url $base $"/StopPoint/($stopPointId)/TaxiRanks")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/compareOverlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# operationId: TravelTime_GetCompareOverlay
export def "travel-times-compare-overlay-mapcenter-pinlocation-dimensions GetCompareOverlay" [
  z: int
  pinLat: float
  pinLon: float
  mapCenterLat: float
  mapCenterLon: float
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
  --scenarioTitle: string # The title of the scenario.
  --timeOfDayId: string # The id for the time of day (AM/INTER/PM)
  --modeId: string # The id of the mode.
  --direction: string@direction-completer-1 # The direction of travel.
  --travelTimeInterval: int # The total minutes between the travel time bands (format: int32)
  --compareType: string
  --compareValue: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioTitle" $scenarioTitle "scalar") (serialize-qp "timeOfDayId" $timeOfDayId "scalar") (serialize-qp "modeId" $modeId "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "travelTimeInterval" $travelTimeInterval "scalar") (serialize-qp "compareType" $compareType "scalar") (serialize-qp "compareValue" $compareValue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/TravelTimes/compareOverlay/($z)/mapcenter/($mapCenterLat)/($mapCenterLon)/pinlocation/($pinLat)/($pinLon)/dimensions/($width)/($height)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the TravelTime overlay.
#
# GET /TravelTimes/overlay/{z}/mapcenter/{mapCenterLat}/{mapCenterLon}/pinlocation/{pinLat}/{pinLon}/dimensions/{width}/{height}
# operationId: TravelTime_GetOverlay
export def "travel-times-overlay-mapcenter-pinlocation-dimensions GetOverlay" [
  z: int
  pinLat: float
  pinLon: float
  mapCenterLat: float
  mapCenterLon: float
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
  --scenarioTitle: string # The title of the scenario.
  --timeOfDayId: string # The id for the time of day (AM/INTER/PM)
  --modeId: string # The id of the mode.
  --direction: string@direction-completer-1 # The direction of travel.
  --travelTimeInterval: int # The total minutes between the travel time bands (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-app_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenarioTitle" $scenarioTitle "scalar") (serialize-qp "timeOfDayId" $timeOfDayId "scalar") (serialize-qp "modeId" $modeId "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "travelTimeInterval" $travelTimeInterval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/TravelTimes/overlay/($z)/mapcenter/($mapCenterLat)/($mapCenterLon)/pinlocation/($pinLat)/($pinLon)/dimensions/($width)/($height)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the predictions for a given list of vehicle Id's.
#
# GET /Vehicle/{ids}/Arrivals
# operationId: Vehicle_Get
export def "vehicle-arrivals Get" [
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
  let full_url = (build-url $base $"/Vehicle/($ids)/Arrivals")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
