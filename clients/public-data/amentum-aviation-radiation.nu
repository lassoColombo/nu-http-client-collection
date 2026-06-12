# Auto-generated client for Aviation Radiation API v1.5.0
# Source: https://api.apis.guru/v2/specs/amentum.space/aviation_radiation/1.5.0/openapi.json
# Auth: --token flag or $env.AVIATION_RADIATION_API_TOKEN

const BASE_URL = ""
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AVIATION_RADIATION_API_TOKEN | default "" }
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

def base-url-completer [] { [""] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def particle-completer [] { ["Al" "Ar" "B" "Be" "C" "Ca" "Cl" "Cr" "F" "Fe" "K" "Li" "Mg" "Mn" "N" "Na" "Ne" "O" "P" "S" "Sc" "Si" "Ti" "V" "alpha" "deuteron" "e+" "e-" "helion" "mu+" "mu-" "neutron" "photon" "pi+" "pi-" "proton" "total" "triton"] }
def particle-completer-1 [] { ["alpha" "e+" "e-" "gamma" "mu+" "mu-" "neutron" "proton" "total"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cari7-ambient-dose dose" } } | get name | first)
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

# The ambient dose equivalent rate calculated for a single particle type, or accumulated over all particle types.
#
# GET /cari7/ambient_dose
# operationId: app.api_cari7.endpoints.CARI7.ambient_dose
export def "cari7-ambient-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 47 km (the upper limit of the stratosphere). (e.g. 11)
  --latitude: float # Latitude. -90 (S) to 90 (N). (e.g. 30)
  --longitude: float # Longitude. -180 (W) to 180 (E). (e.g. 30)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 12)
  --day: int # Day in DD. (e.g. 1)
  --utc: int # Hour in 24 hour time. (e.g. 3)
  --particle: string@particle-completer # The particle type as a string. Specifying 'total' returns the dose for all particle types.  (e.g. total)
]: nothing -> record<dose_rate: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "altitude" $altitude "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "utc" $utc "scalar") (serialize-qp "particle" $particle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cari7/ambient_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The effective dose rate calculated for a single particle type, or accumulated over all particle types.
#
# GET /cari7/effective_dose
# operationId: app.api_cari7.endpoints.CARI7.effective_dose
export def "cari7-effective-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 47 km (the upper limit of the stratosphere). (e.g. 11)
  --latitude: float # Latitude. -90 (S) to 90 (N). (e.g. 30)
  --longitude: float # Longitude. -180 (W) to 180 (E). (e.g. 30)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 12)
  --day: int # Day in DD. (e.g. 1)
  --utc: int # Hour in 24 hour time. (e.g. 3)
  --particle: string@particle-completer # The particle type as a string. Specifying 'total' returns the dose for all particle types.  (e.g. total)
]: nothing -> record<dose_rate: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "altitude" $altitude "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "utc" $utc "scalar") (serialize-qp "particle" $particle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cari7/effective_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The ambient dose equivalent rate calculated for a single particle type, or accumulated over all particle types.
#
# GET /parma/ambient_dose
# operationId: app.api_parma.endpoints.PARMA.ambient_dose
export def "parma-ambient-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 47 km (the upper limit of the stratosphere). (e.g. 11)
  --atmospheric-depth: float # Atmospheric depth from the top of the atmosphere (in units of g/cm2). The minimum is 0.913 g/cm2, the maximum is 1032.66 g/cm2. WARNING: you can specify either altitude OR atmospheric depth, not both.  (e.g. 0.92)
  --latitude: float # Latitude. -90 (S) to 90 (N). (e.g. 30)
  --longitude: float # Longitude. -180 (W) to 180 (E). (e.g. 30)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 12)
  --day: int # Day in DD. (e.g. 1)
  --particle: string@particle-completer-1 # The particle type as a string. Specifying 'total', only used for the dose calculation, returns the dose for all particle types.  (e.g. proton)
]: nothing -> record<dose_rate: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "altitude" $altitude "scalar") (serialize-qp "atmospheric_depth" $atmospheric_depth "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "particle" $particle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parma/ambient_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The energy differential intensity of a particle at a given zenith angle.
#
# GET /parma/differential_intensity
# operationId: app.api_parma.endpoints.PARMA.differential_intensity
export def "parma-differential-intensity intensity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 47 km (the upper limit of the stratosphere). (e.g. 11)
  --atmospheric-depth: float # Atmospheric depth from the top of the atmosphere (in units of g/cm2). The minimum is 0.913 g/cm2, the maximum is 1032.66 g/cm2. WARNING: you can specify either altitude OR atmospheric depth, not both.  (e.g. 0.92)
  --latitude: float # Latitude. -90 (S) to 90 (N). (e.g. 30)
  --longitude: float # Longitude. -180 (W) to 180 (E). (e.g. 30)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 12)
  --day: int # Day in DD. (e.g. 1)
  --particle: string@particle-completer-1 # The particle type as a string. Specifying 'total', only used for the dose calculation, returns the dose for all particle types.  (e.g. proton)
  --angle: float # Direction cosine. 1.0 is in the downward direction. (e.g. 1)
]: nothing -> record<energies: record<data: list<float>, units: string>, intensities: record<data: list<float>, units: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "altitude" $altitude "scalar") (serialize-qp "atmospheric_depth" $atmospheric_depth "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "particle" $particle "scalar") (serialize-qp "angle" $angle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parma/differential_intensity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The effective dose rate calculated for a single particle type, or accumulated over all particle types.
#
# GET /parma/effective_dose
# operationId: app.api_parma.endpoints.PARMA.effective_dose
export def "parma-effective-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 47 km (the upper limit of the stratosphere). (e.g. 11)
  --atmospheric-depth: float # Atmospheric depth from the top of the atmosphere (in units of g/cm2). The minimum is 0.913 g/cm2, the maximum is 1032.66 g/cm2. WARNING: you can specify either altitude OR atmospheric depth, not both.  (e.g. 0.92)
  --latitude: float # Latitude. -90 (S) to 90 (N). (e.g. 30)
  --longitude: float # Longitude. -180 (W) to 180 (E). (e.g. 30)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 12)
  --day: int # Day in DD. (e.g. 1)
  --particle: string@particle-completer-1 # The particle type as a string. Specifying 'total', only used for the dose calculation, returns the dose for all particle types.  (e.g. proton)
]: nothing -> record<dose_rate: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "altitude" $altitude "scalar") (serialize-qp "atmospheric_depth" $atmospheric_depth "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "particle" $particle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parma/effective_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculate the ambient equivalent dose along a great circle flight route.
#
# GET /route/ambient_dose
# operationId: app.api_icaro.endpoints.ICARO.ambient_dose
export def "route-ambient-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # The ICAO code or IATA code or latitude,longitude pair (in decimal degrees) of the origin airport. (e.g. YSSY)
  --destination: string # The ICAO code or IATA code or latitude,longitude pair (in decimal degrees) of the destination airport. (e.g. 33.94250107,-118.4079971)
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 20 km. (e.g. 10.1)
  --duration: float # The flight duration in hours. The minimum is 0, the maximum is 20 hrs. (e.g. 5)
  --initial-altitude: float # Initial altitude (in km). The minimum is 0 m, the maximum is 20 km. (e.g. 0)
  --cruising-altitudes: list # Cruising altitudes (in km). The minimum is 0 m, the maximum is 20 km. (e.g. [10, 15])
  --climb-times: list # Climb times for each cruising altitude (hours). (e.g. [0.1, 0.5])
  --cruising-times: list # Cruising times at each cruising altitude (hours). (e.g. [1, 2])
  --descent-time: float # Descent time from last cruising altitude to final altitude (hours). (e.g. 0.5)
  --final-altitude: float # Final altitude (in km). (e.g. 0)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 5)
  --day: int # Day in DD. (e.g. 21)
]: nothing -> record<dose: record<date: string, destination: string, origin: string, units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "initial_altitude" $initial_altitude "scalar") (serialize-qp "cruising_altitudes" $cruising_altitudes "multi") (serialize-qp "climb_times" $climb_times "multi") (serialize-qp "cruising_times" $cruising_times "multi") (serialize-qp "descent_time" $descent_time "scalar") (serialize-qp "final_altitude" $final_altitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/route/ambient_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculate the total effective dose along a great circle flight route.
#
# GET /route/effective_dose
# operationId: app.api_icaro.endpoints.ICARO.effective_dose
export def "route-effective-dose dose" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # The ICAO code or IATA code or latitude,longitude pair (in decimal degrees) of the origin airport. (e.g. YSSY)
  --destination: string # The ICAO code or IATA code or latitude,longitude pair (in decimal degrees) of the destination airport. (e.g. 33.94250107,-118.4079971)
  --altitude: float # Altitude (in km). The minimum is 0 m, the maximum is 20 km. (e.g. 10.1)
  --duration: float # The flight duration in hours. The minimum is 0, the maximum is 20 hrs. (e.g. 5)
  --initial-altitude: float # Initial altitude (in km). The minimum is 0 m, the maximum is 20 km. (e.g. 0)
  --cruising-altitudes: list # Cruising altitudes (in km). The minimum is 0 m, the maximum is 20 km. (e.g. [10, 15])
  --climb-times: list # Climb times for each cruising altitude (hours). (e.g. [0.1, 0.5])
  --cruising-times: list # Cruising times at each cruising altitude (hours). (e.g. [1, 2])
  --descent-time: float # Descent time from last cruising altitude to final altitude (hours). (e.g. 0.5)
  --final-altitude: float # Final altitude (in km). (e.g. 0)
  --year: int # Year in YYYY. (e.g. 2019)
  --month: int # Month in MM. (e.g. 5)
  --day: int # Day in DD. (e.g. 21)
]: nothing -> record<dose: record<date: string, destination: string, origin: string, units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "initial_altitude" $initial_altitude "scalar") (serialize-qp "cruising_altitudes" $cruising_altitudes "multi") (serialize-qp "climb_times" $climb_times "multi") (serialize-qp "cruising_times" $cruising_times "multi") (serialize-qp "descent_time" $descent_time "scalar") (serialize-qp "final_altitude" $final_altitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/route/effective_dose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
