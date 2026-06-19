# Auto-generated client for Interactive documentation for your Premium plan vv1
# Source: https://api.apis.guru/v2/specs/meteosource.com/v1/openapi.json
# Auth: --token flag or $env.INTERACTIVE_DOCUMENTATION_FOR_YOUR_PREMIUM_PLAN_TOKEN

const BASE_URL = "http://localhost/api/v1/premium"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o INTERACTIVE_DOCUMENTATION_FOR_YOUR_PREMIUM_PLAN_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://localhost/api/v1/premium"] }
def auth-scheme-completer [] { ["x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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

# Returns air quality data for a single point (geographic name or GPS)
#
# GET /air_quality
# operationId: air_quality_air_quality_get
export def "air-quality get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-id: string # Identifier of a place. To obtain the `place_id` for the location you want, please use endpoints `/find_places_prefix` (search by prefix) or `/find_places` (search by full name).
  --lat: string # Latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.4
  --lon: string # Longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.4
  --timezone: string # Timezone to be used for the date fields. If not specified, local timezone of the forecast location will be used. The format is according to the tzinfo database, so values like `Europe/Prague` or `UTC` can be used. Alternatively you may use the value ``auto`` in which case the local timezone of the location is used. The full list of valid timezone strings can be found [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> record<data: table<aerosol_550: float, air_quality: float, co_surface: float, date: string, dust_550nm: float, dust_mixing_ratio_05: float, no2_surface: float, no_surface: float, ozone_surface: float, ozone_total: float, pm10: float, pm25: float, so2_surface: float>, elevation: int, lat: string, lon: string, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "place_id" $place_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/air_quality" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"place_id": $place_id, "lat": $lat, "lon": $lon, "timezone": $timezone, "key": $key} | compact), body: null}
}

# Search for places. Complete words required.
#
# GET /find_places
# operationId: find_places_find_places_get
export def "find-places get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Place name or ZIP code
  --language: string # The language of text summaries and place names (variable names are never translated). Available languages are: * ``en``: English * ``es``: Spanish * ``fr``: French * ``de``: German * ``pl``: Polish * ``pt``: Portuguese * ``cs``: Czech (default: en)
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> table<adm_area1: string, adm_area2: string, country: string, lat: string, lon: string, name: string, place_id: string, timezone: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/find_places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"text": $text, "language": $language, "key": $key} | compact), body: null}
}

# Prefix search for places. Useful for autocomplete forms.
#
# GET /find_places_prefix
# operationId: find_places_prefix_find_places_prefix_get
export def "find-places-prefix get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Place name or ZIP code
  --language: string # The language of text summaries and place names (variable names are never translated). Available languages are: * ``en``: English * ``es``: Spanish * ``fr``: French * ``de``: German * ``pl``: Polish * ``pt``: Portuguese * ``cs``: Czech (default: en)
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> table<adm_area1: string, adm_area2: string, country: string, lat: string, lon: string, name: string, place_id: string, timezone: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/find_places_prefix" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"text": $text, "language": $language, "key": $key} | compact), body: null}
}

