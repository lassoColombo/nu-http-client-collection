# Auto-generated client for Space Radiation API v1.1.2
# Source: https://api.apis.guru/v2/specs/amentum.space/space_radiation/1.1.2/openapi.json
# Auth: --token flag or $env.SPACE_RADIATION_API_TOKEN

const BASE_URL = ""
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPACE_RADIATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { [""] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def model-completer [] { ["AE9" "AP9" "SPME" "SPMH" "SPMHE" "SPMO"] }
def coord-sys-completer [] { ["GDZ" "GEI" "GEO"] }
def coord-units-completer [] { ["KM" "RE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "gcr-flux-dlr get-calculate" } } | get name | first)
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

# Calculate particle flux
#
# GET /gcr/flux_dlr
# operationId: app.api.endpoints.GCR.calculate_dlr_flux
export def "gcr-flux-dlr get-calculate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # e.g. 2017
  --month: int # e.g. 1
  --day: int # e.g. 1
  --z: float # Particle atomic number (e.g. 6)
  --energy: float # Particle energy in MeV/n Valid range: [0, 106] MeV/n (e.g. 100)
]: nothing -> record<flux: record<units: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "z" $z "scalar") (serialize-qp "energy" $energy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/gcr/flux_dlr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Calculate mean particle flux
#
# GET /trapped/flux_mean
# operationId: app.api.endpoints.TrappedRadiation.calculate_flux_mean
export def "trapped-flux-mean get-calculate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string@model-completer # Which model to use: - Energetic electrons (AE9) - Energetic protons (AP9) - Space plasma model for electrons (SPME) - for hydrogen (SPMH) - for helium (SPMHE) - for oxygen (SPMO) (e.g. AE9)
  --coord-sys: string@coord-sys-completer # Coordinate system to use: - Geodetic/WGS84 (GDZ) - Geocentric Cartesian (GEO) - Geocentric Earth Inertial (GEI) See "Bhavnani, K. H., & Vancour, R. P. (1991). Coordinate systems for space and geophysical applications" for coord system definitions. (e.g. GEI)
  --coord-units: string@coord-units-completer # Coordinate units to use: km (KM) or Earth Radii (RE) (e.g. KM)
  --coord1: float # First coordinate value to specify position. Ordering for GEI, GEO coords:X, Y, Z Ordering for GDZ coords: Alt, Lat, Long Valid ranges for latitude: -90, 90 Valid ranges for longitude: 0, 360 (e.g. 3216.6)
  --coord2: float # Second coordinate value. (e.g. 35426)
  --coord3: float # Third coordinate value. (e.g. 603.4)
  --year: int # e.g. 2017
  --month: int # e.g. 1
  --day: int # e.g. 1
  --hour: int # e.g. 0
  --minute: int # e.g. 0
  --second: int # e.g. 0
]: nothing -> record<energies: record<data: list<float>, units: string>, flux: record<data: list<float>, units: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "coord_sys" $coord_sys "scalar") (serialize-qp "coord_units" $coord_units "scalar") (serialize-qp "coord1" $coord1 "scalar") (serialize-qp "coord2" $coord2 "scalar") (serialize-qp "coord3" $coord3 "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar") (serialize-qp "second" $second "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trapped/flux_mean" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Calculate percentile particle flux
#
# GET /trapped/flux_percentile
# operationId: app.api.endpoints.TrappedRadiation.calculate_flux_percentile
export def "trapped-flux-percentile get-calculate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --model: string@model-completer # Which model to use: - Energetic electrons (AE9) - Energetic protons (AP9) - Space plasma model for electrons (SPME) - for hydrogen (SPMH) - for helium (SPMHE) - for oxygen (SPMO) (e.g. AE9)
  --coord-sys: string@coord-sys-completer # Coordinate system to use: - Geodetic/WGS84 (GDZ) - Geocentric Cartesian (GEO) - Geocentric Earth Inertial (GEI) See "Bhavnani, K. H., & Vancour, R. P. (1991). Coordinate systems for space and geophysical applications" for coord system definitions. (e.g. GEI)
  --coord-units: string@coord-units-completer # Coordinate units to use: km (KM) or Earth Radii (RE) (e.g. KM)
  --coord1: float # First coordinate value to specify position. Ordering for GEI, GEO coords:X, Y, Z Ordering for GDZ coords: Alt, Lat, Long Valid ranges for latitude: -90, 90 Valid ranges for longitude: 0, 360 (e.g. 3216.6)
  --coord2: float # Second coordinate value. (e.g. 35426)
  --coord3: float # Third coordinate value. (e.g. 603.4)
  --year: int # e.g. 2017
  --month: int # e.g. 1
  --day: int # e.g. 1
  --hour: int # e.g. 0
  --minute: int # e.g. 0
  --second: int # e.g. 0
  --percentile: int # Integer percentile at which to calc flux (50 is the median value). (e.g. 50)
]: nothing -> record<energies: record<data: list<float>, units: string>, flux: record<data: list<float>, units: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "model" $model "scalar") (serialize-qp "coord_sys" $coord_sys "scalar") (serialize-qp "coord_units" $coord_units "scalar") (serialize-qp "coord1" $coord1 "scalar") (serialize-qp "coord2" $coord2 "scalar") (serialize-qp "coord3" $coord3 "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "month" $month "scalar") (serialize-qp "day" $day "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "minute" $minute "scalar") (serialize-qp "second" $second "scalar") (serialize-qp "percentile" $percentile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/trapped/flux_percentile" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
