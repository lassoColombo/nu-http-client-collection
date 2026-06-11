# Auto-generated client for Open-Meteo Marine Weather Forecast API v1.0
# Source: https://raw.githubusercontent.com/open-meteo/open-meteo/main/openapi/marine.yml
# Auth: --token flag or $env.OPEN_METEO_MARINE_WEATHER_FORECAST_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_METEO_MARINE_WEATHER_FORECAST_API_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost" "https://marine-api.open-meteo.com" "https://customer-marine-api.open-meteo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def temperature-unit-completer [] { ["celsius" "fahrenheit"] }
def wind-speed-unit-completer [] { ["kmh" "kn" "mph" "ms"] }
def length-unit-completer [] { ["imperial" "metric"] }
def timeformat-completer [] { ["iso8601" "unixtime"] }
def cell-selection-completer [] { ["land" "nearest" "sea"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "marine get" } } | get name | first)
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

# Hourly marine weather forecast
#
# GET /v1/marine
export def "marine get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --latitude: string
  --longitude: string
  --hourly: list # A list of marine weather variables.
  --daily: list # A list of daily marine weather variables.
  --current: list # A list of variables for the current marine conditions.
  --minutely-15: list # A list of marine variables at 15-minute intervals.
  --temperature-unit: string@temperature-unit-completer # default: celsius
  --wind-speed-unit: string@wind-speed-unit-completer # default: kmh
  --length-unit: string@length-unit-completer # Wave height and sea level unit. (default: metric)
  --timeformat: string@timeformat-completer # default: iso8601
  --timezone: string
  --past-days: int # default: 0
  --forecast-days: int # default: 7
  --start-date: string # Start date in ISO 8601 format. (format: date)
  --end-date: string # End date in ISO 8601 format. (format: date)
  --cell-selection: string@cell-selection-completer
  --models: list # Manually select one or more weather models.
  --apikey: string # Only required for commercial subscriptions.
]: nothing -> record<latitude: float, longitude: float, elevation: float, generationtime_ms: float, utc_offset_seconds: int, timezone: string, timezone_abbreviation: string, hourly: record<time: list<string>, wave_height: list<float>, wave_direction: list<float>, wave_period: list<float>, wave_peak_period: list<float>, wind_wave_height: list<float>, wind_wave_direction: list<float>, wind_wave_period: list<float>, wind_wave_peak_period: list<float>, swell_wave_height: list<float>, swell_wave_direction: list<float>, swell_wave_period: list<float>, swell_wave_peak_period: list<float>, secondary_swell_wave_height: list<float>, secondary_swell_wave_period: list<float>, secondary_swell_wave_direction: list<float>, tertiary_swell_wave_height: list<float>, tertiary_swell_wave_period: list<float>, tertiary_swell_wave_direction: list<float>, sea_level_height_msl: list<float>, sea_surface_temperature: list<float>, ocean_current_velocity: list<float>, ocean_current_direction: list<float>>, hourly_units: record<time: string, wave_height: string, wave_direction: string, wave_period: string, wave_peak_period: string, wind_wave_height: string, wind_wave_direction: string, wind_wave_period: string, wind_wave_peak_period: string, swell_wave_height: string, swell_wave_direction: string, swell_wave_period: string, swell_wave_peak_period: string, secondary_swell_wave_height: string, secondary_swell_wave_period: string, secondary_swell_wave_direction: string, tertiary_swell_wave_height: string, tertiary_swell_wave_period: string, tertiary_swell_wave_direction: string, sea_level_height_msl: string, sea_surface_temperature: string, ocean_current_velocity: string, ocean_current_direction: string>, daily: record<time: list<string>, wave_height_max: list<float>, wave_direction_dominant: list<float>, wave_period_max: list<float>, wind_wave_height_max: list<float>, wind_wave_direction_dominant: list<float>, wind_wave_period_max: list<float>, wind_wave_peak_period_max: list<float>, swell_wave_height_max: list<float>, swell_wave_direction_dominant: list<float>, swell_wave_period_max: list<float>, swell_wave_peak_period_max: list<float>>, daily_units: record<time: string, wave_height_max: string, wave_direction_dominant: string, wave_period_max: string, wind_wave_height_max: string, wind_wave_direction_dominant: string, wind_wave_period_max: string, wind_wave_peak_period_max: string, swell_wave_height_max: string, swell_wave_direction_dominant: string, swell_wave_period_max: string, swell_wave_peak_period_max: string>, current: record<time: string, interval: int, wave_height: float, wave_direction: float, wave_period: float, wind_wave_height: float, wind_wave_direction: float, wind_wave_period: float, wind_wave_peak_period: float, swell_wave_height: float, swell_wave_direction: float, swell_wave_period: float, swell_wave_peak_period: float, sea_surface_temperature: float, ocean_current_velocity: float, ocean_current_direction: float>, current_units: record<time: string, wave_height: string, wave_direction: string, wave_period: string, wind_wave_height: string, wind_wave_direction: string, wind_wave_period: string, wind_wave_peak_period: string, swell_wave_height: string, swell_wave_direction: string, swell_wave_period: string, swell_wave_peak_period: string, sea_surface_temperature: string, ocean_current_velocity: string, ocean_current_direction: string>, minutely_15: record<time: list<string>, ocean_current_velocity: list<float>, ocean_current_direction: list<float>, sea_level_height_msl: list<float>>, minutely_15_units: record<time: string, ocean_current_velocity: string, ocean_current_direction: string, sea_level_height_msl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://marine-api.open-meteo.com")
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "hourly" $hourly "csv") (serialize-qp "daily" $daily "csv") (serialize-qp "current" $current "csv") (serialize-qp "minutely_15" $minutely_15 "csv") (serialize-qp "temperature_unit" $temperature_unit "scalar") (serialize-qp "wind_speed_unit" $wind_speed_unit "scalar") (serialize-qp "length_unit" $length_unit "scalar") (serialize-qp "timeformat" $timeformat "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "past_days" $past_days "scalar") (serialize-qp "forecast_days" $forecast_days "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "cell_selection" $cell_selection "scalar") (serialize-qp "models" $models "csv") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/marine" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