# Returns PNG weather map for given area and variable
#
# GET /map
# operationId: map_map_get
export def "map get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tile-x: int # The X coordinate of Google Maps tile
  --tile-y: int # The Y coordinate of Google Maps tile
  --tile-zoom: int # The zoom level of Google Maps tile
  --min-lat: string # Minimal latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.2
  --min-lon: string # Minimal longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.2
  --max-lat: string # Maximal latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.2.
  --max-lon: string # Maximal longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.2
  --variable: string # Name of the variable for your map. Available values are: * `temperature`: Temperature 2 metres above ground * `feels_like_temperature`: Feels like temperature * `clouds`: Percentage of sky covered by clouds * `precipitation`: Total precipitation amount accumulated since last hour * `wind_speed`: Wind speed 10 metres above the ground * `wind_gust`: Wind gust speed * `pressure`: Atmospheric pressure at mean sea level * `humidity`: Relative humidity * `wave_height`: Wave height * `wave_period`: Wave period * `sea_temperature`: Sea temperature (available only for +-24 hours) * `air_quality`: Air quality index * `ozone_surface`: Ozone at surface level * `ozone_total`: Total column ozone * `no2`: Nitrogen dioxide at surface level * `pm2.5`: Particulate matter d < 2.5 µm (PM2.5)
  --datetime: string # There are two ways to specify date and time for your map: 1. Datetime in `YYYY-MM-DDTHH:MM` format and `UTC` timezone, e.g. `2021-08-24T12:00` 2. Offset from current time in `[+-]<minutes|hours|days>` format, e.g. `+10minutes`, `-2hours` or `+1days`
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tile_x" $tile_x "scalar") (serialize-qp "tile_y" $tile_y "scalar") (serialize-qp "tile_zoom" $tile_zoom "scalar") (serialize-qp "min_lat" $min_lat "scalar") (serialize-qp "min_lon" $min_lon "scalar") (serialize-qp "max_lat" $max_lat "scalar") (serialize-qp "max_lon" $max_lon "scalar") (serialize-qp "variable" $variable "scalar") (serialize-qp "datetime" $datetime "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/map" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"tile_x": $tile_x, "tile_y": $tile_y, "tile_zoom": $tile_zoom, "min_lat": $min_lat, "min_lon": $min_lon, "max_lat": $max_lat, "max_lon": $max_lon, "variable": $variable, "datetime": $datetime, "key": $key} | compact), body: null}
}

# Returns the nearest named location for a given GPS coordinates.
#
# GET /nearest_place
# operationId: nearest_place_nearest_place_get
export def "nearest-place get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string # Latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.4
  --lon: string # Longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.4
  --language: string # The language of text summaries and place names (variable names are never translated). Available languages are: * ``en``: English * ``es``: Spanish * ``fr``: French * ``de``: German * ``pl``: Polish * ``pt``: Portuguese * ``cs``: Czech (default: en)
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> record<adm_area1: string, adm_area2: string, country: string, lat: string, lon: string, name: string, place_id: string, timezone: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/nearest_place" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lat": $lat, "lon": $lon, "language": $language, "key": $key} | compact), body: null}
}

# Returns weather data for a single point (geographic name or GPS)
#
# GET /point
# operationId: point_point_get
export def "point get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-id: string # Identifier of a place. To obtain the `place_id` for the location you want, please use endpoints `/find_places_prefix` (search by prefix) or `/find_places` (search by full name).
  --lat: string # Latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.4
  --lon: string # Longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.4
  --sections: string # Sections to be included in the response. You can specify more section by separating the values with a comma. The available values are: * ``current``: Current weather situation * ``daily``: Forecasts for each whole day, without the daily parts * ``daily-parts``: Forecasts for each whole day, morning, afternoon and evening * Important: forecast for the morning, afternoon and evening is available only for the first 7 days in the forecast * ``hourly``: Forecasts with hourly resolution * ``minutely``: Precipitation forecast with 1 minute resolution * ``alerts``: The weather alerts * ``all``: All sections (default: current,hourly)
  --timezone: string # Timezone to be used for the date fields. If not specified, local timezone of the forecast location will be used. The format is according to the tzinfo database, so values like `Europe/Prague` or `UTC` can be used. Alternatively you may use the value ``auto`` in which case the local timezone of the location is used. The full list of valid timezone strings can be found [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).
  --language: string # The language of text summaries and place names (variable names are never translated). Available languages are: * ``en``: English * ``es``: Spanish * ``fr``: French * ``de``: German * ``pl``: Polish * ``pt``: Portuguese * ``cs``: Czech (default: en)
  --units: string # Unit system to be used. The available values are: * `auto`: Select the system automatically, based on the forecast location. * `metric`: Metric (SI) units (`°C`, `mm/h`, `m/s`, `cm`, `km`, `hPa`). * `us`: Imperial units (`°F`, `in/h`, `mph`, `in`, `mi`, `Hg`). * `uk`: Same as ``metric``, except that visibility is in `miles` and wind speeds are in `mph`. * `ca`: Same as ``metric``, except that wind speeds are in `km/h` and pressure is in `kPa`. (default: auto)
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> record<alerts: record<data: string>, current: record<cloud_cover: float, dew_point: float, feels_like: float, humidity: int, icon: string, icon_num: int, irradiance: float, ozone: float, precipitation: record<total: float, type: string>, pressure: float, summary: string, temperature: float, uv_index: float, visibility: float, wind: record<angle: float, dir: string, gusts: float, speed: float>, wind_chill: float>, daily: record<data: list<record>>, elevation: int, hourly: record<data: list<record>>, lat: string, lon: string, minutely: record<data: list<record>, summary: string>, timezone: string, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "place_id" $place_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "sections" $sections "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/point" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"place_id": $place_id, "lat": $lat, "lon": $lon, "sections": $sections, "timezone": $timezone, "language": $language, "units": $units, "key": $key} | compact), body: null}
}

