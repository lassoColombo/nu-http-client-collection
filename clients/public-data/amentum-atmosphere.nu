# Auto-generated client for Atmosphere API v1.1.1
# Source: https://api.apis.guru/v2/specs/amentum.space/atmosphere/1.1.1/openapi.json
# Auth: --token flag or $env.ATMOSPHERE_API_TOKEN

const BASE_URL = ""
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ATMOSPHERE_API_TOKEN | default "" }
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
def base-url-completer [] { [""] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "jb2008 atmosphere" } } | get name | first)
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

# Compute atmospheric density and temperatures
#
# GET /jb2008
# operationId: app.api.endpoints.JB2008.sample_atmosphere
export def "jb2008 atmosphere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --year: int # Year in YYYY format (e.g. 2020)
  --month: int # Month in MM format (e.g. 5)
  --day: int # Day in DD format (e.g. 23)
  --altitude: float # Altitude in (km) (e.g. 300)
  --geodetic-latitude: float # GeodeticLatitude (deg) -90 to 90 deg (e.g. 42)
  --geodetic-longitude: float # GeodeticLongitude (deg) 0 to 360 deg (e.g. 42)
  --utc: float # Coordinated Universal Time (hrs) (e.g. 2)
]: nothing -> record<at_alt_temp: record<units: string, value: float>, exospheric_temp: record<units: string, value: float>, total_mass_density: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "geodetic_latitude" $geodetic_latitude "scalar") (serialize-qp "geodetic_longitude" $geodetic_longitude "scalar") (serialize-qp "utc" $utc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/jb2008" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compute atmospheric composition, density, and temperatures
#
# GET /nrlmsise00
# operationId: app.api.endpoints.NRLMSISE00.sample_atmosphere
export def "nrlmsise00 atmosphere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --year: int # Year in YYYY format (e.g. 2020)
  --month: int # Month in MM format (e.g. 5)
  --day: int # Day in DD format (e.g. 23)
  --altitude: float # Altitude in (km) (e.g. 300)
  --geodetic-latitude: float # GeodeticLatitude (deg) -90 to 90 deg (e.g. 42)
  --geodetic-longitude: float # GeodeticLongitude (deg) 0 to 360 deg (e.g. 42)
  --utc: float # Coordinated Universal Time (hrs) (e.g. 2)
  --f107a: float # (Optional) 81 day average of F10.7 flux (SFU) centered on the specified day. F107 and F107A values correspond to the 10.7 cm radio flux at the actual distance of Earth from Sun rather than radio flux at 1 AU. F107, F107A, AP effects can be neglected below 80 km. If unspecified, values provided by the US National Oceanic and  Atmospheric Administration are retrieved automatically.  (e.g. 120)
  --f107: float # (Optional) Daily F10.7 cm radio flux for previous day (SFU). F107 and F107A values correspond to the 10.7 cm radio flux at the actual distance of Earth from Sun rather than radio flux at 1 AU. F107, F107A, AP effects can be neglected below 80 km. If unspecified, values provided by the US National Oceanic and  Atmospheric Administration are retrieved automatically.  (e.g. 120)
  --ap: float # (Optional) The Ap-index provides a daily average level for geomagnetic activity F107, F107A, AP effects can be neglected below 80 km. If unspecified, the average of values in the 24 hours preceding the date-time  are automatically calculated from data provided by GFZ German Research Centre  for Geosciences.  (e.g. 30)
]: nothing -> record<Ar_density: record<units: string, value: float>, H_density: record<units: string, value: float>, He_density: record<units: string, value: float>, N2_density: record<units: string, value: float>, N_density: record<units: string, value: float>, O2_density: record<units: string, value: float>, O_density: record<units: string, value: float>, anomalous_O_density: record<units: string, value: float>, ap: record<value: float>, at_alt_temp: record<units: string, value: float>, exospheric_temp: record<units: string, value: float>, f107: record<units: string, value: float>, f107a: record<units: string, value: float>, total_mass_density: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "geodetic_latitude" $geodetic_latitude "scalar") (serialize-qp "geodetic_longitude" $geodetic_longitude "scalar") (serialize-qp "utc" $utc "scalar") (serialize-qp "f107a" $f107a "scalar") (serialize-qp "f107" $f107 "scalar") (serialize-qp "ap" $ap "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nrlmsise00" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forecast winds, ion and molecular densities, and temperatures in the atmosphere
#
# GET /wam-ipe
# operationId: app.api_wfs.endpoints.WFS.get_values
export def "wam-ipe values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --latitude: float # Latitude (deg) -90 to 90 deg (e.g. 42)
  --longitude: float # Longitude (deg) 0 to 360 deg or -180 to 180 deg (e.g. 42)
  --altitude: float # Altitude in (km) (e.g. 300)
  --year: int # Year in YYYY format (e.g. 2020)
  --month: int # Month in MM format (e.g. 5)
  --day: int # Day in DD format (e.g. 23)
  --hour: int # UTC Hour of the day in 24 hour format (e.g. 15)
  --minute: int # Minute of the given hour (e.g. 10)
]: nothing -> record<N2_density: record<units: string, value: float>, O2_density: record<units: string, value: float>, O_density: record<units: string, value: float>, eastward_wind_neutral: record<units: string, value: float>, northward_wind_neutral: record<units: string, value: float>, point: record<altitude: float, latitude: float, longitude: float>, temp_neutral: record<units: string, value: float>, total_mass_density: record<units: string, value: float>, upward_wind_neutral: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "altitude" $altitude "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wam-ipe" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
