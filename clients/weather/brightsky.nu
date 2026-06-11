# Auto-generated client for Bright Sky v2.2.9
# Source: https://api.brightsky.dev/openapi.json
# Auth: --token flag or $env.BRIGHT_SKY_TOKEN

const BASE_URL = "https://api.brightsky.dev"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BRIGHT_SKY_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.brightsky.dev"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def units-completer [] { ["dwd" "si"] }
def format-completer [] { ["bytes" "compressed" "plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sources get" } } | get name | first)
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

# Weather sources (stations)
#
# GET /sources
# operationId: getSources
export def "sources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # Latitude in decimal degrees.
  --lon: float # Longitude in decimal degrees.
  --max-dist: int # Maximum distance of record location from the location given by `lat` and `lon`, in meters. Only has an effect when using `lat` and `lon`. (default: 50000)
  --dwd-station-id: list # DWD station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --wmo-station-id: list # WMO station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --source-id: list # Bright Sky source ID, as retrieved from the [`/sources` endpoint](/operations/getSources). You can supply multiple source IDs separated by commas, ordered from highest to lowest priority.
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
]: nothing -> record<sources: table<id: int, dwd_station_id: string, wmo_station_id: string, station_name: string, observation_type: string, first_record: string, last_record: string, lat: float, lon: float, height: float, distance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "max_dist" $max_dist "scalar") (serialize-qp "dwd_station_id" $dwd_station_id "multi") (serialize-qp "wmo_station_id" $wmo_station_id "multi") (serialize-qp "source_id" $source_id "multi") (serialize-qp "tz" $tz "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Current weather
#
# GET /current_weather
# operationId: getCurrentWeather
export def "current-weather get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # Latitude in decimal degrees.
  --lon: float # Longitude in decimal degrees.
  --max-dist: int # Maximum distance of record location from the location given by `lat` and `lon`, in meters. Only has an effect when using `lat` and `lon`. (default: 50000)
  --dwd-station-id: list # DWD station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --wmo-station-id: list # WMO station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --source-id: list # Bright Sky source ID, as retrieved from the [`/sources` endpoint](/operations/getSources). You can supply multiple source IDs separated by commas, ordered from highest to lowest priority.
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
  --units: string@units-completer # Physical units in which meteorological parameters will be returned. Set to `si` to use <a href="https://en.wikipedia.org/wiki/International_System_of_Units">SI units</a> (except for precipitation, which is always measured in millimeters). The default `dwd` option uses a set of units that is more common in meteorological applications and civil use: <table>   <tr><td></td><td>DWD</td><td>SI</td></tr>   <tr><td>Cloud cover</td><td>%</td><td>%</td></tr>   <tr><td>Dew point</td><td>°C</td><td>K</td></tr>   <tr><td>Precipitation</td><td>mm</td><td><s>kg / m²</s> <strong>mm</strong></td></tr>   <tr><td>Precipitation probability</td><td>%</td><td>%</td></tr>   <tr><td>Pressure</td><td>hPa</td><td>Pa</td></tr>   <tr><td>Relative humidity</td><td>%</td><td>%</td></tr>   <tr><td>Solar irradiation</td><td>kWh / m²</td><td>J / m²</td></tr>   <tr><td>Sunshine</td><td>min</td><td>s</td></tr>   <tr><td>Temperature</td><td>°C</td><td>K</td></tr>   <tr><td>Visibility</td><td>m</td><td>m</td></tr>   <tr><td>Wind (gust) direction</td><td>°</td><td>°</td></tr>   <tr><td>Wind (gust) speed</td><td>km / h</td><td>m / s</td></tr> </table> (default: dwd)
]: nothing -> record<weather: record<timestamp: string, source_id: int, cloud_cover: float, condition: string, dew_point: float, icon: string, pressure_msl: float, relative_humidity: int, temperature: float, visibility: int, fallback_source_ids: record, precipitation_10: float, precipitation_30: float, precipitation_60: float, solar_10: float, solar_30: float, solar_60: float, sunshine_30: int, sunshine_60: int, wind_direction_10: int, wind_direction_30: int, wind_direction_60: int, wind_speed_10: float, wind_speed_30: float, wind_speed_60: float, wind_gust_direction_10: int, wind_gust_direction_30: int, wind_gust_direction_60: int, wind_gust_speed_10: float, wind_gust_speed_30: float, wind_gust_speed_60: float>, sources: table<id: int, dwd_station_id: string, wmo_station_id: string, station_name: string, observation_type: string, first_record: string, last_record: string, lat: float, lon: float, height: float, distance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "max_dist" $max_dist "scalar") (serialize-qp "dwd_station_id" $dwd_station_id "multi") (serialize-qp "wmo_station_id" $wmo_station_id "multi") (serialize-qp "source_id" $source_id "multi") (serialize-qp "tz" $tz "scalar") (serialize-qp "units" $units "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/current_weather" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hourly weather (including forecasts)
#
# GET /weather
# operationId: getWeather
export def "weather get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Timestamp of first weather record (or forecast) to retrieve, in ISO 8601 format. May contain time and/or UTC offset. (format: date-time)
  --last-date: string # Timestamp of last weather record (or forecast) to retrieve, in ISO 8601 format. Will default to `date + 1 day`. (format: date-time)
  --lat: float # Latitude in decimal degrees.
  --lon: float # Longitude in decimal degrees.
  --max-dist: int # Maximum distance of record location from the location given by `lat` and `lon`, in meters. Only has an effect when using `lat` and `lon`. (default: 50000)
  --dwd-station-id: list # DWD station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --wmo-station-id: list # WMO station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --source-id: list # Bright Sky source ID, as retrieved from the [`/sources` endpoint](/operations/getSources). You can supply multiple source IDs separated by commas, ordered from highest to lowest priority.
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
  --units: string@units-completer # Physical units in which meteorological parameters will be returned. Set to `si` to use <a href="https://en.wikipedia.org/wiki/International_System_of_Units">SI units</a> (except for precipitation, which is always measured in millimeters). The default `dwd` option uses a set of units that is more common in meteorological applications and civil use: <table>   <tr><td></td><td>DWD</td><td>SI</td></tr>   <tr><td>Cloud cover</td><td>%</td><td>%</td></tr>   <tr><td>Dew point</td><td>°C</td><td>K</td></tr>   <tr><td>Precipitation</td><td>mm</td><td><s>kg / m²</s> <strong>mm</strong></td></tr>   <tr><td>Precipitation probability</td><td>%</td><td>%</td></tr>   <tr><td>Pressure</td><td>hPa</td><td>Pa</td></tr>   <tr><td>Relative humidity</td><td>%</td><td>%</td></tr>   <tr><td>Solar irradiation</td><td>kWh / m²</td><td>J / m²</td></tr>   <tr><td>Sunshine</td><td>min</td><td>s</td></tr>   <tr><td>Temperature</td><td>°C</td><td>K</td></tr>   <tr><td>Visibility</td><td>m</td><td>m</td></tr>   <tr><td>Wind (gust) direction</td><td>°</td><td>°</td></tr>   <tr><td>Wind (gust) speed</td><td>km / h</td><td>m / s</td></tr> </table> (default: dwd)
]: nothing -> record<weather: table<timestamp: string, source_id: int, cloud_cover: float, condition: string, dew_point: float, icon: string, pressure_msl: float, relative_humidity: int, temperature: float, visibility: int, fallback_source_ids: record, precipitation: float, solar: float, sunshine: int, wind_direction: int, wind_speed: float, wind_gust_direction: int, wind_gust_speed: float, precipitation_probability: int, precipitation_probability_6h: int>, sources: table<id: int, dwd_station_id: string, wmo_station_id: string, station_name: string, observation_type: string, first_record: string, last_record: string, lat: float, lon: float, height: float, distance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "last_date" $last_date "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "max_dist" $max_dist "scalar") (serialize-qp "dwd_station_id" $dwd_station_id "multi") (serialize-qp "wmo_station_id" $wmo_station_id "multi") (serialize-qp "source_id" $source_id "multi") (serialize-qp "tz" $tz "scalar") (serialize-qp "units" $units "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/weather" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Raw SYNOP observations
#
# GET /synop
# operationId: getSynop
export def "synop get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Timestamp of first weather record (or forecast) to retrieve, in ISO 8601 format. May contain time and/or UTC offset. (format: date-time)
  --last-date: string # Timestamp of last weather record (or forecast) to retrieve, in ISO 8601 format. Will default to `date + 1 day`. (format: date-time)
  --dwd-station-id: list # DWD station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --wmo-station-id: list # WMO station ID, typically five alphanumeric characters. You can supply multiple station IDs separated by commas, ordered from highest to lowest priority.
  --source-id: list # Bright Sky source ID, as retrieved from the [`/sources` endpoint](/operations/getSources). You can supply multiple source IDs separated by commas, ordered from highest to lowest priority.
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
  --units: string@units-completer # Physical units in which meteorological parameters will be returned. Set to `si` to use <a href="https://en.wikipedia.org/wiki/International_System_of_Units">SI units</a> (except for precipitation, which is always measured in millimeters). The default `dwd` option uses a set of units that is more common in meteorological applications and civil use: <table>   <tr><td></td><td>DWD</td><td>SI</td></tr>   <tr><td>Cloud cover</td><td>%</td><td>%</td></tr>   <tr><td>Dew point</td><td>°C</td><td>K</td></tr>   <tr><td>Precipitation</td><td>mm</td><td><s>kg / m²</s> <strong>mm</strong></td></tr>   <tr><td>Precipitation probability</td><td>%</td><td>%</td></tr>   <tr><td>Pressure</td><td>hPa</td><td>Pa</td></tr>   <tr><td>Relative humidity</td><td>%</td><td>%</td></tr>   <tr><td>Solar irradiation</td><td>kWh / m²</td><td>J / m²</td></tr>   <tr><td>Sunshine</td><td>min</td><td>s</td></tr>   <tr><td>Temperature</td><td>°C</td><td>K</td></tr>   <tr><td>Visibility</td><td>m</td><td>m</td></tr>   <tr><td>Wind (gust) direction</td><td>°</td><td>°</td></tr>   <tr><td>Wind (gust) speed</td><td>km / h</td><td>m / s</td></tr> </table> (default: dwd)
]: nothing -> record<weather: table<timestamp: string, source_id: int, cloud_cover: float, condition: string, dew_point: float, icon: string, pressure_msl: float, relative_humidity: int, temperature: float, visibility: int, fallback_source_ids: record, precipitation_10: float, precipitation_30: float, precipitation_60: float, solar_10: float, solar_30: float, solar_60: float, sunshine_30: int, sunshine_60: int, wind_direction_10: int, wind_direction_30: int, wind_direction_60: int, wind_speed_10: float, wind_speed_30: float, wind_speed_60: float, wind_gust_direction_10: int, wind_gust_direction_30: int, wind_gust_direction_60: int, wind_gust_speed_10: float, wind_gust_speed_30: float, wind_gust_speed_60: float, sunshine_10: int>, sources: table<id: int, dwd_station_id: string, wmo_station_id: string, station_name: string, observation_type: string, first_record: string, last_record: string, lat: float, lon: float, height: float, distance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "last_date" $last_date "scalar") (serialize-qp "dwd_station_id" $dwd_station_id "multi") (serialize-qp "wmo_station_id" $wmo_station_id "multi") (serialize-qp "source_id" $source_id "multi") (serialize-qp "tz" $tz "scalar") (serialize-qp "units" $units "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/synop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Radar
#
# GET /radar
# operationId: getRadar
export def "radar get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bbox: list # Bounding box (top, left, bottom, right) **in pixels**, edges are inclusive. (_Defaults to full 1200x1100 grid._)
  --distance: int # Alternative way to set a bounding box, must be used together with `lat` and `lon`. Data will reach `distance` meters to each side of this location, but is possibly cut off at the edges of the radar grid. (default: 200000)
  --lat: float # Latitude in decimal degrees.
  --lon: float # Longitude in decimal degrees.
  --date: string # Timestamp of first record to retrieve, in ISO 8601 format. May contain time and/or UTC offset. (_Defaults to 1 hour before latest measurement._) (format: date-time)
  --last-date: string # Timestamp of last record to retrieve, in ISO 8601 format. May contain time and/or UTC offset. (_Defaults to 2 hours after `date`._) (format: date-time)
  --format: string@format-completer #  Determines how the precipitation data is encoded into the `precipitation_5` field: * `compressed`: base64-encoded, zlib-compressed bytestring of 2-byte integers * `bytes`: base64-encoded bytestring of 2-byte integers * `plain`: Nested array of integers          (default: compressed)
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
]: nothing -> record<radar: table<timestamp: string, source: string, precipitation_5: string>, geometry: record, bbox: list<int>, latlon_position: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "bbox" $bbox "multi") (serialize-qp "distance" $distance "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "last_date" $last_date "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "tz" $tz "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Alerts
#
# GET /alerts
# operationId: getAlerts
export def "alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # Latitude in decimal degrees.
  --lon: float # Longitude in decimal degrees.
  --warn-cell-id: int # Municipality warn cell ID.
  --tz: string # Timezone in which record timestamps will be presented, as <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones">tz database name</a>. Will also be used as timezone when parsing `date` and `last_date`, unless these have explicit UTC offsets. If omitted but `date` has an explicit UTC offset, that offset will be used as timezone. Otherwise will default to UTC.
]: nothing -> record<alerts: table<id: int, alert_id: string, status: string, effective: string, onset: string, expires: string, category: string, response_type: string, urgency: string, severity: string, certainty: string, event_code: int, event_en: string, event_de: string, headline_en: string, headline_de: string, description_en: string, description_de: string, instruction_en: string, instruction_de: string>, location: record<warn_cell_id: int, name: string, name_short: string, district: string, state: string, state_short: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "warn_cell_id" $warn_cell_id "scalar") (serialize-qp "tz" $tz "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