# Returns weather data for a single location and given day in the past
#
# GET /time_machine
# operationId: time_machine_time_machine_get
export def "time-machine get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-id: string # Identifier of a place. To obtain the `place_id` for the location you want, please use endpoints `/find_places_prefix` (search by prefix) or `/find_places` (search by full name).
  --lat: string # Latitude in format 12N, 12.3N, 12.3, or 13S, 13.2S, -13.4
  --lon: string # Longitude in format 12E, 12.3E, 12.3, or 13W, 13.2W, -13.4
  --date: string # The UTC day of the data in the past. Specify in `YYYY-MM-DD` format, e.g. `2021-08-24`. (format: date)
  --timezone: string # Timezone to be used for the date fields. If not specified, local timezone of the location will be used. The format is according to the tzinfo database, so values like `Europe/Prague` or `UTC` can be used. Alternatively you may use the value ``auto`` in which case the local timezone of the location is used. The full list of valid timezone strings can be found [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).
  --units: string # Unit system to be used. The available values are: * `auto`: Select the system automatically, based on the forecast location. * `metric`: Metric (SI) units (`°C`, `mm/h`, `m/s`, `cm`, `km`, `hPa`). * `us`: Imperial units (`°F`, `in/h`, `mph`, `in`, `mi`, `Hg`). * `uk`: Same as ``metric``, except that visibility is in `miles` and wind speeds are in `mph`. * `ca`: Same as ``metric``, except that wind speeds are in `km/h` and pressure is in `kPa`. (default: auto)
  --key: string # Your unique API key. You can either specify it in this parameter, or set it in `X-API-Key` header.
]: nothing -> record<data: table<cape: int, cloud_cover: record, date: string, dew_point: float, evaporation: int, feels_like: float, humidity: int, icon: int, irradiance: int, ozone: int, precipitation: record, pressure: float, soil_temperature: float, surface_temperature: float, temperature: float, weather: string, wind: record, wind_chill: float>, elevation: int, lat: string, lon: string, statistics: record<precipitation: record<avg: float, probability: int>, temperature: record<avg: float, avg_max: float, avg_min: float, record_max: float, record_min: float>, wind: record<avg_angle: float, avg_dir: string, avg_speed: float, max_gust: float, max_speed: float>>, timezone: string, units: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "place_id" $place_id "scalar") (serialize-qp "lat" $lat "scalar") (serialize-qp "lon" $lon "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "units" $units "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time_machine" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"place_id": $place_id, "lat": $lat, "lon": $lon, "date": $date, "timezone": $timezone, "units": $units, "key": $key} | compact), body: null}
}
