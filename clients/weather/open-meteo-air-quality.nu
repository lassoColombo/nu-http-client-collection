# Auto-generated client for Open-Meteo Air Quality API v1.0
# Source: https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/air-quality.yml
# Auth: --token flag or $env.OPEN_METEO_AIR_QUALITY_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_METEO_AIR_QUALITY_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost" "https://air-quality-api.open-meteo.com" "https://customer-air-quality-api.open-meteo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def timeformat-completer [] { ["iso8601" "unixtime"] }
def domains-completer [] { ["auto" "cams_europe" "cams_global"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "air-quality get" } } | get name | first)
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

# Hourly air quality forecast
#
# GET /v1/air-quality
export def "air-quality get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --latitude: string
  --longitude: string
  --hourly: list # A list of air quality variables which should be returned.
  --current: list # A list of variables to return for the current conditions.
  --timeformat: string@timeformat-completer # default: iso8601
  --timezone: string
  --past-days: int # default: 0
  --forecast-days: int # default: 5
  --start-date: string # Start date in ISO 8601 format. (format: date)
  --end-date: string # End date in ISO 8601 format. (format: date)
  --domains: string@domains-completer # CAMS domain: auto, cams_europe, or cams_global.
  --apikey: string # Only required for commercial subscriptions.
]: nothing -> record<latitude: float, longitude: float, elevation: float, generationtime_ms: float, utc_offset_seconds: int, timezone: string, timezone_abbreviation: string, hourly: record<time: list<string>, pm10: list<float>, pm2_5: list<float>, carbon_monoxide: list<float>, carbon_dioxide: list<float>, nitrogen_dioxide: list<float>, sulphur_dioxide: list<float>, ozone: list<float>, aerosol_optical_depth: list<float>, dust: list<float>, uv_index: list<float>, uv_index_clear_sky: list<float>, ammonia: list<float>, methane: list<float>, alder_pollen: list<float>, birch_pollen: list<float>, grass_pollen: list<float>, mugwort_pollen: list<float>, olive_pollen: list<float>, ragweed_pollen: list<float>, formaldehyde: list<float>, glyoxal: list<float>, non_methane_volatile_organic_compounds: list<float>, pm10_wildfires: list<float>, peroxyacyl_nitrates: list<float>, secondary_inorganic_aerosol: list<float>, residential_elementary_carbon: list<float>, total_elementary_carbon: list<float>, pm2_5_total_organic_matter: list<float>, sea_salt_aerosol: list<float>, nitrogen_monoxide: list<float>, european_aqi: list<int>, european_aqi_pm2_5: list<int>, european_aqi_pm10: list<int>, european_aqi_nitrogen_dioxide: list<int>, european_aqi_ozone: list<int>, european_aqi_sulphur_dioxide: list<int>, us_aqi: list<int>, us_aqi_pm2_5: list<int>, us_aqi_pm10: list<int>, us_aqi_nitrogen_dioxide: list<int>, us_aqi_carbon_monoxide: list<int>, us_aqi_ozone: list<int>, us_aqi_sulphur_dioxide: list<int>, is_day: list<int>>, hourly_units: record<time: string, pm10: string, pm2_5: string, carbon_monoxide: string, carbon_dioxide: string, nitrogen_dioxide: string, sulphur_dioxide: string, ozone: string, aerosol_optical_depth: string, dust: string, uv_index: string, uv_index_clear_sky: string, ammonia: string, methane: string, alder_pollen: string, birch_pollen: string, grass_pollen: string, mugwort_pollen: string, olive_pollen: string, ragweed_pollen: string, formaldehyde: string, glyoxal: string, non_methane_volatile_organic_compounds: string, pm10_wildfires: string, peroxyacyl_nitrates: string, secondary_inorganic_aerosol: string, residential_elementary_carbon: string, total_elementary_carbon: string, pm2_5_total_organic_matter: string, sea_salt_aerosol: string, nitrogen_monoxide: string, european_aqi: string, european_aqi_pm2_5: string, european_aqi_pm10: string, european_aqi_nitrogen_dioxide: string, european_aqi_ozone: string, european_aqi_sulphur_dioxide: string, us_aqi: string, us_aqi_pm2_5: string, us_aqi_pm10: string, us_aqi_nitrogen_dioxide: string, us_aqi_carbon_monoxide: string, us_aqi_ozone: string, us_aqi_sulphur_dioxide: string, is_day: string>, current: record<time: string, interval: int, european_aqi: int, us_aqi: int, pm10: float, pm2_5: float, carbon_monoxide: float, nitrogen_dioxide: float, sulphur_dioxide: float, ozone: float, aerosol_optical_depth: float, dust: float, uv_index: float, uv_index_clear_sky: float, ammonia: float, alder_pollen: float, birch_pollen: float, grass_pollen: float, mugwort_pollen: float, olive_pollen: float, ragweed_pollen: float>, current_units: record<time: string, european_aqi: string, us_aqi: string, pm10: string, pm2_5: string, carbon_monoxide: string, nitrogen_dioxide: string, sulphur_dioxide: string, ozone: string, aerosol_optical_depth: string, dust: string, uv_index: string, uv_index_clear_sky: string, ammonia: string, alder_pollen: string, birch_pollen: string, grass_pollen: string, mugwort_pollen: string, olive_pollen: string, ragweed_pollen: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://air-quality-api.open-meteo.com")
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "hourly" $hourly "csv") (serialize-qp "current" $current "csv") (serialize-qp "timeformat" $timeformat "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "past_days" $past_days "scalar") (serialize-qp "forecast_days" $forecast_days "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domains" $domains "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/air-quality" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
