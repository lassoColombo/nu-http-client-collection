# Auto-generated client for Open-Meteo Historical Weather API v1.0
# Source: https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/historical-weather.yml
# Auth: --token flag or $env.OPEN_METEO_HISTORICAL_WEATHER_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_METEO_HISTORICAL_WEATHER_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost" "https://archive-api.open-meteo.com" "https://customer-archive-api.open-meteo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def temperature-unit-completer [] { ["celsius" "fahrenheit"] }
def wind-speed-unit-completer [] { ["kmh" "kn" "mph" "ms"] }
def precipitation-unit-completer [] { ["inch" "mm"] }
def timeformat-completer [] { ["iso8601" "unixtime"] }
def cell-selection-completer [] { ["land" "nearest" "sea"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "archive get" } } | get name | first)
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

# Open-Meteo Historical Weather API
#
# GET /v1/archive
export def "archive get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: string # Geographical WGS84 coordinates. Multiple coordinates can be comma separated.
  --longitude: string
  --hourly: list # A list of weather variables which should be returned.
  --daily: list # A list of daily weather variable aggregations.
  --start-date: string # Start date in ISO 8601 format. Required. (format: date)
  --end-date: string # End date in ISO 8601 format. Required. (format: date)
  --elevation: float # format: float
  --temperature-unit: string@temperature-unit-completer # default: celsius
  --wind-speed-unit: string@wind-speed-unit-completer # default: kmh
  --precipitation-unit: string@precipitation-unit-completer # default: mm
  --timeformat: string@timeformat-completer # If format unixtime is selected, all time values are returned in UNIX epoch time. (default: iso8601)
  --timezone: string # Any IANA time zone name is supported. Use auto to resolve the local time zone.
  --past-days: int # Return past days of data. (default: 0)
  --forecast-days: int # Number of forecast days. (default: 0)
  --past-hours: int
  --forecast-hours: int
  --tilt: float # Slope tilt in degrees for global_tilted_irradiance calculation. (format: float, default: 0)
  --azimuth: float # Azimuth for global_tilted_irradiance. North=0, East=90, South=180, West=270. (format: float, default: 0)
  --cell-selection: string@cell-selection-completer # Grid cell selection preference: land, sea, or nearest.
  --apikey: string # Only required for commercial subscriptions.
  --models: list # Manually select one or more weather models.
]: nothing -> record<latitude: float, longitude: float, elevation: float, generationtime_ms: float, utc_offset_seconds: int, timezone: string, timezone_abbreviation: string, hourly: record<time: list<string>, temperature_2m: list<float>, relative_humidity_2m: list<float>, dew_point_2m: list<float>, apparent_temperature: list<float>, precipitation: list<float>, rain: list<float>, snowfall: list<float>, snow_depth: list<float>, weather_code: list<int>, pressure_msl: list<float>, surface_pressure: list<float>, cloud_cover: list<float>, cloud_cover_low: list<float>, cloud_cover_mid: list<float>, cloud_cover_high: list<float>, et0_fao_evapotranspiration: list<float>, vapour_pressure_deficit: list<float>, wind_speed_10m: list<float>, wind_speed_100m: list<float>, wind_direction_10m: list<float>, wind_direction_100m: list<float>, wind_gusts_10m: list<float>, soil_temperature_0_to_7cm: list<float>, soil_temperature_7_to_28cm: list<float>, soil_temperature_28_to_100cm: list<float>, soil_temperature_100_to_255cm: list<float>, soil_moisture_0_to_7cm: list<float>, soil_moisture_7_to_28cm: list<float>, soil_moisture_28_to_100cm: list<float>, soil_moisture_100_to_255cm: list<float>, soil_moisture_0_to_100cm: list<float>, soil_temperature_0_to_100cm: list<float>, soil_moisture_index_0_to_7cm: list<float>, soil_moisture_index_7_to_28cm: list<float>, soil_moisture_index_28_to_100cm: list<float>, soil_moisture_index_0_to_100cm: list<float>, boundary_layer_height: list<float>, wet_bulb_temperature_2m: list<float>, total_column_integrated_water_vapour: list<float>, is_day: list<int>, sunshine_duration: list<float>, growing_degree_days_base_0_limit_50: list<float>, leaf_wetness_probability: list<float>, wave_height: list<float>, wave_direction: list<float>, wave_period: list<float>, sea_surface_temperature: list<float>, shortwave_radiation: list<float>, direct_radiation: list<float>, diffuse_radiation: list<float>, direct_normal_irradiance: list<float>, global_tilted_irradiance: list<float>, terrestrial_radiation: list<float>, shortwave_radiation_instant: list<float>, direct_radiation_instant: list<float>, diffuse_radiation_instant: list<float>, direct_normal_irradiance_instant: list<float>, global_tilted_irradiance_instant: list<float>, terrestrial_radiation_instant: list<float>>, hourly_units: record<time: string, temperature_2m: string, relative_humidity_2m: string, dew_point_2m: string, apparent_temperature: string, precipitation: string, rain: string, snowfall: string, snow_depth: string, weather_code: string, pressure_msl: string, surface_pressure: string, cloud_cover: string, cloud_cover_low: string, cloud_cover_mid: string, cloud_cover_high: string, et0_fao_evapotranspiration: string, vapour_pressure_deficit: string, wind_speed_10m: string, wind_speed_100m: string, wind_direction_10m: string, wind_direction_100m: string, wind_gusts_10m: string, soil_temperature_0_to_7cm: string, soil_temperature_7_to_28cm: string, soil_temperature_28_to_100cm: string, soil_temperature_100_to_255cm: string, soil_moisture_0_to_7cm: string, soil_moisture_7_to_28cm: string, soil_moisture_28_to_100cm: string, soil_moisture_100_to_255cm: string, soil_moisture_0_to_100cm: string, soil_temperature_0_to_100cm: string, soil_moisture_index_0_to_7cm: string, soil_moisture_index_7_to_28cm: string, soil_moisture_index_28_to_100cm: string, soil_moisture_index_0_to_100cm: string, boundary_layer_height: string, wet_bulb_temperature_2m: string, total_column_integrated_water_vapour: string, is_day: string, sunshine_duration: string, growing_degree_days_base_0_limit_50: string, leaf_wetness_probability: string, wave_height: string, wave_direction: string, wave_period: string, sea_surface_temperature: string, shortwave_radiation: string, direct_radiation: string, diffuse_radiation: string, direct_normal_irradiance: string, global_tilted_irradiance: string, terrestrial_radiation: string, shortwave_radiation_instant: string, direct_radiation_instant: string, diffuse_radiation_instant: string, direct_normal_irradiance_instant: string, global_tilted_irradiance_instant: string, terrestrial_radiation_instant: string>, daily: record<time: list<string>, weather_code: list<int>, temperature_2m_mean: list<float>, temperature_2m_max: list<float>, temperature_2m_min: list<float>, apparent_temperature_mean: list<float>, apparent_temperature_max: list<float>, apparent_temperature_min: list<float>, sunrise: list<string>, sunset: list<string>, daylight_duration: list<float>, sunshine_duration: list<float>, precipitation_sum: list<float>, rain_sum: list<float>, snowfall_sum: list<float>, precipitation_hours: list<float>, wind_speed_10m_max: list<float>, wind_gusts_10m_max: list<float>, wind_direction_10m_dominant: list<float>, shortwave_radiation_sum: list<float>, et0_fao_evapotranspiration: list<float>, cloud_cover_mean: list<float>, dew_point_2m_mean: list<float>, dew_point_2m_max: list<float>, dew_point_2m_min: list<float>, relative_humidity_2m_mean: list<float>, relative_humidity_2m_max: list<float>, relative_humidity_2m_min: list<float>, pressure_msl_mean: list<float>, wind_speed_10m_mean: list<float>, wet_bulb_temperature_2m_mean: list<float>, vapour_pressure_deficit_max: list<float>, soil_moisture_0_to_7cm_mean: list<float>, soil_moisture_7_to_28cm_mean: list<float>, soil_moisture_28_to_100cm_mean: list<float>, soil_moisture_0_to_100cm_mean: list<float>, soil_temperature_0_to_7cm_mean: list<float>, soil_temperature_7_to_28cm_mean: list<float>, soil_temperature_28_to_100cm_mean: list<float>>, daily_units: record<time: string, weather_code: string, temperature_2m_mean: string, temperature_2m_max: string, temperature_2m_min: string, apparent_temperature_mean: string, apparent_temperature_max: string, apparent_temperature_min: string, sunrise: string, sunset: string, daylight_duration: string, sunshine_duration: string, precipitation_sum: string, rain_sum: string, snowfall_sum: string, precipitation_hours: string, wind_speed_10m_max: string, wind_gusts_10m_max: string, wind_direction_10m_dominant: string, shortwave_radiation_sum: string, et0_fao_evapotranspiration: string, cloud_cover_mean: string, dew_point_2m_mean: string, dew_point_2m_max: string, dew_point_2m_min: string, relative_humidity_2m_mean: string, relative_humidity_2m_max: string, relative_humidity_2m_min: string, pressure_msl_mean: string, wind_speed_10m_mean: string, wet_bulb_temperature_2m_mean: string, vapour_pressure_deficit_max: string, soil_moisture_0_to_7cm_mean: string, soil_moisture_7_to_28cm_mean: string, soil_moisture_28_to_100cm_mean: string, soil_moisture_0_to_100cm_mean: string, soil_temperature_0_to_7cm_mean: string, soil_temperature_7_to_28cm_mean: string, soil_temperature_28_to_100cm_mean: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://archive-api.open-meteo.com")
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "hourly" $hourly "csv") (serialize-qp "daily" $daily "csv") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "elevation" $elevation "scalar") (serialize-qp "temperature_unit" $temperature_unit "scalar") (serialize-qp "wind_speed_unit" $wind_speed_unit "scalar") (serialize-qp "precipitation_unit" $precipitation_unit "scalar") (serialize-qp "timeformat" $timeformat "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "past_days" $past_days "scalar") (serialize-qp "forecast_days" $forecast_days "scalar") (serialize-qp "past_hours" $past_hours "scalar") (serialize-qp "forecast_hours" $forecast_hours "scalar") (serialize-qp "tilt" $tilt "scalar") (serialize-qp "azimuth" $azimuth "scalar") (serialize-qp "cell_selection" $cell_selection "scalar") (serialize-qp "apikey" $apikey "scalar") (serialize-qp "models" $models "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
